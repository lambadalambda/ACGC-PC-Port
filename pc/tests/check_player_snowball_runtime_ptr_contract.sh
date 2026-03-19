#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player snowball pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'ACTOR\* push_snowball_label_shadow;' 'player struct has push-snowball shadow field'
check_contains "include/m_player.h" 'ACTOR\* wade_snowball_label_shadow;' 'player struct has wade-snowball shadow field'
check_contains "src/game/m_player_main_push_snowball.c_inc" 'if \(player->wade_snowball_label_shadow != label\) \{' 'wade-to-push transition compares host shadow label'
check_contains "src/game/m_player_main_push_snowball.c_inc" 'player->push_snowball_label_shadow = \(ACTOR\*\)label;' 'push-snowball request stores host shadow label'
check_contains "src/game/m_player_main_wade_snowball.c_inc" 'player->wade_snowball_label_shadow = player->push_snowball_label_shadow;' 'wade-snowball request carries host shadow label'
check_contains "src/game/m_player_main_wade_snowball.c_inc" 'Player_actor_request_main_push_snowball_all\(game, player->wade_snowball_label_shadow, 1,' 'wade-snowball resume uses host shadow label'
check_contains "src/game/m_player_common.c_inc" 'player->push_snowball_label_shadow == label' 'push-snowball label check uses host shadow label'
check_contains "src/game/m_player_common.c_inc" 'player->wade_snowball_label_shadow == label' 'wade-snowball label check uses host shadow label'
