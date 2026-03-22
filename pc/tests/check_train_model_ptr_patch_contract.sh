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

check_contains "src/data/model/obj_train1_1.c" 'void pc_patch_obj_train1_1_model_display_lists\(void\)' 'train1_1 LP64 patch helper exists'
check_contains "src/data/model/obj_train1_1.c" 'obj_train1_1_t1_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(obj_train1_t1_tex_txt\);' 'train1_1 primary texture pointer patched'
check_contains "src/data/model/obj_train1_1.c" 'obj_train1_2_model\[6\]\.words\.w1 = pc_gbi_ptr_encode\(obj_train1_2_t2_model\);' 'train1_2 display list pointer patched'

check_contains "src/data/model/obj_train_3.c" 'void pc_patch_obj_train1_3_model_display_lists\(void\)' 'train1_3 LP64 patch helper exists'
check_contains "src/data/model/obj_train_3.c" 'obj_train1_3_t5_model\[13\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_train_3_v\[18\]\);' 'train1_3 mid vertex pointer patched'
check_contains "src/data/model/obj_train_3.c" 'obj_train1_3_door2_model\[8\]\.words\.w1 = pc_gbi_ptr_encode\(obj_train_3_v\);' 'train1_3 door vertex pointer patched'

check_contains "src/actor/ac_train0.c" 'extern void pc_patch_obj_train1_1_model_display_lists\(void\);' 'train actor declares train1_1 patch helper'
check_contains "src/actor/ac_train0.c" 'extern void pc_patch_obj_train1_3_model_display_lists\(void\);' 'train actor declares train1_3 patch helper'
check_contains "src/actor/ac_train0.c" 'pc_patch_obj_train1_1_model_display_lists\(\);' 'train actor applies train1_1 patch helper'
check_contains "src/actor/ac_train0.c" 'pc_patch_obj_train1_3_model_display_lists\(\);' 'train actor applies train1_3 patch helper'

printf '%s\n' 'check_train_model_ptr_patch_contract: OK'
