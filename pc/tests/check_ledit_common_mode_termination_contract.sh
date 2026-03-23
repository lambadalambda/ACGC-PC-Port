#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RST_WIN_C="$REPO_ROOT/src/data/model/rst_win.c"

python3 - "$RST_WIN_C" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8", errors="replace").read()

match = re.search(r"Gfx\s+ledit_common_mode\[\]\s*=\s*\{(.*?)\};", text, re.S)
if match is None:
    print(f"missing contract: ledit_common_mode definition ({path})", file=sys.stderr)
    raise SystemExit(1)

body = match.group(1)
if "gsSPEndDisplayList()" not in body:
    print(f"missing contract: ledit_common_mode is terminated ({path})", file=sys.stderr)
    raise SystemExit(1)

print("check_ledit_common_mode_termination_contract: OK")
PY
