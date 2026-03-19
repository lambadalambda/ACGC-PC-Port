#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing checked runtime pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRAram.cpp" '#define JKR_ARAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRAram host address'
check_contains "src/static/JSystem/JKernel/JKRAramStream.cpp" '#define JKR_ARAM_STREAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRAramStream host address'
check_contains "src/static/JSystem/JKernel/JKRDvdAramRipper.cpp" '#define JKR_DVD_ARAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDvdAramRipper host address'
check_contains "src/static/JSystem/JKernel/JKRDvdAramRipper.cpp" '#define JKR_DVD_ARAM_CALLBACK_ARG\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDvdAramRipper callback argument'
check_contains "src/static/JSystem/JKernel/JKRDvdAramRipper.cpp" 'u32 length = \(u32\)ALIGN_NEXT\(\(uintptr_t\)\(dmaCurrent - dmaBuf\), 32\);' 'JKRDvdAramRipper keeps DMA length math host-width until final narrow'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" '#include "pc_runtime_ptr.h"' 'JKRHeap includes runtime pointer guard helper'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'uintptr_t userRamSize = \(uintptr_t\)\(\(u8\*\)arenaHi - \(u8\*\)arenaLo\);' 'JKRHeap keeps user RAM size math at host width'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" '\*outUserRamSize = PC_RUNTIME_U32_PTR\(userRamSize\);' 'JKRHeap narrows user RAM size through runtime guard'
check_contains "src/static/JSystem/JKernel/JKRThread.cpp" '#include "pc_runtime_ptr.h"' 'JKRThread includes runtime pointer guard helper'
check_contains "src/static/JSystem/JKernel/JKRThread.cpp" 'uintptr_t stackSize = \(uintptr_t\)threadRecord->stackEnd - \(uintptr_t\)threadRecord->stackBase;' 'JKRThread keeps adopted stack size math at host width'
check_contains "src/static/JSystem/JKernel/JKRThread.cpp" 'this->mStackSize = PC_RUNTIME_U32_PTR\(stackSize\);' 'JKRThread narrows adopted stack size through runtime guard'
check_contains "src/static/JSystem/JKernel/JKRDecomp.cpp" '#define JKR_DECOMP_CALLBACK_ARG\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDecomp callback argument'

if rg -q 'u32 length = ALIGN_NEXT\(\(u32\)\(dmaCurrent - dmaBuf\), 32\);' "$REPO_ROOT/src/static/JSystem/JKernel/JKRDvdAramRipper.cpp"; then
    printf '%s\n' 'unexpected legacy JKR DVD ARAM DMA length truncation' >&2
    exit 1
fi

if rg -q '\*outUserRamSize = \(u32\)\(\(u8\*\)arenaHi - \(u8\*\)arenaLo\);' "$REPO_ROOT/src/static/JSystem/JKernel/JKRHeap.cpp"; then
    printf '%s\n' 'unexpected legacy JKR heap user RAM size truncation' >&2
    exit 1
fi

if rg -q 'this->mStackSize = \(u32\)\(\(uintptr_t\)threadRecord->stackEnd - \(uintptr_t\)threadRecord->stackBase\);' "$REPO_ROOT/src/static/JSystem/JKernel/JKRThread.cpp"; then
    printf '%s\n' 'unexpected legacy JKR thread stack size truncation' >&2
    exit 1
fi
