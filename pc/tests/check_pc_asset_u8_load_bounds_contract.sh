#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

python3 - "$REPO_ROOT" <<'PY'
import pathlib
import re
import sys

repo_root = pathlib.Path(sys.argv[1])
src_root = repo_root / "src"

decl_re = re.compile(r"^\s*static\s+u8\s+([A-Za-z_][A-Za-z0-9_]*)\[(0x[0-9A-Fa-f]+|[0-9]+)\]", re.M)
load_re = re.compile(r"pc_load_asset\([^,]+,\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*(0x[0-9A-Fa-f]+|[0-9]+)\s*,")

violations = []

for path in src_root.rglob("*.c"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    decls = {m.group(1): int(m.group(2), 0) for m in decl_re.finditer(text)}

    if not decls:
        continue

    for m in load_re.finditer(text):
        symbol = m.group(1)
        load_size = int(m.group(2), 0)
        decl_size = decls.get(symbol)

        if decl_size is not None and load_size > decl_size:
            rel_path = path.relative_to(repo_root)
            violations.append(f"{rel_path}: {symbol} decl=0x{decl_size:X} load=0x{load_size:X}")

if violations:
    print("u8 asset load size exceeds destination buffer:", file=sys.stderr)
    for item in violations:
        print(f"  {item}", file=sys.stderr)
    raise SystemExit(1)
PY
