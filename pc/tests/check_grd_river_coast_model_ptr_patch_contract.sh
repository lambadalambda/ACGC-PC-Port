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

check_contains "src/data/field/bg/acre/grd_s_t_r1_1/grd_s_t_r1_1.c" 'static void pc_patch_grd_s_t_r1_1_model\(void\)' 'grd_s_t_r1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_r1_1/grd_s_t_r1_1.c" 'grd_s_t_r1_1_model\[70\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_t_r1_1_v\[154\]\);' 'grd_s_t_r1_1 final river vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_r1_1/grd_s_t_r1_1.c" 'grd_s_t_r1_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_t_r1_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_r1_1/grd_s_t_r1_1.c" 'pc_patch_grd_s_t_r1_1_model\(\);' 'grd_s_t_r1_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_m_2/grd_s_m_2.c" 'static void pc_patch_grd_s_m_2_model\(void\)' 'grd_s_m_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_m_2/grd_s_m_2.c" 'grd_s_m_2_model\[3\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_m_2 segment-C display list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_2/grd_s_m_2.c" 'grd_s_m_2_modelT\[22\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_m_2 water layer segment-D pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_2/grd_s_m_2.c" 'pc_patch_grd_s_m_2_model\(\);' 'grd_s_m_2 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_c1_r1_1/grd_s_c1_r1_1.c" 'static void pc_patch_grd_s_c1_r1_1_model\(void\)' 'grd_s_c1_r1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c1_r1_1/grd_s_c1_r1_1.c" 'grd_s_c1_r1_1_model\[88\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c1_r1_1_v\[245\]\);' 'grd_s_c1_r1_1 final bush vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c1_r1_1/grd_s_c1_r1_1.c" 'grd_s_c1_r1_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_c1_r1_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c1_r1_1/grd_s_c1_r1_1.c" 'pc_patch_grd_s_c1_r1_1_model\(\);' 'grd_s_c1_r1_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_m_4/grd_s_m_4.c" 'static void pc_patch_grd_s_m_4_model\(void\)' 'grd_s_m_4 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_m_4/grd_s_m_4.c" 'grd_s_m_4_model\[64\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_m_4 segment-C display list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_4/grd_s_m_4.c" 'grd_s_m_4_modelT\[26\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_m_4 water layer segment-D pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_4/grd_s_m_4.c" 'pc_patch_grd_s_m_4_model\(\);' 'grd_s_m_4 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_r1_b_1/grd_s_r1_b_1.c" 'static void pc_patch_grd_s_r1_b_1_model\(void\)' 'grd_s_r1_b_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r1_b_1/grd_s_r1_b_1.c" 'grd_s_r1_b_1_model\[11\]\.words\.w1 = pc_gbi_ptr_encode\(bridge_1_pal_dummy\);' 'grd_s_r1_b_1 bridge palette pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r1_b_1/grd_s_r1_b_1.c" 'grd_s_r1_b_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_r1_b_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r1_b_1/grd_s_r1_b_1.c" 'pc_patch_grd_s_r1_b_1_model\(\);' 'grd_s_r1_b_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_m_3/grd_s_m_3.c" 'static void pc_patch_grd_s_m_3_model\(void\)' 'grd_s_m_3 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_m_3/grd_s_m_3.c" 'grd_s_m_3_model\[65\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_m_3 segment-C display list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_3/grd_s_m_3.c" 'grd_s_m_3_modelT\[22\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_m_3 water layer segment-D pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_3/grd_s_m_3.c" 'pc_patch_grd_s_m_3_model\(\);' 'grd_s_m_3 loader calls patch helper'

printf '%s\n' 'check_grd_river_coast_model_ptr_patch_contract: OK'
