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
check_contains "include/dolphin/ai.h" '#if defined\(TARGET_PC\)' 'AI header has TARGET_PC-specific DMA signature guard'
check_contains "include/dolphin/ai.h" 'void AIInitDMA\(uintptr_t start_addr, u32 length\);' 'AI DMA signature uses host-width pointer on PC'
check_contains "pc/src/pc_audio.c" 'void AIInitDMA\(uintptr_t addr, u32 size\)' 'PC audio DMA implementation accepts host-width pointer'
check_contains "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(\(uintptr_t\)use_rsp_madep, DAC_SIZE \* 2\);' 'aictrl DMA source pointer uses host-width cast'
check_contains "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(\(uintptr_t\)dac\[2\], DAC_SIZE \* 2\);' 'aictrl initial DMA source pointer uses host-width cast'
check_contains "src/static/jaudio_NES/internal/waveread.c" 'static void PTconvert\(void\*\* pointer, uintptr_t base_address\)' 'waveread pointer conversion helper is host-width'
check_contains "src/static/jaudio_NES/internal/waveread.c" 'uintptr_t base_addr = \(uintptr_t\)data;' 'waveread base address is host-width'
check_contains "src/static/jaudio_NES/internal/bankread.c" 'static void PTconvert\(void\*\* pointer, uintptr_t base_address\)' 'bankread pointer conversion helper is host-width'
check_contains "src/static/jaudio_NES/internal/bankread.c" 'uintptr_t base_addr = \(uintptr_t\)ibnk_address;' 'bankread base address is host-width'
check_contains "src/static/jaudio_NES/internal/seqsetup.c" 'Init_Track\(track, PC_RUNTIME_U32_PTR\(puVar2\), NULL\);' 'seqsetup track init pointer'
check_contains "src/static/jaudio_NES/internal/dvdthread.c" 'ARQPostRequest\(nullptr, call->owner, ARQ_TYPE_ARAM_TO_MRAM, ARQ_PRIORITY_HIGH,' 'dvdthread uses explicit owner id for ARAM->DRAM task on PC'
check_contains "src/static/jaudio_NES/internal/dvdthread.c" 'ARQPostRequest\(nullptr, call->owner, ARQ_TYPE_MRAM_TO_ARAM, ARQ_PRIORITY_HIGH,' 'dvdthread uses explicit owner id for DRAM->ARAM task on PC'
check_contains "include/PR/abi.h" 'unsigned int pc_audio_cmd_ptr_encode\(const void\* ptr\);' 'ABI declares audio command pointer encoder on PC'
check_contains "include/PR/abi.h" '#define A_CMD_PTR_WORD\(value\) pc_audio_cmd_ptr_encode\(\(const void\*\)\(value\)\)' 'ABI command pointer words route through encoder on PC'
check_contains "include/jaudio_NES/audiocommon.h" '_a->words.w1 = A_CMD_PTR_WORD\(dst\);' 'audio common command pointer words use encoder macro'
check_contains "src/static/jaudio_NES/internal/rspsim.c" 'unsigned int pc_audio_cmd_ptr_encode\(const void\* ptr\)' 'rspsim provides command pointer encoder'
check_contains "src/static/jaudio_NES/internal/rspsim.c" 'static void\* pc_audio_cmd_ptr_decode_word\(u32 word\)' 'rspsim decodes command pointer words'
check_contains "src/static/jaudio_NES/internal/driver.c" 'Nas_LoadBuffer2\(cmd\+\+, dmem, size, &del_p->left_reverb_buf\[startPos\]\);' 'driver aux load uses host pointer directly'
check_contains "src/static/jaudio_NES/internal/driver.c" 'Nas_SaveBuffer2\(cmd\+\+, dmem, size, &del_p->left_reverb_buf\[startPos\]\);' 'driver aux save uses host pointer directly'
check_contains "src/static/jaudio_NES/internal/memory.c" 'uintptr_t base_addr = \(uintptr_t\)p2;' 'memory heap base uintptr_t'
check_contains "src/static/jaudio_NES/internal/memory.c" 'heap->base = \(u8\*\)ALIGN_NEXT\(base_addr, 32\);' 'memory heap aligned base'
check_contains "src/static/jaudio_NES/internal/memory.c" 'b->sample = \(u8\*\)\(\(uintptr_t\)a->_04 \+ \(\(uintptr_t\)b->sample - \(uintptr_t\)a->sample\)\);' 'memory restore address arithmetic'

