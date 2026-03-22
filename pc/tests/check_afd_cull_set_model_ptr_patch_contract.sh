#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/actor/ac_field_draw.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing aFD cull-set LP64 patch contract: $label" >&2
        exit 1
    fi
}

check_contains 'static void aFD_patch_cull_set_model\(void\)' 'LP64 aFD cull-set patch helper'
check_contains 'aFD_cull_set_model\[0\]\.words\.w1 = pc_gbi_ptr_encode\(aFD_cull_set_gfx\);' 'cull setup display list pointer patch'
check_contains 'aFD_cull_set_model\[1\]\.words\.w1 = SEGMENT_ADDR\(G_MWO_SEGMENT_A, 0\);' 'segment A display list pointer patch'
check_contains 'aFD_patch_cull_set_model\(\);' 'draw path invokes cull-set patch helper'
