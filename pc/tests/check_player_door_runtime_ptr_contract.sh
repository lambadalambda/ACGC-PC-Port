#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player door pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy player door pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'ACTOR\* door_label_shadow;' 'player struct has LP64 door label shadow field'
check_contains "src/game/m_player_main_door.c_inc" '#if defined\(TARGET_PC\) && UINTPTR_MAX > 0xFFFFFFFFu' 'door request has LP64 branch'
check_contains "src/game/m_player_main_door.c_inc" 'player->door_label_shadow = \(ACTOR\*\)label;' 'door request stores host shadow label'
check_contains "src/game/m_player_main_door.c_inc" 'player->requested_main_index_data.door.label = 0;' 'door request clears legacy u32 label on LP64'
check_contains "src/game/m_player_common.c_inc" '#if defined\(TARGET_PC\) && UINTPTR_MAX > 0xFFFFFFFFu' 'door label getter has LP64 branch'
check_contains "src/game/m_player_common.c_inc" 'return GET_PLAYER_ACTOR_GAME\(game\)->door_label_shadow;' 'door label getter reads host shadow label'
