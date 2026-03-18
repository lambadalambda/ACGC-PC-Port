#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio driver pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio driver pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/driver.c" 'samplesToLoadAddr = \(u8\*\)Nas_WaveDmaCallBack\(PC_RUNTIME_U32_PTR\(tmpSamplesToLoadAddr\),' 'driver DMA callback source address'
check_contains "src/static/jaudio_NES/internal/driver.c" 'sampleDataChunkAlignPad = \(s32\)\(\(uintptr_t\)samplesToLoadAddr & 0xF\);' 'driver sample alignment uses uintptr_t'
check_contains "src/static/jaudio_NES/internal/driver.c" 'aLoadBuffer2\(cmd\+\+, PC_RUNTIME_U32_PTR\(VELOCONV_TABLE\[vel_conv_idx\]\), 0x800,' 'driver velocity table load'
check_contains "src/static/jaudio_NES/internal/driver.c" 'Nas_LoadBuffer2\(cmd\+\+, DMEM_COMB_TEMP - combFilterSize, combFilterSize,' 'driver comb filter load call'
check_contains "src/static/jaudio_NES/internal/driver.c" 'PC_RUNTIME_U32_PTR\(combFilterState\)' 'driver comb filter state narrowing'
check_contains "src/static/jaudio_NES/internal/driver.c" 'PC_RUNTIME_U32_PTR\(&del_p->left_reverb_buf\[param->start_pos\]\)' 'driver left reverb buffer state'
check_contains "src/static/jaudio_NES/internal/driver.c" 'PC_RUNTIME_U32_PTR\(&del_p->right_reverb_buf\[param->start_pos\]\)' 'driver right reverb buffer state'
check_contains "src/static/jaudio_NES/internal/driver.c" 'PC_RUNTIME_U32_PTR\(driver->synth_params->adpcm_state\)' 'driver adpcm state narrowing'
check_contains "src/static/jaudio_NES/internal/driver.c" '#define JAUDIO_CALLBACK_TAG\(value\) \(\(uintptr_t\)\(value\) & 0xFFu\)' 'driver callback tag helper'
check_contains "src/static/jaudio_NES/internal/driver.c" 'cmd = \(Acmd\*\)JAUDIO_CALLBACK_TAG\(NA_DACOUT_CALLBACK\(cmd, 2 \* size, updateIndex\)\);' 'driver dac callback tag use'
check_contains "src/static/jaudio_NES/internal/driver.c" 'uintptr_t reverbAddrTag;' 'driver reverb callback tag storage'
check_contains "src/static/jaudio_NES/internal/driver.c" 'reverbAddrTag = UINT32_MAX;' 'driver reverb sentinel tag'
check_contains "src/static/jaudio_NES/internal/driver.c" 'reverbAddrTag = JAUDIO_CALLBACK_TAG\(NA_SOUND_CALLBACK\(sample, numSamplesToLoadAdj, flags, chan_id\)\);' 'driver sound callback tag use'
check_contains "src/static/jaudio_NES/internal/driver.c" 'if \(reverbAddrTag == UINT32_MAX\)' 'driver reverb sentinel compare'
check_contains "src/static/jaudio_NES/internal/driver.c" '\(s32\)reverbAddrTag' 'driver reverb load tag cast'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" '#define JAUDIO_U32_CALLBACK\(type, value\) \(\(type\)\(uintptr_t\)\(u32\)\(value\)\)' 'subsys callback reconstruction helper'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'NA_VFRAME_CALLBACK = JAUDIO_U32_CALLBACK\(VFRAME_CALLBACK, port->param.asU32\);' 'subsys vframe callback restore'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'NA_SOUND_CALLBACK = JAUDIO_U32_CALLBACK\(SOUND_CALLBACK, port->param.asU32\);' 'subsys sound callback restore'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'NA_DACOUT_CALLBACK = JAUDIO_U32_CALLBACK\(DACOUT_CALLBACK, port->param.asU32\);' 'subsys dac callback restore'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'AG.seq_callbacks\[port->command.arg2\] = JAUDIO_U32_CALLBACK\(SequenceCallback, port->param.asU32\);' 'subsys sequence callback restore'

check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_WaveDmaCallBack\(\(u32\)\(tmpSamplesToLoadAddr\),' 'legacy driver DMA source cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'sampleDataChunkAlignPad = \(u32\)samplesToLoadAddr & 0xF;' 'legacy driver sample alignment cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'aLoadBuffer2\(cmd\+\+, \(u32\)VELOCONV_TABLE\[vel_conv_idx\], 0x800, sizeof\(VELOCONV_TABLE\[vel_conv_idx\]\)\);' 'legacy driver velocity table cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_LoadBuffer2\(cmd\+\+, DMEM_COMB_TEMP - combFilterSize, combFilterSize, \(s32\)combFilterState\);' 'legacy driver comb filter load cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_SaveBuffer2\(cmd\+\+, DMEM_TEMP - combFilterSize \+ size, combFilterSize, \(s32\)combFilterState\);' 'legacy driver comb filter save cast'
check_absent "src/static/jaudio_NES/internal/driver.c" '\(s32\)&del_p->left_reverb_buf\[param->start_pos\]' 'legacy driver left reverb cast'
check_absent "src/static/jaudio_NES/internal/driver.c" '\(s32\)&del_p->right_reverb_buf\[param->start_pos\]' 'legacy driver right reverb cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'Nas_PCM8dec\(cmd\+\+, flags, \(s32\)driver->synth_params->adpcm_state\);' 'legacy driver adpcm state cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'cmd = \(Acmd\*\)\(\(u32\)NA_DACOUT_CALLBACK\(cmd, 2 \* size, updateIndex\) & 0xFF\);' 'legacy driver dac callback cast'
check_absent "src/static/jaudio_NES/internal/driver.c" 'void\* reverbAddrSrc;' 'legacy driver reverb pointer temp'
check_absent "src/static/jaudio_NES/internal/driver.c" 'reverbAddrSrc = \(void\*\)\(\(u32\)NA_SOUND_CALLBACK\(sample, numSamplesToLoadAdj, flags, chan_id\) & 0xFF\);' 'legacy driver sound callback cast'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'NA_VFRAME_CALLBACK = \(VFRAME_CALLBACK\)port->param.asU32;' 'legacy subsys vframe callback cast'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'NA_SOUND_CALLBACK = \(SOUND_CALLBACK\)port->param.asU32;' 'legacy subsys sound callback cast'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'NA_DACOUT_CALLBACK = \(DACOUT_CALLBACK\)port->param.asU32;' 'legacy subsys dac callback cast'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'AG.seq_callbacks\[port->command.arg2\] = \(SequenceCallback\)port->param.asU32;' 'legacy subsys sequence callback cast'
