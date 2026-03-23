#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MSG_DATA_INC="$REPO_ROOT/src/game/m_msg_data.c_inc"
MSG_DRAW_INC="$REPO_ROOT/src/game/m_msg_draw_window.c_inc"
CHOICE_DRAW_INC="$REPO_ROOT/src/game/m_choice_draw.c_inc"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$MSG_DATA_INC" 'con_kaiwa2_modelT\[1\]\.words\.w1 = pc_gbi_ptr_encode\(con_kaiwa2_w3_tex\);' 'message bubble first texture pointer is patched'
check_contains "$MSG_DATA_INC" 'con_kaiwa2_modelT\[3\]\.words\.w1 = pc_gbi_ptr_encode\(&con_kaiwa2_v\[0\]\);' 'message bubble vertex pointer is patched'
check_contains "$MSG_DATA_INC" 'con_kaiwa2_modelT\[6\]\.words\.w1 = pc_gbi_ptr_encode\(con_kaiwa2_w2_tex\);' 'message bubble second texture pointer is patched'
check_contains "$MSG_DATA_INC" 'con_kaiwa2_modelT\[10\]\.words\.w1 = pc_gbi_ptr_encode\(con_kaiwa2_w1_tex\);' 'message bubble third texture pointer is patched'
check_contains "$MSG_DATA_INC" 'con_kaiwaname_modelT\[1\]\.words\.w1 = pc_gbi_ptr_encode\(con_namefuti_TXT\);' 'nameplate texture pointer is patched'
check_contains "$MSG_DATA_INC" 'con_kaiwaname_modelT\[3\]\.words\.w1 = pc_gbi_ptr_encode\(&con_kaiwaname_v\[0\]\);' 'nameplate vertex pointer is patched'
check_contains "$MSG_DRAW_INC" 'mMsg_patch_window_display_lists\(\);' 'message draw path invokes LP64 patch helper'

check_contains "$CHOICE_DRAW_INC" 'con_sentaku2_modelT\[2\]\.words\.w1 = pc_gbi_ptr_encode\(con_waku_swaku3_tex\);' 'choice window texture pointer is patched'
check_contains "$CHOICE_DRAW_INC" 'con_sentaku2_modelT\[4\]\.words\.w1 = pc_gbi_ptr_encode\(&con_sentaku2_v\[0\]\);' 'choice window vertex pointer is patched'
check_contains "$CHOICE_DRAW_INC" 'mChoice_patch_window_display_list\(\);' 'choice draw path invokes LP64 patch helper'

printf '%s\n' 'check_msg_choice_window_ptr_patch_contract: OK'
