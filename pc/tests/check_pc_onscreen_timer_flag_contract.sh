#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PC_MAIN_C="$REPO_ROOT/pc/src/pc_main.c"
PC_PLATFORM_H="$REPO_ROOT/pc/include/pc_platform.h"
PLAY_C="$REPO_ROOT/src/game/m_play.c"

if ! rg -q 'int[[:space:]]+g_pc_onscreen_timer[[:space:]]*=[[:space:]]*0;' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main onscreen timer global flag' >&2
    exit 1
fi

if ! rg -q 'strcmp\(argv\[i\], "--on-screen-timer"\) == 0' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main --on-screen-timer parse contract' >&2
    exit 1
fi

if ! rg -q 'strcmp\(argv\[i\], "--onscreen-timer"\) == 0' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main --onscreen-timer alias parse contract' >&2
    exit 1
fi

if ! rg -q 'printf\("  --on-screen-timer[[:space:]]+Show T\+MM:SS timer overlay\\n"\);' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main --on-screen-timer help text contract' >&2
    exit 1
fi

if ! rg -q 'extern int[[:space:]]+g_pc_onscreen_timer;' "$PC_PLATFORM_H"; then
    printf '%s\n' 'missing pc_platform onscreen timer extern contract' >&2
    exit 1
fi

if ! rg -q 'static void draw_pc_onscreen_timer\(void\)' "$PLAY_C"; then
    printf '%s\n' 'missing gameplay onscreen timer draw helper contract' >&2
    exit 1
fi

if ! rg -q 'draw_pc_onscreen_timer\(\);' "$PLAY_C"; then
    printf '%s\n' 'missing gameplay onscreen timer draw call contract' >&2
    exit 1
fi

if ! rg -q 'JW_JUTReport\(24, 24, 1, "T\+%02u:%02u"' "$PLAY_C"; then
    printf '%s\n' 'missing gameplay onscreen timer report format contract' >&2
    exit 1
fi

printf '%s\n' 'check_pc_onscreen_timer_flag_contract: OK'
