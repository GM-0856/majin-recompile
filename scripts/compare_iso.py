"""Read-only XDVDFS file/hash comparison; never extracts or modifies inputs."""
import hashlib
import json
import struct
import sys
from pathlib import Path

iso = Path(sys.argv[1])
game = Path(sys.argv[2])
out = Path(sys.argv[3])
size = iso.stat().st_size
magic = b'MICROSOFT*XBOX*MEDIA'
entries = {}
with iso.open('rb') as stream:
    def read(pos, length):
        if pos < 0 or length < 0 or pos + length > size:
            raise ValueError('Out-of-bounds ISO read')
        stream.seek(pos)
        data = stream.read(length)
        if len(data) != length:
            raise ValueError('Short ISO read')
        return data

    bases = []
    for candidate in (0, 0xFD90000, 0x2080000, 0x18300000):
        descriptor = read(candidate + 32 * 2048, 2048)
        if descriptor[:20] == magic and descriptor[-20:] == magic:
            bases.append((candidate, descriptor))
    if len(bases) != 1:
        raise ValueError(f'Expected one game filesystem, found {len(bases)}')
    base, descriptor = bases[0]
    root_sector, root_size = struct.unpack_from('<II', descriptor, 20)
    directories = set()

    def walk(sector, length, parent):
        if not length:
            return
        if (sector, length) in directories or length > 64 * 1024 * 1024:
            raise ValueError('Repeated/oversized directory')
        directories.add((sector, length))
        table = read(base + sector * 2048, length)
        pending, visited = [0], set()
        while pending:
            offset = pending.pop()
            if offset in visited or offset + 14 > length:
                raise ValueError('Invalid directory tree')
            visited.add(offset)
            left, right, file_sector, file_size, flags, n = struct.unpack_from('<HHIIBB', table, offset)
            if offset + 14 + n > length or not n:
                raise ValueError('Invalid name')
            name = table[offset+14:offset+14+n].decode('ascii')
            if name in ('.', '..') or '/' in name or '\\' in name:
                raise ValueError('Unsafe path')
            path = parent + name
            for child in (left, right):
                if child:
                    pending.append(child * 4)
            if flags & 0x10:
                walk(file_sector, file_size, path + '/')
            else:
                key = path.casefold()
                if key in entries:
                    raise ValueError('Duplicate path')
                entries[key] = dict(path=path, bytes=file_size, sector=file_sector)

    walk(root_sector, root_size, '')
    local = {p.relative_to(game).as_posix().casefold(): p for p in game.rglob('*') if p.is_file()}
    print(f'ISO files: {len(entries)}, payload: {sum(e["bytes"] for e in entries.values())}, local files: {len(local)}', flush=True)
    for i, (key, entry) in enumerate(sorted(entries.items(), key=lambda pair: pair[1]['sector'])):
        digest = hashlib.sha256()
        pos, remaining = base + entry['sector'] * 2048, entry['bytes']
        while remaining:
            chunk = read(pos, min(remaining, 1024*1024))
            digest.update(chunk)
            pos += len(chunk)
            remaining -= len(chunk)
        entry['iso_sha256'] = digest.hexdigest()
        p = local.get(key)
        if p is None:
            entry['status'] = 'missing_local'
        else:
            entry['local_bytes'] = p.stat().st_size
            with p.open('rb') as f:
                entry['local_sha256'] = hashlib.file_digest(f, 'sha256').hexdigest()
            entry['status'] = 'identical' if entry['iso_sha256'] == entry['local_sha256'] else 'different'
        if i % 2000 == 0:
            print(f'Compared {i+1}/{len(entries)}', flush=True)
    report = dict(iso=str(iso), iso_bytes=size, partition_offset=base,
                  iso_payload_bytes=sum(e['bytes'] for e in entries.values()),
                  iso_file_count=len(entries), local_file_count=len(local),
                  identical=sum(e['status']=='identical' for e in entries.values()),
                  differences=[e for e in entries.values() if e['status']!='identical'],
                  local_only=[str(local[k].relative_to(game)) for k in local.keys()-entries.keys()],
                  files=list(entries.values()))
    out.write_text(json.dumps(report, indent=2))
    print(json.dumps({k:v for k,v in report.items() if k!='files'}, indent=2), flush=True)
