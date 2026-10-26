"""Export pinned source inputs without Git history, game data or build outputs."""
from pathlib import Path, PurePosixPath
import argparse, subprocess, zipfile, io, json, hashlib, posixpath, shutil, stat


def is_compiled_blob(name, data):
    if PurePosixPath(name).suffix.lower() in ('.exe','.dll','.so','.dylib','.o','.obj','.pdb','.class','.jar'):
        return True
    at=int.from_bytes(data[60:64],'little') if len(data)>=64 and data[:2]==b'MZ' else -1
    if at>=0 and data[at:at+4]==b'PE\0\0':return True
    return data.startswith((b'\x7fELF',b'!<arch>\n',b'\xcf\xfa\xed\xfe',b'\xce\xfa\xed\xfe',b'\xfe\xed\xfa\xcf',b'\xfe\xed\xfa\xce',b'\xca\xfe\xba\xbe',b'\xbe\xba\xfe\xca'))

def omit_prebuilt(name):
    return (name.startswith('ReXGlue/tools/binutils/') and name!='ReXGlue/tools/binutils/LICENSE') or name in (
        'ReXGlue/thirdparty/imgui/examples/libs/glfw/lib-vc2010-32/glfw3.lib',
        'ReXGlue/thirdparty/imgui/examples/libs/glfw/lib-vc2010-64/glfw3.lib',
        'ReXGlue/thirdparty/sdl3/android-project/gradle/wrapper/gradle-wrapper.jar')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ProjectRoot',required=True,type=Path)
    parser.add_argument('--SdkRoot',required=True,type=Path)
    parser.add_argument('--BuildRecord',required=True,type=Path)
    parser.add_argument('--Output',required=True,type=Path)
    parser.add_argument('--PublicRelease',action='store_true')
    parser.add_argument('--LauncherBuildRecord',required=True,type=Path)
    args=parser.parse_args()
    git=shutil.which('git')
    if not git: raise RuntimeError('Git must be on PATH')
    evidence=json.loads(args.BuildRecord.read_text(encoding='utf-8-sig'))
    def gitrun(root,*cmd):
        return subprocess.check_output([git,'-C',str(root),*cmd])
    project_revision=gitrun(args.ProjectRoot,'rev-parse','HEAD').decode().strip()
    for module in evidence['DependencyRevisions']:
        actual=gitrun(args.SdkRoot/'thirdparty'/module['Name'],'rev-parse','HEAD').decode().strip()
        if actual!=module['Revision']: raise RuntimeError('Dependency revision mismatch')
    if gitrun(args.SdkRoot,'rev-parse','HEAD').decode().strip()!=evidence['SdkRevision']:
        raise RuntimeError('SDK revision mismatch')
    # Packaging/docs may advance, but the compiled project inputs must remain exact.
    changed=gitrun(args.ProjectRoot,'diff',evidence['GameSourceRevision'],project_revision,'--','prototype').decode()
    if changed: raise RuntimeError('Compiled project sources changed since clean build')
    if args.Output.exists(): raise RuntimeError('Refusing to overwrite source archive')
    args.Output.parent.mkdir(parents=True,exist_ok=True)
    patched=['src/audio/xma_context.cpp','src/audio/empty_packet_recovery.h','src/audio/empty_packet_recovery_test.cpp','src/core/logging.cpp','src/core/texture_warning_sink.h','src/graphics/command_processor.cpp','src/graphics/release_frame_timing.h','src/graphics/graphics_system.cpp','src/graphics/frame_deadline.h']
    inventory=[]; materialized=[]; omitted_prebuilt=[]
    with zipfile.ZipFile(args.Output,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as output:
        def write(name,data):
            parts=PurePosixPath(name).parts
            if any(p in ('.git','private','out','reports','__pycache__') for p in parts):raise RuntimeError('Excluded source path: '+name)
            if PurePosixPath(name).suffix.lower() in ('.iso','.xex','.pak','.gtd','.ged','.pdb','.obj'):raise RuntimeError('Excluded source content: '+name)
            if is_compiled_blob(name,data):raise RuntimeError('Compiled file in source companion: '+name)
            info=zipfile.ZipInfo(name,date_time=(2026,10,2,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=(stat.S_IFREG|0o644)<<16
            output.writestr(info,data)
            inventory.append({'Path':name,'Bytes':len(data),'SHA256':hashlib.sha256(data).hexdigest().upper()})
        def export(root,revision,prefix,skip=()):
            data=gitrun(root,'archive','--format=zip',revision)
            with zipfile.ZipFile(io.BytesIO(data)) as source:
                entries={i.filename:i for i in source.infolist() if not i.is_dir()}
                def contents(name,seen=()):
                    if name in seen:raise RuntimeError('Cyclic source symlink')
                    item=entries[name]
                    value=source.read(item)
                    if stat.S_ISLNK(item.external_attr>>16):
                        target=posixpath.normpath(posixpath.join(posixpath.dirname(name),value.decode()))
                        if target.startswith('../') or target.startswith('/') or target not in entries:raise RuntimeError('Source symlink leaves dependency')
                        materialized.append(prefix+name)
                        return contents(target,seen+(name,))
                    return value
                for name in sorted(entries):
                    full=prefix+name
                    omit=omit_prebuilt(full)
                    if omit:
                        data=contents(name)
                        omitted_prebuilt.append({'Path':full,'Bytes':len(data),'SHA256':hashlib.sha256(data).hexdigest().upper(),'Reason':'Optional upstream PPC-test, ImGui example or Android Gradle prebuilt; not needed by documented Windows build with REXGLUE_BUILD_TESTS=OFF.'})
                        continue
                    if name not in skip:write(full,contents(name))
        export(args.ProjectRoot,project_revision,'Project/')
        export(args.SdkRoot,evidence['SdkRevision'],'ReXGlue/',patched)
        for path in patched:write('ReXGlue/'+path,(args.SdkRoot/path).read_bytes())
        for module in evidence['DependencyRevisions']:
            name=module['Name']
            export(args.SdkRoot/'thirdparty'/name,module['Revision'],'ReXGlue/thirdparty/'+name+'/')
        write('BUILD-EVIDENCE.json',args.BuildRecord.read_bytes())
        write('LAUNCHER-BUILD.json',args.LauncherBuildRecord.read_bytes())
        if evidence.get('PrivacyPostprocessing'):
            write('BINARY-PRIVACY.json',(args.BuildRecord.parent/'sanitized-binaries/BINARY-PRIVACY.json').read_bytes())
        write('SOURCE_BUILD.md',(args.ProjectRoot/'SOURCE_BUILD.md').read_bytes())
        write('SDK_DISTRIBUTION.md',(args.ProjectRoot/'SDK_DISTRIBUTION.md').read_bytes())
        metadata={'ProjectSourceRevision':project_revision,'GameSourceRevision':evidence['GameSourceRevision'],'SdkRevision':evidence['SdkRevision'],'DependencyRevisions':evidence['DependencyRevisions'],'PatchedSdkFiles':patched,'MaterializedSourceSymlinks':sorted(set(materialized)),'ExcludedPrebuiltTools':omitted_prebuilt,'GameDerivedGeneratedSourcesIncluded':False,'OriginalGameDataIncluded':False,'PublicRelease':args.PublicRelease,'Files':inventory}
        output.writestr('SOURCE-INVENTORY.json',json.dumps(metadata,indent=2))
    digest=hashlib.sha256(args.Output.read_bytes()).hexdigest().upper()
    args.Output.with_suffix(args.Output.suffix+'.sha256').write_text(digest+'\n',encoding='ascii')
    subprocess.run([__import__('sys').executable,str(args.ProjectRoot/'scripts/check-public-privacy.py'),'--Root',str(args.ProjectRoot),'--History','--Archive',str(args.Output)],check=True)
    print('Source companion:',args.Output)
    print('Files:',len(inventory),'SHA256:',digest)

if __name__=='__main__':main()
