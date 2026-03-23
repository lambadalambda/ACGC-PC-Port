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

check_contains "src/data/field/bg/acre/grd_s_r5_b_2/grd_s_r5_b_2.c" 'static void pc_patch_grd_s_r5_b_2_model\(void\)' 'grd_s_r5_b_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r5_b_2/grd_s_r5_b_2.c" 'grd_s_r5_b_2_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(bush_pal_dummy\);' 'grd_s_r5_b_2 pointer fixups emitted'
check_contains "src/data/field/bg/acre/grd_s_r5_b_2/grd_s_r5_b_2.c" 'pc_patch_grd_s_r5_b_2_model\(\);' 'grd_s_r5_b_2 loader calls helper'

check_contains "src/data/field/bg/acre/grd_s_t_st1_2/grd_s_t_st1_2.c" 'static void pc_patch_grd_s_t_st1_2_model\(void\)' 'grd_s_t_st1_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_st1_2/grd_s_t_st1_2.c" 'grd_s_t_st1_2_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(bush_pal_dummy\);' 'grd_s_t_st1_2 pointer fixups emitted'
check_contains "src/data/field/bg/acre/grd_s_t_st1_2/grd_s_t_st1_2.c" 'pc_patch_grd_s_t_st1_2_model\(\);' 'grd_s_t_st1_2 loader calls helper'

check_contains "src/data/field/bg/acre/grd_s_t_1/grd_s_t_1.c" 'static void pc_patch_grd_s_t_1_model\(void\)' 'grd_s_t_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_1/grd_s_t_1.c" 'grd_s_t_1_modelT\[7\]\.words\.w1 = pc_gbi_ptr_encode\(water_2_tex_dummy\);' 'grd_s_t_1 modelT nested pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_1/grd_s_t_1.c" 'pc_patch_grd_s_t_1_model\(\);' 'grd_s_t_1 loader calls helper'

check_contains "src/data/field/bg/acre/grd_s_r4_2/grd_s_r4_2.c" 'static void pc_patch_grd_s_r4_2_model\(void\)' 'grd_s_r4_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r4_2/grd_s_r4_2.c" 'grd_s_r4_2_modelT\[9\]\.words\.w1 = \(unsigned int\)\(uintptr_t\)\(0x08000000\);' 'grd_s_r4_2 modelT nested pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r4_2/grd_s_r4_2.c" 'pc_patch_grd_s_r4_2_model\(\);' 'grd_s_r4_2 loader calls helper'

check_contains "src/data/field/bg/acre/grd_s_t_r1_4/grd_s_t_r1_4.c" 'static void pc_patch_grd_s_t_r1_4_model\(void\)' 'grd_s_t_r1_4 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_r1_4/grd_s_t_r1_4.c" 'grd_s_t_r1_4_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(rail_pal_dummy\);' 'grd_s_t_r1_4 pointer fixups emitted'
check_contains "src/data/field/bg/acre/grd_s_t_r1_4/grd_s_t_r1_4.c" 'pc_patch_grd_s_t_r1_4_model\(\);' 'grd_s_t_r1_4 loader calls helper'

check_contains "src/data/field/bg/acre/grd_s_e1_r1_1/grd_s_e1_r1_1.c" 'static void pc_patch_grd_s_e1_r1_1_model\(void\)' 'grd_s_e1_r1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e1_r1_1/grd_s_e1_r1_1.c" 'grd_s_e1_r1_1_modelT\[9\]\.words\.w1 = \(unsigned int\)\(uintptr_t\)\(0x08000000\);' 'grd_s_e1_r1_1 modelT nested pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e1_r1_1/grd_s_e1_r1_1.c" 'pc_patch_grd_s_e1_r1_1_model\(\);' 'grd_s_e1_r1_1 loader calls helper'

check_contains "src/data/model/obj_s_station1.c" 'obj_s_station2_t1_1_model\[5\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_station2_v\);' 'station2 model primary vertex pointer patched'
check_contains "src/data/model/obj_s_station1.c" 'obj_s_station2_long_model\[5\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_station2_v\[105\]\);' 'station2 long model pointer patched'
check_contains "src/data/model/obj_station1_shadow.c" 'obj_station2_shadow_low_model\[6\]\.words\.w1 = SEGMENT_ADDR\(0x8, 0x2C0\);' 'station2 low shadow segment pointer patched'

