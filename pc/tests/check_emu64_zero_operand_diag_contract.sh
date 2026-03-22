#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/libforest/emu64/emu64.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing emu64 zero-operand diagnostic contract: $label" >&2
        exit 1
    fi
}

check_contains 's_pc_emu64_zero_diag' 'task-level zero-operand diagnostics state'
check_contains '\[PC\]\[emu64\]\[taskdiag\]' 'per-task diagnostic summary output'
check_contains 's_pc_emu64_zero_diag\.dl_addr0_skips\+\+' 'G_DL zero-address counter'
check_contains 's_pc_emu64_zero_diag\.vtx_addr0\+\+' 'G_VTX zero-address counter'
check_contains 's_pc_emu64_zero_diag\.mtx_addr0\+\+' 'G_MTX zero-address counter'
check_contains 's_pc_emu64_zero_diag\.setimg_addr0\+\+' 'G_SETTIMG zero-address counter'
check_contains 's_pc_emu64_zero_diag\.tlut_addr0\+\+' 'G_LOADTLUT zero-address counter'
check_contains 'pc_emu64_zero_operand_log\("G_VTX"' 'detailed zero-address event logging for G_VTX'
check_contains 'pc_emu64_zero_operand_log\("G_MTX"' 'detailed zero-address event logging for G_MTX'
