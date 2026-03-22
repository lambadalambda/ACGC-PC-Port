#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
MACRO_FILE="$REPO_ROOT/include/JSystem/JKernel/JKRMacro.h"
JKR_DIR="$REPO_ROOT/src/static/JSystem/JKernel"
JKR_HEAP_CPP="$REPO_ROOT/src/static/JSystem/JKernel/JKRHeap.cpp"

if ! rg -q '#define JKR_HEAP_OBJ_ALIGN ' "$MACRO_FILE"; then
    printf '%s\n' 'missing JKR heap object alignment macro' >&2
    exit 1
fi

if ! rg -q '#define JKR_HEAP_OBJ_ALIGN_TAIL ' "$MACRO_FILE"; then
    printf '%s\n' 'missing JKR heap tail alignment macro' >&2
    exit 1
fi

if rg -q 'new \(JKRGetSystemHeap\(\), -4\)|\? 4 : -4' "$JKR_DIR"; then
    printf '%s\n' 'found legacy 4-byte object alignment in JKernel allocations' >&2
    exit 1
fi

if rg -q 'alloc\(byteCount, 4, nullptr\)' "$JKR_HEAP_CPP"; then
    printf '%s\n' 'found legacy 4-byte default operator new alignment' >&2
    exit 1
fi
