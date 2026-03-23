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

check_contains "src/data/model/obj_s_station1.c" 'void pc_patch_obj_station1_model_display_lists\(void\)' 'station1 LP64 patch helper exists'
check_contains "src/data/model/obj_s_station1.c" 'obj_s_station1_t1_model\[10\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_station1_v\[108\]\);' 'station1 second vertex pointer patched'
check_contains "src/data/model/obj_s_station1.c" 'obj_w_station1_t3_model\[2\]\.words\.w1 = pc_gbi_ptr_encode\(obj_w_station1_t3_tex_txt\);' 'winter station1 texture pointer patched'

check_contains "src/data/model/obj_station1_shadow.c" 'void pc_patch_station_shadow_models\(void\)' 'station shadow LP64 patch helper exists'
check_contains "src/data/model/obj_station1_shadow.c" 'obj_station1_shadow_lowT_model\[6\]\.words\.w1 = SEGMENT_ADDR\(0x8, 0x130\);' 'station1 shadow low segment pointer patched'
check_contains "src/data/model/obj_station1_shadow.c" 'obj_station2_shadow_hi_model\[11\]\.words\.w1 = SEGMENT_ADDR\(0x8, 0x200\);' 'station2 shadow second segment pointer patched'

check_contains "src/actor/ac_station.c" 'extern void pc_patch_obj_station1_model_display_lists\(void\);' 'station actor declares station model patch helper'
check_contains "src/actor/ac_station.c" 'extern void pc_patch_station_shadow_models\(void\);' 'station actor declares station shadow patch helper'
check_contains "src/actor/ac_station.c" 'pc_patch_obj_station1_model_display_lists\(\);' 'station actor applies station model patch helper'
check_contains "src/actor/ac_station.c" 'pc_patch_station_shadow_models\(\);' 'station actor applies station shadow patch helper'

printf '%s\n' 'check_station_model_ptr_patch_contract: OK'
