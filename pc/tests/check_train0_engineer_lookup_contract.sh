#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE_MAIN="$REPO_ROOT/src/actor/ac_train0.c"
FILE_MOVE="$REPO_ROOT/src/actor/ac_train0_move.c_inc"

if ! rg -q 'engineer_p = Actor_info_fgName_search\(&play->actor_info, SP_NPC_ENGINEER, ACTOR_PART_NPC\);' "$FILE_MAIN"; then
    printf '%s\n' 'missing train0 dt engineer actor lookup contract' >&2
    exit 1
fi

if ! rg -q 'ac_p = Actor_info_fgName_search\(&play->actor_info, SP_NPC_ENGINEER, ACTOR_PART_NPC\);' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 move engineer actor lookup contract' >&2
    exit 1
fi

if ! rg -q 'engineer_p = Actor_info_fgName_search\(&play->actor_info, SP_NPC_ENGINEER, ACTOR_PART_NPC\);' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 delcheck engineer actor lookup contract' >&2
    exit 1
fi

if ! rg -q 'train0->arg3 = FALSE;' "$FILE_MAIN"; then
    printf '%s\n' 'missing train0 engineer ownership flag init contract' >&2
    exit 1
fi

if ! rg -q 'train0->arg3 = TRUE;' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 engineer ownership flag set contract' >&2
    exit 1
fi

if ! rg -q 'spawned_now = TRUE;' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 spawn-tick parity gate contract' >&2
    exit 1
fi

if ! rg -q 'if \(train0->arg3 && engineer_p != NULL\)' "$FILE_MAIN"; then
    printf '%s\n' 'missing train0 dt ownership-gated engineer delete contract' >&2
    exit 1
fi

if ! rg -q 'if \(train0->arg3 && ac_p != NULL && !spawned_now\)' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 ownership-gated engineer position contract' >&2
    exit 1
fi

if ! rg -q 'if \(train0->arg3 && engineer_p != NULL\)' "$FILE_MOVE"; then
    printf '%s\n' 'missing train0 delcheck ownership-gated engineer delete contract' >&2
    exit 1
fi

if rg -q '\(ACTOR\*\)train0->arg3' "$FILE_MAIN"; then
    printf '%s\n' 'legacy train0 arg3 pointer cast still present in main file' >&2
    exit 1
fi

if rg -q '\(ACTOR\*\)train0->arg3' "$FILE_MOVE"; then
    printf '%s\n' 'legacy train0 arg3 pointer cast still present in move file' >&2
    exit 1
fi

if rg -q 'train0->arg3 = \(int\)' "$FILE_MAIN"; then
    printf '%s\n' 'legacy train0 arg3 pointer-int store still present in main file' >&2
    exit 1
fi

if rg -q 'train0->arg3 = \(int\)' "$FILE_MOVE"; then
    printf '%s\n' 'legacy train0 arg3 pointer-int store still present in move file' >&2
    exit 1
fi
