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

check_contains "src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" 'pc_patch_grd_s_e3_1_model\(void\)' 'grd_s_e3_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" 'pc_patch_grd_s_e3_1_model\(\);' 'grd_s_e3_1 loader applies patch helper'
check_contains "src/data/field/bg/acre/grd_s_e3_c1_1/grd_s_e3_c1_1.c" 'pc_patch_grd_s_e3_c1_1_model\(void\)' 'grd_s_e3_c1_1 LP64 patch helper exists'
check_contains "src/data/field/bg/acre/grd_s_e3_c1_1/grd_s_e3_c1_1.c" 'pc_patch_grd_s_e3_c1_1_model\(\);' 'grd_s_e3_c1_1 loader applies patch helper'

check_contains "src/data/model/player_tool.c" 'pc_patch_player_tool_models\(void\)' 'player_tool LP64 patch helper exists'
check_contains "src/data/model/player_tool.c" 'pc_patch_player_tool_models\(\);' 'player_tool loader applies patch helper'
check_contains "src/data/model/tol_uki_12.c" 'pc_patch_tol_uki_12_models\(void\)' 'rod bobber LP64 patch helper exists'
check_contains "src/actor/ac_uki_draw.c_inc" 'pc_patch_tol_uki_12_models\(\);' 'rod draw path applies bobber patch helper'

check_contains "src/data/model/tol_umb_01.c" 'pc_patch_tol_umb_01_models\(void\)' 'umbrella LP64 patch helper exists'
check_contains "src/actor/tool/ac_t_umbrella.c" 'pc_patch_tol_umb_01_models\(\);' 'umbrella actor applies LP64 patch helper'
check_contains "src/game/m_inventory_ovl.c" 'pc_patch_tol_umb_01_models\(\);' 'inventory umbrella preview applies LP64 patch helper'

check_contains "src/data/model/obj_item_apple2.c" 'pc_patch_obj_item_apple2_models\(void\)' 'apple DL LP64 patch helper exists'
check_contains "src/data/model/obj_item_apple2.c" 'pc_patch_obj_item_apple2_models\(\);' 'apple loader applies patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_tree5_models\(\);' 'bg-item patch set applies tree5 patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_tree5_apple_models\(\);' 'bg-item patch set applies tree5 apple patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_stoneE_models\(\);' 'bg-item patch set applies stoneE patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_s_fenceS_models\(\);' 'bg-item patch set applies fenceS patch helper'
check_contains "src/bg_item/bg_item.c" 'pc_patch_obj_fenceS_shadow_models\(\);' 'bg-item patch set applies fenceS shadow patch helper'

check_contains "src/data/model/ef_ame02_00.c" 'pc_patch_ef_ame02_00_models\(void\)' 'rain splash LP64 patch helper exists'
check_contains "src/actor/ac_weather_rain.c" 'pc_patch_ef_ame02_00_models\(\);' 'rain weather path applies rain splash patch helper'
check_contains "src/data/model/ef_dust01_00.c" 'pc_patch_ef_dust01_00_models\(void\)' 'dust LP64 patch helper exists'
check_contains "src/effect/ef_dust.c" 'pc_patch_ef_dust01_00_models\(\);' 'dust effect path applies dust patch helper'
check_contains "src/data/model/ef_sibuki01_00.c" 'pc_patch_ef_sibuki01_00_models\(void\)' 'splash LP64 patch helper exists'
check_contains "src/effect/ef_sibuki.c" 'pc_patch_ef_sibuki01_00_models\(\);' 'splash effect path applies patch helper'
check_contains "src/data/model/ef_koke_suiteki01_00.c" 'pc_patch_ef_koke_suiteki01_00_models\(void\)' 'droplet LP64 patch helper exists'
check_contains "src/effect/ef_mizutama.c" 'pc_patch_ef_koke_suiteki01_00_models\(\);' 'droplet effect path applies patch helper'
check_contains "src/data/model/ef_bodyprint01_00.c" 'pc_patch_ef_bodyprint01_00_models\(void\)' 'bodyprint LP64 patch helper exists'
check_contains "src/effect/ef_tumble_bodyprint.c" 'pc_patch_ef_bodyprint01_00_models\(\);' 'bodyprint effect path applies patch helper'
check_contains "src/data/model/ef_turi_hamon01_00.c" 'pc_patch_ef_turi_hamon01_00_models\(void\)' 'fishing ripple LP64 patch helper exists'
check_contains "src/effect/ef_turi_hamon.c" 'pc_patch_ef_turi_hamon01_00_models\(\);' 'fishing ripple effect path applies patch helper'

printf '%s\n' 'check_zero_operand_tail_ptr_patch_contract: OK'
