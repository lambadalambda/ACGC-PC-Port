#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

python3 "$GEN" --source src/data/model/rom_myhome1_floor.c --check-helper pc_patch_rom_myhome1_floor_models >/dev/null
python3 "$GEN" --source src/data/model/rom_myhome1_wall.c --check-helper pc_patch_rom_myhome1_wall_models >/dev/null
python3 "$GEN" --source src/data/model/rom_myhome4_1_floor.c --check-helper pc_patch_rom_myhome4_1_floor_models >/dev/null
python3 "$GEN" --source src/data/model/rom_myhome4_1_wall.c --check-helper pc_patch_rom_myhome4_1_wall_models >/dev/null
python3 "$GEN" --source src/data/model/obj_myhome_step_down.c --check-helper pc_patch_obj_myhome_step_down_model >/dev/null
python3 "$GEN" --source src/data/model/obj_myhome_step_up.c --check-helper pc_patch_obj_myhome_step_up_model >/dev/null

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_my_indoor.c" 'pc_patch_rom_myhome1_wall_models\(\);' 'my indoor draw path patches wall models before display'
check_contains "src/actor/ac_my_indoor.c" 'pc_patch_rom_myhome1_floor_models\(\);' 'my indoor draw path patches floor models before display'
check_contains "src/actor/ac_my_indoor.c" 'pc_patch_rom_myhome4_1_wall_models\(\);' 'my indoor draw path patches expanded wall models before display'
check_contains "src/actor/ac_my_indoor.c" 'pc_patch_rom_myhome4_1_floor_models\(\);' 'my indoor draw path patches expanded floor models before display'
check_contains "src/actor/ac_my_indoor.c" 'pc_patch_obj_myhome_step_down_model\(\);' 'my indoor draw path patches step-down model before display'
check_contains "src/actor/ac_my_indoor.c" 'pc_patch_obj_myhome_step_up_model\(\);' 'my indoor draw path patches step-up model before display'
check_contains "src/data/model/rom_myhome1_wall.c" 'pc_patch_rom_myhome1_wall_models\(\);' 'myhome wall loader applies model patch helper'
check_contains "src/data/model/rom_myhome4_1_wall.c" 'pc_patch_rom_myhome4_1_wall_models\(\);' 'myhome4 wall loader applies model patch helper'
check_contains "src/actor/ac_my_house.c" 'pc_patch_obj_myhome_models\(\);' 'my house actor applies outdoor myhome model patch helper'

printf '%s\n' 'check_myhome_indoor_ptr_patch_contract: OK'
