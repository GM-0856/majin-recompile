"""Find exact 4-instruction virtual dispatch thunks in a private code snapshot.

No guessing of function boundaries: each match is lwz/lwz/mtctr/bctr, 16 bytes.
This writes a candidate report only. Config additions require review.
"""
import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
data = (ROOT / 'private/loaded-text.bin').read_bytes()
base = 0x82150000
mapping = (ROOT / 'prototype/generated/default/majin_init.cpp').read_text()
known = {int(x, 16) for x in re.findall(r'\{ 0x([0-9A-F]{8}),', mapping)}
results = []
for offset in range(0, len(data) - 15, 4):
    a, b, c, d = struct.unpack_from('>4I', data, offset)
    # lwz r12,0(r3); lwz r11,slot(r12), or both loads through r11.
    valid_loads = ((a == 0x81830000 and b >> 16 == 0x816C) or
                   (a == 0x81630000 and b >> 16 == 0x816B))
    slot = b & 0xFFFF
    if valid_loads and slot % 4 == 0 and slot < 0x8000 and c == 0x7D6903A6 and d == 0x4E800420:
        address = base + offset
        results.append({'address': f'0x{address:08X}', 'slot_offset': slot,
                        'registered': address in known, 'size': 16,
                        'words': [f'{word:08X}' for word in (a,b,c,d)]})
(ROOT / 'reports/dispatch-thunks.json').write_text(json.dumps(results, indent=2))
missing = [item for item in results if not item['registered']]
print(f'Exact matches: {len(results)}; already registered: {len(results)-len(missing)}; missing: {len(missing)}')
print(json.dumps(missing[:12], indent=2))
