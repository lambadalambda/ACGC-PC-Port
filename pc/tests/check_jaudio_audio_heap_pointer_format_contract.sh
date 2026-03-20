#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/system.c"

if ! rg -q 'AUDIOHEAP SET ADDR %p \(SIZE %xh\)' "$FILE"; then
    printf '%s\n' 'missing jaudio audio heap pointer format contract' >&2
    exit 1
fi

if ! rg -q '\(void\*\)heap_p' "$FILE"; then
    printf '%s\n' 'missing jaudio audio heap pointer cast to void* in diagnostic' >&2
    exit 1
fi

if rg -q 'AUDIOHEAP SET ADDR %xh \(SIZE %xh\) .*PC_RUNTIME_U32_PTR\(heap_p\)' "$FILE"; then
    printf '%s\n' 'legacy jaudio audio heap narrowing diagnostic still present' >&2
    exit 1
fi
