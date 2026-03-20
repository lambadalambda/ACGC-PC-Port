#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing waterfall audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy waterfall audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_fallS.c" 'aFLS_AUDIO_TOKEN_BASE = 0x46530000u' 'south waterfall token base'
check_contains "src/actor/ac_fallS.c" '_Static_assert\(BLOCK_X_NUM \* UT_X_NUM \* BLOCK_Z_NUM \* UT_Z_NUM <= aFLS_AUDIO_TOKEN_INVALID,' 'south waterfall token size assertion'
check_contains "src/actor/ac_fallS.c" 'u32 ut_index = \(u32\)\(ut_z \* \(BLOCK_X_NUM \* UT_X_NUM\) \+ ut_x\);' 'south waterfall token computes unit index'
check_contains "src/actor/ac_fallS.c" 'return aFLS_AUDIO_TOKEN_BASE \| ut_index;' 'south waterfall token encodes unit index'
check_contains "src/actor/ac_fallS_move.c_inc" 'sAdo_OngenPos\(aFLS_GetAudioToken\(actor\), 12, &pos\);' 'south waterfall uses stable audio token'

check_contains "src/actor/ac_fallSESW.c" 'aFLEW_AUDIO_TOKEN_BASE = 0x46450000u' 'east waterfall token base'
check_contains "src/actor/ac_fallSESW.c" '_Static_assert\(BLOCK_X_NUM \* UT_X_NUM \* BLOCK_Z_NUM \* UT_Z_NUM <= aFLEW_AUDIO_TOKEN_INVALID,' 'east waterfall token size assertion'
check_contains "src/actor/ac_fallSESW.c" 'u32 ut_index = \(u32\)\(ut_z \* \(BLOCK_X_NUM \* UT_X_NUM\) \+ ut_x\);' 'east waterfall token computes unit index'
check_contains "src/actor/ac_fallSESW.c" 'return aFLEW_AUDIO_TOKEN_BASE \| ut_index;' 'east waterfall token encodes unit index'
check_contains "src/actor/ac_fallSESW_move.c_inc" 'sAdo_OngenPos\(aFLEW_GetAudioToken\(actor\), 12, &pos\);' 'east waterfall uses stable audio token'

check_absent "src/actor/ac_fallS_move.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'south waterfall still narrows actor pointer'
check_absent "src/actor/ac_fallSESW_move.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'east waterfall still narrows actor pointer'
