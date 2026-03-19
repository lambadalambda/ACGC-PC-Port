#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player net-catch pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy player net-catch pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player.h" 'int \(\*Set_Item_net_catch_request_table_proc\)\(ACTOR\*, GAME\*, void\*, s8, const xyz_t\*, f32\);' 'request-table proc uses pointer-safe label parameter'
check_contains "include/m_player.h" 'int \(\*Set_Item_net_catch_request_force_proc\)\(ACTOR\*, GAME\*, void\*, s8\);' 'force-request proc uses pointer-safe label parameter'
check_contains "include/m_player.h" 'void\* \(\*Get_item_net_catch_label_proc\)\(ACTOR\*\);' 'get-label proc returns pointer-safe label'
check_contains "include/m_player.h" 'int \(\*Change_item_net_catch_label_proc\)\(ACTOR\*, void\*, s8\);' 'change-label proc takes pointer-safe label'
check_contains "include/m_player.h" 'void\* item_net_catch_label_shadow;' 'player struct has LP64 net-catch shadow label'
check_contains "include/m_player.h" 'void\* item_net_catch_label_request_table_shadow\[mPlayer_NET_CATCH_TABLE_COUNT\];' 'player struct has LP64 net-catch request table shadow'
check_contains "include/m_player.h" 'void\* item_net_catch_label_request_force_shadow;' 'player struct has LP64 net-catch force shadow label'

check_contains "src/game/m_player_common.c_inc" 'return player->item_net_catch_label_shadow;' 'net-catch getter reads LP64 shadow label'
check_contains "src/game/m_player_common.c_inc" 'player->item_net_catch_label_request_table_shadow\[idx\] = label;' 'request-table setter stores LP64 shadow label'
check_contains "src/game/m_player_common.c_inc" 'player->item_net_catch_label_request_force_shadow = label;' 'force setter stores LP64 shadow label'
check_contains "src/game/m_player_common.c_inc" 'player->item_net_catch_label = \(u32\)label;' '32-bit path keeps explicit current-label narrowing'
check_contains "src/game/m_player_common.c_inc" 'player->item_net_catch_label_request_table\[idx\] = \(u32\)label;' '32-bit path keeps explicit request-table narrowing'
check_contains "src/game/m_player_common.c_inc" 'player->item_net_catch_label_request_force = \(u32\)label;' '32-bit path keeps explicit force-label narrowing'

check_contains "src/game/m_player_main_swing_net.c_inc" 'Player_actor_Set_Item_net_catch_label_p\(player, NULL\);' 'swing-net setup clears pointer-safe current label'
check_contains "src/game/m_player_main_swing_net.c_inc" 'ACTOR\* hit_actor = NULL;' 'swing-net hit actor stays pointer-width safe'
check_contains "src/game/m_player_lib.c" 'extern void\* mPlib_Get_item_net_catch_label\(void\)' 'player lib getter returns pointer-safe label'
check_contains "src/game/m_player_lib.c" 'extern int mPlib_Change_item_net_catch_label\(void\* label, s8 type\)' 'player lib changer takes pointer-safe label'

check_absent "src/actor" 'u32 (label|catch_label) = mPlib_Get_item_net_catch_label' 'actor net-catch readers still narrow labels to u32'
check_absent "src/actor" '\(u32\)mPlib_Get_item_net_catch_label' 'actor net-catch readers still cast label reads'
check_absent "src/actor" 'Set_Item_net_catch_request_(table|force)_proc\([^\n]*\(u32\)' 'actor net-catch producers still pass narrowed labels'
check_absent "src/actor" 'mPlib_Change_item_net_catch_label\(\(u32\)' 'actor net-catch label changes still narrow labels'
