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
check_contains "src/static/jaudio_NES/internal/dspbuf.c" 'PC_RUNTIME_U32_PTR\(dsp_buf\[write_buffer\]\)' 'dspbuf source buffer'
check_contains "src/static/jaudio_NES/internal/dspbuf.c" 'PC_RUNTIME_U32_PTR\(&dsp_buf\[write_buffer\]\[JAC_FRAMESAMPLES\]\)' 'dspbuf destination buffer'
check_contains "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(CH_BUF\)' 'dspinterface channel buffer'
check_contains "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(DSPRES_FILTER\)' 'dspinterface response filter'
check_contains "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(DSPADPCM_FILTER\)' 'dspinterface adpcm filter'
check_contains "src/static/jaudio_NES/internal/dspinterface.c" 'PC_RUNTIME_U32_PTR\(FX_BUF\)' 'dspinterface fx buffer'

check_absent "src/static/jaudio_NES/internal/oneshot.c" 'AllocDSPchannel\(0, \(u32\)jc\)' 'oneshot raw alloc owner cast'
check_absent "src/static/jaudio_NES/internal/oneshot.c" 'DeAllocDSPchannel\(jc->dspChannel, \(u32\)jc\)' 'oneshot raw dealloc owner cast'
check_absent "src/static/jaudio_NES/internal/driverinterface.c" 'AllocDSPchannel\(0, \(u32\)jc\)' 'driverinterface raw alloc owner cast'
check_absent "src/static/jaudio_NES/internal/driverinterface.c" 'DeAllocDSPchannel\(jc->dspChannel, \(u32\)jc\)' 'driverinterface raw dealloc owner cast'
check_absent "src/static/jaudio_NES/internal/ipldec.c" '\(u32\)cmd' 'ipldec raw command cast'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" 'DsyncFrame\(JAC_SUBFRAMES, \(u32\)dsp_buf\[write_buffer\]' 'dspbuf raw source cast'
check_absent "src/static/jaudio_NES/internal/dspbuf.c" '\(u32\)&dsp_buf\[write_buffer\]\[JAC_FRAMESAMPLES\]' 'dspbuf raw destination cast'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" ', \(u32\)CH_BUF,' 'dspinterface raw channel buffer cast'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" ', \(u32\)DSPRES_FILTER,' 'dspinterface raw response filter cast'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" ', \(u32\)DSPADPCM_FILTER,' 'dspinterface raw adpcm filter cast'
check_absent "src/static/jaudio_NES/internal/dspinterface.c" ', \(u32\)FX_BUF\)' 'dspinterface raw fx buffer cast'
