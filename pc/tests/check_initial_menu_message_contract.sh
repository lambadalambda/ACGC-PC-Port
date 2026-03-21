#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing initial_menu message contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy initial_menu pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/static/initial_menu.c" 'static OSMessage initial_menu_MessageToken\(u32 token\)' 'initial_menu encodes message tokens through helper'
check_contains "src/static/initial_menu.c" 'static u32 initial_menu_MessageTokenValue\(OSMessage msg\)' 'initial_menu decodes message tokens through helper'
check_contains "src/static/initial_menu.c" 'OSMessage msg;' 'initial_menu uses OSMessage payload storage'
check_contains "src/static/initial_menu.c" 'initial_menu_MessageTokenValue\(msg\) == INITIAL_MENU_OSMESG_FADEOUT_STEP' 'initial_menu compares decoded fadeout token'
check_contains "src/static/initial_menu.c" 'osSendMesg\(&commandQ, initial_menu_MessageToken\(INITIAL_MENU_OSMESG_INIT_DONE\), OS_MESSAGE_NOBLOCK\);' 'initial_menu sends encoded init token'
check_contains "src/static/initial_menu.c" 'osSendMesg\(&commandQ, initial_menu_MessageToken\(INITIAL_MENU_OSMESG_LOAD_GAME_DONE\), OS_MESSAGE_NOBLOCK\);' 'initial_menu sends encoded load-game token'
check_contains "src/static/initial_menu.c" 'osCreateThread2\(Thread_p, 1, &proc, NULL, \(u8\*\)initialMenuStack \+ INITIAL_MENU_STACK_SIZE, INITIAL_MENU_STACK_SIZE,' 'initial_menu stack end uses pointer-width arithmetic'
check_contains "src/static/initial_menu.c" 'make_dl_nintendo_logo\(&g, 255\);' 'initial menu logo draw is built with runtime pointer-safe commands'
check_contains "src/static/initial_menu.c" 'gSPDisplayList\(g\+\+, SEGMENT_ADDR\(8, 0\)\);' 'initial menu step rendering uses segmented runtime display-list calls'
check_contains "src/static/initial_menu.c" 'gSPDisplayList\(g\+\+, initial_dl\);' 'initial menu step rendering emits initial state display list at runtime'

check_absent "src/static/initial_menu.c" 'osRecvMesg\(&commandQ, \(OSMessage\*\)&msg, OS_MESSAGE_BLOCK\);' 'legacy blocking receive cast'
check_absent "src/static/initial_menu.c" 'osRecvMesg\(&commandQ, \(OSMessage\*\)&msg, OS_MESSAGE_NOBLOCK\);' 'legacy nonblocking receive cast'
check_absent "src/static/initial_menu.c" '\(OSMessage\)INITIAL_MENU_OSMESG_FADEOUT_STEP' 'legacy fadeout token cast'
check_absent "src/static/initial_menu.c" '\(OSMessage\)INITIAL_MENU_OSMESG_INIT_DONE' 'legacy init token cast'
check_absent "src/static/initial_menu.c" '\(OSMessage\)INITIAL_MENU_OSMESG_LOAD_GAME_DONE' 'legacy load-game token cast'
check_absent "src/static/initial_menu.c" '\(void\*\)\(\(int\)initialMenuStack \+ INITIAL_MENU_STACK_SIZE\)' 'legacy stack pointer truncation'
check_absent "src/static/initial_menu.c" 'static Gfx logo_draw_dl\[\]' 'legacy static logo draw display list removed'
check_absent "src/static/initial_menu.c" 'static Gfx step1_draw_dl\[\]' 'legacy static step1 draw display list removed'
check_absent "src/static/initial_menu.c" 'static Gfx step2_draw_dl\[\]' 'legacy static step2 draw display list removed'
check_absent "src/static/initial_menu.c" 'gSPDisplayList\(g\+\+, step1_draw_dl\);' 'legacy step1 static display list dispatch removed'
check_absent "src/static/initial_menu.c" 'gSPDisplayList\(g\+\+, step2_draw_dl\);' 'legacy step2 static display list dispatch removed'
