#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NPC_CTRL_INC="$REPO_ROOT/src/actor/npc/ac_npc_ctrl.c_inc"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$NPC_CTRL_INC" 'return aNPC_setupActor_sub\(play, idx, name, profile, &pos, mvlist_no, arg\);' 'setupActor proc returns spawn status explicitly'

printf '%s\n' 'check_npc_setup_actor_return_contract: OK'
