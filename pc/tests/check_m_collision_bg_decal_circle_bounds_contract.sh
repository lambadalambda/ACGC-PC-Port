#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/game/m_collision_bg_column.c_inc"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing decal circle bounds contract: $label" >&2
        exit 1
    fi
}

check_contains '#if defined\(TARGET_PC\) \|\| defined\(BUGFIXES\)' 'PC uses safe decal-circle path'
check_contains 'bzero\(regist, sizeof\(mCoBG_regist_circle_info_c\)\);' 'single-entry clear uses struct size'
check_contains 'bzero\(mCoBG_regist_circle_info, sizeof\(mCoBG_regist_circle_info\)\);' 'init clear uses full array size'
check_contains 'return i;' 'registration exits after first free slot'
