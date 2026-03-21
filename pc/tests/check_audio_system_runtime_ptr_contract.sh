#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio system pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio system pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t ctrl_base = \(uintptr_t\)ctrl_p;' 'bank ctrl base uses host pointer width'
check_contains "src/static/jaudio_NES/internal/system.c" '#define OFS2RAM\(base_addr, ofs\) \(\(uintptr_t\)\(base_addr\) \+ \(uintptr_t\)\(u32\)\(ofs\)\)' 'OFS2RAM preserves host pointer width'
check_contains "src/static/jaudio_NES/internal/system.c" '#define U32_ADDR_PTR\(type, addr\) \(\(type\*\)\(uintptr_t\)\(addr\)\)' 'u32 address reconstruction helper'
check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t wt_bits = \(uintptr_t\)wavetouch_str->wavetable;' 'wavetable pointer bits'
check_contains "src/static/jaudio_NES/internal/system.c" 'wt_bits != 0 && wt_bits <= UINT32_MAX && wt_bits < 0x10000000u' 'wavetable offset discrimination'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 loop_ofs = PC_RUNTIME_U32_PTR\(wavetable->loop\);' 'wavetable loop offset narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 book_ofs = PC_RUNTIME_U32_PTR\(wavetable->book\);' 'wavetable book offset narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 sample_ofs = PC_RUNTIME_U32_PTR\(wavetable->sample\);' 'wavetable sample offset narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&percvt->tuned_sample, ctrl_base, wave_media\);' 'percussion wavetable base'
check_contains "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&sfx->tuned_sample, ctrl_base, wave_media\);' 'sfx wavetable base'
check_contains "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&inst->normal_pitch_tuned_sample, ctrl_base, wave_media\);' 'instrument wavetable base'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 src_addr = PC_RUNTIME_U32_PTR\(SrcAddr\);' 'fast copy source narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t src_addr_bits = \(uintptr_t\)SrcAddr;' 'fast copy source alignment uses uintptr_t'
check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t dest_addr_bits = \(uintptr_t\)DestAdd;' 'fast copy destination alignment uses uintptr_t'
check_contains "src/static/jaudio_NES/internal/system.c" 'ARStartDMA\(1 /\* ARAM→MRAM \*/, pc_aram_host_addr_encode\(dram_addr\), aram_offset, size\);' 'Nas_StartDma uses ARAM host pointer codec'
check_contains "src/static/jaudio_NES/internal/system.c" 'cache->current_device_addr = PC_RUNTIME_U32_PTR\(wavetable->sample\);' 'lps current device address'
check_contains "src/static/jaudio_NES/internal/system.c" 'bgload->current_device_addr = PC_RUNTIME_U32_PTR\(src\);' 'background copy device address'
check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t wave0_base;' 'wave media RAM base storage width'
check_contains "src/static/jaudio_NES/internal/system.c" 'uintptr_t wave1_base;' 'wave media disk base storage width'
check_contains "src/static/jaudio_NES/internal/system.c" 'wave0_base = \(uintptr_t\)wave_media->wave0_p;' 'wave media RAM base host pointer'
check_contains "src/static/jaudio_NES/internal/system.c" 'wave1_base = \(uintptr_t\)wave_media->wave1_p;' 'wave media disk base host pointer'
check_contains "src/static/jaudio_NES/internal/system.c" 'header->entries\[i\]\.addr \+= PC_RUNTIME_U32_PTR\(data\);' 'bank header entry base'
check_contains "src/static/jaudio_NES/internal/system.c" 'return PC_RUNTIME_U32_PTR\(ram_p\);' 'wave cache return narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'OSReport\("AUDIOHEAP SET ADDR %p \(SIZE %xh\) \\n", \(void\*\)heap_p, heap_size\);' 'audio heap report uses host pointer formatting'
check_contains "src/static/jaudio_NES/internal/system.c" 'preload->end_and_medium_key = PC_RUNTIME_U32_PTR\(wavetable->sample\) \+ wavetable->size \+ wavetable->medium;' 'preload sample key'
check_contains "src/static/jaudio_NES/internal/system.c" 'key = PC_RUNTIME_U32_PTR\(wavetable->sample\) \+ wavetable->size \+ wavetable->medium;' 'bg wave sample key'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'extern void Nap_SetPtr\(u32 cmd, uintptr_t param\)' 'audio port has pointer command API'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'sAudioPortPtrParam\[256\]' 'audio port stores full-width pointer payloads'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'return \(uintptr_t\)port->param.asU32;' 'audio pointer payload falls back to legacy u32 param'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'NA_VFRAME_CALLBACK = JAUDIO_U32_CALLBACK\(VFRAME_CALLBACK, Nap_PortGetPtr\(port\)\);' 'vframe callback reconstructs pointer via pointer path'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'AG.seq_callbacks\[port->command.arg2\] = JAUDIO_U32_CALLBACK\(SequenceCallback, Nap_PortGetPtr\(port\)\);' 'sequence callback reconstructs pointer via pointer path'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'subtrack->sfx_state = \(u8\*\)Nap_PortGetPtr\(port\);' 'subtrack sfx-state pointer reconstructs through pointer payload path'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'subtrack->filter = \(s16\*\)Nap_PortGetPtr\(port\);' 'subtrack filter pointer reconstructs through pointer payload path'
check_contains "src/static/jaudio_NES/game/rhythm.c" 'Nap_SetPtr\(NA_MAKE_COMMAND\(228, 0, 0, 0\), \(uintptr_t\)Na_GetRhythmSeNum\);' 'rhythm callback registration uses pointer command API'
check_contains "src/static/jaudio_NES/game/rhythm.c" 'Nap_SetPtr\(NA_MAKE_COMMAND\(228, 0, 0, 1\), \(uintptr_t\)Na_RhythmGrpProcess\);' 'rhythm group callback registration uses pointer command API'
check_contains "src/static/jaudio_NES/game/melody.c" 'Nap_SetPtr\(NA_MAKE_COMMAND\(0x10, 0x00, subTrack, 0x00\), \(uintptr_t\)pData\);' 'melody sequence state pointer registration uses pointer command API'
check_contains "src/static/jaudio_NES/game/melody.c" 'Nap_SetPtr\(NA_MAKE_COMMAND\(0x10, 0x02, sub_track, 0x00\), \(uintptr_t\)melody\);' 'furniture melody state pointer registration uses pointer command API'
check_contains "include/jaudio_NES/audiocommon.h" '_a->words\.w1 = A_CMD_PTR_WORD\(addr\);' 'fir filter command encodes pointer payload'
check_contains "include/jaudio_NES/audiocommon.h" '_a->words\.w1 = A_CMD_PTR_WORD\(m\);' 'env mixer command encodes pointer payload'

