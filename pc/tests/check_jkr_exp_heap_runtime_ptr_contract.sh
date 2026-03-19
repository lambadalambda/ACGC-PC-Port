#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKRExpHeap pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JKRExpHeap pointer truncation: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'uintptr_t startAddr;' 'tail allocation start address type'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'startAddr = ALIGN_PREV\(contentAddr \+ block->mAllocatedSpace - size, align\);' 'tail allocation alignment uses uintptr_t'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'usedSize = \(u32\)\(contentAddr \+ block->mAllocatedSpace - startAddr\);' 'tail allocation size uses pointer diff'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'newBlock = \(CMemBlock\*\)startAddr - 1;' 'tail allocation reconstructs pointer from uintptr_t'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTWarningConsole_f\(":::addr %p: bad heap signature\. \(%c%c\)\\n", \(void\*\)block,' 'heap signature warning uses %p'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTReportConsole_f\("%s %p: %08x  %3d %3d  \(%p %p\)\\n", block->_isTempMemBlock\(\) \? " temp" : "alloc",' 'used block dump uses %p'
check_contains "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTReportConsole_f\("%s %p: %08x  %3d %3d  \(%p %p\)\\n", " free", block->getContent\(\),' 'free block dump uses %p'

check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'u32 start;' 'legacy tail allocation start type'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'start = \(u32\)ALIGN_PREV\(contentAddr \+ block->mAllocatedSpace - size, align\);' 'legacy tail allocation address cast'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'newBlock = \(CMemBlock\*\)start - 1;' 'legacy tail allocation pointer reconstruction'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTWarningConsole_f\(":::addr %08x: bad heap signature\. \(%c%c\)\\n", block,' 'legacy heap signature warning'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTReportConsole_f\("%s %08x: %08x  %3d %3d  \(%08x %08x\)\\n", block->_isTempMemBlock\(\) \? " temp" : "alloc",' 'legacy used block dump'
check_absent "src/static/JSystem/JKernel/JKRExpHeap.cpp" 'JUTReportConsole_f\("%s %08x: %08x  %3d %3d  \(%08x %08x\)\\n", " free", block->getContent\(\),' 'legacy free block dump'
