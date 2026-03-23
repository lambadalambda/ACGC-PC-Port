#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME64_INC="$REPO_ROOT/src/static/jaudio_NES/game/game64.c_inc"

if rg -q -- 'STUCK \(port5 never set' "$GAME64_INC"; then
    printf '%s\n' 'failing contract: Sou_TrgEndCheck still force-frees STUCK port5 slots' >&2
    exit 1
fi

if rg -q -- 'FORCE FREE' "$GAME64_INC"; then
    printf '%s\n' 'failing contract: debug force-free path still present in game64.c_inc' >&2
    exit 1
fi

printf '%s\n' 'check_trg_stuck_force_free_contract: OK'
