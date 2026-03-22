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

check_contains "src/data/field/bg/acre/grd_s_t_5/grd_s_t_5.c" 'static void pc_patch_grd_s_t_5_model\(void\)' 'grd_s_t_5 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_5/grd_s_t_5.c" 'grd_s_t_5_modelT\[9\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'grd_s_t_5 modelT segment display-list pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_5/grd_s_t_5.c" 'grd_s_t_5_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(bush_pal_dummy\);' 'grd_s_t_5 first TLUT pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_5/grd_s_t_5.c" 'grd_s_t_5_model\[73\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_t_5_v\[199\]\);' 'grd_s_t_5 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_5/grd_s_t_5.c" 'pc_patch_grd_s_t_5_model\(\);' 'grd_s_t_5 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_t_st1_1/grd_s_t_st1_1.c" 'static void pc_patch_grd_s_t_st1_1_model\(void\)' 'grd_s_t_st1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_st1_1/grd_s_t_st1_1.c" 'grd_s_t_st1_1_model\[13\]\.words\.w1 = pc_gbi_ptr_encode\(station_tex_dummy\);' 'grd_s_t_st1_1 station texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_st1_1/grd_s_t_st1_1.c" 'grd_s_t_st1_1_model\[65\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_t_st1_1_v\[149\]\);' 'grd_s_t_st1_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_st1_1/grd_s_t_st1_1.c" 'pc_patch_grd_s_t_st1_1_model\(\);' 'grd_s_t_st1_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_t_sh_1/grd_s_t_sh_1.c" 'static void pc_patch_grd_s_t_sh_1_model\(void\)' 'grd_s_t_sh_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_sh_1/grd_s_t_sh_1.c" 'grd_s_t_sh_1_model\[40\]\.words\.w1 = pc_gbi_ptr_encode\(rail_tex_dummy\);' 'grd_s_t_sh_1 rail texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_sh_1/grd_s_t_sh_1.c" 'grd_s_t_sh_1_model\[61\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_t_sh_1_v\[128\]\);' 'grd_s_t_sh_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_sh_1/grd_s_t_sh_1.c" 'pc_patch_grd_s_t_sh_1_model\(\);' 'grd_s_t_sh_1 loader calls patch helper'

check_contains "src/data/field/bg/acre/grd_s_t_po_1/grd_s_t_po_1.c" 'static void pc_patch_grd_s_t_po_1_model\(void\)' 'grd_s_t_po_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_t_po_1/grd_s_t_po_1.c" 'grd_s_t_po_1_model\[18\]\.words\.w1 = pc_gbi_ptr_encode\(rail_tex_dummy\);' 'grd_s_t_po_1 rail texture pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_po_1/grd_s_t_po_1.c" 'grd_s_t_po_1_model\[59\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_t_po_1_v\[129\]\);' 'grd_s_t_po_1 final vertex pointer patched'
check_contains "src/data/field/bg/acre/grd_s_t_po_1/grd_s_t_po_1.c" 'pc_patch_grd_s_t_po_1_model\(\);' 'grd_s_t_po_1 loader calls patch helper'

printf '%s\n' 'check_grd_town_model_ptr_patch_contract: OK'
