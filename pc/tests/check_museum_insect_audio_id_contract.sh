#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing museum insect audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy museum insect audio cast: $label" >&2
        exit 1
    fi
}

check_contains "include/ac_museum_insect_priv.h" '#define mMI_AUDIO_TOKEN_BASE 0x4D490000u' 'museum insect audio token base'
check_contains "include/ac_museum_insect_priv.h" '#define mMI_AUDIO_TOKEN\(actor\) \(mMI_AUDIO_TOKEN_BASE \+ \(u32\)\(\(actor\)->_00\)\)' 'museum insect audio token macro'

check_contains "src/actor/ac_museum_insect_ka.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), 0xcf, &actor->_1C\);' 'museum mosquito uses stable audio token'
check_contains "src/actor/ac_museum_insect_batta.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), batta_sound_data\[id\], &actor->_1C\);' 'museum locust uses stable audio token'
check_contains "src/actor/ac_museum_insect_goki.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), 0xa8, &actor->_1C\);' 'museum cockroach uses stable audio token'
check_contains "src/actor/ac_museum_insect_okera.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), 68, &actor->_1C\);' 'museum mole cricket wait uses stable audio token'
check_contains "src/actor/ac_museum_insect_okera.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), 69, &actor->_1C\);' 'museum mole cricket emerge uses stable audio token'
check_contains "src/actor/ac_museum_insect_semi.c_inc" 'sAdo_OngenPos\(mMI_AUDIO_TOKEN\(actor\), semi_sound_data\[id\], &actor->_1C\);' 'museum cicada uses stable audio token'

check_absent "src/actor/ac_museum_insect_ka.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'museum mosquito still narrows audio id'
check_absent "src/actor/ac_museum_insect_batta.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'museum locust still narrows audio id'
check_absent "src/actor/ac_museum_insect_goki.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'museum cockroach still narrows audio id'
check_absent "src/actor/ac_museum_insect_okera.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'museum mole cricket still narrows audio id'
check_absent "src/actor/ac_museum_insect_semi.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'museum cicada still narrows audio id'