check_absent "src/static/jaudio_NES/internal/system.c" '#define OFS2RAM\(base, ofs\) \(\(u32\)\(ofs\) \+ \(u32\)base\)' 'legacy OFS2RAM base cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'u32 ctrl_base = PC_RUNTIME_U32_PTR\(ctrl_p\);' 'legacy bank ctrl base narrowing'
check_absent "src/static/jaudio_NES/internal/system.c" 'u32 wave0_base = PC_RUNTIME_U32_PTR\(wave_media->wave0_p\);' 'legacy wave media RAM base narrowing'
check_absent "src/static/jaudio_NES/internal/system.c" 'u32 wave1_base = PC_RUNTIME_U32_PTR\(wave_media->wave1_p\);' 'legacy wave media disk base narrowing'
check_absent "src/static/jaudio_NES/internal/system.c" '#define BANK_ENTRY\(ctrl, idx\) \(\(\(u32\*\)\(\(u32\)ctrl\)\) \+ idx\)' 'legacy BANK_ENTRY cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'u32 wt_ofs = \(u32\)wavetouch_str->wavetable;' 'legacy wavetable offset cast'
check_absent "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&percvt->tuned_sample, \(u32\)ctrl_p, wave_media\);' 'legacy percussion base cast'
check_absent "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&sfx->tuned_sample, \(u32\)ctrl_p, wave_media\);' 'legacy sfx base cast'
check_absent "src/static/jaudio_NES/internal/system.c" '__WaveTouch\(&inst->normal_pitch_tuned_sample, \(u32\)ctrl_p, wave_media\);' 'legacy instrument base cast'
check_absent "src/static/jaudio_NES/internal/system.c" '\(u32\)SrcAddr' 'legacy fast copy source casts'
check_absent "src/static/jaudio_NES/internal/system.c" '\(u32\)dram_addr' 'legacy Nas_StartDma dram cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'cache->current_device_addr = \(u32\)wavetable->sample;' 'legacy lps device cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'bgload->current_device_addr = \(u32\)src;' 'legacy bgload device cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'header->entries\[i\]\.addr \+= \(u32\)data;' 'legacy bank header base cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'return \(u32\)ram_p;' 'legacy wave cache return cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'OSReport\("AUDIOHEAP SET ADDR %xh \(SIZE %xh\) \\n", \(u32\)heap_p, heap_size\);' 'legacy audio heap report cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'preload->end_and_medium_key = \(u32\)wavetable->sample \+ wavetable->size \+ wavetable->medium;' 'legacy preload sample key cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'key = \(u32\)wavetable->sample \+ wavetable->size \+ wavetable->medium;' 'legacy bg wave sample key cast'
check_absent "src/static/jaudio_NES/internal/system.c" 'ARStartDMA\(1 /\* ARAM→MRAM \*/, PC_RUNTIME_U32_PTR\(dram_addr\), aram_offset, size\);' 'legacy Nas_StartDma runtime narrowing'
check_absent "src/static/jaudio_NES/game/rhythm.c" 'Nap_SetS32\(NA_MAKE_COMMAND\(228, 0, 0, 0\), \(s32\)Na_GetRhythmSeNum\);' 'legacy rhythm callback cast to s32'
check_absent "src/static/jaudio_NES/game/rhythm.c" 'Nap_SetS32\(NA_MAKE_COMMAND\(228, 0, 0, 1\), \(s32\)Na_RhythmGrpProcess\);' 'legacy rhythm group callback cast to s32'
check_absent "src/static/jaudio_NES/game/melody.c" 'Nap_SetS32\(NA_MAKE_COMMAND\(0x10, 0x00, subTrack, 0x00\), \(u64\)pData\);' 'legacy melody sequence state pointer narrowing path'
check_absent "src/static/jaudio_NES/game/melody.c" 'Nap_SetS32\(NA_MAKE_COMMAND\(0x10, 0x02, sub_track, 0x00\), \(u64\)melody\);' 'legacy furniture melody state pointer narrowing path'
check_absent "include/jaudio_NES/audiocommon.h" '_a->words\.w1 = \(unsigned int\)\(addr\);' 'legacy fir filter pointer narrowing'
check_absent "include/jaudio_NES/audiocommon.h" '_a->words\.w1 = \(unsigned int\)\(m\);' 'legacy env mixer pointer narrowing'
