#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

OUTPUT="$(python3 "$TOOL" --source "src/data/field/bg/acre/grd_s_e3_1/grd_s_e3_1.c" --symbol "grd_s_e3_1_model" --emit-helper "pc_patch_grd_s_e3_1_model_generated")"

check_output() {
    local pattern="$1"
    local desc="$2"

    if ! printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_output '^#if defined\(TARGET_PC\) && defined\(PC_EXPERIMENTAL_64BIT\)$' 'helper mode emits LP64 guard opening'
check_output '^void pc_patch_grd_s_e3_1_model_generated\(void\) \{$' 'helper mode emits target helper signature'
check_output '^    static int s_patched = FALSE;$' 'helper mode emits one-time patch guard state'
check_output '^    grd_s_e3_1_model\[36\]\.words\.w1 = pc_gbi_ptr_encode\(&grd_s_e3_1_v\[83\]\);$' 'helper mode emits assignment payload'
check_output '^#else$' 'helper mode emits non-LP64 alternate branch'
check_output '^#endif$' 'helper mode emits guard closing'

printf '%s\n' 'check_gfx_fixup_gen_helper_mode_contract: OK'
