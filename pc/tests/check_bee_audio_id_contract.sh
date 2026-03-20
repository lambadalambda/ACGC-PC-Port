#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing bee audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy bee audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_bee.c" 'aBEE_AUDIO_TOKEN_BASE = 0x42450000u' 'bee audio token base'
check_contains "src/actor/ac_bee.c" '_Static_assert\(BLOCK_X_NUM \* UT_X_NUM \* BLOCK_Z_NUM \* UT_Z_NUM <= aBEE_AUDIO_TOKEN_INVALID,' 'bee token size assertion'
check_contains "src/actor/ac_bee.c" 'u32 ut_index = \(u32\)\(ut_z \* \(BLOCK_X_NUM \* UT_X_NUM\) \+ ut_x\);' 'bee token computes unit index'
check_contains "src/actor/ac_bee.c" 'sAdo_OngenPos\(aBEE_GetAudioToken\(actorx\), NA_SE_B0, &actorx->world.position\);' 'bee uses stable audio token'
check_contains "src/bg_item/bg_item_common.c_inc" 'xyz_t_move\(&drop->actorx_p->home.position, &drop->position\);' 'bee activation updates home position'

check_absent "src/actor/ac_bee.c" 'sAdo_OngenPos\(\(u32\)actorx' 'bee still narrows actor pointer'
