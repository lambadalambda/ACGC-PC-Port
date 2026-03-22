#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TMP_SRC="$TMP_DIR/grd_s_e3_1.c"
cp "$REPO_ROOT/src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" "$TMP_SRC"

OUTPUT="$(python3 "$TOOL" --source "$TMP_SRC" --symbol "grd_s_e3_1_model" --apply-helper "pc_patch_grd_s_e3_1_model")"

check_output() {
    local pattern="$1"
    local desc="$2"

    if ! printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_file() {
    local pattern="$1"
    local desc="$2"

    if ! rg -q "$pattern" "$TMP_SRC"; then
        printf '%s\n' "missing applied helper content: $desc" >&2
        exit 1
    fi
}

check_output '^# updated helper: pc_patch_grd_s_e3_1_model$' 'apply mode reports helper update'
check_file '^#if.*PC_EXPERIMENTAL_64BIT' 'guard opening preserved in applied helper block'
check_file '^static void pc_patch_grd_s_e3_1_model\(void\) \{$' 'static helper signature preserved'
check_file 'grd_s_e3_1_model\[8\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[0\]\);' 'vertex fixup line present after apply mode rewrite'
check_file 'grd_s_e3_1_model\[36\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[83\]\);' 'last fixup line present after apply mode rewrite'

printf '%s\n' 'check_gfx_fixup_gen_apply_mode_contract: OK'
