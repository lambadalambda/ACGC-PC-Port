#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

OUTPUT="$(python3 "$TOOL" --source "src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" --symbol "grd_s_e3_1_model")"

check_output() {
    local pattern="$1"
    local desc="$2"

    if ! printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_output 'grd_s_e3_1_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_pal_dummy\);' 'TLUT pointer fixup line generated'
check_output 'grd_s_e3_1_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(cliff_tex_dummy\);' 'texture pointer fixup line generated'
check_output 'grd_s_e3_1_model\[8\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[0\]\);' 'first vertex pointer fixup line generated'
check_output 'grd_s_e3_1_model\[17\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[32\]\);' 'second vertex pointer fixup line generated'
check_output 'grd_s_e3_1_model\[27\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[64\]\);' 'third vertex pointer fixup line generated'
check_output 'grd_s_e3_1_model\[33\]\.words\.w1 = pc_gbi_ptr_encode\(earth_pal_dummy\);' 'second TLUT pointer fixup line generated'
check_output 'grd_s_e3_1_model\[34\]\.words\.w1 = pc_gbi_ptr_encode\(grass_tex_dummy\);' 'second texture pointer fixup line generated'
check_output 'grd_s_e3_1_model\[36\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[83\]\);' 'final vertex pointer fixup line generated'

printf '%s\n' 'check_gfx_fixup_gen_poc_contract: OK'
