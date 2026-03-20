#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing snowman audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy snowman audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_snowman.c" 'aSMAN_AUDIO_TOKEN_BASE = 0x534E0000u' 'snowman audio token base'
check_contains "src/actor/ac_snowman.c" '#define aSMAN_AUDIO_TOKEN\(part\) \(aSMAN_AUDIO_TOKEN_BASE \+ \(u32\)\(part\)\)' 'snowman audio token macro'
check_contains "src/actor/ac_snowman.c" 'sAdo_OngenPos\(aSMAN_AUDIO_TOKEN\(actor->snowman_part\), 52, &actorx->world.position\);' 'snowman uses part token'

check_absent "src/actor/ac_snowman.c" 'sAdo_OngenPos\(\(u32\)actorx' 'snowman still narrows actor pointer'
