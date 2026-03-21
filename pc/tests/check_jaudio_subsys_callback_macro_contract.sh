#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/sub_sys.c"

if ! rg -q '#define JAUDIO_U32_CALLBACK\(type, value\) \(\(type\)\(uintptr_t\)\(value\)\)' "$FILE"; then
    printf '%s\n' 'missing jaudio sub_sys callback macro pointer-width cast contract' >&2
    exit 1
fi

if rg -q '#define JAUDIO_U32_CALLBACK\(type, value\) \(\(type\)\(uintptr_t\)\(u32\)\(value\)\)' "$FILE"; then
    printf '%s\n' 'legacy jaudio sub_sys callback macro redundant u32 downcast still present' >&2
    exit 1
fi
