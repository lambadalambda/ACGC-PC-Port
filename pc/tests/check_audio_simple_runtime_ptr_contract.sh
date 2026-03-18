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
check_contains "src/static/jaudio_NES/internal/heapctrl.c" 'dma_buffer_top = PC_RUNTIME_U32_PTR\(JAC_ARAM_DMA_BUFFER_TOP\);' 'heapctrl dma buffer top'
check_contains "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(PC_RUNTIME_U32_PTR\(use_rsp_madep\), DAC_SIZE \* 2\);' 'aictrl DMA source pointer'
check_contains "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(PC_RUNTIME_U32_PTR\(dac\[2\]\), DAC_SIZE \* 2\);' 'aictrl initial DMA source pointer'
check_contains "src/static/jaudio_NES/internal/waveread.c" 'u32 base_addr = PC_RUNTIME_U32_PTR\(data\);' 'waveread base address'
check_contains "src/static/jaudio_NES/internal/bankread.c" 'u32 base_addr    = PC_RUNTIME_U32_PTR\(ibnk_address\);' 'bankread base address'
check_contains "src/static/jaudio_NES/internal/seqsetup.c" 'Init_Track\(track, PC_RUNTIME_U32_PTR\(puVar2\), NULL\);' 'seqsetup track init pointer'
check_contains "src/static/jaudio_NES/internal/memory.c" 'uintptr_t base_addr = \(uintptr_t\)p2;' 'memory heap base uintptr_t'
check_contains "src/static/jaudio_NES/internal/memory.c" 'heap->base = \(u8\*\)ALIGN_NEXT\(base_addr, 32\);' 'memory heap aligned base'
check_contains "src/static/jaudio_NES/internal/memory.c" 'b->sample = \(u8\*\)\(\(uintptr_t\)a->_04 \+ \(\(uintptr_t\)b->sample - \(uintptr_t\)a->sample\)\);' 'memory restore address arithmetic'

check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)init_load_addr' 'dummyrom preload cast'
check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)mq' 'dummyrom message queue cast'
check_absent "src/static/jaudio_NES/internal/aramcall.c" '\(u32\)alloc' 'aramcall mother heap cast'
check_absent "src/static/jaudio_NES/internal/heapctrl.c" 'dma_buffer_top = \(u32\)JAC_ARAM_DMA_BUFFER_TOP' 'heapctrl dma buffer top cast'
check_absent "src/static/jaudio_NES/internal/aictrl.c" '\(u32\)use_rsp_madep' 'aictrl DMA source cast'
check_absent "src/static/jaudio_NES/internal/aictrl.c" '\(u32\)dac\[2\]' 'aictrl initial DMA source cast'
check_absent "src/static/jaudio_NES/internal/waveread.c" 'u32 base_addr = \(u32\)data;' 'waveread base cast'
check_absent "src/static/jaudio_NES/internal/bankread.c" 'u32 base_addr    = \(u32\)ibnk_address;' 'bankread base cast'
check_absent "src/static/jaudio_NES/internal/seqsetup.c" 'Init_Track\(track, \(u32\)puVar2, NULL\);' 'seqsetup track init cast'
check_absent "src/static/jaudio_NES/internal/memory.c" 'length = p3 - \(\(u32\)p2 & 0x1F\);' 'memory heap base cast'
check_absent "src/static/jaudio_NES/internal/memory.c" 'heap->base = \(u8\*\)ALIGN_NEXT\(\(u32\)p2, 32\);' 'memory heap align cast'
check_absent "src/static/jaudio_NES/internal/memory.c" 'b->sample = \(u8\*\)\(\(u32\)a->_04 \+ \(b->sample - \(u32\)a->sample\)\);' 'memory restore address casts'
