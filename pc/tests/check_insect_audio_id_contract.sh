#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing insect audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy insect audio cast: $label" >&2
        exit 1
    fi
}

check_contains "include/ac_insect_h.h" 'extern u32 aINS_GetAudioToken\(const aINS_INSECT_ACTOR\* insect\);' 'insect audio token helper declaration'
check_contains "src/actor/ac_insect.c" 'aINS_AUDIO_TOKEN_BASE = 0x494E0000u' 'insect audio token base'
check_contains "src/actor/ac_insect.c" 'aINS_AUDIO_TOKEN_INVALID = aINS_AUDIO_TOKEN_BASE \+ aINS_ACTOR_NUM' 'insect audio invalid token'
check_contains "src/actor/ac_insect.c" 'offset % sizeof\(aINS_ctrlActor->insect_actor\[0\]\) != 0' 'insect audio helper checks slot alignment'
check_contains "src/actor/ac_insect.c" 'return aINS_AUDIO_TOKEN_BASE \+ \(u32\)\(offset / sizeof\(aINS_ctrlActor->insect_actor\[0\]\)\);' 'insect audio helper derives pool index token'
check_contains "src/actor/ac_insect.c" 'aINS_ctrlActor = NULL;' 'insect teardown clears control-actor pointer'

check_contains "src/actor/ac_ins_amenbo.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_25, &actorx->world.position\);' 'pond skater uses insect audio token'
check_contains "src/actor/ac_ins_batta.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), batta_sound_data\[idx\], &actor->world.position\);' 'locust audio uses insect audio token'
check_contains "src/actor/ac_ins_goki.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_GOKI_MOVE, &actorx->world.position\);' 'cockroach movement uses insect audio token'
check_contains "src/actor/ac_ins_ka.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_KA_BUZZ, &actorx->world.position\);' 'mosquito buzz uses insect audio token'
check_contains "src/actor/ac_ins_kabuto.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_25, &actorx->world.position\);' 'beetle flight uses insect audio token'
check_contains "src/actor/ac_ins_kera.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_MOLE_CRICKET_OUT, &actorx->world.position\);' 'mole cricket uses insect audio token'
check_contains "src/actor/ac_ins_semi.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), semi_sound_data\[semi_idx\], &actorx->world.position\);' 'cicada cry uses insect audio token'
check_contains "src/actor/ac_ins_tentou.c" 'sAdo_OngenPos\(aINS_GetAudioToken\(insect\), NA_SE_26, &actorx->world.position\);' 'ladybug and mantis use insect audio token'

check_absent "src/actor/ac_ins_amenbo.c" 'sAdo_OngenPos\(\(u32\)' 'pond skater still narrows audio id'
check_absent "src/actor/ac_ins_batta.c" 'sAdo_OngenPos\(\(u32\)' 'locust still narrows audio id'
check_absent "src/actor/ac_ins_goki.c" 'sAdo_OngenPos\(\(u32\)' 'cockroach still narrows audio id'
check_absent "src/actor/ac_ins_ka.c" 'sAdo_OngenPos\(\(u32\)' 'mosquito still narrows audio id'
check_absent "src/actor/ac_ins_kabuto.c" 'sAdo_OngenPos\(\(u32\)' 'beetle still narrows audio id'
check_absent "src/actor/ac_ins_kera.c" 'sAdo_OngenPos\(\(u32\)' 'mole cricket still narrows audio id'
check_absent "src/actor/ac_ins_semi.c" 'sAdo_OngenPos\(\(u32\)' 'cicada still narrows audio id'
check_absent "src/actor/ac_ins_tentou.c" 'sAdo_OngenPos\(\(u32\)' 'ladybug and mantis still narrow audio id'
