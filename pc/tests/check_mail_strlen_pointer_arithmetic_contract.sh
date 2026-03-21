#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/game/m_mail_check_ovl.c"

if ! rg -q 'u8\*\s+end_p\s*=\s*str\s*\+\s*len\s*;' "$FILE"; then
    printf '%s\n' 'missing mail strlen pointer arithmetic contract' >&2
    exit 1
fi

if rg -q 'u8\*\s+end_p\s*=\s*\(u8\*\)\(\s*len\s*\+\s*\(int\)str\s*\)\s*;' "$FILE"; then
    printf '%s\n' 'legacy mail strlen pointer-int cast arithmetic still present' >&2
    exit 1
fi
