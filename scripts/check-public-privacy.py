"""Fail on local user paths, current login names or common secret signatures.

Audits tracked files, all reachable Git blobs/metadata, or release archives.
Only upstream toml++/Tracy documentation fixtures may use dummy user paths.
Outputs categories and file names, never matching values.
"""
from pathlib import Path
import argparse, collections, os, re, subprocess, zipfile

USER_PATH=re.compile(rb'(?i)[A-Z]:[\\/]Users[\\/]([^\\/\s\x00\"<>]+)')
SECRET=re.compile(rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[A-Z0-9]{16})\b|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----')
def problems(data,name,forbidden=()):
    result=set()
    forms=[data]
    if b':\0' in data or b'\0:\0' in data:
        forms.extend((data[::2],data[1::2]))
    fixture=name.startswith('ReXGlue/thirdparty/tomlplusplus/tests/') or name=='ReXGlue/thirdparty/tracy/manual/tracy.md'
    for body in forms:
        for match in USER_PATH.finditer(body):
            if not (fixture and match[1].lower() in (b'user',b'nodejs')):result.add('local-user-directory')
        if SECRET.search(body):result.add('credential-signature')
        for value in forbidden:
            if value and value.lower() in body.lower():result.add('local-identity-string')
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--Root',type=Path,default=Path(__file__).resolve().parents[1])
    p.add_argument('--Git',default='git');p.add_argument('--History',action='store_true')
    p.add_argument('--Archive',type=Path,action='append',default=[])
    p.add_argument('--ForbiddenText',action='append',default=[])
    args=p.parse_args();failures=[];counts=collections.Counter()
    forbidden=[s.encode() for s in args.ForbiddenText]
    login=os.environ.get('USERNAME','')
    if len(login)>=4 and login.lower() not in ('user','runner','admin','root','build'):forbidden.append(login.encode())
    def check(data,surface,name):
        counts[surface]+=1
        for kind in problems(data,name,forbidden):failures.append((surface,name,kind))
    def git(*items):return subprocess.check_output([args.Git,'-C',str(args.Root),*items])
    for rel in filter(None,git('ls-files','-z').decode().split('\0')):
        check(rel.encode(),'tracked-name',rel)
        if (args.Root/rel).is_file():check((args.Root/rel).read_bytes(),'tracked-content',rel)
    if args.History:
        for line in git('rev-list','--objects','--all').decode().splitlines():
            oid,_,name=line.partition(' ');kind=git('cat-file','-t',oid).strip().decode()
            check(name.encode(),'history-name',name)
            if kind in ('blob','commit','tag'):check(git('cat-file',kind,oid),'history-'+kind,name or oid)
    for archive in args.Archive:
        with zipfile.ZipFile(archive) as source:
            for info in source.infolist():
                check(info.filename.encode(),'archive-name',info.filename)
                if not info.is_dir():check(source.read(info),'archive-content',info.filename.removeprefix('Majin-Recompile/').removeprefix('Project/'))
    for surface,name,kind in failures:print('FAIL',surface,name,kind)
    print('Privacy scan:',dict(counts),'findings:',len(failures))
    if failures:raise SystemExit(1)

if __name__=='__main__':main()
