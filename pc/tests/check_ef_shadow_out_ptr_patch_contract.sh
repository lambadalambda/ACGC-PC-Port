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

check_contains "src/data/model/ef_shadow_out.c" 'void pc_patch_ef_shadow_out_modelT\(void\)' 'ef shadow LP64 patch helper exists'
check_contains "src/data/model/ef_shadow_out.c" 'ef_shadow_out_modelT\[4\]\.words\.w1 = pc_gbi_ptr_encode\(ef_shadow_out_0_int_i4\);' 'ef shadow first texture pointer patched'
check_contains "src/data/model/ef_shadow_out.c" 'ef_shadow_out_modelT\[18\]\.words\.w1 = SEGMENT_ADDR\(ANIME_1_TXT_SEG, 0\);' 'ef shadow segment display list pointer patched'
check_contains "src/data/model/ef_shadow_out.c" 'ef_shadow_out_modelT\[20\]\.words\.w1 = pc_gbi_ptr_encode\(ef_shadow_out_v\);' 'ef shadow vertex pointer patched'

check_contains "src/game/m_actor_shadow.c" 'extern void pc_patch_ef_shadow_out_modelT\(void\);' 'actor shadow declares ef shadow patch helper'
check_contains "src/game/m_actor_shadow.c" 'pc_patch_ef_shadow_out_modelT\(\);' 'actor shadow applies ef shadow patch before draw'

printf '%s\n' 'check_ef_shadow_out_ptr_patch_contract: OK'
