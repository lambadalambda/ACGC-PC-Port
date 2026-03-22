#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

OUTPUT="$(python3 "$TOOL" --source "src/data/model/player_tool.c" --symbol "main2_sao_model")"

check_output() {
    local pattern="$1"
    local desc="$2"

    if ! printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_not_output() {
    local pattern="$1"
    local desc="$2"

    if printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "unexpected gfx fixup generator output: $desc" >&2
        exit 1
    fi
}

check_output 'main2_sao_model\[0\]\.words\.w1 = SEGMENT_ADDR\(0x0D, 0x0\);' 'matrix segment-base fixup emitted as segmented address'
check_output 'main2_sao_model\[4\]\.words\.w1 = SEGMENT_ADDR\(0x0D, 0x40\);' 'matrix segment-offset fixup emitted as segmented address'
check_not_output 'main2_sao_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(' 'matrix segment-base must not be encoded as host pointer'
check_not_output 'main2_sao_model\[4\]\.words\.w1 = pc_gbi_ptr_encode\(' 'matrix segment-offset must not be encoded as host pointer'

check_output 'main2_sao_model\[3\]\.words\.w1 = pc_gbi_ptr_encode\(&tol_sao_1_v\[34\]\);' 'vertex pointer fixup emitted'
check_output 'main2_sao_model\[8\]\.words\.w1 = pc_gbi_ptr_encode\(tol_sao_1_pal\);' 'TLUT pointer fixup emitted'
check_output 'main2_sao_model\[9\]\.words\.w1 = pc_gbi_ptr_encode\(tol_sao_1_main1_tex_txt\);' 'texture pointer fixup emitted'
check_output 'main2_sao_model\[12\]\.words\.w1 = pc_gbi_ptr_encode\(&tol_sao_1_v\[37\]\);' 'second vertex pointer fixup emitted'

printf '%s\n' 'check_gfx_fixup_gen_player_tool_contract: OK'
