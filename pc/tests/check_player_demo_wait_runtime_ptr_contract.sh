#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player demo-wait pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'ACTOR\* demo_wait_label_shadow;' 'player struct has LP64 demo-wait shadow field'
check_contains "include/m_player.h" 'ACTOR\* demo_wait_label_shadow;' 'submenu change data has LP64 demo-wait shadow field'
check_contains "src/game/m_player_main_demo_wait.c_inc" 'player->demo_wait_label_shadow = \(ACTOR\*\)label;' 'demo-wait request stores player host shadow label'
check_contains "src/game/m_player_main_demo_wait.c_inc" 'Player_actor_request_main_demo_wait_all\(game, req_demo_wait_p->umbrella_flag, change_data_p->demo_wait_label_shadow,' 'submenu demo-wait request uses host shadow label'
check_contains "src/game/m_player_lib.c" 'change_data_from_submenu_p->demo_wait_label_shadow = speak_actor_p;' 'submenu demo-wait setter stores host shadow label'
check_contains "src/game/m_player_lib.c" 'return GET_PLAYER_ACTOR_GAME\(game\)->demo_wait_label_shadow == label;' 'demo-wait compare uses host shadow label'
