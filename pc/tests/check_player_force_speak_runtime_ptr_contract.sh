#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player force-speak pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy player force-speak pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'ACTOR\* able_force_speak_label_shadow;' 'player struct has LP64 force-speak shadow field'
check_contains "src/game/m_player_lib.c" '#if defined\(TARGET_PC\) && UINTPTR_MAX > 0xFFFFFFFFu' 'force-speak setter has LP64 branch'
check_contains "src/game/m_player_lib.c" 'player->able_force_speak_label_shadow = label;' 'force-speak setter stores host shadow pointer'
check_contains "src/game/m_player_lib.c" 'player->able_force_speak_label = 0;' 'force-speak setter clears legacy u32 field on LP64'
check_contains "src/game/m_player_common.c_inc" '#if defined\(TARGET_PC\) && UINTPTR_MAX > 0xFFFFFFFFu' 'force-speak check has LP64 branch'
check_contains "src/game/m_player_common.c_inc" 'ACTOR\* able_force_speak_label = player->able_force_speak_label_shadow;' 'force-speak check reads host shadow pointer'
check_contains "src/game/m_player_common.c_inc" 'player->able_force_speak_label_shadow = NULL;' 'force-speak reset clears host shadow pointer'

check_absent "src/game/m_player_lib.c" 'GET_PLAYER_ACTOR_NOW\(\)->able_force_speak_label = \(u32\)label;' 'legacy force-speak setter cast'
