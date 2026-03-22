#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "src/data/model/girl_model.c" 'void pc_patch_girl_model_display_lists\(void\)' 'girl model LP64 patch helper exists'
check_contains "src/data/model/girl_model.c" 'head_grl_model\[0\]\.words\.w1 = SEGMENT_ADDR\(ANIME_6_TXT_SEG, \(7\) \* sizeof\(Mtx\)\);' 'girl head matrix segment pointer patched'
check_contains "src/data/model/girl_model.c" 'head_grl_model\[46\]\.words\.w1 = anime_1_txt;' 'girl head anime texture pointer patched'
check_contains "src/data/model/girl_model.c" 'Larm1_grl_model\[23\]\.words\.w1 = pc_gbi_ptr_encode\(&grl_1_v\[167\]\);' 'girl left arm vertex pointer patched'
check_contains "src/data/model/girl_model.c" 'bace_grl_model\[17\]\.words\.w1 = pc_gbi_ptr_encode\(grl_1_hole_tex_txt\);' 'girl base hole texture pointer patched'

check_contains "src/game/m_player_lib.c" 'extern void pc_patch_girl_model_display_lists\(void\);' 'player lib declares girl patch helper'
check_contains "src/game/m_player_lib.c" 'pc_patch_girl_model_display_lists\(\);' 'player model selection applies girl patch'

printf '%s\n' 'check_girl_model_ptr_patch_contract: OK'
