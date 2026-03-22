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

check_contains "src/data/model/obj_s_house1.c" 'obj_s_house2_t3_model\[14\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_house2_v\[93\]\);' 'house2 secondary vertex pointer patched'
check_contains "src/data/model/obj_house1_shadow.c" 'obj_s_house2_shadow_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'house2 shadow segment pointer patched'

check_contains "src/data/model/obj_s_myhome1.c" 'void pc_patch_obj_myhome_models\(void\)' 'myhome model patch helper exists'
check_contains "src/data/model/obj_s_myhome1.c" 'obj_s_myhome1_t3_model\[10\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_myhome1_v\[70\]\);' 'myhome1 secondary vertex pointer patched'
check_contains "src/data/model/obj_s_myhome1.c" 'obj_w_myhome1_t3_model\[10\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_w_myhome1_v\[70\]\);' 'winter myhome1 secondary vertex pointer patched'
check_contains "src/data/model/obj_myhome1_shadowE.c" 'void pc_patch_obj_myhome_shadow_models\(void\)' 'myhome shadow patch helper exists'
check_contains "src/data/model/obj_myhome1_shadowE.c" 'obj_myhome1_shadowWT_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'myhome shadow segment pointer patched'
check_contains "src/actor/ac_my_house.c" 'pc_patch_obj_myhome_models\(\);' 'my house actor applies model patch helper'
check_contains "src/actor/ac_my_house.c" 'pc_patch_obj_myhome_shadow_models\(\);' 'my house actor applies shadow patch helper'

check_contains "src/data/model/obj_s_post_flag_model.c" 'void pc_patch_obj_s_post_models\(void\)' 'summer post model patch helper exists'
check_contains "src/data/model/obj_s_post_flag_model.c" 'obj_s_post_main_model\[20\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_post_v\[41\]\);' 'summer post interior vertex pointer patched'
check_contains "src/data/model/obj_w_post_model.c" 'void pc_patch_obj_w_post_models\(void\)' 'winter post model patch helper exists'
check_contains "src/data/model/obj_w_post_model.c" 'obj_w_post_main_model\[20\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_w_post_v\[41\]\);' 'winter post interior vertex pointer patched'
check_contains "src/actor/ac_mailbox.c" 'pc_patch_obj_s_post_models\(\);' 'mailbox actor applies summer post patch helper'
check_contains "src/actor/ac_mailbox.c" 'pc_patch_obj_w_post_models\(\);' 'mailbox actor applies winter post patch helper'
check_contains "src/actor/ac_mailbox.c" 'post_flag_saki_model_type0\[2\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'mailbox flag texture segment pointer patched'

check_contains "src/data/model/obj_s_toudai.c" 'void pc_patch_obj_toudai_models\(void\)' 'toudai model patch helper exists'
check_contains "src/data/model/obj_s_toudai.c" 'obj_s_toudai_body_model\[33\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_toudai_v\[95\]\);' 'toudai body secondary vertex pointer patched'
check_contains "src/data/model/obj_s_toudai_shadow.c" 'void pc_patch_obj_s_toudai_shadow_models\(void\)' 'toudai shadow patch helper exists'
check_contains "src/data/model/obj_s_toudai_shadow.c" 'obj_s_toudai_shadow_1_model\[5\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'toudai shadow segment pointer patched'
check_contains "src/actor/ac_toudai.c" 'pc_patch_obj_toudai_models\(\);' 'toudai actor applies model patch helper'
check_contains "src/actor/ac_toudai.c" 'pc_patch_obj_s_toudai_shadow_models\(\);' 'toudai actor applies shadow patch helper'

check_contains "src/data/model/obj_s_lotus.c" 'void pc_patch_obj_s_lotus_models\(void\)' 'lotus model patch helper exists'
check_contains "src/data/model/obj_s_lotus.c" 'obj_s_lotus_flower1_model\[16\]\.words\.w1 = pc_gbi_ptr_encode\(&obj_s_lotus_v\[64\]\);' 'lotus flower secondary vertex pointer patched'
check_contains "src/actor/ac_lotus.c" 'pc_patch_obj_s_lotus_models\(\);' 'lotus actor applies model patch helper'

check_contains "src/data/model/obj_s_kouban.c" 'void pc_patch_obj_kouban_models\(void\)' 'kouban model patch helper exists'
check_contains "src/data/model/obj_s_kouban.c" 'obj_s_kouban_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_kouban_light_model\);' 'kouban top-level display list pointer patched'
check_contains "src/data/model/obj_s_kouban.c" 'obj_s_kouban_t3_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(obj_s_kouban_v\);' 'kouban base vertex pointer patched'
check_contains "src/data/model/obj_s_kouban_shadow.c" 'void pc_patch_obj_s_kouban_shadow_models\(void\)' 'kouban shadow patch helper exists'
check_contains "src/data/model/obj_s_kouban_shadow.c" 'obj_s_kouban_shadow_model\[6\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'kouban shadow segment pointer patched'
check_contains "src/actor/ac_police_box.c" 'pc_patch_obj_kouban_models\(\);' 'police box actor applies kouban patch helper'
check_contains "src/actor/ac_police_box.c" 'pc_patch_obj_s_kouban_shadow_models\(\);' 'police box actor applies shadow patch helper'

printf '%s\n' 'check_structure_mailbox_prop_ptr_patch_contract: OK'
