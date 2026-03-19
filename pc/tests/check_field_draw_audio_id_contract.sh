#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing field draw audio id contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy field draw audio id pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/actor/ac_field_draw.c" 'aFD_ONGEN_TOKEN_BASE = 0x41460000,' 'field draw defines a stable audio token base'
check_contains "src/actor/ac_field_draw.c" 'aFD_ONGEN_TOKEN_FROG = 0x4146FFFE,' 'field draw defines a stable frog audio token'
check_contains "src/actor/ac_field_draw.c" 'aFD_ONGEN_TOKEN_POND = 0x4146FFFF,' 'field draw defines a stable pond audio token'
check_contains "src/actor/ac_field_draw.c" 'static u32 aFD_make_ongen_token\(int bx, int bz, int sound_source_no\)' 'field draw derives deterministic audio tokens'
check_contains "src/actor/ac_field_draw.c" 'u32 ongen_id = aFD_make_ongen_token\(info->bx, info->bz, info->sound_source_no\);' 'field draw block audio uses deterministic token'
check_contains "src/actor/ac_field_draw.c" 'sAdo_OngenPos\(aFD_ONGEN_TOKEN_FROG, 0xA1, &frog_se_pos\);' 'field draw frog audio uses stable token'
check_contains "src/actor/ac_field_draw.c" 'sAdo_OngenPos\(aFD_ONGEN_TOKEN_POND, 0x16, &pond_pos\);' 'field draw pond audio uses stable token'

check_absent "src/actor/ac_field_draw.c" 'u32 ongen_id = \(u32\)actorx \+' 'legacy field draw actor pointer audio id'
check_absent "src/actor/ac_field_draw.c" 'sAdo_OngenPos\(\(u32\)&Bg_Draw_Actor_move, 0xA1, &frog_se_pos\);' 'legacy frog audio pointer token'
check_absent "src/actor/ac_field_draw.c" 'sAdo_OngenPos\(\(u32\)&Bg_Draw_Actor_ct, 0x16, &pond_pos\);' 'legacy pond audio pointer token'
