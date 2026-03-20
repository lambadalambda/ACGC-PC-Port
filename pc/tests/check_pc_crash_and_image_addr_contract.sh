#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing PC crash/image address contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy PC crash/image address code: $label" >&2
        exit 1
    fi
}

check_contains "pc/include/pc_platform.h" 'uintptr_t pc_crash_get_addr\(void\);' 'crash address getter uses uintptr_t'
check_contains "pc/include/pc_platform.h" 'uintptr_t pc_crash_get_data_addr\(void\);' 'crash data getter uses uintptr_t'
check_contains "pc/include/pc_platform.h" 'extern uintptr_t pc_image_base;' 'image base uses uintptr_t'
check_contains "pc/include/pc_platform.h" 'extern uintptr_t pc_image_end;' 'image end uses uintptr_t'

check_contains "pc/src/pc_main.c" 'uintptr_t pc_image_base = 0;' 'pc_main image base definition uses uintptr_t'
check_contains "pc/src/pc_main.c" 'uintptr_t pc_image_end  = 0;' 'pc_main image end definition uses uintptr_t'
check_contains "pc/src/pc_main.c" 'static uintptr_t pc_get_image_end\(const void\* image_base\)' 'image end helper returns uintptr_t'
check_contains "pc/src/pc_main.c" 'static volatile uintptr_t pc_last_crash_addr = 0;' 'last crash addr uses uintptr_t'
check_contains "pc/src/pc_main.c" 'static volatile uintptr_t pc_last_crash_data_addr = 0;' 'last crash data addr uses uintptr_t'
check_absent "pc/src/pc_main.c" '\(unsigned int\)\(uintptr_t\)' 'legacy unsigned int narrowing cast removed from pc_main'

check_contains "src/static/libforest/emu64/emu64_utility.c" 'extern "C" uintptr_t pc_image_base;' 'emu64 image base extern uses uintptr_t'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'extern "C" uintptr_t pc_image_end;' 'emu64 image end extern uses uintptr_t'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'if \(\(uintptr_t\)segadr >= pc_image_base && \(uintptr_t\)segadr < pc_image_end\)' 'seg2k0 image-range comparison widens segmented address explicitly'

check_contains "src/graph.c" 'printf\("\[PC\] CRASH in sAdo_GameFrame! addr=%p data=%p\\n",' 'graph crash log prints pointer-safe addresses'
check_contains "src/game.c" 'printf\("\[PC\] CRASH in game exec! doing_point=%d specific=0x%02X addr=%p data=%p\\n",' 'game crash log prints pointer-safe addresses'

check_absent "src/graph.c" 'addr=0x%08X data=0x%08X' 'graph legacy 32-bit crash printf removed'
check_absent "src/game.c" 'addr=0x%08X data=0x%08X' 'game legacy 32-bit crash printf removed'
