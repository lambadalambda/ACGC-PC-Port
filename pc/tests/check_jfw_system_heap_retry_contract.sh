#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JFW system heap retry contract: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" '#if defined\(TARGET_PC\) && defined\(PC_EXPERIMENTAL_64BIT\)' 'LP64-only fallback guard'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'if \(systemHeap == nullptr && rootHeap != nullptr\)' 'retry path only when initial create fails'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'u32 retrySize = \(u32\)rootHeap->getFreeSize\(\);' 'retry starts from current root free size'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'retrySize = \(retrySize - 0x10\) & ~0xFu;' 'retry size keeps 16-byte alignment and headroom'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'systemHeap = JKRExpHeap::create\(retrySize, rootHeap, false\);' 'retry path re-attempts system heap create'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'CSetUpParam::sysHeapSize = retrySize;' 'successful retry updates configured system heap size'
check_contains "src/static/JSystem/JFramework/JFWSystem.cpp" 'JFWSystem::firstInit: reduced sys heap size to %08x' 'retry path logs adjusted size for diagnosis'
