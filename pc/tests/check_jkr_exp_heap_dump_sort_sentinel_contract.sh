#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKRExpHeap dump_sort contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JKRExpHeap dump_sort code: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'CMemBlock\* block = nullptr;' 'dump_sort candidate sentinel uses nullptr'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'if \(\(uintptr_t\)var1 < \(uintptr_t\)iterBlock && \(block == nullptr \|\| \(uintptr_t\)iterBlock < \(uintptr_t\)block\)\)' 'dump_sort compares candidate addresses via uintptr_t'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'if \(block == nullptr\) \{' 'dump_sort terminates on nullptr sentinel'

check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" '\(CMemBlock\*\)0xffffffff' 'legacy 32-bit all-ones sentinel removed'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'if \(var1 < iterBlock && iterBlock < block\)' 'legacy raw pointer ordering comparison removed'
