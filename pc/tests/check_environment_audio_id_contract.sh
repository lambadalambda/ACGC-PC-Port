#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing environment audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy environment audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_koinobori.c" 'aKOI_AUDIO_TOKEN = 0x4B4F0000u' 'koinobori audio token constant'
check_contains "src/actor/ac_koinobori_move.c_inc" 'sAdo_OngenPos\(aKOI_AUDIO_TOKEN, 0x35, &actor->world.position\);' 'koinobori uses stable audio token'

check_contains "src/actor/ac_shrine.c" 'aSHR_AUDIO_TOKEN = 0x53480000u' 'shrine audio token constant'
check_contains "src/actor/ac_shrine_move.c_inc" 'sAdo_OngenPos\(aSHR_AUDIO_TOKEN, 0x5A, &actorx->world.position\);' 'shrine uses stable audio token'

check_contains "src/actor/ac_kamakura_indoor.c" 'aKI_AUDIO_TOKEN = 0x4B490000u' 'kamakura indoor audio token constant'
check_contains "src/actor/ac_kamakura_indoor.c" 'sAdo_OngenPos\(aKI_AUDIO_TOKEN, NA_SE_KOKORO_TOGURU, &k_indoor->mochi.pos\);' 'kamakura indoor uses stable audio token'

check_contains "src/bg_item/bg_item_common.c_inc" 'bIT_SHIN_AUDIO_TOKEN_BASE = 0x42490000u' 'bg-item shine audio token base'
check_contains "src/bg_item/bg_item_common.c_inc" 'sAdo_OngenPos\(bIT_SHIN_AUDIO_TOKEN_BASE \+ \(u32\)i, 0x2C, &shin->position\);' 'bg-item shine uses stable slot token'

check_absent "src/actor/ac_koinobori_move.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'koinobori still narrows audio id'
check_absent "src/actor/ac_shrine_move.c_inc" 'sAdo_OngenPos\(\(u32\)actorx' 'shrine still narrows audio id'
check_absent "src/actor/ac_kamakura_indoor.c" 'sAdo_OngenPos\(\(u32\)actorx' 'kamakura indoor still narrows audio id'
check_absent "src/bg_item/bg_item_common.c_inc" 'sAdo_OngenPos\(\(u32\)shin' 'bg-item shine still narrows audio id'
