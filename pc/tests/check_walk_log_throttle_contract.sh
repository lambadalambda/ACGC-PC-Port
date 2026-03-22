#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/game/game64.c_inc"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing walk log throttle contract: $label" >&2
        exit 1
    fi
}

check_contains 's_walk_se_log_count' 'walk-se log counter'
check_contains 's_walk_req_log_count' 'walk request log counter'
check_contains 's_walk_blocked_log_count' 'walk blocked log counter'
check_contains 'g_pc_verbose != 0 && s_walk_se_log_count <' 'walk-se verbose gate'
check_contains 'g_pc_verbose != 0 && s_walk_req_log_count <' 'walk request verbose gate'
check_contains 'g_pc_verbose != 0 && s_walk_blocked_log_count <' 'walk blocked verbose gate'
