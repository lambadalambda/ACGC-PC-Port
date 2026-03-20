#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/actor/ac_ins_goki.c"

if ! rg -q 'static mActor_name_t\* aIGK_get_item_slot\(aINS_INSECT_ACTOR\* insect\)' "$FILE"; then
    printf '%s\n' 'missing goki item-slot helper contract' >&2
    exit 1
fi

if ! rg -q 'return mFI_GetUnitFG\(insect->tools_actor.actor_class.home.position\);' "$FILE"; then
    printf '%s\n' 'missing goki home-position item-slot lookup contract' >&2
    exit 1
fi

if ! rg -q 'item_p = aIGK_get_item_slot\(insect\);' "$FILE"; then
    printf '%s\n' 'missing goki item-slot helper use in spawn path' >&2
    exit 1
fi

if ! rg -q 'if \(item_p == NULL \|\| \*item_p != ITM_KABU_SPOILED\)' "$FILE"; then
    printf '%s\n' 'missing goki item-slot helper use in patience check' >&2
    exit 1
fi

if rg -q '#define aIGK_GET_ITEM_P\(insect\)' "$FILE"; then
    printf '%s\n' 'legacy goki pointer-int getter macro still present' >&2
    exit 1
fi

if rg -q '#define aIGK_SET_ITEM_P\(insect, item_p\)' "$FILE"; then
    printf '%s\n' 'legacy goki pointer-int setter macro still present' >&2
    exit 1
fi

if rg -q '\(int\)item_p' "$FILE"; then
    printf '%s\n' 'legacy goki pointer-to-int cast still present' >&2
    exit 1
fi
