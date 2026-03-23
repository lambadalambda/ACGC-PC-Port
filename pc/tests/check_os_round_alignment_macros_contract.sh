#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OS_UTIL_H="$REPO_ROOT/include/dolphin/os/OSUtil.h"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$OS_UTIL_H" '#define OSRoundUp32B\(x\) \(\(\(\(uintptr_t\)\(x\)\) \+ \(uintptr_t\)0x1F\) & ~\(uintptr_t\)0x1F\)' 'OSRoundUp32B uses uintptr_t arithmetic'
check_contains "$OS_UTIL_H" '#define OSRoundDown32B\(x\) \(\(\(uintptr_t\)\(x\)\) & ~\(uintptr_t\)0x1F\)' 'OSRoundDown32B uses uintptr_t arithmetic'

if rg -q '#define OSRoundUp32B\(x\) \(\(\(u32\)\(x\)' "$OS_UTIL_H"; then
    printf '%s\n' 'failing contract: OSRoundUp32B still truncates through u32' >&2
    exit 1
fi

if rg -q '#define OSRoundDown32B\(x\) \(\(\(u32\)\(x\)' "$OS_UTIL_H"; then
    printf '%s\n' 'failing contract: OSRoundDown32B still truncates through u32' >&2
    exit 1
fi

printf '%s\n' 'check_os_round_alignment_macros_contract: OK'
