#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NPC_TALK_INC="$REPO_ROOT/src/actor/npc/ac_npc_talk.c_inc"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$NPC_TALK_INC" 'int eff_count = \(int\)ARRAY_COUNT\(eff_idx\);' 'talk demo table size is captured'
check_contains "$NPC_TALK_INC" 'else if \(order >= 0 && order < eff_count\)' 'incoming demo order is bounds-checked'
check_contains "$NPC_TALK_INC" 'last_order > aNPC_MANPU_CODE_NONE && last_order < eff_count' 'stored demo code is bounds-checked'
check_contains "$NPC_TALK_INC" 'nactorx->talk_info.demo_code = \(order >= 0 && order < eff_count\) \? order : aNPC_MANPU_CODE_NONE;' 'invalid demo order is sanitized'

printf '%s\n' 'check_npc_talk_demo_code_bounds_contract: OK'
