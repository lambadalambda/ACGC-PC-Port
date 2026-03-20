#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing DVDLow pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy DVDLow pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/dvd/dvdlow.c" '#include "pc_runtime_ptr.h"' 'DVDLow uses runtime checked narrowing helper'
check_contains "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\] = PC_RUNTIME_U32_PTR\(addr\);' 'Read command DMA address uses checked narrowing'
check_contains "src/static/dolphin/dvd/dvdlow.c" 'ASSERTMSGLINE\(0x3d2, \(\(\(uintptr_t\)diskID\) & 31\) == 0,' 'DVDLowReadDiskID alignment uses uintptr_t'
check_contains "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\]   = PC_RUNTIME_U32_PTR\(diskID\);' 'ReadDiskID DMA address uses checked narrowing'
check_contains "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\]   = PC_RUNTIME_U32_PTR\(info\);' 'Inquiry DMA address uses checked narrowing'

check_absent "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\] = \(u32\)addr;' 'legacy Read DMA cast removed'
check_absent "src/static/dolphin/dvd/dvdlow.c" 'ASSERTMSGLINE\(0x3d2, \(\(\(u32\)diskID\) & 31\) == 0,' 'legacy ReadDiskID alignment cast removed'
check_absent "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\]   = \(u32\)diskID;' 'legacy ReadDiskID DMA cast removed'
check_absent "src/static/dolphin/dvd/dvdlow.c" '__DIRegs\[5\]   = \(u32\)info;' 'legacy Inquiry DMA cast removed'
