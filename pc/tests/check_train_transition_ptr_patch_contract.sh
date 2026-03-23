#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROM_TRAIN_IN="$REPO_ROOT/src/data/field/bg/acre/rom_train_in/rom_train_in.c"
ROM_TRAIN_OUT="$REPO_ROOT/src/data/model/rom_train_out.c"
OBJ_ROMTRAIN_DOOR="$REPO_ROOT/src/data/model/obj_romtrain_door.c"
TRAIN_WINDOW_ACTOR="$REPO_ROOT/src/actor/ac_train_window.c"
TRAIN_DOOR_ACTOR="$REPO_ROOT/src/actor/ac_train_door.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$ROM_TRAIN_IN" 'void pc_patch_rom_train_in_display_lists\(void\)' 'rom_train_in LP64 patch helper exists'
check_contains "$ROM_TRAIN_IN" 'rom_train_in_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(rom_train_1_pal\);' 'rom_train_in main model palette pointer is patched'
check_contains "$ROM_TRAIN_IN" 'rom_train_in_model\[129\]\.words\.w1 = pc_gbi_ptr_encode\(&rom_train_in_v\[194\]\);' 'rom_train_in tail vertex pointer is patched'
check_contains "$ROM_TRAIN_IN" 'rom_train_in_modelT\[15\]\.words\.w1 = pc_gbi_ptr_encode\(rom_train_light_tex\);' 'rom_train_in translucent model light texture pointer is patched'

check_contains "$ROM_TRAIN_OUT" 'void pc_patch_rom_train_out_display_lists\(void\)' 'rom_train_out LP64 patch helper exists'
check_contains "$ROM_TRAIN_OUT" 'rom_train_out_tunnel_model\[9\]\.words\.w1 = pc_gbi_ptr_encode\(&rom_train_out_v\[8\]\);' 'rom_train_out tunnel vertex pointer is patched'
check_contains "$ROM_TRAIN_OUT" 'rom_train_out_bgcloud_modelT\[6\]\.words\.w1 = anime_2_txt;' 'rom_train_out anime display list pointer is patched'

check_contains "$OBJ_ROMTRAIN_DOOR" 'void pc_patch_obj_romtrain_door_display_lists\(void\)' 'rom train door LP64 patch helper exists'
check_contains "$OBJ_ROMTRAIN_DOOR" 'obj_romtrain_door_model\[8\]\.words\.w1 = pc_gbi_ptr_encode\(obj_romtrain_door_v\);' 'rom train door vertex pointer is patched'

check_contains "$TRAIN_WINDOW_ACTOR" 'pc_patch_rom_train_in_display_lists\(\);' 'train window actor triggers rom_train_in patch'
check_contains "$TRAIN_WINDOW_ACTOR" 'pc_patch_rom_train_out_display_lists\(\);' 'train window actor triggers rom_train_out patch'
check_contains "$TRAIN_DOOR_ACTOR" 'pc_patch_obj_romtrain_door_display_lists\(\);' 'train door actor triggers rom train door patch'

printf '%s\n' 'check_train_transition_ptr_patch_contract: OK'
