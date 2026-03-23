#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODEL_FILE="$REPO_ROOT/src/data/model/tol_keitai_1.c"
ACTOR_FILE="$REPO_ROOT/src/actor/tool/ac_t_keitai.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$MODEL_FILE" 'void pc_patch_tol_keitai_1_model\(void\)' 'tol_keitai helper exists'
check_contains "$MODEL_FILE" 'main1_keitai1_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(tol_keitai_1_pal\);' 'main1 palette pointer is patched'
check_contains "$MODEL_FILE" 'main1_keitai1_model\[13\]\.words\.w1 = pc_gbi_ptr_encode\(tol_keitai_1_shitaomote1_tex_txt\);' 'main1 second texture pointer is patched'
check_contains "$MODEL_FILE" 'main2_keitai1_model\[13\]\.words\.w1 = pc_gbi_ptr_encode\(tol_keitai_1_ueomote1_tex_txt\);' 'main2 second texture pointer is patched'
check_contains "$ACTOR_FILE" 'pc_patch_tol_keitai_1_model\(\);' 'keitai actor draw path invokes LP64 patch helper'

printf '%s\n' 'check_keitai_model_ptr_patch_contract: OK'
