"""Remove build-user paths from unsigned Windows PE diagnostic strings.

Changes only equal-length, NUL-terminated ASCII strings in read-only .rdata.
Refuses executable/writable sections, signed images and unexpected PE checksums.
Writes separate output files and a path-free provenance report.
"""
from pathlib import Path
import argparse, hashlib, json, re, struct

USER_PATH=re.compile(rb'(?i)[A-Z]:[\\/]Users[\\/]')

def digest(data): return hashlib.sha256(data).hexdigest().upper()

def sections(data):
    if data[:2]!=b'MZ': raise ValueError('Not a PE image')
    pe=struct.unpack_from('<I',data,0x3c)[0]
    if data[pe:pe+4]!=b'PE\0\0': raise ValueError('Invalid PE header')
    optional=pe+24
    if struct.unpack_from('<H',data,optional)[0]!=0x20b: raise ValueError('Expected PE32+')
    if struct.unpack_from('<I',data,optional+64)[0]: raise ValueError('Nonzero PE checksum requires separate review')
    if any(struct.unpack_from('<II',data,optional+112+8*4)): raise ValueError('Signed image cannot be redacted')
    count=struct.unpack_from('<H',data,pe+6)[0]
    start=optional+struct.unpack_from('<H',data,pe+20)[0]
    result=[]
    for i in range(count):
        off=start+40*i
        name=data[off:off+8].rstrip(b'\0').decode('ascii')
        size,raw=struct.unpack_from('<II',data,off+16)
        flags=struct.unpack_from('<I',data,off+36)[0]
        if raw+size>len(data): raise ValueError('Section outside file')
        result.append((name,raw,raw+size,flags))
    return result

def virtual_path(original):
    normalized=original.replace(b'\\',b'/')
    suffix=None
    for marker,prefix in [(b'/rexglue-sdk-audio-debug/',b'ReXGlue/'),(b'/win-amd64/share/rexglue/',b'SDK/share/rexglue/'),(b'/project/prototype/',b'Project/prototype/')]:
        if marker in normalized:
            suffix=prefix+normalized.split(marker,1)[1];break
    if suffix is None: suffix=b'source/'+normalized.rsplit(b'/',1)[-1]
    padding=len(original)-len(suffix)-7
    if padding<1: raise ValueError('Path too short for neutral mapping')
    return b'build/'+b'_'*padding+b'/'+suffix

def sanitize(data):
    layout=sections(data); result=bytearray(data); changes=[]
    for match in USER_PATH.finditer(data):
        begin=match.start(); end=data.find(b'\0',begin,begin+2048)
        if end<0 or begin==0 or data[begin-1]!=0: raise ValueError('Path is not a standalone string')
        original=data[begin:end]
        if any(c<32 or c>126 for c in original): raise ValueError('Unexpected diagnostic string encoding')
        container=[s for s in layout if s[1]<=begin and end<s[2]]
        if len(container)!=1 or container[0][0]!='.rdata' or container[0][3]&(0x20000000|0x80000000):
            raise ValueError('Path outside read-only non-executable .rdata')
        replacement=virtual_path(original)
        assert len(replacement)==len(original)
        result[begin:end]=replacement
        changes.append({'Offset':begin,'Bytes':len(original),'Section':'.rdata'})
    after=bytes(result)
    for name,start,end,flags in layout:
        if name!='.rdata' and after[start:end]!=data[start:end]: raise AssertionError('Non-diagnostic section changed')
    proof=bytearray(after)
    for change in changes:
        start=change['Offset'];end=start+change['Bytes'];proof[start:end]=data[start:end]
    if bytes(proof)!=data or len(after)!=len(data): raise AssertionError('Unexpected byte changes')
    if USER_PATH.search(after): raise AssertionError('Unmapped build path')
    return after,{'InputSHA256':digest(data),'OutputSHA256':digest(after),'DiagnosticStringsRedacted':len(changes),'OnlyListedDiagnosticStringsChanged':True,'AllExecutableSectionsIdentical':True,'ChangedRanges':changes}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--InputDirectory',required=True,type=Path)
    p.add_argument('--OutputDirectory',required=True,type=Path)
    args=p.parse_args();args.OutputDirectory.mkdir(parents=True,exist_ok=True)
    report={'Method':'Equal-length diagnostic source-path redaction in unsigned PE read-only .rdata; executable sections and all other bytes unchanged','Binaries':{}}
    for name in ('majin.exe','rexruntime.dll','rexgpu-xenos.dll'):
        dest=args.OutputDirectory/name
        if dest.exists(): raise ValueError('Refusing to overwrite existing output')
        value,proof=sanitize((args.InputDirectory/name).read_bytes())
        dest.write_bytes(value);report['Binaries'][name]=proof
    (args.OutputDirectory/'BINARY-PRIVACY.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({name:{k:v for k,v in proof.items() if k!='ChangedRanges'} for name,proof in report['Binaries'].items()},indent=2))

if __name__=='__main__':main()
