#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing gyoei audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy gyoei audio cast: $label" >&2
        exit 1
    fi
}

check_contains "include/ac_gyoei.h" 'aGYO_AUDIO_TOKEN_BASE = 0x47590000u' 'gyoei audio token base'
check_contains "include/ac_gyoei.h" 'aGYO_AUDIO_TOKEN_INVALID = aGYO_AUDIO_TOKEN_BASE \| 0xFFFFu' 'gyoei invalid audio token'
check_contains "include/ac_gyoei.h" '#define aGYO_AUDIO_TOKEN\(slot\)' 'gyoei audio token macro'
check_contains "include/ac_gyoei.h" '\(\(slot\) >= 0 && \(slot\) < aGYO_MAX_GYOEI\)' 'gyoei audio token range check'
check_contains "src/actor/ac_gyoei_clip.c_inc" 'ctrl->swork1 = idx;' 'gyoei ctrl stores pool slot'
check_contains "src/actor/ac_gyo_kaseki.c" 'sAdo_OngenPos\(aGYO_AUDIO_TOKEN\(gyo->swork1\), NA_SE_24, &actorx->world.position\);' 'gyo kaseki uses slot token'
check_contains "src/actor/ac_gyo_test.c" 'sAdo_OngenPos\(aGYO_AUDIO_TOKEN\(gyo->swork1\), NA_SE_24, &actorx->world.position\);' 'gyo test uses slot token'

check_absent "src/actor/ac_gyo_kaseki.c" 'sAdo_OngenPos\(\(u32\)actorx' 'gyo kaseki still narrows actor pointer'
check_absent "src/actor/ac_gyo_test.c" 'sAdo_OngenPos\(\(u32\)actorx' 'gyo test still narrows actor pointer'
