#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/pc/src/pc_main.c"

if ! rg -q 'int[[:space:]]+g_pc_selftest[[:space:]]*=[[:space:]]*0;' "$FILE"; then
    printf '%s\n' 'missing pc_main selftest mode flag' >&2
    exit 1
fi

if ! rg -q 'strcmp\(argv\[i\], "--selftest"\) == 0' "$FILE"; then
    printf '%s\n' 'missing pc_main --selftest CLI parse contract' >&2
    exit 1
fi

if ! rg -q 'printf\("  --selftest[[:space:]]+Run startup self-test and exit\\n"\);' "$FILE"; then
    printf '%s\n' 'missing pc_main --selftest help text contract' >&2
    exit 1
fi

if ! rg -q 'if \(g_pc_selftest\) \{' "$FILE"; then
    printf '%s\n' 'missing pc_main selftest early return branch' >&2
    exit 1
fi

if ! rg -q 'printf\("\[PC\] selftest: ok' "$FILE"; then
    printf '%s\n' 'missing pc_main selftest success marker' >&2
    exit 1
fi

python3 - "$FILE" <<'PY'
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
selftest_idx = text.find('if (g_pc_selftest) {')
settings_idx = text.find('pc_settings_load();')

if selftest_idx == -1 or settings_idx == -1 or selftest_idx > settings_idx:
    raise SystemExit('selftest branch must return before platform/settings init')
PY
