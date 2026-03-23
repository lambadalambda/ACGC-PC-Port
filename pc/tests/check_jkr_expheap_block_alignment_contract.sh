#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXP_HEAP_CPP="$REPO_ROOT/src/static/JSystem/JKernel/JKRExpHeap.cpp"
EXP_HEAP_H="$REPO_ROOT/include/JSystem/JKernel/JKRExpHeap.h"
JKR_ARAM_CPP="$REPO_ROOT/src/static/JSystem/JKernel/JKRAram.cpp"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$EXP_HEAP_CPP" 'static constexpr u32 kExpHeapBlockAlign = \(sizeof\(void\*\) > 4\) \? 8u : 4u;' 'exp heap LP64 block alignment constant is defined'
check_contains "$EXP_HEAP_CPP" 'mHead->initiate\(nullptr, nullptr, p2 - sizeof\(CMemBlock\), 0, 0\);' 'exp heap constructor uses CMemBlock size instead of 0x10'
check_contains "$EXP_HEAP_CPP" 'alignment <= \(int\)kExpHeapBlockAlign' 'head allocation fast path threshold tracks LP64 block alignment'
check_contains "$EXP_HEAP_CPP" '-alignment <= \(int\)kExpHeapBlockAlign' 'tail allocation fast path threshold tracks LP64 block alignment'
check_contains "$EXP_HEAP_CPP" 'size = ALIGN_NEXT\(size, kExpHeapBlockAlign\);' 'exp heap size rounding uses LP64-safe block alignment'

if rg -q 'ALIGN_NEXT\(size, 4\)' "$EXP_HEAP_CPP"; then
    printf '%s\n' 'failing contract: found legacy 4-byte size rounding in JKRExpHeap' >&2
    exit 1
fi

if rg -q 'p2 - 0x10' "$EXP_HEAP_CPP"; then
    printf '%s\n' 'failing contract: JKRExpHeap constructor still assumes 16-byte CMemBlock' >&2
    exit 1
fi

check_contains "$EXP_HEAP_H" 'return \(CMemBlock\*\)\(\(uintptr_t\)data - sizeof\(CMemBlock\)\);' 'JKRExpHeap::CMemBlock::getBlock uses CMemBlock size'
check_contains "$JKR_ARAM_CPP" 'data - sizeof\(JKRExpHeap::CMemBlock\)' 'JKRAram uses LP64-safe CMemBlock header offset'

if rg -q 'data \+ -0x10' "$JKR_ARAM_CPP"; then
    printf '%s\n' 'failing contract: JKRAram still assumes 16-byte CMemBlock header' >&2
    exit 1
fi

printf '%s\n' 'check_jkr_expheap_block_alignment_contract: OK'
