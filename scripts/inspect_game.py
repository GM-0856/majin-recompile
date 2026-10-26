"""Read-only inventory and XEX header inspection. Uses Python's standard library."""
import hashlib
import json
import struct
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "private" / "game-data"
REPORTS = ROOT / "reports"


def main():
    REPORTS.mkdir(exist_ok=True)
    executable = GAME / "default.xex"
    data = executable.read_bytes()
    if data[:4] != b"XEX2":
        raise ValueError("Expected XEX2 signature")
    u32 = lambda offset: struct.unpack_from(">I", data, offset)[0]
    headers = dict(struct.unpack_from(">II", data, 24 + i * 8)
                   for i in range(u32(20)))
    execution = headers[0x40006]
    fmt = headers[0x3FF]
    files = sorted(p for p in GAME.rglob("*") if p.is_file())
    inventory = [{"path": p.relative_to(GAME).as_posix(), "bytes": p.stat().st_size}
                 for p in files]
    report = {
        "game_directory": str(GAME),
        "executable": "default.xex",
        "sha256": hashlib.sha256(data).hexdigest(),
        "xex_bytes": len(data),
        "signature": "XEX2",
        "title_id": f"{u32(execution + 12):08X}",
        "media_id": f"{u32(execution):08X}",
        "version_raw": f"0x{u32(execution + 4):08X}",
        "base_version_raw": f"0x{u32(execution + 8):08X}",
        "entry_point": f"0x{headers[0x10100]:08X}",
        "image_base": f"0x{headers[0x10201]:08X}",
        "encryption_type_raw": struct.unpack_from(">H", data, fmt + 4)[0],
        "compression_type_raw": struct.unpack_from(">H", data, fmt + 6)[0],
        "file_count": len(files),
        "total_bytes": sum(item["bytes"] for item in inventory),
        "extensions": dict(sorted(Counter(p.suffix or "(none)" for p in files).items())),
        "validation_scope": "Header inspection and file inventory only; not a complete integrity or runtime validation.",
    }
    (REPORTS / "game-inventory.json").write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    (REPORTS / "xex-summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
