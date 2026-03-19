#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing furniture audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    path=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$path"; then
        printf '%s\n' "unexpected legacy furniture audio cast: $label" >&2
        exit 1
    fi
}

check_contains "include/ac_furniture.h" '#define aFTR_AUDIO_TOKEN_BASE 0x46540000u' 'furniture audio token base'
check_contains "include/ac_furniture.h" '#define aFTR_AUDIO_TOKEN\(ftr_actor\) \(aFTR_AUDIO_TOKEN_BASE \+ \(u32\)\(\(ftr_actor\)->id\)\)' 'furniture audio token uses stable furniture id'
check_contains "src/furniture/ac_tak_stew.c" 'sAdo_OngenPos\(aFTR_AUDIO_TOKEN\(ftr_actor\), 0x54, &ftr_actor->position\);' 'stew furniture uses stable audio token'
check_contains "src/furniture/ac_sum_abura.c" 'sAdo_RoomIncectPos\(aFTR_AUDIO_TOKEN\(ftr_actor\), 60, &ftr_actor->position\);' 'abura furniture insect sound uses stable audio token'
check_contains "src/furniture/ac_ike_island_hako01.c" 'sAdo_OngenPos\(aFTR_AUDIO_TOKEN\(ftr_actor\), 0x52, &ftr_actor->position\);' 'island box furniture uses stable audio token'
check_contains "src/furniture/ac_hnw_common.c" 'sAdo_RhythmStart\(aFTR_AUDIO_TOKEN\(ftr_actor\), state \+ 1, delay\);' 'haniwa rhythm start uses stable audio token'
check_contains "src/actor/ac_my_room.c" 'sAdo_OngenPos\(aFTR_AUDIO_TOKEN\(ftr_actor\), 39, &ftr_actor->position\);' 'my room furniture audio uses stable token'

check_absent "src" 'sAdo_(OngenPos|RoomIncectPos|RhythmStart|GetRhythmDelay|RhythmPos|GetRhythmAnimCounter|RhythmStop)\(\(u32\)\s*ftr_actor' 'legacy furniture pointer audio casts'
