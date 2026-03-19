#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing OSMemory pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy OSMemory pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/os/OSMemory.c" '#define TRUNC\(n, a\) \(\(\(uintptr_t\)\(n\)\) & ~\(\(uintptr_t\)\(a\)-1\)\)' 'TRUNC macro uses uintptr_t'
check_contains "src/static/dolphin/os/OSMemory.c" '#define ROUND\(n, a\) \(\(\(uintptr_t\)\(n\) \+ \(uintptr_t\)\(a\)-1\) & ~\(\(uintptr_t\)\(a\)-1\)\)' 'ROUND macro uses uintptr_t'
check_contains "src/static/dolphin/os/OSMemory.c" 'uintptr_t start;' 'start uses uintptr_t'
check_contains "src/static/dolphin/os/OSMemory.c" 'uintptr_t end;' 'end uses uintptr_t'
check_contains "src/static/dolphin/os/OSMemory.c" 'end   = \(uintptr_t\)addr \+ nBytes;' 'end calculation uses uintptr_t'
check_contains "src/static/dolphin/os/OSMemory.c" 'DCFlushRange\(\(void\*\)start, \(u32\)\(end - start\)\);' 'flush range uses host-width diff before u32 narrowing'

check_absent "src/static/dolphin/os/OSMemory.c" '#define TRUNC\(n, a\) \(\(\(u32\)\(n\)\) & ~\(\(a\)-1\)\)' 'legacy TRUNC macro cast'
check_absent "src/static/dolphin/os/OSMemory.c" '#define ROUND\(n, a\) \(\(\(u32\)\(n\) \+ \(a\)-1\) & ~\(\(a\)-1\)\)' 'legacy ROUND macro cast'
check_absent "src/static/dolphin/os/OSMemory.c" 'end   = \(u32\)addr \+ nBytes;' 'legacy end pointer truncation'
