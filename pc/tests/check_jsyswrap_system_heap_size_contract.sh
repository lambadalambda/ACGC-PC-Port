#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing jsyswrap heap size contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy jsyswrap heap size pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jsyswrap.cpp" '#include "pc_runtime_ptr.h"' 'jsyswrap includes runtime pointer guard helper'
check_contains "src/static/jsyswrap.cpp" 'uintptr_t system_heap_size = \(uintptr_t\)arena_hi - \(uintptr_t\)arena_lo;' 'jsyswrap keeps system heap size math at host width'
check_contains "src/static/jsyswrap.cpp" 'uintptr_t root_heap_header_size = \(\(uintptr_t\)sizeof\(JKRExpHeap\) \+ 0xF\) & ~\(uintptr_t\)0xF;' 'jsyswrap derives root heap header size from host type layout'
check_contains "src/static/jsyswrap.cpp" 'uintptr_t root_heap_align_slop = \(\(\(uintptr_t\)sizeof\(JKRExpHeap::CMemBlock\) \+ 0xF\) & ~\(uintptr_t\)0xF\) -' 'jsyswrap derives alloc alignment slop from CMemBlock layout'
check_contains "src/static/jsyswrap.cpp" 'root_heap_reserve = root_heap_header_size \+ 0x10 \+ root_heap_align_slop;' 'jsyswrap derives runtime reserve instead of fixed constant'
check_contains "src/static/jsyswrap.cpp" 'if \(system_heap_size < root_heap_reserve \|\| system_heap_size - root_heap_reserve > 0xFFFFFFFFu\)' 'jsyswrap checks dynamic reserve underflow and u32 narrowing bound'
check_contains "src/static/jsyswrap.cpp" 'system_heap_size -= root_heap_reserve;' 'jsyswrap subtracts dynamic reserve from arena size'
check_contains "src/static/jsyswrap.cpp" 'SystemHeapSize = PC_RUNTIME_U32_PTR\(system_heap_size\);' 'jsyswrap narrows system heap size through runtime guard'

check_absent "src/static/jsyswrap.cpp" 'SystemHeapSize = \(u32\)system_heap_size;' 'legacy direct system heap size cast'
check_absent "src/static/jsyswrap.cpp" 'system_heap_size < 0xD0' 'legacy fixed root heap reserve bound check'
check_absent "src/static/jsyswrap.cpp" 'system_heap_size -= 0xD0;' 'legacy fixed root heap reserve subtraction'
