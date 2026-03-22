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

check_contains "src/data/field/bg/acre/grd_s_f_pk_1/grd_s_f_pk_1.c" 'static void pc_patch_grd_s_f_pk_1_model\(void\)' 'grd_s_f_pk_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_pk_1/grd_s_f_pk_1.c" 'grd_s_f_pk_1_model\[67\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_pk_1_v\[214\]\);' 'grd_s_f_pk_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_pk_1/grd_s_f_pk_1.c" 'pc_patch_grd_s_f_pk_1_model\(\);' 'grd_s_f_pk_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_r7_p_1/grd_s_r7_p_1.c" 'static void pc_patch_grd_s_r7_p_1_model\(void\)' 'grd_s_r7_p_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_r7_p_1/grd_s_r7_p_1.c" 'grd_s_r7_p_1_modelT\[7\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_r7_p_1 modelT segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r7_p_1/grd_s_r7_p_1.c" 'grd_s_r7_p_1_model\[74\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_r7_p_1_v\[202\]\);' 'grd_s_r7_p_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_r7_p_1/grd_s_r7_p_1.c" 'pc_patch_grd_s_r7_p_1_model\(\);' 'grd_s_r7_p_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e2_t_1/grd_s_e2_t_1.c" 'static void pc_patch_grd_s_e2_t_1_model\(void\)' 'grd_s_e2_t_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e2_t_1/grd_s_e2_t_1.c" 'grd_s_e2_t_1_model\[55\]\.words\.w1 = pc_gbi_ptr_encode\(rail_tex_dummy\);' 'grd_s_e2_t_1 rail texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e2_t_1/grd_s_e2_t_1.c" 'pc_patch_grd_s_e2_t_1_model\(\);' 'grd_s_e2_t_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e2_1/grd_s_e2_1.c" 'static void pc_patch_grd_s_e2_1_model\(void\)' 'grd_s_e2_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e2_1/grd_s_e2_1.c" 'grd_s_e2_1_model\[39\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e2_1_v\[88\]\);' 'grd_s_e2_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e2_1/grd_s_e2_1.c" 'pc_patch_grd_s_e2_1_model\(\);' 'grd_s_e2_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e2_c1_1/grd_s_e2_c1_1.c" 'static void pc_patch_grd_s_e2_c1_1_model\(void\)' 'grd_s_e2_c1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e2_c1_1/grd_s_e2_c1_1.c" 'grd_s_e2_c1_1_model\[37\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e2_c1_1_v\[77\]\);' 'grd_s_e2_c1_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e2_c1_1/grd_s_e2_c1_1.c" 'pc_patch_grd_s_e2_c1_1_model\(\);' 'grd_s_e2_c1_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e2_m_1/grd_s_e2_m_1.c" 'static void pc_patch_grd_s_e2_m_1_model\(void\)' 'grd_s_e2_m_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e2_m_1/grd_s_e2_m_1.c" 'grd_s_e2_m_1_model\[3\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_e2_m_1 model segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e2_m_1/grd_s_e2_m_1.c" 'grd_s_e2_m_1_modelT\[16\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_e2_m_1 modelT segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e2_m_1/grd_s_e2_m_1.c" 'pc_patch_grd_s_e2_m_1_model\(\);' 'grd_s_e2_m_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_m_1/grd_s_m_1.c" 'static void pc_patch_grd_s_m_1_model\(void\)' 'grd_s_m_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_m_1/grd_s_m_1.c" 'grd_s_m_1_model\[58\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_m_1 model segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_1/grd_s_m_1.c" 'grd_s_m_1_modelT\[28\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_D, 0\);' 'grd_s_m_1 modelT segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_1/grd_s_m_1.c" 'pc_patch_grd_s_m_1_model\(\);' 'grd_s_m_1 loader calls patch helper'

printf '%s\n' 'check_grd_e2_coast_model_ptr_patch_contract: OK'
