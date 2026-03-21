#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/channel.c"

if ! rg -q '#define JAUDIO_U32_ADDR_PTR\(type, value\) \(\(type\*\)\(uintptr_t\)\(value\)\)' "$FILE"; then
    printf '%s\n' 'missing jaudio channel address macro pointer-width cast contract' >&2
    exit 1
fi

if rg -q '#define JAUDIO_U32_ADDR_PTR\(type, value\) \(\(type\*\)\(uintptr_t\)\(u32\)\(value\)\)' "$FILE"; then
    printf '%s\n' 'legacy jaudio channel address macro redundant u32 downcast still present' >&2
    exit 1
fi
