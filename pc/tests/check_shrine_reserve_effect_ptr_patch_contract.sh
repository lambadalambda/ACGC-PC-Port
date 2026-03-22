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

check_contains "src/data/field/bg/acre/grd_s_e4_1/grd_s_e4_1.c" 'static void pc_patch_grd_s_e4_1_model\(void\)' 'grd_s_e4_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e4_1/grd_s_e4_1.c" 'grd_s_e4_1_model\[14\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e4_1_v\[7\]\);' 'grd_s_e4_1 cliff vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e4_1/grd_s_e4_1.c" 'pc_patch_grd_s_e4_1_model\(\);' 'grd_s_e4_1 loader calls patch helper'

check_contains "src/data/model/obj_s_shrine.c" 'static void pc_patch_obj_s_shrine_models\(void\)' 'shrine LP64 patch helper exists'
check_contains "src/data/model/obj_s_shrine.c" 'obj_s_shrine_base_model\[48\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_shrine_v\[207\]\);' 'shrine base final vertex pointer patched'
check_contains "src/data/model/obj_s_shrine.c" 'obj_s_shrine_bubble_model\[7\]\.words\.w1 = SEGMENT_ADDR\(ANIME_4_TXT_SEG, 0\);' 'shrine bubble segment display list patched'
check_contains "src/data/model/obj_s_shrine.c" 'pc_patch_obj_s_shrine_models\(\);' 'shrine loader calls patch helper'

check_contains "src/data/model/obj_shrine_shadow.c" 'void pc_patch_obj_shrine_shadow_models\(void\)' 'shrine shadow LP64 patch helper exists'
check_contains "src/data/model/obj_shrine_shadow.c" 'obj_shrine_shadow_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'shrine shadow segment vertex source patched'
check_contains "src/actor/ac_shrine.c" 'pc_patch_obj_shrine_shadow_models\(\);' 'shrine actor path applies shadow patch helper'

check_contains "src/data/model/obj_s_buildsite.c" 'void pc_patch_obj_s_buildsite_models\(void\)' 'buildsite LP64 patch helper exists'
check_contains "src/data/model/obj_s_buildsite.c" 'reserve_DL_model\[0\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'reserve display list segment pointer patched'
check_contains "src/data/model/obj_s_buildsite.c" 'reserve_DL_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_buildsite_v\);' 'reserve display list vertex pointer patched'

check_contains "src/data/model/reserve_shadow.c" 'void pc_patch_reserve_shadow_models\(void\)' 'reserve shadow LP64 patch helper exists'
check_contains "src/data/model/reserve_shadow.c" 'reserve_shadow_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'reserve shadow segment vertex source patched'
check_contains "src/actor/ac_reserve.c" 'pc_patch_obj_s_buildsite_models\(\);' 'reserve actor applies buildsite patch helper'
check_contains "src/actor/ac_reserve.c" 'pc_patch_reserve_shadow_models\(\);' 'reserve actor applies shadow patch helper'

check_contains "src/data/model/ef_s_yabu01_00.c" 'void pc_patch_ef_s_yabu01_00_models\(void\)' 'bush happa LP64 patch helper exists'
check_contains "src/data/model/ef_s_yabu01_00.c" 'ef_s_yabu01_00_modelT\[7\]\.words\.w1 = pc_gbi_ptr_encode\(ef_s_yabu01_00_v\);' 'bush happa vertex pointer patched'
check_contains "src/effect/ef_bush_happa.c" 'pc_patch_ef_s_yabu01_00_models\(\);' 'bush happa effect path applies patch helper'

printf '%s\n' 'check_shrine_reserve_effect_ptr_patch_contract: OK'
