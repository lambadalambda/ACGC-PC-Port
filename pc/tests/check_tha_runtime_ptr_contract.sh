#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing THA pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy THA pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/TwoHeadArena.c" 'static uintptr_t THA_alloc_tail_addr\(TwoHeadArena\* this, size_t siz, int mask\)' 'tail allocation helper uses uintptr_t'
check_contains "src/TwoHeadArena.c" 'return \(\(tail_addr - siz\) & \(uintptr_t\)mask\);' 'tail allocation helper keeps host-width math'
check_contains "src/TwoHeadArena.c" 'static uintptr_t THA_align_head_addr\(TwoHeadArena\* this, int mask\)' 'head alignment helper uses uintptr_t'
check_contains "src/TwoHeadArena.c" 'return \(int\)\(\(intptr_t\)this->tail_p - \(intptr_t\)THA_align_head_addr\(this, mask\)\);' 'free byte calculation uses intptr_t diff'
check_contains "src/game/m_play.c" 'alloc = \(uintptr_t\)THA_alloc16\(&game->tha, freebytes\);' 'play arena init uses uintptr_t alloc'
check_contains "src/famicom_emu.c" 'alloc = \(uintptr_t\)THA_alloc16\(&game->tha, freebytes\);' 'famicom arena init uses uintptr_t alloc'

check_absent "src/TwoHeadArena.c" '\(u32\)this->tail_p' 'legacy tail pointer truncation'
check_absent "src/TwoHeadArena.c" '\(int\)this->tail_p - \(mask & \(int\)\(this->head_p \+ ~mask\)\)' 'legacy free byte pointer truncation'
check_absent "src/game/m_play.c" 'alloc = \(u32\)THA_alloc16\(&game->tha, freebytes\);' 'legacy play THA cast'
check_absent "src/famicom_emu.c" 'alloc = \(u32\)THA_alloc16\(&game->tha, freebytes\);' 'legacy famicom THA cast'
