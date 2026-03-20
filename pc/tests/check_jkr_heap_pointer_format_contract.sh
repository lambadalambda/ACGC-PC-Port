#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKRHeap pointer-format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JKRHeap pointer format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "alloc %x byte in heap %p", byteCount, \(void\*\)this\);' 'alloc warning prints heap pointer with %p'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "free %p in heap %p", memory, \(void\*\)this\);' 'free warning prints pointers with %p'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "freeAll in heap %p", \(void\*\)this\);' 'freeAll warning prints heap pointer with %p'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "freeTail in heap %p", \(void\*\)this\);' 'freeTail warning prints heap pointer with %p'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "resize block %p into %x in heap %p", memoryBlock, newSize, \(void\*\)this\);' 'resize warning prints pointers with %p'
check_contains "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "change heap ID into %x in heap %p", newGroupID, \(void\*\)this\);' 'changeGroupID warning prints heap pointer with %p'

check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "alloc %x byte in heap %x", byteCount, this\);' 'legacy alloc heap %x format removed'
check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "free %x in heap %x", memory, this\);' 'legacy free %x pointer format removed'
check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "freeAll in heap %x", this\);' 'legacy freeAll heap %x format removed'
check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "freeTail in heap %x", this\);' 'legacy freeTail heap %x format removed'
check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "resize block %x into %x in heap %x", memoryBlock, newSize, this\);' 'legacy resize pointer %x format removed'
check_absent "src/static/JSystem/JKernel/JKRHeap.cpp" 'JUT_WARNING_F\(!mInitFlag, "change heap ID into %x in heap %x", newGroupID, this\);' 'legacy changeGroupID heap %x format removed'
