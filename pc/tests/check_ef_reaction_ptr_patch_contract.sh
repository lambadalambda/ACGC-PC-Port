#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHOCK_MODEL="$REPO_ROOT/src/data/model/ef_shock01_00.c"
SHOCK_EFFECT="$REPO_ROOT/src/effect/ef_shock.c"
HIRAMEKI_MODEL="$REPO_ROOT/src/data/model/ef_hirameki01_den.c"
HIRAMEKI_DEN_EFFECT="$REPO_ROOT/src/effect/ef_hirameki_den.c"
HIRAMEKI_HIKARI_EFFECT="$REPO_ROOT/src/effect/ef_hirameki_hikari.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$SHOCK_MODEL" 'void pc_patch_ef_shock01_modelT\(void\)' 'ef_shock helper exists'
check_contains "$SHOCK_MODEL" 'ef_shock01_00_modelT\[3\]\.words\.w1 = pc_gbi_ptr_encode\(ef_shock01_0\);' 'ef_shock texture pointer is patched'
check_contains "$SHOCK_MODEL" 'ef_shock01_00_modelT\[6\]\.words\.w1 = pc_gbi_ptr_encode\(ef_shock01_00_v\);' 'ef_shock vertex pointer is patched'
check_contains "$SHOCK_EFFECT" 'pc_patch_ef_shock01_modelT\(\);' 'ef_shock draw path invokes helper'

check_contains "$HIRAMEKI_MODEL" 'void pc_patch_ef_hirameki01_modelT\(void\)' 'ef_hirameki helper exists'
check_contains "$HIRAMEKI_MODEL" 'ef_hirameki01_den_modelT\[3\]\.words\.w1 = pc_gbi_ptr_encode\(ef_hirameki01_0\);' 'ef_hirameki den texture pointer is patched'
check_contains "$HIRAMEKI_MODEL" 'ef_hirameki01_hikari_modelT\[4\]\.words\.w1 = pc_gbi_ptr_encode\(ef_hirameki01_1\);' 'ef_hirameki hikari texture pointer is patched'
check_contains "$HIRAMEKI_DEN_EFFECT" 'pc_patch_ef_hirameki01_modelT\(\);' 'ef_hirameki den draw path invokes helper'
check_contains "$HIRAMEKI_HIKARI_EFFECT" 'pc_patch_ef_hirameki01_modelT\(\);' 'ef_hirameki hikari draw path invokes helper'

printf '%s\n' 'check_ef_reaction_ptr_patch_contract: OK'
