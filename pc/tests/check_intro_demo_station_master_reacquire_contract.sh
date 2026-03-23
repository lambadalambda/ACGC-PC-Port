#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="src/actor/ac_intro_demo_move.c_inc"

check_contains() {
    local pattern="$1"
    local desc="$2"

    if ! rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "missing contract: $desc ($FILE)" >&2
        exit 1
    fi
}

check_contains 'Actor_info_fgName_search\(&play->actor_info, SP_NPC_STATION_MASTER, ACTOR_PART_NPC\);' 'intro demo reacquires station master actor each frame'
check_contains 'talk_actor = mDemo_Get_talk_actor\(\);' 'intro demo inspects active talk actor for speak fallback'
check_contains 'talk_actor->npc_id == SP_NPC_STATION_MASTER' 'intro demo fallback confirms porter npc id'
check_contains 'mDemo_Check\(mDemo_TYPE_TALK, station_master\) == TRUE' 'intro demo accepts porter TALK state in gate checks'
check_contains 'mDemo_Check\(mDemo_TYPE_TALK, talk_actor\) == TRUE' 'intro demo fallback accepts TALK actor state'
check_contains 'if \(station_master_talking == TRUE\) \{' 'intro demo gates speak-start on reconciled talking state'
check_contains 'if \(station_master_talking == FALSE\) \{' 'intro demo gates speak-end on reconciled talking state'

printf '%s\n' 'check_intro_demo_station_master_reacquire_contract: OK'
