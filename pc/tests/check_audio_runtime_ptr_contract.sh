#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio runtime pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio pointer pattern: $label" >&2
        exit 1
    fi
}

check_contains "include/jaudio_NES/audiocommon.h" '#define NA_AUDIO_PTR_PARAM\(ptr\) \(\(s32\)PC_RUNTIME_U32_PTR\(ptr\)\)' 'audio command pointer parameter'
check_contains "src/static/jaudio_NES/internal/jammain_2.c" 'fmtParms\[i\] = PC_RUNTIME_U32_PTR\(Jam_OfsToAddr\(SEQ_P, fmtParms\[i\]\)\);' 'jammain pointer formatting parameter'
check_contains "src/static/jaudio_NES/internal/sample.c" 'alignedbitsDst = \(u8\)\(\(uintptr_t\)bdest & 0x3u\);' 'sample alignment uses uintptr_t'
check_contains "src/game/m_train_control.c" 'mTRC_KISHA_ONGEN_COMING = 0x54524301,' 'train coming audio token uses stable fixed id'
check_contains "src/game/m_train_control.c" 'mTRC_KISHA_ONGEN_EXISTS = 0x54524302,' 'train exists audio token uses stable fixed id'
check_contains "src/game/m_train_control.c" 'ongen = mTRC_KISHA_ONGEN_COMING;' 'train coming audio path uses fixed token'
check_contains "src/game/m_train_control.c" 'ongen2 = mTRC_KISHA_ONGEN_EXISTS;' 'train exists audio path uses fixed token'
check_absent "src/static/jaudio_NES/internal/sample.c" 'CAST_PTR_U32' 'sample pointer truncation macro'
check_absent "src/game/m_train_control.c" 'ongen = \(u32\)Common_GetPointer\(train_coming_flag\);' 'legacy train coming pointer cast'
check_absent "src/game/m_train_control.c" 'ongen2 = \(u32\)Common_GetPointer\(train_exists_flag\);' 'legacy train exists pointer cast'
