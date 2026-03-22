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

check_contains "src/data/field/bg/acre/grd_s_f_2/grd_s_f_2.c" 'static void pc_patch_grd_s_f_2_model\(void\)' 'grd_s_f_2 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_2/grd_s_f_2.c" 'grd_s_f_2_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(bush_pal_dummy\);' 'grd_s_f_2 TLUT pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_2/grd_s_f_2.c" 'grd_s_f_2_model\[58\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_2_v\[131\]\);' 'grd_s_f_2 last vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_2/grd_s_f_2.c" 'pc_patch_grd_s_f_2_model\(\);' 'grd_s_f_2 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_f_3/grd_s_f_3.c" 'static void pc_patch_grd_s_f_3_model\(void\)' 'grd_s_f_3 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_3/grd_s_f_3.c" 'grd_s_f_3_model\[13\]\.words\.w1 = pc_gbi_ptr_encode\(grass_tex_dummy\);' 'grd_s_f_3 texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_3/grd_s_f_3.c" 'grd_s_f_3_model\[42\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_3_v\[100\]\);' 'grd_s_f_3 last vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_3/grd_s_f_3.c" 'pc_patch_grd_s_f_3_model\(\);' 'grd_s_f_3 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_f_mh_1/grd_s_f_mh_1.c" 'static void pc_patch_grd_s_f_mh_1_model\(void\)' 'grd_s_f_mh_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_mh_1/grd_s_f_mh_1.c" 'grd_s_f_mh_1_model\[26\]\.words\.w1 = pc_gbi_ptr_encode\(grass_tex_dummy\);' 'grd_s_f_mh_1 texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_mh_1/grd_s_f_mh_1.c" 'grd_s_f_mh_1_model\[49\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_mh_1_v\[183\]\);' 'grd_s_f_mh_1 last vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_mh_1/grd_s_f_mh_1.c" 'pc_patch_grd_s_f_mh_1_model\(\);' 'grd_s_f_mh_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_f_1/grd_s_f_1.c" 'static void pc_patch_grd_s_f_1_model\(void\)' 'grd_s_f_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_f_1/grd_s_f_1.c" 'grd_s_f_1_model\[18\]\.words\.w1 = pc_gbi_ptr_encode\(grass_tex_dummy\);' 'grd_s_f_1 grass texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_1/grd_s_f_1.c" 'grd_s_f_1_model\[55\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_f_1_v\[136\]\);' 'grd_s_f_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_f_1/grd_s_f_1.c" 'pc_patch_grd_s_f_1_model\(\);' 'grd_s_f_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_e1_1/grd_s_e1_1.c" 'static void pc_patch_grd_s_e1_1_model\(void\)' 'grd_s_e1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e1_1/grd_s_e1_1.c" 'grd_s_e1_1_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'grd_s_e1_1 cliff texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e1_1/grd_s_e1_1.c" 'grd_s_e1_1_model\[34\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e1_1_v\[63\]\);' 'grd_s_e1_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_e1_1/grd_s_e1_1.c" 'pc_patch_grd_s_e1_1_model\(\);' 'grd_s_e1_1 loader calls patch helper'

printf '%s\n' 'check_grd_scene_model_ptr_patch_contract: OK'
