#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing festival npc audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy festival npc audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/npc/ac_countdown_npc1_talk.c_inc" 'aCD1_AUDIO_TOKEN_BASE = 0x43440000u' 'countdown token base'
check_contains "src/actor/npc/ac_countdown_npc1_talk.c_inc" 'sAdo_OngenPos\(aCD1_AUDIO_TOKEN\(idx\), se_no\[idx\], &actor->npc_class.actor_class.world.position\);' 'countdown uses stable token'

check_contains "src/actor/npc/ac_hanabi_npc1_talk.c_inc" 'aHN1_AUDIO_TOKEN_BASE = 0x484E0000u' 'hanabi token base'
check_contains "src/actor/npc/ac_hanabi_npc1_talk.c_inc" 'sAdo_OngenPos\(aHN1_AUDIO_TOKEN\(actor\), actor->clap_se_no, &actor->npc_class.actor_class.world.position\);' 'hanabi uses stable token'

check_contains "src/actor/npc/ac_hanami_npc0_talk.c_inc" 'aHM0_AUDIO_TOKEN_BASE = 0x484D0000u' 'hanami token base'
check_contains "src/actor/npc/ac_hanami_npc0_talk.c_inc" 'sAdo_OngenPos\(aHM0_AUDIO_TOKEN\(actor\), actor->clap_se_no, &actor->npc_class.actor_class.world.position\);' 'hanami uses stable token'

check_contains "src/actor/npc/ac_harvest_npc0.c" 'aHT0_AUDIO_TOKEN_BASE = 0x48540000u' 'harvest token base'
check_contains "src/actor/npc/ac_harvest_npc0.c_inc" 'sAdo_OngenPos\(aHT0_AUDIO_TOKEN\(actor\), actor->_9A8, &actor->actor.actor_class.world.position\);' 'harvest uses stable token'

check_contains "src/actor/npc/ac_tamaire_npc0_schedule.c_inc" 'aTMN0_AUDIO_TOKEN_BASE = 0x544D0000u' 'tamaire token base'
check_contains "src/actor/npc/ac_tamaire_npc0_schedule.c_inc" 'sAdo_OngenPos\(aTMN0_AUDIO_TOKEN\(actorx\), NA_SE_2F, &actorx->world.position\);' 'tamaire uses stable token'

check_contains "src/actor/npc/ac_tokyoso_npc1_schedule.c_inc" 'aTKN1_AUDIO_TOKEN_BASE = 0x544B0000u' 'tokyoso token base'
check_contains "src/actor/npc/ac_tokyoso_npc1_schedule.c_inc" 'sAdo_OngenPos\(aTKN1_AUDIO_TOKEN\(actorx\), 0x2F, &actorx->world.position\);' 'tokyoso team one uses stable token'
check_contains "src/actor/npc/ac_tokyoso_npc1_schedule.c_inc" 'sAdo_OngenPos\(aTKN1_AUDIO_TOKEN\(actorx\), 0x31, &actorx->world.position\);' 'tokyoso team zero uses stable token'

check_contains "src/actor/npc/event/ac_ev_soncho2_think.c_inc" 'aES2_AUDIO_TOKEN = 0x45530000u' 'soncho token constant'
check_contains "src/actor/npc/event/ac_ev_soncho2_think.c_inc" 'sAdo_OngenPos\(aES2_AUDIO_TOKEN, NA_SE_2F, &soncho->npc_class.actor_class.world.position\);' 'soncho uses stable token'

check_absent "src/actor/npc/ac_countdown_npc1_talk.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'countdown still narrows actor pointer'
check_absent "src/actor/npc/ac_hanabi_npc1_talk.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'hanabi still narrows actor pointer'
check_absent "src/actor/npc/ac_hanami_npc0_talk.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'hanami still narrows actor pointer'
check_absent "src/actor/npc/ac_harvest_npc0.c_inc" 'sAdo_OngenPos\(\(u32\)actor' 'harvest still narrows actor pointer'
check_absent "src/actor/npc/ac_tamaire_npc0_schedule.c_inc" 'sAdo_OngenPos\(\(u32\)actorx' 'tamaire still narrows actor pointer'
check_absent "src/actor/npc/ac_tokyoso_npc1_schedule.c_inc" 'sAdo_OngenPos\(\(u32\)actorx' 'tokyoso still narrows actor pointer'
check_absent "src/actor/npc/event/ac_ev_soncho2_think.c_inc" 'sAdo_OngenPos\(\(u32\)soncho' 'soncho still narrows actor pointer'
