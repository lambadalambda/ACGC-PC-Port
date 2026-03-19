#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing OSAlloc pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy OSAlloc pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/os/OSAlloc.c" '\(\(\(uintptr_t\)\(arenaStart\) <= \(uintptr_t\)\(cell\)\) && \(\(uintptr_t\)\(cell\) < \(uintptr_t\)\(arenaEnd\)\)\)' 'InRange macro uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" '#define ROUND_PTR_UP\(ptr, align\).*uintptr_t' 'round-up pointer helper uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" '#define ROUND_PTR_DOWN\(ptr, align\).*uintptr_t' 'round-down pointer helper uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ASSERTMSGLINE\(0x168, \(\(uintptr_t\)cell & \(ALIGNMENT - 1\)\) == 0,' 'allocated cell alignment uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ASSERTMSGLINE\(0x240, \(\(uintptr_t\)ptr & \(ALIGNMENT - 1\)\) == 0,' 'free pointer alignment uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ASSERTREPORT\(0x387, \(\(uintptr_t\)cell & \(ALIGNMENT - 1\)\) == 0\);' 'allocated list alignment check uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ASSERTREPORT\(0x399, \(\(uintptr_t\)cell & \(ALIGNMENT - 1\)\) == 0\);' 'free list alignment check uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ASSERTMSGLINE\(0x3BE, \(\(uintptr_t\)ptr & \(ALIGNMENT - 1\)\) == 0,' 'referent alignment uses uintptr_t'
check_contains "src/static/dolphin/os/OSAlloc.c" 'cell = \(struct Cell\*\)\(\(u8\*\)ptr - HEADERSIZE\);' 'header backtracking uses byte pointer arithmetic'
check_contains "src/static/dolphin/os/OSAlloc.c" 'arenaStart   = ROUND_PTR_UP\(\(u8\*\)HeapArray \+ arraySize, ALIGNMENT\);' 'arena start alignment uses helper'
check_contains "src/static/dolphin/os/OSAlloc.c" 'ArenaEnd     = ROUND_PTR_DOWN\(arenaEnd, ALIGNMENT\);' 'arena end alignment uses helper'
check_contains "src/static/dolphin/os/OSAlloc.c" 'start = ROUND_PTR_UP\(start, ALIGNMENT\);' 'heap start alignment uses helper'
check_contains "src/static/dolphin/os/OSAlloc.c" 'end   = ROUND_PTR_DOWN\(end, ALIGNMENT\);' 'heap end alignment uses helper'
check_contains "src/static/dolphin/os/OSAlloc.c" 'hd->size      = \(long\)\(\(uintptr_t\)end - \(uintptr_t\)start\);' 'heap size uses uintptr_t diff'
check_contains "src/static/dolphin/os/OSAlloc.c" 'OSReport\("%p\t%ld\t%p\t%p\t%p\\n", \(void\*\)cell, cell->size,' 'heap dump uses %p pointer reports'

check_absent "src/static/dolphin/os/OSAlloc.c" '\(\(u32\)arenaStart <= \(u32\)cell\) && \(\(u32\)cell < \(u32\)arenaEnd\)' 'legacy InRange macro cast'
check_absent "src/static/dolphin/os/OSAlloc.c" '0xFFFFFFE0' 'legacy truncated alignment mask'
check_absent "src/static/dolphin/os/OSAlloc.c" '!\(\(s32\)cell & 0x1F\)' 'legacy allocated cell cast'
check_absent "src/static/dolphin/os/OSAlloc.c" 'OFFSET\(ptr, ALIGNMENT\)' 'legacy free pointer OFFSET check'
check_absent "src/static/dolphin/os/OSAlloc.c" 'OFFSET\(cell, ALIGNMENT\)' 'legacy cell OFFSET checks'
check_absent "src/static/dolphin/os/OSAlloc.c" '!OFFSET\(ptr, 32\)' 'legacy referent OFFSET check'
check_absent "src/static/dolphin/os/OSAlloc.c" 'cell = \(void\*\)\(\(u32\)ptr - 0x20\);' 'legacy free header backtrack cast'
check_absent "src/static/dolphin/os/OSAlloc.c" 'cell = \(void\*\)\(\(u32\)ptr - HEADERSIZE\);' 'legacy referent header backtrack cast'
check_absent "src/static/dolphin/os/OSAlloc.c" 'OSReport\("%x\t%d\t%x\t%x\t%x\\n", cell, cell->size,' 'legacy heap dump pointer format'
