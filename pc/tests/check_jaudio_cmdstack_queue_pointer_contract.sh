#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/cmdstack.c"
HDR="$REPO_ROOT/include/jaudio_NES/cmdstack.h"

if ! rg -q 'uintptr_t _00;' "$HDR"; then
    printf '%s\n' 'missing jaudio cmdstack head pointer-width storage contract' >&2
    exit 1
fi

if ! rg -q 'uintptr_t _04;' "$HDR"; then
    printf '%s\n' 'missing jaudio cmdstack tail pointer-width storage contract' >&2
    exit 1
fi

if ! rg -q '#define CMDSTACK_LINK_CAPACITY' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack shadow-link table contract' >&2
    exit 1
fi

if ! rg -q 'if \(!set_cmd_next\(a2, NULL\)\)' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack enqueue link-allocation guard contract' >&2
    exit 1
fi

if ! rg -q 'port->_00 = \(uintptr_t\)a2;' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack head enqueue pointer-width contract' >&2
    exit 1
fi

if ! rg -q 'port->_04 = \(uintptr_t\)a2;' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack tail enqueue pointer-width contract' >&2
    exit 1
fi

if ! rg -q 'port->_00 = \(uintptr_t\)next;' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack dequeue pointer-width contract' >&2
    exit 1
fi

if ! rg -q 'p = \(uintptr_t\)get_cmd_next\(\(u32\*\)\(uintptr_t\)p\);' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack stay-queue pointer-width traversal contract' >&2
    exit 1
fi

if ! rg -q 'a2\[3\]\s*=\s*1;' "$FILE"; then
    printf '%s\n' 'missing jaudio cmdstack in-queue sentinel contract' >&2
    exit 1
fi

if rg -q 'PC_RUNTIME_U32_PTR\(' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack u32 pointer narrowing helper usage still present' >&2
    exit 1
fi

if rg -q '\(\(int\*\)port->_04\)\[4\] = \(int\)a2;' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack tail-link pointer-int cast still present' >&2
    exit 1
fi

if rg -q 'port->_00 = \(int\)a2;' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack head-link pointer-int cast still present' >&2
    exit 1
fi

if rg -q 'port->_04 = \(int\)a2;' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack tail pointer-int cast still present' >&2
    exit 1
fi

if rg -q 'a2\[3\]\s*=\s*\(int\)port;' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack queue-owner pointer-int cast still present' >&2
    exit 1
fi

if rg -q 'p = \(\(u32\*\)\(uintptr_t\)p\)\[4\];' "$FILE"; then
    printf '%s\n' 'legacy jaudio cmdstack stay-queue u32 next traversal still present' >&2
    exit 1
fi
