#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/game/m_mail_check_ovl.c"

if ! rg -q 'u8\* end_p = str \+ len;' "$FILE"; then
    printf '%s\n' 'missing mail strlen pointer arithmetic contract' >&2
    exit 1
fi

if rg -q 'u8\* end_p = \(u8\*\)\(len \+ \(int\)str\);' "$FILE"; then
    printf '%s\n' 'legacy mail strlen pointer-int cast arithmetic still present' >&2
    exit 1
fi
