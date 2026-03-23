#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="src/actor/ac_ride_off_demo_move.c_inc"

check_contains() {
    local pattern="$1"
    local desc="$2"

    if ! rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "missing contract: $desc ($FILE)" >&2
        exit 1
    fi
}

check_contains 'Actor_info_fgName_search\(&play->actor_info, SP_NPC_STATION_MASTER, ACTOR_PART_NPC\);' 'ride-off demo reacquires station master actor each frame'
check_contains 'talk_actor = mDemo_Get_talk_actor\(\);' 'ride-off demo inspects active talk actor fallback'
check_contains 'talk_actor->npc_id == SP_NPC_STATION_MASTER' 'ride-off demo fallback confirms porter npc id'
check_contains 'mDemo_Check\(mDemo_TYPE_TALK, station_master\) == TRUE' 'ride-off demo accepts TALK state for porter gate'
check_contains 'mDemo_Check\(mDemo_TYPE_TALK, talk_actor\) == TRUE' 'ride-off demo fallback accepts TALK actor state'
check_contains 'if \(station_master_talking == TRUE\) \{' 'ride-off demo gates talk-start on reconciled state'
check_contains 'else if \(station_master_talking == FALSE\) \{' 'ride-off demo gates talk-end on reconciled state'

printf '%s\n' 'check_ride_off_demo_station_master_reacquire_contract: OK'
