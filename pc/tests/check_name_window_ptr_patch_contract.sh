#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN_TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"
NAM_WIN_C="$REPO_ROOT/src/data/model/nam_win.c"
MRA_WIN_C="$REPO_ROOT/src/data/model/mra_win.c"
RST_WIN_C="$REPO_ROOT/src/data/model/rst_win.c"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

python3 "$GEN_TOOL" --source "$NAM_WIN_C" --check-helper pc_patch_nam_win_display_lists >/dev/null
python3 "$GEN_TOOL" --source "$MRA_WIN_C" --check-helper pc_patch_mra_win_display_lists >/dev/null
python3 "$GEN_TOOL" --source "$RST_WIN_C" --check-helper pc_patch_rst_win_display_lists >/dev/null

check_contains "$NAM_WIN_C" 'pc_patch_nam_win_display_lists\(\);' 'nam_win loader invokes LP64 patch helper'
check_contains "$MRA_WIN_C" 'pc_patch_mra_win_display_lists\(\);' 'mra_win loader invokes LP64 patch helper'
check_contains "$RST_WIN_C" 'pc_patch_rst_win_display_lists\(\);' 'rst_win loader invokes LP64 patch helper'

printf '%s\n' 'check_name_window_ptr_patch_contract: OK'
