#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "src/game/m_titledemo.c" 'static int mTD_demo_index_clamped\(void\)' 'title-demo index clamp helper exists'
check_contains "src/game/m_titledemo.c" 'int demo_idx = mTD_demo_index_clamped\(\);' 'title-demo callsites use clamped index'
check_contains "src/game/m_titledemo.c" 'int keydata_count = get_demo_header\(demo_idx, mTD_HEADER_SIZE\);' 'title-demo keydata uses per-demo key count'
check_contains "src/game/m_titledemo.c" 'if \(frame < 0\)' 'title-demo keydata lower-bound clamp exists'
check_contains "src/game/m_titledemo.c" 'else if \(frame >= keydata_count\)' 'title-demo keydata upper-bound clamp exists'

printf '%s\n' 'check_titledemo_keydata_bounds_contract: OK'
