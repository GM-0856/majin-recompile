"""Audit four-instruction virtual dispatch through volatile r9-r12.

Recognize lwz table,0(r3); lwz target,slot(table); mtctr target; bctr.
Only missing entry seeds are emitted, with sizes inferred for shared tails.
"""
import json
import re
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data = (root / 'private/loaded-text.bin').read_bytes()
mapping = (root / 'prototype/generated/default/majin_init.cpp').read_text()
known = {int(x, 16) for x in re.findall(r'\{ 0x([0-9A-F]{8}),', mapping)}
matches = []
for offset in range(0, len(data) - 15, 4):
    a, b, c, d = struct.unpack_from('>4I', data, offset)
    table, target = (a >> 21) & 31, (b >> 21) & 31
    if table not in range(9, 13) or target not in range(9, 13):
        continue
    if a != (0x80030000 | (table << 21)):
        continue
    if b >> 16 != (0x8000 | (target << 5) | table):
        continue
    slot = b & 0xFFFF
    if slot >= 0x8000 or slot % 4:
        continue
    if c != (0x7C0903A6 | (target << 21)) or d != 0x4E800420:
        continue
    address = offset + 0x82150000
    matches.append(dict(address=f'0x{address:08X}', table_register=table,
                        target_register=target, slot=slot, registered=address in known))
missing = [item for item in matches if not item['registered']]
(root / 'reports/dispatch-variants.json').write_text(json.dumps(matches, indent=2))
print(json.dumps(dict(matches=len(matches), missing=len(missing), entries=missing), indent=2))
