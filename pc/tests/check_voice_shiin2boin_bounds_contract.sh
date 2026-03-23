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

check_contains "$GAME64_INC" 'if \(a < ARRAY_COUNT\(SHIIN2BOIN\)\)' 'voice lookup bounds check exists'
check_contains "$GAME64_INC" 'sou_now_boin = SHIIN2BOIN\[a\];' 'voice lookup still uses SHIIN2BOIN table'
check_contains "$GAME64_INC" 'sou_now_boin = 0;' 'voice lookup fallback for out-of-range index exists'

printf '%s\n' 'check_voice_shiin2boin_bounds_contract: OK'