check_contains "src/data/model/ef_wipe2.c" 'void pc_patch_ef_wipe2_models\(void\)' 'ef_wipe2 LP64 patch helper exists'
check_contains "src/data/model/ef_wipe2.c" 'ef_wipe2_modelT\[9\]\.words\.w1 = pc_gbi_ptr_encode\(ef_wipe2_v\);' 'ef_wipe2 vertex pointer patched'
check_contains "src/game/m_fbdemo_triforce.c" 'pc_patch_ef_wipe2_models\(\);' 'triforce draw applies ef_wipe2 patch helper'

check_contains "src/data/model/ef_kisha_kemuri01_00.c" 'void pc_patch_ef_kisha_kemuri01_models\(void\)' 'ef_kisha_kemuri LP64 patch helper exists'
check_contains "src/data/model/ef_kisha_kemuri01_00.c" 'ef_kisha_kemuri01_modelT\[9\]\.words\.w1 = pc_gbi_ptr_encode\(ef_kisha_kemuri01_00_v\);' 'ef_kisha_kemuri vertex pointer patched'
check_contains "src/effect/ef_kisha_kemuri.c" 'pc_patch_ef_kisha_kemuri01_models\(\);' 'train-smoke effect draw applies helper'

check_contains "src/data/npc/model/mdl/mnk_1.c" 'static void pc_patch_mnk_1_models\(void\)' 'mnk_1 LP64 patch helper exists'
check_contains "src/data/npc/model/mdl/mnk_1.c" 'head_mnk_model\[7\]\.words\.w1 = pc_gbi_ptr_encode\(&mnk_1_v\[0\]\);' 'mnk_1 head vertex pointer patched'
check_contains "src/data/npc/model/mdl/mnk_1.c" 'pc_patch_mnk_1_models\(\);' 'mnk_1 loader calls helper'

check_contains "src/data/npc/model/mdl/rcn_1.c" 'static void pc_patch_rcn_1_models\(void\)' 'rcn_1 LP64 patch helper exists'
check_contains "src/data/npc/model/mdl/rcn_1.c" 'head_rcn_model\[7\]\.words\.w1 = pc_gbi_ptr_encode\(&rcn_1_v\[14\]\);' 'rcn_1 head vertex pointer patched'
check_contains "src/data/npc/model/mdl/rcn_1.c" 'pc_patch_rcn_1_models\(\);' 'rcn_1 loader calls helper'

check_contains "src/data/npc/model/mdl/cat_1.c" 'static void pc_patch_cat_1_models\(void\)' 'cat_1 LP64 patch helper exists'
check_contains "src/data/npc/model/mdl/cat_1.c" 'head_cat_model\[12\]\.words\.w1 = pc_gbi_ptr_encode\(&cat_1_v\[6\]\);' 'cat_1 head vertex pointer patched'
check_contains "src/data/npc/model/mdl/cat_1.c" 'pc_patch_cat_1_models\(\);' 'cat_1 loader calls helper'

check_contains "src/data/model/ef_gimonhu01_00.c" 'void pc_patch_ef_gimonhu01_models\(void\)' 'ef_gimonhu LP64 patch helper exists'
check_contains "src/data/model/ef_gimonhu01_00.c" 'ef_gimonhu01_00_modelT\[7\]\.words\.w1 = pc_gbi_ptr_encode\(ef_gimonhu01_00_v\);' 'ef_gimonhu vertex pointer patched'
check_contains "src/effect/ef_gimonhu.c" 'pc_patch_ef_gimonhu01_models\(\);' 'gimonhu effect draw applies helper'

check_contains "src/data/model/obj_s_cedar5.c" 'void pc_patch_obj_s_cedar5_models\(void\)' 'cedar5 LP64 patch helper exists'
check_contains "src/data/model/obj_s_cedar5.c" 'obj_s_cedar5_leafT_mat_model\[1\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_cedar_leaf_tex\);' 'cedar5 leaf texture pointer patched'
check_contains "src/data/model/obj_s_cedar5.c" 'obj_s_cedar5_trunkT_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_cedar5_v\[68\]\);' 'cedar5 trunk vertex pointer patched'

check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_cedar5_models\(\);' 'normal bg-item path applies cedar5 helper'
check_contains "src/bg_item/bg_cherry_item.c" 'pc_patch_obj_s_cedar5_models\(\);' 'cherry bg-item path applies cedar5 helper'
check_contains "src/bg_item/bg_winter_item.c" 'pc_patch_obj_s_cedar5_models\(\);' 'winter bg-item path applies cedar5 helper'
check_contains "src/bg_item/bg_xmas_item.c" 'pc_patch_obj_s_cedar5_models\(\);' 'xmas bg-item path applies cedar5 helper'

printf '%s\n' 'check_post_train_scene_ptr_patch_contract: OK'
