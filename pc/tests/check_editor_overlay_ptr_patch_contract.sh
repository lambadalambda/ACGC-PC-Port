#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN_TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"
KAI_SOUSA_C="$REPO_ROOT/src/data/model/kai_sousa.c"
LAT_SP_C="$REPO_ROOT/src/data/model/lat_sp.c"
EDITOR_OVL_C="$REPO_ROOT/src/game/m_editor_ovl.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

python3 "$GEN_TOOL" --source "$KAI_SOUSA_C" --check-helper pc_patch_kai_sousa_display_lists >/dev/null

check_contains "$LAT_SP_C" 'void pc_patch_lat_sp_display_lists\(void\)' 'lat_sp LP64 helper exists'
check_contains "$LAT_SP_C" 'lat_sousa_spT_model\[5\]\.words\.w1 = pc_gbi_ptr_encode\(lat_sousa_sp_tex\);' 'lat_sp texture pointer is patched'
check_contains "$LAT_SP_C" 'lat_end_cordT_model\[7\]\.words\.w1 = pc_gbi_ptr_encode\(lat_tegami_end_tex\);' 'lat_end texture pointer is patched'

check_contains "$EDITOR_OVL_C" 'pc_patch_kai_sousa_display_lists\(\);' 'editor overlay invokes kai_sousa LP64 patch helper'
check_contains "$EDITOR_OVL_C" 'pc_patch_lat_sp_display_lists\(\);' 'editor overlay invokes lat_sp LP64 patch helper'

printf '%s\n' 'check_editor_overlay_ptr_patch_contract: OK'
