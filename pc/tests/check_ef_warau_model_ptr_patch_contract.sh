#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODEL_FILE="$REPO_ROOT/src/data/model/ef_warau01_00.c"
EFFECT_FILE="$REPO_ROOT/src/effect/ef_warau.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$MODEL_FILE" 'void pc_patch_ef_warau01_modelT\(void\)' 'LP64 patch helper exists for ef_warau display lists'
check_contains "$MODEL_FILE" 'ef_warau01_00_modelT\[5\]\.words\.w1 = pc_gbi_ptr_encode\(ef_warau01us\);' 'ef_warau 00 texture pointer is patched'
check_contains "$MODEL_FILE" 'ef_warau01_00_modelT\[8\]\.words\.w1 = pc_gbi_ptr_encode\(ef_warau01_00_v\);' 'ef_warau 00 vertex pointer is patched'
check_contains "$MODEL_FILE" 'ef_warau01_03_modelT\[8\]\.words\.w1 = pc_gbi_ptr_encode\(ef_warau01_03_v\);' 'ef_warau 03 vertex pointer is patched'
check_contains "$EFFECT_FILE" 'pc_patch_ef_warau01_modelT\(\);' 'effect draw path invokes ef_warau patch helper'

printf '%s\n' 'check_ef_warau_model_ptr_patch_contract: OK'
