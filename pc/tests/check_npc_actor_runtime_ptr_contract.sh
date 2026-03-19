#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing NPC actor pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy NPC actor pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/npc/ac_npc_ctrl.c_inc" '\*actor = \(NPC_ACTOR\*\)ALIGN_NEXT\(\(uintptr_t\)aNPC_n_actor_cl_tbl\[i\]\.buf, 16\);' 'keep actor alignment uses uintptr_t'

check_absent "src/actor/npc/ac_npc_ctrl.c_inc" '\*actor = \(NPC_ACTOR\*\)ALIGN_NEXT\(\(u32\)aNPC_n_actor_cl_tbl\[i\]\.buf, 16\);' 'legacy keep actor alignment cast'
