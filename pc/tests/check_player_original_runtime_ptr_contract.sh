#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing player original pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy player original pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/m_player_lib.h" 'extern uintptr_t mPlib_Get_PlayerTexRom_p\(int idx\);' 'player texture accessor uses uintptr_t'
check_contains "include/m_player_lib.h" 'extern uintptr_t mPlib_Get_PlayerPalletRom_p\(int idx\);' 'player palette accessor uses uintptr_t'
check_contains "src/game/m_player_lib.c" 'static int mPlib_Object_Exchange_keep_new\(GAME_PLAY\* play, s16 bank, uintptr_t src, u32 size, int aram_flag\)' 'object exchange helper uses uintptr_t source'
check_contains "src/game/m_player_lib.c" 'return \(uintptr_t\)Now_Private->my_org\[org_idx & 7\]\.design\.data;' 'player texture host pointer uses uintptr_t'
check_contains "src/game/m_player_lib.c" 'return \(uintptr_t\)mNW_PaletteIdx2Palette\(Now_Private->my_org\[org_idx & 7\]\.palette\);' 'player palette host pointer uses uintptr_t'
check_contains "src/game/m_player_lib.c" 'bcopy\(\(const void\*\)player_tex_rom_p, player_tex_p, mNW_DESIGN_TEX_SIZE\);' 'player texture copy uses host pointer width'
check_contains "src/game/m_player_lib.c" 'bcopy\(\(const void\*\)player_pallet_rom_p, player_pallet_p, mNW_PALETTE_SIZE\);' 'player palette copy uses host pointer width'

check_absent "include/m_player_lib.h" 'extern u32 mPlib_Get_PlayerTexRom_p\(int idx\);' 'legacy texture accessor u32 return'
check_absent "include/m_player_lib.h" 'extern u32 mPlib_Get_PlayerPalletRom_p\(int idx\);' 'legacy palette accessor u32 return'
check_absent "src/game/m_player_lib.c" 'return \(u32\)Now_Private->my_org\[org_idx & 7\]\.design\.data;' 'legacy texture pointer truncation'
check_absent "src/game/m_player_lib.c" 'return \(u32\)mNW_PaletteIdx2Palette\(Now_Private->my_org\[org_idx & 7\]\.palette\);' 'legacy palette pointer truncation'
