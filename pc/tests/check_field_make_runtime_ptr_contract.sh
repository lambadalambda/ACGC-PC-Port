#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing field make pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy field make pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/game/m_field_make.c" 'fg_data_p = \(mFM_fg_data_c\*\)\(ALIGN_NEXT\(\(uintptr_t\)gamealloc_data_p, 32\)\);' 'field data alignment uses uintptr_t'
check_contains "src/game/m_field_make.c" 'fgnpc_data_p = \(mFM_fg_data_c\*\)\(ALIGN_NEXT\(\(uintptr_t\)gamealloc_data_p, 32\)\);' 'field npc data alignment uses uintptr_t'
check_contains "src/game/m_field_make.c" 'field_info->bg_display_list_p\[i\] = \(u8\*\)ALIGN_NEXT\(\(uintptr_t\)field_info->bg_display_list_p\[i\], 16\);' 'background display list alignment uses uintptr_t'

check_absent "src/game/m_field_make.c" 'fg_data_p = \(mFM_fg_data_c\*\)\(ALIGN_NEXT\(\(u32\)gamealloc_data_p, 32\)\);' 'legacy field data alignment cast'
check_absent "src/game/m_field_make.c" 'fgnpc_data_p = \(mFM_fg_data_c\*\)\(ALIGN_NEXT\(\(u32\)gamealloc_data_p, 32\)\);' 'legacy field npc data alignment cast'
check_absent "src/game/m_field_make.c" 'field_info->bg_display_list_p\[i\] = \(u8\*\)\(\(u32\)\(field_info->bg_display_list_p\[i\]\) \+ \(16 - 1\)\);' 'legacy background display list alignment add cast'
check_absent "src/game/m_field_make.c" 'field_info->bg_display_list_p\[i\] = \(u8\*\)\(\(u32\)\(field_info->bg_display_list_p\[i\]\) & \(~\(16 - 1\)\)\);' 'legacy background display list alignment mask cast'
