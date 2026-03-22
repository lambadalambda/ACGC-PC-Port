#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

OUTPUT_E3="$(python3 "$TOOL" --source "src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" --symbol "grd_s_e3_1_model" --check-helper "pc_patch_grd_s_e3_1_model")"
OUTPUT_UMB="$(python3 "$TOOL" --source "src/data/model/tol_umb_01.c" --symbol "kasa_umb01_model" --symbol "e_umb01_model" --check-helper "pc_patch_tol_umb_01_models")"
OUTPUT_TOOL="$(python3 "$TOOL" --source "src/data/model/player_tool.c" --symbol "main1_sao_model" --symbol "main2_sao_model" --symbol "main3_sao_model" --symbol "main4_sao_model" --check-helper "pc_patch_player_tool_models")"

check_output() {
    local output="$1"
    local pattern="$2"
    local desc="$3"

    if ! printf '%s\n' "$output" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_output "$OUTPUT_E3" '^# helper matches: pc_patch_grd_s_e3_1_model$' 'check mode confirms grd_s_e3_1 helper parity'
check_output "$OUTPUT_UMB" '^# helper matches: pc_patch_tol_umb_01_models$' 'check mode confirms umbrella helper parity'
check_output "$OUTPUT_TOOL" '^# helper matches: pc_patch_player_tool_models$' 'check mode confirms player tool helper parity with segment normalization'

printf '%s\n' 'check_gfx_fixup_gen_check_mode_contract: OK'
