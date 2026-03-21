#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio DSP pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio DSP pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/oneshot.c" 'AllocDSPchannel\(0, PC_RUNTIME_U32_PTR\(jc\)\);' 'oneshot alloc owner'
check_contains "src/static/jaudio_NES/internal/oneshot.c" 'DeAllocDSPchannel\(jc->dspChannel, PC_RUNTIME_U32_PTR\(jc\)\);' 'oneshot dealloc owner'
check_contains "src/static/jaudio_NES/internal/driverinterface.c" 'DeAllocDSPchannel\(jc->dspChannel, PC_RUNTIME_U32_PTR\(jc\)\);' 'driverinterface dealloc owner'
check_contains "src/static/jaudio_NES/internal/driverinterface.c" 'ch = AllocDSPchannel\(0, PC_RUNTIME_U32_PTR\(jc\)\);' 'driverinterface alloc owner'
check_contains "src/static/jaudio_NES/internal/ipldec.c" 'WriteTask\(DSPTARGET_IPL, PC_RUNTIME_U32_PTR\(cmd\), task, callback\)' 'ipldec IPL command pointer'
check_contains "src/static/jaudio_NES/internal/ipldec.c" 'WriteTask\(DSPTARGET_AGB, PC_RUNTIME_U32_PTR\(cmd\), task, callback\)' 'ipldec AGB command pointer'
check_contains "include/jaudio_NES/dspproc.h" '#if defined\(TARGET_PC\)' 'dspproc header has TARGET_PC signature guard'
check_contains "include/jaudio_NES/dspproc.h" 'void DsetupTable\(u32 arg0, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t arg4\);' 'dspproc setup uses host-width pointers on PC'
check_contains "include/jaudio_NES/dspproc.h" 'void DsyncFrame\(u32 subframes, uintptr_t dspbuf_start, uintptr_t dspbuf_end\);' 'dspproc frame sync uses host-width pointers on PC'
check_contains "src/static/jaudio_NES/internal/dspproc.c" 'extern void DsetupTable\(u32 arg0, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t arg4\)' 'PC DsetupTable implementation accepts host-width pointers'
check_contains "src/static/jaudio_NES/internal/dspproc.c" 'extern void DsyncFrame\(u32 subframes, uintptr_t dspbuf_start, uintptr_t dspbuf_end\)' 'PC DsyncFrame implementation accepts host-width pointers'
check_contains "src/static/jaudio_NES/internal/dspbuf.c" 'DsyncFrame\(JAC_SUBFRAMES, \(uintptr_t\)dsp_buf\[write_buffer\],' 'dspbuf source buffer cast to host-width'
check_contains "src/static/jaudio_NES/internal/dspbuf.c" '\(uintptr_t\)&dsp_buf\[write_buffer\]\[JAC_FRAMESAMPLES\]\);' 'dspbuf destination buffer cast to host-width'
check_contains "src/static/jaudio_NES/internal/dspinterface.c" 'DsetupTable\(\(u32\)CH_BUF_LENGTH, \(uintptr_t\)CH_BUF, \(uintptr_t\)DSPRES_FILTER, \(uintptr_t\)DSPADPCM_FILTER,' 'dspinterface setup call passes host-width pointers on PC'

check_absent "src/static/jaudio_NES/internal/oneshot.c" 'AllocDSPchannel\(0, \(u32\)jc\)' 'oneshot raw alloc owner cast'
check_absent "src/static/jaudio_NES/internal/oneshot.c" 'DeAllocDSPchannel\(jc->dspChannel, \(u32\)jc\)' 'oneshot raw dealloc owner cast'
check_absent "src/static/jaudio_NES/internal/driverinterface.c" 'AllocDSPchannel\(0, \(u32\)jc\)' 'driverinterface raw alloc owner cast'
check_absent "src/static/jaudio_NES/internal/driverinterface.c" 'DeAllocDSPchannel\(jc->dspChannel, \(u32\)jc\)' 'driverinterface raw dealloc owner cast'
check_absent "src/static/jaudio_NES/internal/ipldec.c" '\(u32\)cmd' 'ipldec raw command cast'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" 'DsyncFrame\(JAC_SUBFRAMES, \(u32\)dsp_buf\[write_buffer\]' 'dspbuf raw source cast'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" '\(u32\)&dsp_buf\[write_buffer\]\[JAC_FRAMESAMPLES\]' 'dspbuf raw destination cast'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" 'PC_RUNTIME_U32_PTR\(dsp_buf\[write_buffer\]\)' 'legacy checked narrowing for dspbuf source buffer'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" 'PC_RUNTIME_U32_PTR\(&dsp_buf\[write_buffer\]\[JAC_FRAMESAMPLES\]\)' 'legacy checked narrowing for dspbuf destination buffer'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(CH_BUF\)' 'legacy checked narrowing for dspinterface channel buffer'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(DSPRES_FILTER\)' 'legacy checked narrowing for dspinterface response filter'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(DSPADPCM_FILTER\)' 'legacy checked narrowing for dspinterface adpcm filter'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(FX_BUF\)' 'legacy checked narrowing for dspinterface fx buffer'
