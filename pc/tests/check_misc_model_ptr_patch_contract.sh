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

check_contains "src/data/model/obj_e_mikanbox.c" 'void pc_patch_obj_e_mikanbox_models\(void\)' 'mikanbox LP64 patch helper exists'
check_contains "src/data/model/obj_e_mikanbox.c" 'obj_e_mikanbox_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(obj_e_mikanbox_v\);' 'mikanbox vertex pointer patched'
check_contains "src/data/model/obj_e_mikanbox.c" 'pc_patch_obj_e_mikanbox_models\(\);' 'mikanbox loader applies patch helper'

check_contains "src/data/model/obj_s_fenceL.c" 'void pc_patch_obj_s_fenceL_models\(void\)' 'fence LP64 patch helper exists'
check_contains "src/data/model/obj_s_fenceL.c" 'obj_s_fenceLT_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_fenceL_v\);' 'fence vertex pointer patched'

check_contains "src/data/model/obj_s_sightmap.c" 'void pc_patch_obj_s_sightmap_models\(void\)' 'sightmap LP64 patch helper exists'
check_contains "src/data/model/obj_s_sightmap.c" 'obj_s_sightmapT_mat_model\[2\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_sightmap_tex\);' 'sightmap texture pointer patched'
check_contains "src/data/model/obj_s_sightmap.c" 'pc_patch_obj_s_sightmap_models\(\);' 'sightmap loader applies patch helper'

check_contains "src/data/model/obj_s_notice.c" 'void pc_patch_obj_s_notice_models\(void\)' 'notice LP64 patch helper exists'
check_contains "src/data/model/obj_s_notice.c" 'obj_s_noticeT_mat_model\[2\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_notice_tex\);' 'notice texture pointer patched'
check_contains "src/data/model/obj_s_notice.c" 'pc_patch_obj_s_notice_models\(\);' 'notice loader applies patch helper'

check_contains "src/data/model/obj_s_stoneA.c" 'void pc_patch_obj_s_stoneA_models\(void\)' 'stoneA LP64 patch helper exists'
check_contains "src/data/model/obj_stoneA_shadow.c" 'void pc_patch_obj_stoneA_shadow_models\(void\)' 'stoneA shadow LP64 patch helper exists'
check_contains "src/data/model/obj_notice.c" 'void pc_patch_obj_notice_shadow_models\(void\)' 'notice shadow LP64 patch helper exists'

check_contains "src/data/model/f_tree5.c" 'void pc_patch_obj_f_tree5_models\(void\)' 'tree5 LP64 patch helper exists'
check_contains "src/data/model/f_tree5.c" 'obj_f_tree5_trunkT_gfx_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_f_tree5_v\[15\]\);' 'tree5 trunk vertex pointer patched'
check_contains "src/data/model/obj_tree5_shadow.c" 'void pc_patch_obj_tree5_shadow_models\(void\)' 'tree5 shadow LP64 patch helper exists'

check_contains "src/bg_item/bg_item.c" 'bIT_patch_lp64_bg_item_models\(\);' 'bg_item actor applies LP64 bg-item patch set'
check_contains "src/bg_item/bg_cherry_item.c" 'bIT_patch_lp64_bg_item_models\(\);' 'bg_cherry actor applies LP64 bg-item patch set'
check_contains "src/bg_item/bg_winter_item.c" 'bIT_patch_lp64_bg_item_models\(\);' 'bg_winter actor applies LP64 bg-item patch set'
check_contains "src/bg_item/bg_xmas_item.c" 'bIT_patch_lp64_bg_item_models\(\);' 'bg_xmas actor applies LP64 bg-item patch set'

check_contains "src/data/model/ef_hanabira01_00.c" 'void pc_patch_ef_hanabira01_00_models\(void\)' 'sakura effect LP64 patch helper exists'
check_contains "src/actor/ac_weather_sakura.c" 'pc_patch_ef_hanabira01_00_models\(\);' 'sakura weather path applies effect patch helper'

check_contains "src/data/model/point_light.c" 'void pc_patch_point_light_models\(void\)' 'point-light LP64 patch helper exists'
check_contains "src/game/m_lights.c" 'pc_patch_point_light_models\(\);' 'light renderer applies point-light patch helper'

check_contains "src/data/npc/model/mdl/end_1.c" 'static void pc_patch_end_1_models\(void\)' 'end_1 NPC LP64 patch helper exists'
check_contains "src/data/npc/model/mdl/end_1.c" 'Lfoot1_end_model\[0\]\.words\.w1 = SEGMENT_ADDR\(ANIME_6_TXT_SEG, 0x0\);' 'end_1 left-foot matrix segment pointer patched'
check_contains "src/data/npc/model/mdl/end_1.c" 'Lfoot1_end_model\[11\]\.words\.w1 = pc_gbi_ptr_encode\(&end_1_v\[319\]\);' 'end_1 left-foot vertex pointer patched'
check_contains "src/data/npc/model/mdl/end_1.c" 'base_end_model\[39\]\.words\.w1 = pc_gbi_ptr_encode\(&end_1_v\[439\]\);' 'end_1 base final vertex pointer patched'
check_contains "src/data/npc/model/mdl/end_1.c" 'pc_patch_end_1_models\(\);' 'end_1 loader applies patch helper'

printf '%s\n' 'check_misc_model_ptr_patch_contract: OK'
