#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing house goki audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy house goki audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_house_goki.c" 'aHG_AUDIO_TOKEN_BASE = 0x48470000u' 'house goki audio token base'
check_contains "src/actor/ac_house_goki.c" '_Static_assert\(BLOCK_X_NUM \* UT_X_NUM \* BLOCK_Z_NUM \* UT_Z_NUM <= aHG_AUDIO_TOKEN_INVALID,' 'house goki token size assertion'
check_contains "src/actor/ac_house_goki.c" 'u32 ut_index = \(u32\)\(ut_z \* \(BLOCK_X_NUM \* UT_X_NUM\) \+ ut_x\);' 'house goki token computes unit index'
check_contains "src/actor/ac_house_goki.c" 'sAdo_OngenPos\(aHG_GetAudioToken\(actorx\), NA_SE_GOKI_MOVE, &actorx->world.position\);' 'house goki uses stable audio token'

check_absent "src/actor/ac_house_goki.c" 'sAdo_OngenPos\(\(u32\)goki' 'house goki still narrows actor pointer'
