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

check_contains "src/data/model/boy_model.c" 'void pc_patch_boy_model_display_lists\(void\)' 'boy model LP64 patch helper exists'
check_contains "src/data/model/boy_model.c" 'head_boy_model\[0\]\.words\.w1 = SEGMENT_ADDR\(ANIME_6_TXT_SEG, \(7\) \* sizeof\(Mtx\)\);' 'head matrix segment pointer patched'
check_contains "src/data/model/boy_model.c" 'head_boy_model\[61\]\.words\.w1 = anime_2_txt;' 'head anime texture pointer patched'
check_contains "src/data/model/boy_model.c" 'Larm1_boy_model\[24\]\.words\.w1 = pc_gbi_ptr_encode\(&boy_1_v\[0xa3\]\);' 'left arm vertex pointer patched'
check_contains "src/data/model/boy_model.c" 'base_boy_model\[29\]\.words\.w1 = anime_3_txt;' 'base anime texture pointer patched'

check_contains "src/game/m_player_lib.c" 'extern void pc_patch_boy_model_display_lists\(void\);' 'player lib declares boy patch helper'
check_contains "src/game/m_player_lib.c" 'pc_patch_boy_model_display_lists\(\);' 'player model selection applies boy patch'

printf '%s\n' 'check_boy_model_ptr_patch_contract: OK'
