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

check_contains "src/data/model/obj_s_house1.c" 'void pc_patch_obj_s_house_models\(void\)' 'house model LP64 patch helper exists'
check_contains "src/data/model/obj_s_house1.c" 'obj_s_house1_t1_model\[14\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_house1_v\[107\]\);' 'house1 secondary vertex pointer patched'
check_contains "src/data/model/obj_s_house1.c" 'obj_s_house4_t3_model\[15\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_house4_v\[59\]\);' 'house4 secondary vertex pointer patched'

check_contains "src/data/model/obj_house1_shadow.c" 'void pc_patch_obj_house_shadow_models\(void\)' 'house shadow LP64 patch helper exists'
check_contains "src/data/model/obj_house1_shadow.c" 'obj_s_house3_shadow_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'house3 shadow segment pointer patched'
check_contains "src/actor/ac_house.c" 'pc_patch_obj_s_house_models\(\);' 'house actor applies model patch helper'
check_contains "src/actor/ac_house.c" 'pc_patch_obj_house_shadow_models\(\);' 'house actor applies shadow patch helper'

check_contains "src/data/model/obj_s_yubinkyoku.c" 'void pc_patch_obj_s_yubinkyoku_models\(void\)' 'post office model LP64 patch helper exists'
check_contains "src/data/model/obj_s_yubinkyoku.c" 'obj_s_yubinkyoku_door_model\[3\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'post office door segment pointer patched'
check_contains "src/data/model/obj_s_yubinkyoku_shadow.c" 'void pc_patch_obj_s_yubinkyoku_shadow_models\(void\)' 'post office shadow LP64 patch helper exists'
check_contains "src/data/model/obj_s_yubinkyoku_shadow.c" 'obj_s_yubinkyoku_shadow_2_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'post office shadow segment pointer patched'
check_contains "src/actor/ac_post_office.c" 'pc_patch_obj_s_yubinkyoku_models\(\);' 'post office actor applies model patch helper'
check_contains "src/actor/ac_post_office.c" 'pc_patch_obj_s_yubinkyoku_shadow_models\(\);' 'post office actor applies shadow patch helper'

check_contains "src/data/model/obj_s_melody.c" 'void pc_patch_obj_s_melody_models\(void\)' 'melody LP64 patch helper exists'
check_contains "src/data/model/obj_s_melody.c" 'obj_s_melodyT_mat_model\[2\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_melody_tex\);' 'melody texture pointer patched'
check_contains "src/data/model/obj_melody.c" 'void pc_patch_obj_melody_shadow_models\(void\)' 'melody shadow LP64 patch helper exists'
check_contains "src/data/model/obj_melody.c" 'obj_melody_shadowT_mat_model\[1\]\.words\.w1 = pc_gbi_ptr_encode\(obj_melody_shadow_tex\);' 'melody shadow texture pointer patched'

check_contains "src/data/model/obj_s_stoneB.c" 'void pc_patch_obj_s_stoneB_models\(void\)' 'stoneB LP64 patch helper exists'
check_contains "src/data/model/obj_s_stoneB.c" 'obj_s_stoneB_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_stoneB_v\);' 'stoneB vertex pointer patched'
check_contains "src/data/model/obj_s_stoneC.c" 'void pc_patch_obj_s_stoneC_models\(void\)' 'stoneC LP64 patch helper exists'
check_contains "src/data/model/obj_s_stoneC.c" 'obj_s_stoneC_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_stoneC_v\);' 'stoneC vertex pointer patched'
check_contains "src/data/model/obj_s_stoneD.c" 'void pc_patch_obj_s_stoneD_models\(void\)' 'stoneD LP64 patch helper exists'
check_contains "src/data/model/obj_s_stoneD.c" 'obj_s_stoneD_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_stoneD_v\);' 'stoneD vertex pointer patched'

check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_stoneB_models\(\);' 'bg_item actor applies stoneB patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_stoneC_models\(\);' 'bg_item actor applies stoneC patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_stoneD_models\(\);' 'bg_item actor applies stoneD patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_melody_models\(\);' 'bg_item actor applies melody patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_melody_shadow_models\(\);' 'bg_item actor applies melody-shadow patch helper'
check_contains "src/bg_item/bg_cherry_item.c" 'pc_patch_obj_s_melody_models\(\);' 'bg_cherry actor applies melody patch helper'
check_contains "src/bg_item/bg_winter_item.c" 'pc_patch_obj_s_melody_models\(\);' 'bg_winter actor applies melody patch helper'
check_contains "src/bg_item/bg_xmas_item.c" 'pc_patch_obj_s_melody_models\(\);' 'bg_xmas actor applies melody patch helper'

printf '%s\n' 'check_house_postoffice_bgitem_ptr_patch_contract: OK'
