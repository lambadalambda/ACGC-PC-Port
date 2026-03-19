#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player stung-mosquito pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'ACTOR\* stung_mosquito_label_shadow;' 'player struct has stung-mosquito shadow field'
check_contains "include/m_player.h" 'ACTOR\* notice_mosquito_label_shadow;' 'player struct has notice-mosquito shadow field'
check_contains "src/game/m_player_main_stung_mosquito.c_inc" 'player->stung_mosquito_label_shadow = \(ACTOR\*\)label;' 'stung-mosquito request stores host shadow label'
check_contains "src/game/m_player_main_stung_mosquito.c_inc" 'Player_actor_request_main_notice_mosquito\(game, player->stung_mosquito_label_shadow, mPlayer_REQUEST_PRIORITY_26\);' 'notice transition uses host shadow label'
check_contains "src/game/m_player_main_stung_mosquito.c_inc" 'Player_actor_request_main_notice_mosquito\(game, \(void\*\)stung_mosquito_p->label, mPlayer_REQUEST_PRIORITY_26\);' '32-bit notice transition keeps explicit pointer cast'
check_contains "src/game/m_player_main_notice_mosquito.c_inc" 'player->notice_mosquito_label_shadow = \(ACTOR\*\)label;' 'notice-mosquito request stores host shadow label'
check_contains "src/game/m_player_main_notice_mosquito.c_inc" 'req_notice_mosquito_p->label = \(u32\)label;' '32-bit notice request keeps explicit pointer narrowing'
check_contains "src/game/m_player_common.c_inc" 'ACTOR\* stung_label = GET_PLAYER_ACTOR_GAME\(game\)->stung_mosquito_label_shadow;' 'stung-mosquito check reads host shadow label'
check_contains "src/game/m_player_common.c_inc" 'ACTOR\* notice_label = GET_PLAYER_ACTOR_GAME\(game\)->notice_mosquito_label_shadow;' 'notice-mosquito check reads host shadow label'
