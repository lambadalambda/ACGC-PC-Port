#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

OUTPUT="$(python3 "$TOOL" --source "pc/tests/check_static_ptr_contract.c" --symbol "sTextureDisplayList")"

check_output() {
    local pattern="$1"
    local desc="$2"

    if ! printf '%s\n' "$OUTPUT" | rg -q "$pattern"; then
        printf '%s\n' "missing gfx fixup generator contract: $desc" >&2
        exit 1
    fi
}

check_output 'sTextureDisplayList\[0\]\.words\.w1 = pc_gbi_ptr_encode\(sContractTexture\);' 'texture pointer fixup generated from static test DL'
check_output 'sTextureDisplayList\[1\]\.words\.w1 = pc_gbi_ptr_encode\(sNestedDisplayList\);' 'nested display-list pointer fixup generated from static test DL'

printf '%s\n' 'check_gfx_fixup_gen_static_ptr_contract: OK'
