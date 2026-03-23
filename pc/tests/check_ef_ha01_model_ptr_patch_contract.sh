#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODEL_FILE="$REPO_ROOT/src/data/model/ef_ha01_00.c"
EFFECT_FILE="$REPO_ROOT/src/effect/ef_ha.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$MODEL_FILE" 'void pc_patch_ef_ha01_00_modelT\(void\)' 'LP64 patch helper exists for ef_ha display list'
check_contains "$MODEL_FILE" 'ef_ha01_00_modelT\[4\]\.words\.w1 = pc_gbi_ptr_encode\(ef_ha01_0\);' 'texture pointer is patched for ef_ha model'
check_contains "$MODEL_FILE" 'ef_ha01_00_modelT\[7\]\.words\.w1 = pc_gbi_ptr_encode\(ef_ha01_00_v\);' 'vertex pointer is patched for ef_ha model'
check_contains "$EFFECT_FILE" 'pc_patch_ef_ha01_00_modelT\(\);' 'effect draw path invokes ef_ha patch helper'

printf '%s\n' 'check_ef_ha01_model_ptr_patch_contract: OK'
