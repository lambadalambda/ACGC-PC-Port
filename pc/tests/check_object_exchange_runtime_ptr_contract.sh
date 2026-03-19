#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing object exchange pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy object exchange pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/m_scene.h" 'static inline char\* mSc_align_next_bank_ram_address\(char\* addr, size_t size, u32 align\)' 'shared bank address helper'
check_contains "include/m_scene.h" 'return \(char\*\)ALIGN_NEXT\(\(uintptr_t\)addr \+ size, align\);' 'shared bank address helper uses uintptr_t'
check_contains "src/game/m_scene.c" 'area = mSc_align_next_bank_ram_address\(exchange->next_bank_ram_address, size, 32\);' 'secure exchange keep bank uses helper'
check_contains "src/game/m_scene.c" 'size = \(u32\)\(\(\(uintptr_t\)play->object_exchange.max_ram_address -' 'initial exchange remaining size uses uintptr_t'
check_contains "src/game/m_scene.c" 'mSc_align_next_bank_ram_address\(play->object_exchange.next_bank_ram_address, size, 32\);' 'initial exchange partition end uses helper'
check_contains "src/game/m_scene.c" 'char\* area = mSc_align_next_bank_ram_address\(exchange->next_bank_ram_address, bank->size, 32\);' 'exchange bank dma copy uses helper'
check_contains "src/game/m_scene_ftr.c" 'exchange->next_bank_ram_address = mSc_align_next_bank_ram_address\(exchange->next_bank_ram_address, size, 16\);' 'room bank allocator uses helper'
check_contains "src/game/m_player_lib.c" 'obj_ex->next_bank_ram_address = mSc_align_next_bank_ram_address\(obj_ex->next_bank_ram_address, size, 32\);' 'player bank allocator uses helper'

check_absent "src/game/m_scene.c" 'area = \(char\*\)ALIGN_NEXT\(\(u32\)exchange->next_bank_ram_address \+ size, 32\);' 'legacy secure exchange cast'
check_absent "src/game/m_scene.c" 'size = \(u32\)\(play->object_exchange.max_ram_address - play->object_exchange.next_bank_ram_address\) / 2;' 'legacy initial exchange pointer diff'
check_absent "src/game/m_scene.c" '\(char\*\)ALIGN_NEXT\(\(u32\)play->object_exchange.next_bank_ram_address \+ size, 32\);' 'legacy initial partition end cast'
check_absent "src/game/m_scene.c" 'char\* area = \(char\*\)ALIGN_NEXT\(\(u32\)exchange->next_bank_ram_address \+ bank->size, 32\);' 'legacy exchange dma copy cast'
check_absent "src/game/m_scene_ftr.c" 'exchange->next_bank_ram_address = \(char\*\)ALIGN_NEXT\(\(u32\)exchange->next_bank_ram_address \+ size, 16\);' 'legacy room bank cast'
check_absent "src/game/m_player_lib.c" 'obj_ex->next_bank_ram_address = \(char\*\)ALIGN_NEXT\(\(u32\)obj_ex->next_bank_ram_address \+ size, 32\);' 'legacy player bank cast'
