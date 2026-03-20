#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing PC OS physical-address width contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy PC OS physical-address cast: $label" >&2
        exit 1
    fi
}

check_contains "pc/src/pc_os.c" '#include "pc_runtime_ptr.h"' 'pc_os uses runtime checked narrowing helper'
check_contains "pc/src/pc_os.c" 'u32 OSCachedToPhysical\(void\* caddr\) \{' 'OSCachedToPhysical definition present'
check_contains "pc/src/pc_os.c" 'u32 OSUncachedToPhysical\(void\* ucaddr\) \{' 'OSUncachedToPhysical definition present'
check_contains "pc/src/pc_os.c" 'uintptr_t caddr_bits = \(uintptr_t\)caddr;' 'cached translation uses uintptr_t source bits'
check_contains "pc/src/pc_os.c" 'uintptr_t ucaddr_bits = \(uintptr_t\)ucaddr;' 'uncached translation uses uintptr_t source bits'
check_contains "pc/src/pc_os.c" 'uintptr_t arena_base_bits = \(uintptr_t\)arena_memory;' 'translations use uintptr_t arena base'
check_contains "pc/src/pc_os.c" 'return PC_RUNTIME_U32_PTR\(caddr_bits - arena_base_bits\);' 'cached translation narrows through checked helper'
check_contains "pc/src/pc_os.c" 'return PC_RUNTIME_U32_PTR\(ucaddr_bits - arena_base_bits\);' 'uncached translation narrows through checked helper'

check_absent "pc/src/pc_os.c" 'u32 OSCachedToPhysical\(void\* caddr\) \{ return \(u32\)\(\(u8\*\)caddr - arena_memory\); \}' 'legacy cached pointer-diff cast removed'
check_absent "pc/src/pc_os.c" 'u32 OSUncachedToPhysical\(void\* ucaddr\) \{ return \(u32\)\(\(u8\*\)ucaddr - arena_memory\); \}' 'legacy uncached pointer-diff cast removed'
