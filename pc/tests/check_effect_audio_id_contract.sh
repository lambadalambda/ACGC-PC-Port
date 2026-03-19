#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing effect audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy effect audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/effect/ef_effect_control.c" 'eEC_ONGEN_TOKEN_BASE = 0x45430000,' 'effect audio token base'
check_contains "src/effect/ef_effect_control.c" 'size_t effect_idx = \(size_t\)\(effect - eEC_ctrl_work\.effects\);' 'effect audio token uses pool index'
check_contains "src/effect/ef_effect_control.c" 'return eEC_ONGEN_TOKEN_BASE \+ \(u32\)effect_idx;' 'effect audio token returns stable u32 id'
check_contains "src/effect/ef_warau.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 15, &effect->position\);' 'warau effect uses stable audio token'
check_contains "src/effect/ef_siawase_hikari.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 14, &effect->position\);' 'siawase hikari effect uses stable audio token'
check_contains "src/effect/ef_otikomi.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 0x59, &effect->position\);' 'otikomi effect uses stable audio token'
check_contains "src/effect/ef_naku.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 0x2E, &effect->position\);' 'naku effect uses stable audio token'
check_contains "src/effect/ef_lovelove.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 14, &effect->position\);' 'lovelove effect uses stable audio token'
check_contains "src/effect/ef_kangaeru.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 0x58, &effect->position\);' 'kangaeru effect uses stable audio token'
check_contains "src/effect/ef_buruburu.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 0x2D, &effect->position\);' 'buruburu effect uses stable audio token'
check_contains "src/effect/ef_ase2.c" 'sAdo_OngenPos\(eEC_EffectAudioToken\(effect\), 0x29, &effect->position\);' 'ase2 effect uses stable audio token'

check_absent "src/effect/ef_warau.c" 'sAdo_OngenPos\(\(u32\)effect, 15, &effect->position\);' 'legacy warau effect pointer cast'
check_absent "src/effect/ef_siawase_hikari.c" 'sAdo_OngenPos\(\(u32\)effect, 14, &effect->position\);' 'legacy siawase hikari effect pointer cast'
check_absent "src/effect/ef_otikomi.c" 'sAdo_OngenPos\(\(u32\)effect, 0x59, &effect->position\);' 'legacy otikomi effect pointer cast'
check_absent "src/effect/ef_naku.c" 'sAdo_OngenPos\(\(u32\)effect, 0x2E, &effect->position\);' 'legacy naku effect pointer cast'
check_absent "src/effect/ef_lovelove.c" 'sAdo_OngenPos\(\(u32\)effect, 14, &effect->position\);' 'legacy lovelove effect pointer cast'
check_absent "src/effect/ef_kangaeru.c" 'sAdo_OngenPos\(\(u32\)effect, 0x58, &effect->position\);' 'legacy kangaeru effect pointer cast'
check_absent "src/effect/ef_buruburu.c" 'sAdo_OngenPos\(\(u32\) ?effect, 0x2D, &effect->position\);' 'legacy buruburu effect pointer cast'
check_absent "src/effect/ef_ase2.c" 'sAdo_OngenPos\(\(u32\)effect, 0x29, &effect->position\);' 'legacy ase2 effect pointer cast'
