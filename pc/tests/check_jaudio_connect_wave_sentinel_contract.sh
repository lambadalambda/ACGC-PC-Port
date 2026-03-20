#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/connect.c"

if ! rg -q '\(uintptr_t\)wave->data != \(uintptr_t\)0xffffffffu' "$FILE"; then
    printf '%s\n' 'missing jaudio connect LP64 sentinel contract' >&2
    exit 1
fi

if rg -q '\(int\)wave->data != 0xffffffff' "$FILE"; then
    printf '%s\n' 'legacy jaudio connect pointer-int sentinel cast still present' >&2
    exit 1
fi
