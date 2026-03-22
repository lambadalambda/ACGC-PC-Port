#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/rspsim.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing jaudio resample state wrap contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    pattern=$1
    label=$2

    if rg -q "$pattern" "$FILE"; then
        printf '%s\n' "unexpected jaudio resample legacy pattern: $label" >&2
        exit 1
    fi
}

check_contains 'static void jac_resample_store_state\(s16\* dst, const s16\* ring, s32 ring_index\)' 'wrapped resample state helper'
check_contains 'dst\[i\] = ring\[\(start \+ i\) & 7\];' 'state save uses wrapped ring indexing'
check_contains 'jac_resample_store_state\(\(s16\*\)pc_audio_cmd_ptr_decode_word\(cmdLo\), spC, var_r8\);' 'resample command stores wrapped state'
check_absent 'Jac_bcopy\(&spC\[var_r8 - 4\], pc_audio_cmd_ptr_decode_word\(cmdLo\), 8 \* sizeof\(s16\)\);' 'linear copy from stack ring'
