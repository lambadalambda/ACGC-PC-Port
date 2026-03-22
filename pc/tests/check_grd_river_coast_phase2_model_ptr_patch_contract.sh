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

check_contains "src/data/field/bg/acre/grd_s_c1_s_1/grd_s_c1_s_1.c" 'static void pc_patch_grd_s_c1_s_1_model\(void\)' 'grd_s_c1_s_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c1_s_1/grd_s_c1_s_1.c" 'grd_s_c1_s_1_model\[63\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c1_s_1_v\[182\]\);' 'grd_s_c1_s_1 final bush vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c1_s_1/grd_s_c1_s_1.c" 'pc_patch_grd_s_c1_s_1_model\(\);' 'grd_s_c1_s_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_r7_1/grd_s_r7_1.c" 'static void pc_patch_grd_s_r7_1_model\(void\)' 'grd_s_r7_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r7_1/grd_s_r7_1.c" 'grd_s_r7_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_r7_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r7_1/grd_s_r7_1.c" 'pc_patch_grd_s_r7_1_model\(\);' 'grd_s_r7_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_f_ko_1/grd_s_f_ko_1.c" 'static void pc_patch_grd_s_f_ko_1_model\(void\)' 'grd_s_f_ko_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_ko_1/grd_s_f_ko_1.c" 'grd_s_f_ko_1_model\[64\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_ko_1_v\[180\]\);' 'grd_s_f_ko_1 final stone vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_ko_1/grd_s_f_ko_1.c" 'pc_patch_grd_s_f_ko_1_model\(\);' 'grd_s_f_ko_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_r3_1/grd_s_r3_1.c" 'static void pc_patch_grd_s_r3_1_model\(void\)' 'grd_s_r3_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r3_1/grd_s_r3_1.c" 'grd_s_r3_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_r3_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r3_1/grd_s_r3_1.c" 'pc_patch_grd_s_r3_1_model\(\);' 'grd_s_r3_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_r6_1/grd_s_r6_1.c" 'static void pc_patch_grd_s_r6_1_model\(void\)' 'grd_s_r6_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r6_1/grd_s_r6_1.c" 'grd_s_r6_1_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_r6_1 water layer segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r6_1/grd_s_r6_1.c" 'pc_patch_grd_s_r6_1_model\(\);' 'grd_s_r6_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e3_t_1/grd_s_e3_t_1.c" 'static void pc_patch_grd_s_e3_t_1_model\(void\)' 'grd_s_e3_t_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e3_t_1/grd_s_e3_t_1.c" 'grd_s_e3_t_1_model\[57\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_t_1_v\[130\]\);' 'grd_s_e3_t_1 rail vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e3_t_1/grd_s_e3_t_1.c" 'pc_patch_grd_s_e3_t_1_model\(\);' 'grd_s_e3_t_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e3_m_1/grd_s_e3_m_1.c" 'static void pc_patch_grd_s_e3_m_1_model\(void\)' 'grd_s_e3_m_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e3_m_1/grd_s_e3_m_1.c" 'grd_s_e3_m_1_model\[3\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_e3_m_1 segment-C display list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e3_m_1/grd_s_e3_m_1.c" 'grd_s_e3_m_1_modelT\[16\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_e3_m_1 water layer segment-D pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e3_m_1/grd_s_e3_m_1.c" 'pc_patch_grd_s_e3_m_1_model\(\);' 'grd_s_e3_m_1 loader calls patch helper'

printf '%s\n' 'check_grd_river_coast_phase2_model_ptr_patch_contract: OK'
