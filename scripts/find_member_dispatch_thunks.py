"""Audit exact member-object dispatch thunks; emit config only with --emit.

Pattern observed at runtime targets 0x824419F8 and 0x82750410.
Only five aligned instructions with a terminal bctr and zero padding qualify.
No guest instruction is replaced. Original code snapshot stays private.
"""
import argparse
import json
import re
import struct
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--emit', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
data = (root / 'private/loaded-text.bin').read_bytes()
mapping = (root / 'prototype/generated/default/majin_init.cpp').read_text()
known = {int(x, 16) for x in re.findall(r'\{ 0x([0-9A-F]{8}),', mapping)}
matches = []
for offset in range(0, len(data) - 23, 4):
    a, b, c, d, e, padding = struct.unpack_from('>6I', data, offset)
    # lwz r3,member(r3); lwz r11,0(r3); lwz r10/r11,slot(r11)
    # mtctr r10/r11; bctr; zero padding.
    if a >> 16 != 0x8063 or b != 0x81630000:
        continue
    if not ((c >> 16 == 0x814B and d == 0x7D4903A6) or
            (c >> 16 == 0x816B and d == 0x7D6903A6)):
        continue
    member, slot = a & 0xFFFF, c & 0xFFFF
    if member >= 0x8000 or member % 4 or slot >= 0x8000 or slot % 4:
        continue
    if e != 0x4E800420 or padding != 0:
        continue
    address = 0x82150000 + offset
    matches.append(dict(address=f'0x{address:08X}', member_offset=member,
                        slot_offset=slot, size=20, registered=address in known))
missing = [item for item in matches if not item['registered']]
if args.emit:
    config = ['# Exact five-instruction member dispatch thunks; see audit report.', '[functions]']
    # Let the analyzer resolve shared tails with existing inner-entry thunks.
    config += [f"{item['address']} = {{ name = \"sub_{item['address'][2:]}\" }}" for item in missing]
    (root / 'prototype/member-dispatch-thunks.toml').write_text('\n'.join(config) + '\n')
(root / 'reports/member-dispatch-thunks.json').write_text(json.dumps(matches, indent=2))
print(json.dumps(dict(matches=len(matches), missing=len(missing), entries=missing), indent=2))
