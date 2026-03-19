#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing submenu overlay pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy submenu overlay pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/game/m_submenu_ovl.c" 'submenu->next_overlay_address = \(char\*\)ALIGN_NEXT\(\(uintptr_t\)dlftbl->seg_end - \(uintptr_t\)dlftbl->seg_start, 64\);' 'submenu overlay size uses uintptr_t'
check_contains "src/game/m_catalog_ovl.c" '\(u8\*\)ALIGN_NEXT\(\(uintptr_t\)overlay->catalog_ovl->item_data\[i\]\.segment_data, 32\);' 'catalog overlay segment alignment uses uintptr_t'

check_absent "src/game/m_submenu_ovl.c" 'submenu->next_overlay_address = \(char\*\)ALIGN_NEXT\(\(u32\)dlftbl->seg_end - \(u32\)dlftbl->seg_start, 64\);' 'legacy submenu overlay size cast'
check_absent "src/game/m_catalog_ovl.c" '\(u8\*\)ALIGN_NEXT\(\(u32\)overlay->catalog_ovl->item_data\[i\]\.segment_data, 32\);' 'legacy catalog overlay alignment cast'
