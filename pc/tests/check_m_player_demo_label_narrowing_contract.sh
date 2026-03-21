#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/game/m_player_lib.c"

if ! rg -q 'req_demo_wait_p->label\s*=\s*PC_RUNTIME_U32_PTR\(speak_actor_p\)\s*;' "$FILE"; then
    printf '%s\n' 'missing m_player demo-wait label checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'player->able_force_speak_label\s*=\s*PC_RUNTIME_U32_PTR\(label\)\s*;' "$FILE"; then
    printf '%s\n' 'missing m_player force-speak label checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'if\s*\(\s*demo_wait_p->label\s*==\s*PC_RUNTIME_U32_PTR\(label\)\s*\)\s*\{' "$FILE"; then
    printf '%s\n' 'missing m_player demo-wait label compare checked narrowing contract' >&2
    exit 1
fi

if rg -q 'req_demo_wait_p->label\s*=\s*\(u32\)speak_actor_p\s*;' "$FILE"; then
    printf '%s\n' 'legacy m_player demo-wait label direct u32 cast still present' >&2
    exit 1
fi

if rg -q 'player->able_force_speak_label\s*=\s*\(u32\)label\s*;' "$FILE"; then
    printf '%s\n' 'legacy m_player force-speak label direct u32 cast still present' >&2
    exit 1
fi

if rg -q 'if\s*\(\s*demo_wait_p->label\s*==\s*\(u32\)label\s*\)\s*\{' "$FILE"; then
    printf '%s\n' 'legacy m_player demo-wait label direct u32 compare cast still present' >&2
    exit 1
fi
