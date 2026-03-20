#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/driver.c"

if ! rg -q 'static Acmd\* Nas_SaveBufferAuto\(Acmd\* cmd, u16 ofs, u16 size, u32 startAddr\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver save-buffer declaration width contract' >&2
    exit 1
fi

if ! rg -q 'static Acmd\* Nas_SaveBufferAuto\(Acmd\* cmd, u16 dmem, u16 size, u32 startAddr\) \{' "$FILE"; then
    printf '%s\n' 'missing jaudio driver save-buffer definition width contract' >&2
    exit 1
fi

if ! rg -q 'u32 startUnaligned = startAddr & 15;' "$FILE"; then
    printf '%s\n' 'missing jaudio driver start alignment unsigned contract' >&2
    exit 1
fi

if ! rg -q 'static void Nas_LoadBuffer2\(Acmd\* cmd, s32 dst, s32 len, u32 src\) \{' "$FILE"; then
    printf '%s\n' 'missing jaudio driver load-buffer source width contract' >&2
    exit 1
fi

if ! rg -q 'static void Nas_SaveBuffer2\(Acmd\* cmd, s32 src, s32 len, u32 dst\) \{' "$FILE"; then
    printf '%s\n' 'missing jaudio driver save-buffer destination width contract' >&2
    exit 1
fi

if ! rg -q 'static void Nas_PCM8dec\(Acmd\* cmd, s32 flags, u32 state\) \{' "$FILE"; then
    printf '%s\n' 'missing jaudio driver pcm8 state width contract' >&2
    exit 1
fi

if ! rg -q '#define JAUDIO_CALLBACK_TAG\(value\) \(\(u32\)\(\(uintptr_t\)\(value\) & 0xFFu\)\)' "$FILE"; then
    printf '%s\n' 'missing jaudio callback tag u32 narrowing contract' >&2
    exit 1
fi

if ! rg -q 'u32 reverbAddrTag;' "$FILE"; then
    printf '%s\n' 'missing jaudio reverb callback tag width contract' >&2
    exit 1
fi

if rg -q '\(s32\)PC_RUNTIME_U32_PTR\(&del_p->left_reverb_buf' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver left reverb address signed cast still present' >&2
    exit 1
fi

if rg -q '\(s32\)PC_RUNTIME_U32_PTR\(&del_p->right_reverb_buf' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver right reverb address signed cast still present' >&2
    exit 1
fi

if rg -q '\(s32\)PC_RUNTIME_U32_PTR\(driver->synth_params->adpcm_state\)' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver adpcm state signed cast still present' >&2
    exit 1
fi

if rg -q '\(s32\)PC_RUNTIME_U32_PTR\(combFilterState\)' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver comb-filter state signed cast still present' >&2
    exit 1
fi

if rg -q '\(s32\)PC_RUNTIME_U32_PTR\(' "$FILE"; then
    printf '%s\n' 'unexpected jaudio driver signed cast on checked pointer narrowing helper' >&2
    exit 1
fi

if rg -q '\(s32\)reverbAddrTag' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver reverb tag signed cast still present' >&2
    exit 1
fi

if rg -q 'uintptr_t reverbAddrTag;' "$FILE"; then
    printf '%s\n' 'legacy jaudio reverb callback tag uintptr_t type still present' >&2
    exit 1
fi
