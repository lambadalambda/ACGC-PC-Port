#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing singleton audio contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy singleton audio cast: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_misin.c" 'aMSN_DUSTCLOTH_AUDIO_TOKEN = 0x4D530000u' 'dustcloth audio token constant'
check_contains "src/actor/ac_misin.c" 'sAdo_OngenPos\(aMSN_DUSTCLOTH_AUDIO_TOKEN, 0x48, &pos\);' 'dustcloth uses stable audio token'
check_contains "src/game/m_player_sound.c_inc" 'mPlayer_KAZAGURUMA_AUDIO_TOKEN = 0x504C0000u' 'player windmill audio token constant'
check_contains "src/game/m_player_sound.c_inc" 'sAdo_OngenPos\(mPlayer_KAZAGURUMA_AUDIO_TOKEN, NA_SE_TEMOCHI_KAZAGURUMA, &actor->world.position\);' 'player windmill uses stable audio token'

check_absent "src/actor/ac_misin.c" 'sAdo_OngenPos\(\(u32\)&aMSN_MoveDustcloth' 'dustcloth still uses function pointer audio id'
check_absent "src/game/m_player_sound.c_inc" 'sAdo_OngenPos\(\(u32\)player' 'player windmill still uses player pointer audio id'
