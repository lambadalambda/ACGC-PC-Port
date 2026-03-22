#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/driver.c"

if ! rg -q 'Nas_LoadBuffer2\(cmd\+\+, dmem, size, &del_p->left_reverb_buf\[startPos\]\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver aux-load left buffer checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_LoadBuffer2\(cmd\+\+, dmem \+ 0x1A0, size, &del_p->right_reverb_buf\[startPos\]\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver aux-load right buffer checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_SaveBuffer2\(cmd\+\+, dmem, size, &del_p->left_reverb_buf\[startPos\]\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver aux-save left buffer checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_SaveBuffer2\(cmd\+\+, dmem \+ 0x1A0, size, &del_p->right_reverb_buf\[startPos\]\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver aux-save right buffer checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_LoadBuffer2\(cmd\+\+, dmem, sizeof\(driver->synth_params->surround_effect_state\),' "$FILE"; then
    printf '%s\n' 'missing jaudio driver surround-state load checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'driver->synth_params->surround_effect_state\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver surround-state pointer forwarding contract' >&2
    exit 1
fi

if ! rg -q 'Nas_SaveBuffer2\(cmd\+\+, DMEM_SURROUND_TEMP \+ size, sizeof\(driver->synth_params->surround_effect_state\),' "$FILE"; then
    printf '%s\n' 'missing jaudio driver surround-state save checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_LoadBuffer2\(cmd\+\+, DMEM_HAAS_TEMP, ALIGN_NEXT\(prevHaasEffectDelaySize, 16\),' "$FILE"; then
    printf '%s\n' 'missing jaudio driver haas-state load checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'driver->synth_params->haas_effect_delay_state\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver haas-state pointer forwarding contract' >&2
    exit 1
fi

if ! rg -q 'Nas_SaveBuffer2\(cmd\+\+, DMEM_HAAS_TEMP \+ size, ALIGN_NEXT\(haasEffectDelaySize, 16\),' "$FILE"; then
    printf '%s\n' 'missing jaudio driver haas-state save checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'Nas_SaveBuffer2\(cmd\+\+, DMEM_TEMP, JAC_FRAMESAMPLES, aiBuf\);' "$FILE"; then
    printf '%s\n' 'missing jaudio driver output buffer checked narrowing contract' >&2
    exit 1
fi

if rg -q 'aLoadBuffer2\(cmd\+\+, &del_p->left_reverb_buf\[startPos\], dmem, size\);' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver aux-load left raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aLoadBuffer2\(cmd\+\+, &del_p->right_reverb_buf\[startPos\], dmem \+ 0x1A0, size\);' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver aux-load right raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aSaveBuffer2\(cmd\+\+, &del_p->left_reverb_buf\[startPos\], dmem, size\);' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver aux-save left raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aSaveBuffer2\(cmd\+\+, &del_p->right_reverb_buf\[startPos\], dmem \+ 0x1A0, size\);' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver aux-save right raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aLoadBuffer2\(cmd\+\+, driver->synth_params->surround_effect_state,' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver surround-state raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aSaveBuffer2\(cmd\+\+, driver->synth_params->surround_effect_state,' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver surround-state raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aLoadBuffer2\(cmd\+\+, driver->synth_params->haas_effect_delay_state,' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver haas-state raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aSaveBuffer2\(cmd\+\+, driver->synth_params->haas_effect_delay_state,' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver haas-state raw pointer cast still present' >&2
    exit 1
fi

if rg -q 'aSaveBuffer2\(cmd\+\+, aiBuf, DMEM_TEMP, JAC_FRAMESAMPLES\);' "$FILE"; then
    printf '%s\n' 'legacy jaudio driver output buffer raw pointer cast still present' >&2
    exit 1
fi
