#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME64_INC="$REPO_ROOT/src/static/jaudio_NES/game/game64.c_inc"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$GAME64_INC" 'for \(j = 0; j < ARRAY_COUNT\(sou_sys_lev\); j\+\+\) \{' 'system level counter loop iterates with j'
check_contains "$GAME64_INC" 'sou_sys_lev\[j\]\._1\+\+;' 'system level counter increments in-bounds slot'

printf '%s\n' 'check_sys_lev_counter_bounds_contract: OK'
