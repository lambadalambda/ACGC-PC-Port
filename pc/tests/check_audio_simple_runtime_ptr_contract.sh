#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing simple audio pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy simple audio pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/dummyrom.c" 'DVDT_DRAMtoARAM\(0, PC_RUNTIME_U32_PTR\(init_load_addr\), AUDIO_ARAM_TOP, init_load_size, nullptr, nullptr\);' 'dummyrom preload address'
check_contains "src/static/jaudio_NES/internal/dummyrom.c" 'DVDT_ARAMtoDRAM\(PC_RUNTIME_U32_PTR\(mq\), dramAddr, aramAddr, size, nullptr, &mesg_finishcall\);' 'dummyrom message queue owner read'
check_contains "src/static/jaudio_NES/internal/dummyrom.c" 'DVDT_DRAMtoARAM\(PC_RUNTIME_U32_PTR\(mq\), dramAddr, aramAddr, size, nullptr, &mesg_finishcall\);' 'dummyrom message queue owner write'
check_contains "src/static/jaudio_NES/internal/aramcall.c" 'Jac_InitMotherHeap\(&aram_mother, PC_RUNTIME_U32_PTR\(alloc\), outSize, 0\);' 'aramcall mother heap base'
check_contains "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(PC_RUNTIME_U32_PTR\(use_rsp_madep\), DAC_SIZE \* 2\);' 'aictrl DMA source pointer'

check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)init_load_addr' 'dummyrom preload cast'
check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)mq' 'dummyrom message queue cast'
check_absent "src/static/jaudio_NES/internal/aramcall.c" '\(u32\)alloc' 'aramcall mother heap cast'
check_absent "src/static/jaudio_NES/internal/aictrl.c" '\(u32\)use_rsp_madep' 'aictrl DMA source cast'
