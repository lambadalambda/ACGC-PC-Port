#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="src/static/dolphin/gx/GXFifo.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "missing GX FIFO LP64 contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    pattern=$1
    label=$2

    if rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "unexpected GX FIFO legacy cast: $label" >&2
        exit 1
    fi
}

check_contains 'static inline u32 gx_fifo_reg_addr\(const void\* ptr\)' 'helper narrows register pointer values through checked helper'
check_contains '__piReg\[3\] = gx_fifo_reg_addr\(realFifo->base\);' 'GXSetCPUFifo writes base via helper'
check_contains '__piReg\[4\] = gx_fifo_reg_addr\(realFifo->top\);' 'GXSetCPUFifo writes top via helper'
check_contains 'SET_REG_FIELD\(673, reg, 21, 5, gx_fifo_reg_addr\(realFifo->wrPtr\) >> 5\);' 'GXSetCPUFifo writes wrPtr via helper'
check_contains '__cpReg\[16\] = PC_RUNTIME_U32_PTR\(realFifo->base\) & 0xFFFF;' 'GXSetGPFifo low base uses checked narrowing'
check_contains '__cpReg\[17\] = gx_fifo_reg_addr\(realFifo->base\) >> 16;' 'GXSetGPFifo high base uses helper'
check_contains '__cpReg\[30\] = PC_RUNTIME_U32_PTR\(break_pt\);' 'GXEnableBreakPt uses checked narrowing'
check_contains 'SET_REG_FIELD\(1500, reg, 21, 5, gx_fifo_reg_addr\(ptr\) >> 5\);' 'GXRedirectWriteGatherPipe uses helper'

check_absent '__piReg\[3\] = \(u32\)realFifo->base & 0x3FFFFFFF;' 'legacy GXSetCPUFifo base cast'
check_absent '__piReg\[4\] = \(u32\)realFifo->top & 0x3FFFFFFF;' 'legacy GXSetCPUFifo top cast'
check_absent 'SET_REG_FIELD\(673, reg, 21, 5, \(\(u32\)realFifo->wrPtr & 0x3FFFFFFF\) >> 5\);' 'legacy GXSetCPUFifo wrPtr cast'
check_absent '__cpReg\[30\] = \(u32\)break_pt;' 'legacy GXEnableBreakPt cast'
check_absent '__cpReg\[31\] = \(\(u32\)break_pt >> 16\) & 0x3FFF;' 'legacy GXEnableBreakPt high-word cast'
check_absent 'SET_REG_FIELD\(1500, reg, 21, 5, \(\(u32\)ptr & 0x3FFFFFFF\) >> 5\);' 'legacy GXRedirectWriteGatherPipe cast'
