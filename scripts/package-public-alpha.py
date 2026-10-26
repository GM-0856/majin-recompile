"""Assemble the public alpha from fingerprinted, already play-tested binaries."""
from pathlib import Path
import argparse, hashlib, json, subprocess, shutil, zipfile, datetime

def sha(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest().upper()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--BuildRecord',required=True,type=Path)
    parser.add_argument('--BinaryInputDirectory',required=True,type=Path)
    parser.add_argument('--LauncherBinary',required=True,type=Path)
    parser.add_argument('--OutputParent',type=Path)
    parser.add_argument('--Candidate',action='store_true',help='Prepare a private, unplaytested candidate; never label it a public release')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    git=shutil.which('git')
    if not git:raise RuntimeError('Git must be on PATH')
    def gitrun(*arguments):return subprocess.check_output([git,'-C',str(root),*arguments],text=True).strip()
    record=json.loads(args.BuildRecord.read_text(encoding='utf-8-sig'))
    if record['Configuration']!='Release' or record['Probe1080pEnabled'] is not False:raise RuntimeError('Unexpected build configuration')
    if gitrun('diff',record['GameSourceRevision'],'HEAD','--','prototype'):raise RuntimeError('Compiled project sources changed')
    if not args.Candidate and record.get('CandidateOnly'):
        raise RuntimeError('Candidate build evidence requires --Candidate; complete gameplay validation before preparing a public release')
    if gitrun('diff','HEAD','--') or gitrun('diff','--cached','--'):raise RuntimeError('Commit tracked changes before public packaging')
    version=(root/'VERSION').read_text().strip()
    parent=args.OutputParent or root/'private/releases'/('v'+version+'-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
    parent.mkdir(parents=True,exist_ok=True)
    destination=parent/'Majin-Recompile'
    destination.mkdir()
    names=['LICENSE','COPYRIGHT.md','VERSION','PUBLICATION.md','README.md','RELEASE_NOTES.md','KEYBOARD_MOUSE.md','CONTROLLERS.md','ISO_IMPORT.md','THIRD_PARTY.md','SDK_DISTRIBUTION.md','SECURITY.md','SECURITY_AUDIT.md','CANDIDATE_VALIDATION.md','DEPENDENCIES.lock.json','CONTRIBUTING.md','ROADMAP.md','AI_USAGE.md','SOURCE_BUILD.md','PLAYTEST_VALIDATION.md','PRIVACY.md','LICENSES/ReXGlue.txt','scripts/launcher.ps1','scripts/run.ps1','scripts/frame-rate.ps1','scripts/game-data.ps1','scripts/disc-import.ps1','scripts/disc-image.cs','scripts/set-game-data.ps1','scripts/collect-diagnostics-assisted.ps1','scripts/collect-diagnostics.ps1','scripts/diagnostics-common.ps1','scripts/performance-metrics.cs','PERFORMANCE_DIAGNOSTICS.md','FPS_60.md']
    visuals=json.loads((root/'assets/launcher/ASSETS.json').read_text())
    for visual in visuals['Files']:
        if sha(root/visual['Path'])!=visual['SHA256']:raise RuntimeError('Launcher asset fingerprint mismatch')
    names+=['assets/launcher/background.png','assets/launcher/logo.png','assets/launcher/majin-fk.ico','assets/launcher/ASSETS.json','assets/launcher/README.md']
    launcher_record=json.loads((args.LauncherBinary.parent/'LAUNCHER-BUILD.json').read_text(encoding='utf-8-sig'))
    if sha(args.LauncherBinary)!=launcher_record['SHA256']:raise RuntimeError('Native launcher fingerprint mismatch')
    for item in launcher_record['SourceInputs']:
        if sha(root/item['Path'])!=item['SHA256']:raise RuntimeError('Native launcher source mismatch')
    notices=json.loads((root/'LICENSES/DEPENDENCY-NOTICES.json').read_text())
    names+=['LICENSES/DEPENDENCY-NOTICES.json']+[n['NoticePath'] for n in notices['Notices']]
    for notice in notices['Notices']:
        if sha(root/notice['NoticePath'])!=notice['SHA256'].upper():raise RuntimeError('Dependency notice changed')
    for relative in dict.fromkeys(names):
        target=destination/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/relative,target)
    for name in ('majin.exe','rexruntime.dll','rexgpu-xenos.dll'):
        path=args.BinaryInputDirectory/name
        if sha(path)!=record['Binaries'][name].upper():raise RuntimeError('Binary fingerprint mismatch: '+name)
        target=destination/'prototype/out/build/win-amd64-release'/name
        target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
    shutil.copy2(args.BuildRecord,destination/'BUILD-EVIDENCE.json')
    if record.get('PrivacyPostprocessing'):
        shutil.copy2(args.BinaryInputDirectory/'BINARY-PRIVACY.json',destination/'BINARY-PRIVACY.json')
    shutil.copy2(args.LauncherBinary,destination/'Majin FK Launcher.exe')
    shutil.copy2(args.LauncherBinary.parent/'LAUNCHER-BUILD.json',destination/'LAUNCHER-BUILD.json')
    (destination/'Collect Diagnostics.cmd').write_text('@echo off\ncd /d "%~dp0"\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\\collect-diagnostics-assisted.ps1" -OpenResult\npause\n',encoding='ascii',newline='\r\n')
    (destination/'READ-ME-FIRST.txt').write_text('''MAJIN RECOMPILE v'''+version+''' - WINDOWS x64 ALPHA

Experimental, unofficial community alpha. European/PAL Xbox 360 ISO tested.
The American/USA and Japanese editions have NOT been tested.
No ISO, gameplay data, DLC, saves or shader caches are included.
Launcher background and icon are bundled; see assets/launcher/README.md.

1. Extract this ZIP completely to a SHORT, writable folder on a local SSD.
   Example: C:\\Games\\Majin. Avoid nesting the long archive name repeatedly.
2. Double-click Majin FK Launcher.exe. No PowerShell console is shown.
3. Choose Import ISO and select your own uncompressed supported Xbox 360 ISO,
   or Browse to extracted data containing default.xex and finalizedXBox360.
4. Start with 1x Native (720p), Original anti-aliasing and Default rendering.
   On the tested Ryzen 5 5500U, use ROV Compatibility; windowed 1280x720 worked.
   Intel Arc B580 worked with Default. ROV may reduce performance.
5. Back up private\\runtime\\user before replacing or deleting this folder.
   Saves stay inside this copy of the app; they are not carried across ZIPs.

Internal 720p/1440p were tested; 1080p internal is unsupported; 4K is unvalidated.
Window/output resolution is separate from internal rendering resolution.
Some stutters, menu-edge stretching, noisy rain and cutscene A/V drift remain.
No full-campaign, universal-hardware or validated high-FPS guarantee is made.
Original is the default. Select 60 FPS (test) for the opt-in capped mode.
Arc 720p/60 tests were near 60; 2x/1440p did not sustain constant 60.
The notebook ROV tests did not sustain 60. Full cinematic timing is unverified.
The owner-tested controller was an 8BitDo Ultimate 2 Wireless. Other devices,
including PS4/PS5, are not all project-tested. See CONTROLLERS.md.

If MSVCP140/VCRUNTIME140 is missing, install Microsoft's Visual C++ x64 runtime:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
The runtime installer is an external prerequisite, not bundled here.

For support, reproduce the problem, close the game and double-click
Collect Diagnostics.cmd. It searches Majin copies and Windows failure events,
then creates a ZIP under reports. Review it before attaching it to an issue.
Nothing is uploaded automatically. Never upload your ISO, game data or saves.

Project code: GPL-3.0-only. Read COPYRIGHT.md, THIRD_PARTY.md and LICENSES.
Matching project/patched SDK/dependency source is provided as a separate
Sources ZIP beside this Windows ZIP on the same GitHub release.
See RELEASE_NOTES.md and PLAYTEST_VALIDATION.md for the exact tested scope.
''',encoding='utf-8',newline='\n')
    if args.Candidate:
        candidate_note='''PRIVATE WINDOWS CANDIDATE - GAMEPLAY VALIDATION PENDING

This package rebuilds the game with the audited project-source changes and uses
the new launcher background, transparent logo and M icon. Runtime/GPU reuse and
their prior build evidence are recorded in BUILD-EVIDENCE.json.

This is a candidate for testing, not the previously play-tested Alpha ZIP.
Do not infer that the older gameplay validation also covers this new executable.
Test Default on Arc B580 and ROV Compatibility on Ryzen 5 5500U: startup,
menu/battle music, gameplay, save, close, restart and reload. Keep known graphical
issues and timing/latency limitations in the test report. No full-campaign,
multi-hour AddressSanitizer or universal-hardware validation is claimed.

No game data, saves, personal settings or shader caches are included in this ZIP.
Use Browse to select your own supported extracted game data, or Import ISO.
Keep your stable installation and saves separate while testing.
'''
        if record.get('FrameRateModeAvailable'):
            candidate_note='''PRIVATE OPTIONAL 60 FPS CANDIDATE - BROADER VALIDATION PENDING

Original remains the default. Select 60 FPS (test) beside VSync to try the new
timing option. Start with 720p internal rendering. See FPS_60.md for scope.
The game and GPU were rebuilt; the audio DLL is unchanged. The source companion
matches the authored timing hooks, SDK changes and pinned dependency revisions.
Private observer route/save/reload tests and exact production startup checks
are distinguished in BUILD-EVIDENCE.json. Test instrumentation is not shipped.
Full campaign, cutscene A/V, notebook/ROV and other GPU validation remain open.
No game data, saves, personal settings, logs or shader caches are included.
Keep the existing stable installation and saves backed up while testing.
'''
        (destination/'CANDIDATE_NOTES.txt').write_text(candidate_note,encoding='utf-8')
        first=destination/'READ-ME-FIRST.txt'
        first.write_text(candidate_note+'\n'+first.read_text(encoding='utf-8'),encoding='utf-8')
        readme=destination/'README.md'
        readme.write_text('> **PRIVATE CANDIDATE:** new executable; gameplay validation pending.\n> See CANDIDATE_NOTES.txt. Statements about the existing Alpha below are historical.\n\n'+readme.read_text(encoding='utf-8'),encoding='utf-8')
    files=[]
    for path in sorted(destination.rglob('*')):
        if path.is_file():files.append({'Path':path.relative_to(destination).as_posix(),'Bytes':path.stat().st_size,'SHA256':sha(path)})
    manifest={'Package':'Majin-Recompile-v'+version+'-Windows-x64','Version':version,'SourceRevision':gitrun('rev-parse','HEAD'),'SourceHasLocalChanges':False,'Configuration':'Release','PublicRelease':True,'WrapperDirectory':'Majin-Recompile','SupportedTestedDisc':'Europe/PAL Xbox 360 revision 4E4D0816 / 67BD87EF / 0.0.0.3','AmericanEditionTested':False,'OriginalGameDataIncluded':False,'Validation':'Scoped owner Arc and notebook tests; Original default, optional 60 mode, known performance/cinematic/controller limits. See PLAYTEST_VALIDATION.md.','BuildEvidence':record,'LauncherBuild':launcher_record,'LauncherVisualAssetsIncluded':True,'Files':files}
    if args.Candidate:
        manifest['Package']+='-candidate'
        manifest['PublicRelease']=False
        manifest['Validation']='Automated candidate checks; optional timing details and remaining broad/manual checks are in BUILD-EVIDENCE.json and FPS_60.md'
        manifest['CandidateOnly']=True
    (destination/'PACKAGE-MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
    archive=parent/('Majin-Recompile-v'+version+('-candidate' if args.Candidate else '')+'-Windows-x64.zip')
    with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as output:
        for path in sorted(destination.rglob('*')):
            if path.is_file():output.write(path,'Majin-Recompile/'+path.relative_to(destination).as_posix())
    archive.with_suffix('.zip.sha256').write_text(sha(archive)+'\n',encoding='ascii')
    subprocess.run([__import__('sys').executable,str(root/'scripts/check-public-privacy.py'),'--Root',str(root),'--History','--Archive',str(archive)],check=True)
    print('Archive:',archive)
    print('SHA256:',sha(archive))

if __name__=='__main__':main()
