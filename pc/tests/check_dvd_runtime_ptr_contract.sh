#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing DVD pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy DVD pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/dvd/dvd.c" '#define DVD_PTR_IS_ALIGNED\(ptr, align\) .*uintptr_t' 'dvd pointer alignment helper uses uintptr_t'
check_contains "src/static/dolphin/dvd/dvd.c" 'ASSERTLINE\(0x23A, DVD_PTR_IS_ALIGNED\(bootInfo->FSTLocation, 32\)\);' 'FST location alignment uses helper'
check_contains "src/static/dolphin/dvd/dvd.c" 'ASSERTMSGLINE\(0x7AC, DVD_PTR_IS_ALIGNED\(addr, 32\),' 'DVDReadAbsAsync alignment uses helper'
check_contains "src/static/dolphin/dvd/dvd.c" 'ASSERTMSGLINE\(0x7FD, DVD_PTR_IS_ALIGNED\(addr, 32\),' 'DVDReadAbsAsyncForBS alignment uses helper'
check_contains "src/static/dolphin/dvd/dvd.c" 'ASSERTMSGLINE\(0x825, DVD_PTR_IS_ALIGNED\(diskID, 32\),' 'DVDReadDiskID alignment uses helper'
check_contains "src/static/dolphin/dvd/dvd.c" 'ASSERTMSGLINE\(0xACC, DVD_PTR_IS_ALIGNED\(info, 32\),' 'DVDInquiry alignment uses helper'
check_contains "src/static/dolphin/dvd/dvdlow.c" 'ASSERTMSGLINE\(0x341, \(\(\(uintptr_t\)addr\) & 31\) == 0,' 'DVDLowRead alignment uses uintptr_t'
check_contains "src/static/dolphin/dvd/dvdfs.c" 'ASSERTMSGLINE\(0x2DA, \(\(\(uintptr_t\)addr\) & \(32 - 1\)\) == 0,' 'DVDReadAsync alignment uses uintptr_t'
check_contains "src/static/dolphin/dvd/dvdfs.c" 'ASSERTMSGLINE\(0x320, \(\(\(uintptr_t\)addr\) & \(32 - 1\)\) == 0,' 'DVDRead alignment uses uintptr_t'

check_absent "src/static/dolphin/dvd/dvd.c" 'ASSERTLINE\(0x23A, \(\(u32\)\(bootInfo->FSTLocation\) & \(32 - 1\)\) == 0\);' 'legacy FST location cast'
check_absent "src/static/dolphin/dvd/dvd.c" '!OFFSET\(addr, 32\)' 'legacy DVD address OFFSET checks'
check_absent "src/static/dolphin/dvd/dvd.c" '!OFFSET\(diskID, 32\)' 'legacy DVD disk ID OFFSET check'
check_absent "src/static/dolphin/dvd/dvd.c" '!OFFSET\(info, 32\)' 'legacy DVD inquiry OFFSET check'
check_absent "src/static/dolphin/dvd/dvdlow.c" '\(\(\(u32\)addr\) & 31\) == 0' 'legacy DVDLowRead cast'
check_absent "src/static/dolphin/dvd/dvdfs.c" '!OFFSET\(addr, 32\)' 'legacy DVDFS OFFSET checks'
