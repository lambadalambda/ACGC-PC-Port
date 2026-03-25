#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

FILES=(
    "src/data/field/bg/acre/grd_s_r1_b_2/grd_s_r1_b_2.c"
    "src/data/field/bg/acre/grd_s_c5_2/grd_s_c5_2.c"
    "src/data/field/bg/acre/grd_s_f_5/grd_s_f_5.c"
    "src/data/field/bg/acre/grd_s_c1_3/grd_s_c1_3.c"
    "src/data/field/bg/acre/grd_s_c6_3/grd_s_c6_3.c"
    "src/data/field/bg/acre/grd_s_r3_3/grd_s_r3_3.c"
    "src/data/field/bg/acre/grd_s_t_2/grd_s_t_2.c"
    "src/data/field/bg/acre/grd_s_f_8/grd_s_f_8.c"
    "src/data/field/bg/acre/grd_s_c5_s_2/grd_s_c5_s_2.c"
    "src/data/field/bg/acre/grd_s_f_mh_3/grd_s_f_mh_3.c"
    "src/data/field/bg/acre/grd_s_r7_2/grd_s_r7_2.c"
)

for rel in "${FILES[@]}"; do
    stem="$(basename "$rel" .c)"
    helper="pc_patch_${stem}_model"

    python3 "$GEN" --source "$rel" --check-helper "$helper" >/dev/null

    if ! rg -q "${helper}\\(\\);" "$REPO_ROOT/$rel"; then
        printf '%s\n' "missing acre loader helper call: ${helper} (${rel})" >&2
        exit 1
    fi
done

printf '%s\n' 'check_house_area_acre_ptr_patch_contract: OK'
