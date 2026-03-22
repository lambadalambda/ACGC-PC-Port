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

check_contains "src/data/field/bg/acre/grd_s_c2_1/grd_s_c2_1.c" 'static void pc_patch_grd_s_c2_1_model\(void\)' 'grd_s_c2_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c2_1/grd_s_c2_1.c" 'grd_s_c2_1_model\[40\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'grd_s_c2_1 cliff texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c2_1/grd_s_c2_1.c" 'grd_s_c2_1_model\[67\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c2_1_v\[171\]\);' 'grd_s_c2_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c2_1/grd_s_c2_1.c" 'pc_patch_grd_s_c2_1_model\(\);' 'grd_s_c2_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_c4_s_1/grd_s_c4_s_1.c" 'static void pc_patch_grd_s_c4_s_1_model\(void\)' 'grd_s_c4_s_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c4_s_1/grd_s_c4_s_1.c" 'grd_s_c4_s_1_model\[47\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'grd_s_c4_s_1 cliff texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c4_s_1/grd_s_c4_s_1.c" 'grd_s_c4_s_1_model\[69\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c4_s_1_v\[179\]\);' 'grd_s_c4_s_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c4_s_1/grd_s_c4_s_1.c" 'pc_patch_grd_s_c4_s_1_model\(\);' 'grd_s_c4_s_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_c5_1/grd_s_c5_1.c" 'static void pc_patch_grd_s_c5_1_model\(void\)' 'grd_s_c5_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c5_1/grd_s_c5_1.c" 'grd_s_c5_1_model\[30\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'grd_s_c5_1 cliff texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c5_1/grd_s_c5_1.c" 'grd_s_c5_1_model\[61\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c5_1_v\[151\]\);' 'grd_s_c5_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c5_1/grd_s_c5_1.c" 'pc_patch_grd_s_c5_1_model\(\);' 'grd_s_c5_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_c7_1/grd_s_c7_1.c" 'static void pc_patch_grd_s_c7_1_model\(void\)' 'grd_s_c7_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_c7_1/grd_s_c7_1.c" 'grd_s_c7_1_model\[15\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'grd_s_c7_1 cliff texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c7_1/grd_s_c7_1.c" 'grd_s_c7_1_model\[64\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_c7_1_v\[166\]\);' 'grd_s_c7_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_c7_1/grd_s_c7_1.c" 'pc_patch_grd_s_c7_1_model\(\);' 'grd_s_c7_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_m_r1_b_2/grd_s_m_r1_b_2.c" 'static void pc_patch_grd_s_m_r1_b_2_model\(void\)' 'grd_s_m_r1_b_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_m_r1_b_2/grd_s_m_r1_b_2.c" 'grd_s_m_r1_b_2_model\[3\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_C, 0\);' 'grd_s_m_r1_b_2 segment display-list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_r1_b_2/grd_s_m_r1_b_2.c" 'grd_s_m_r1_b_2_modelT\[41\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_8, 0\);' 'grd_s_m_r1_b_2 modelT segment pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_r1_b_2/grd_s_m_r1_b_2.c" 'grd_s_m_r1_b_2_model\[87\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_m_r1_b_2_v\[158\]\);' 'grd_s_m_r1_b_2 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_m_r1_b_2/grd_s_m_r1_b_2.c" 'pc_patch_grd_s_m_r1_b_2_model\(\);' 'grd_s_m_r1_b_2 loader calls patch helper'

printf '%s\n' 'check_grd_midrun_model_ptr_patch_contract: OK'
