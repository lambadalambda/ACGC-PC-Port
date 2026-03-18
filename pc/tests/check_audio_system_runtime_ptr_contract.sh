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

check_contains "src/static/jaudio_NES/internal/system.c" 'u32 ctrl_base = PC_RUNTIME_U32_PTR\(ctrl_p\);' 'bank ctrl base narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" '#define OFS2RAM\(base_u32, ofs\) \(\(u32\)\(ofs\) \+ \(base_u32\)\)' 'OFS2RAM uses checked base'
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
check_contains "src/static/jaudio_NES/internal/system.c" 'ARStartDMA\(1 /\* ARAM→MRAM \*/, PC_RUNTIME_U32_PTR\(dram_addr\), aram_offset, size\);' 'Nas_StartDma dram address narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'cache->current_device_addr = PC_RUNTIME_U32_PTR\(wavetable->sample\);' 'lps current device address'
check_contains "src/static/jaudio_NES/internal/system.c" 'bgload->current_device_addr = PC_RUNTIME_U32_PTR\(src\);' 'background copy device address'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 wave0_base = PC_RUNTIME_U32_PTR\(wave_media->wave0_p\);' 'wave media RAM base'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 wave1_base = PC_RUNTIME_U32_PTR\(wave_media->wave1_p\);' 'wave media disk base'
check_contains "src/static/jaudio_NES/internal/system.c" 'header->entries\[i\]\.addr \+= PC_RUNTIME_U32_PTR\(data\);' 'bank header entry base'
check_contains "src/static/jaudio_NES/internal/system.c" 'return PC_RUNTIME_U32_PTR\(ram_p\);' 'wave cache return narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'OSReport\("AUDIOHEAP SET ADDR %xh \(SIZE %xh\) \\n", PC_RUNTIME_U32_PTR\(heap_p\), heap_size\);' 'audio heap report narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'preload->end_and_medium_key = PC_RUNTIME_U32_PTR\(wavetable->sample\) \+ wavetable->size \+ wavetable->medium;' 'preload sample key'
check_contains "src/static/jaudio_NES/internal/system.c" 'key = PC_RUNTIME_U32_PTR\(wavetable->sample\) \+ wavetable->size \+ wavetable->medium;' 'bg wave sample key'

check_absent "src/static/jaudio_NES/internal/system.c" '#define OFS2RAM\(base, ofs\) \(\(u32\)\(ofs\) \+ \(u32\)base\)' 'legacy OFS2RAM base cast'
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
