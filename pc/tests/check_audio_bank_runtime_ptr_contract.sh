#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio bank pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio bank pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/channel.c" '#define JAUDIO_U32_ADDR_PTR\(type, value\) \(\(type\*\)\(uintptr_t\)\(u32\)\(value\)\)' 'channel bank pointer reconstruction helper'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.percussion\[idx\] = JAUDIO_U32_ADDR_PTR\(perctable, table\);' 'channel percussion bank pointer'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.effects\[idx\] = \*JAUDIO_U32_ADDR_PTR\(percvoicetable, table\);' 'channel effects bank pointer'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.instruments\[idx\] = JAUDIO_U32_ADDR_PTR\(voicetable, table\);' 'channel instrument bank pointer'
check_contains "include/jaudio_NES/audiostruct.h" 'voicetable\* instrument_entries;' 'voiceinfo LP64 instrument shadow storage'
check_contains "include/jaudio_NES/audiostruct.h" 'perctable\* percussion_entries;' 'voiceinfo LP64 percussion shadow storage'
check_contains "include/jaudio_NES/audiostruct.h" 'smzwavetable\* wavetable_entries;' 'voiceinfo LP64 wavetable shadow storage'
check_contains "include/jaudio_NES/audiostruct.h" 'u32\* wavetable_keys;' 'voiceinfo LP64 wavetable key storage'
check_contains "include/jaudio_NES/audiostruct.h" 'u16 instrument_capacity;' 'voiceinfo LP64 instrument capacity'
check_contains "include/jaudio_NES/audiostruct.h" 'u16 percussion_capacity;' 'voiceinfo LP64 percussion capacity'
check_contains "include/jaudio_NES/audiostruct.h" 'u16 effect_capacity;' 'voiceinfo LP64 effect capacity'
check_contains "src/static/jaudio_NES/internal/system.c" 'static BOOL pc_init_voiceinfo_shadow\(voiceinfo\* vinfo\)' 'voiceinfo shadow init returns status'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_init_voiceinfo_shadow\(vinfo\)' 'bank load shadow init'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_reset_voiceinfo_shadow\(vinfo\);' 'bank load shadow reset'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_init_voiceinfo_shadow\(&AG.voice_info\[i\]\)' 'audio init shadow allocation'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_reset_voiceinfo_shadow\(vinfo\);' 'bank shadow cleared before use'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_bank_deserialize_perctable\(percvt, U32_ADDR_PTR\(PCPercTable32, ctrl_base \+ inst_ofs\), vinfo, ctrl_base,' 'percussion entries deserialize through LP64 shadow'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_bank_deserialize_percvoicetable\(&vinfo->effects\[i\], &sfx_table\[i\], vinfo, ctrl_base, wave_media\);' 'sfx entries deserialize through LP64 shadow'
check_contains "src/static/jaudio_NES/internal/system.c" 'pc_bank_deserialize_voicetable\(inst, U32_ADDR_PTR\(PCVoiceTable32, \*BANK_ENTRY\(ctrl_base, i\)\), vinfo,' 'instrument entries deserialize through LP64 shadow'
check_contains "src/static/jaudio_NES/internal/system.c" 'if \(!pc_init_voiceinfo_shadow\(vinfo\)\) \{' 'bank load shadow allocation guard'
check_contains "src/static/jaudio_NES/internal/system.c" 'if \(!pc_init_voiceinfo_shadow\(&AG.voice_info\[i\]\)\) \{' 'audio init shadow allocation guard'
check_contains "src/static/jaudio_NES/internal/system.c" 'OSReport\("JAUDIO LP64 shadow allocation failed for bank %d\\n", bank_id\);' 'bank load allocation failure report'

check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.percussion\[idx\] = \(perctable\*\)table;' 'legacy channel percussion cast'
check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.effects\[idx\] = \*\(percvoicetable\*\)table;' 'legacy channel effects cast'
check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.instruments\[idx\] = \(voicetable\*\)table;' 'legacy channel instrument cast'
