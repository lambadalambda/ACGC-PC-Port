#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKR macro pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JKR macro pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/JSystem/JKernel/JKRMacro.h" '#include <stdint\.h>' 'JKR macro header includes stdint'
check_contains "include/JSystem/JKernel/JKRMacro.h" '#define JKR_ISALIGNED\(addr, alignment\) \(\(\(\(uintptr_t\)addr\) & \(\(\(uintptr_t\)alignment\) - 1U\)\) == 0\)' 'JKR_ISALIGNED uses uintptr_t'
check_contains "include/JSystem/JKernel/JKRMacro.h" '#define JKR_ISNOTALIGNED\(addr, alignment\) \(\(\(\(uintptr_t\)addr\) & \(\(\(uintptr_t\)alignment\) - 1U\)\) != 0\)' 'JKR_ISNOTALIGNED uses uintptr_t'
check_contains "include/JSystem/JKernel/JKRMacro.h" '#define JKR_ALIGN\(addr, alignment\) \(\(\(uintptr_t\)addr\) & \(~\(\(\(uintptr_t\)alignment\) - 1U\)\)\)' 'JKR_ALIGN uses uintptr_t'

check_absent "include/JSystem/JKernel/JKRMacro.h" '\(\(\(u32\)addr\) & \(\(\(u32\)alignment\) - 1\)\)' 'legacy JKR_ISALIGNED cast'
check_absent "include/JSystem/JKernel/JKRMacro.h" '\(\(\(u32\)addr\) & \(~\(\(\(u32\)alignment\) - 1\)\)\)' 'legacy JKR_ALIGN cast'