check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)init_load_addr' 'dummyrom preload cast'
check_absent "src/static/jaudio_NES/internal/dummyrom.c" '\(u32\)mq' 'dummyrom message queue cast'
check_absent "src/static/jaudio_NES/internal/aramcall.c" '\(u32\)alloc' 'aramcall mother heap cast'
check_absent "src/static/jaudio_NES/internal/heapctrl.c" 'dma_buffer_top = \(u32\)JAC_ARAM_DMA_BUFFER_TOP' 'heapctrl dma buffer top cast'
check_absent "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(PC_RUNTIME_U32_PTR\(use_rsp_madep\), DAC_SIZE \* 2\);' 'legacy checked narrowing for aictrl DMA source pointer'
check_absent "src/static/jaudio_NES/internal/aictrl.c" 'AIInitDMA\(PC_RUNTIME_U32_PTR\(dac\[2\]\), DAC_SIZE \* 2\);' 'legacy checked narrowing for aictrl initial DMA source pointer'
check_absent "src/static/jaudio_NES/internal/aictrl.c" '\(u32\)use_rsp_madep' 'aictrl DMA source cast'
check_absent "src/static/jaudio_NES/internal/aictrl.c" '\(u32\)dac\[2\]' 'aictrl initial DMA source cast'
check_absent "src/static/jaudio_NES/internal/waveread.c" 'u32 base_addr = PC_RUNTIME_U32_PTR\(data\);' 'legacy checked narrowing for waveread base address'
check_absent "src/static/jaudio_NES/internal/waveread.c" 'u32 base_addr = \(u32\)data;' 'waveread base cast'
check_absent "src/static/jaudio_NES/internal/bankread.c" 'u32 base_addr    = PC_RUNTIME_U32_PTR\(ibnk_address\);' 'legacy checked narrowing for bankread base address'
check_absent "src/static/jaudio_NES/internal/bankread.c" 'u32 base_addr    = \(u32\)ibnk_address;' 'bankread base cast'
check_absent "src/static/jaudio_NES/internal/seqsetup.c" 'Init_Track\(track, \(u32\)puVar2, NULL\);' 'seqsetup track init cast'
check_absent "src/static/jaudio_NES/internal/dvdthread.c" 'ARQPostRequest\(nullptr, JAUDIO_ARQ_PTR\(call\), ARQ_TYPE_ARAM_TO_MRAM, ARQ_PRIORITY_HIGH,' 'legacy checked narrowing of dvdthread task owner in ARAM->DRAM'
check_absent "src/static/jaudio_NES/internal/dvdthread.c" 'ARQPostRequest\(nullptr, JAUDIO_ARQ_PTR\(call\), ARQ_TYPE_MRAM_TO_ARAM, ARQ_PRIORITY_HIGH,' 'legacy checked narrowing of dvdthread task owner in DRAM->ARAM'
check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_LoadBuffer2\(cmd\+\+, dmem, size, PC_RUNTIME_U32_PTR\(&del_p->left_reverb_buf\[startPos\]\)\);' 'legacy checked narrowing for driver aux load left buffer'
check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_SaveBuffer2\(cmd\+\+, dmem, size, PC_RUNTIME_U32_PTR\(&del_p->left_reverb_buf\[startPos\]\)\);' 'legacy checked narrowing for driver aux save left buffer'
check_absent "src/static/jaudio_NES/internal/memory.c" 'length = p3 - \(\(u32\)p2 & 0x1F\);' 'memory heap base cast'
check_absent "src/static/jaudio_NES/internal/memory.c" 'heap->base = \(u8\*\)ALIGN_NEXT\(\(u32\)p2, 32\);' 'memory heap align cast'
check_absent "src/static/jaudio_NES/internal/memory.c" 'b->sample = \(u8\*\)\(\(u32\)a->_04 \+ \(b->sample - \(u32\)a->sample\)\);' 'memory restore address casts'
