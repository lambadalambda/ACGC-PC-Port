#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/pc/src/pc_card.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing pc_card bounds contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    pattern=$1
    label=$2

    if rg -q "$pattern" "$FILE"; then
        printf '%s\n' "unexpected legacy pc_card pattern: $label" >&2
        exit 1
    fi
}

check_contains 'file_len = ftell\(slot->fp\);' 'CARDOpen/CARDCreate capture host file length before narrowing'
check_contains 'if \(file_len < 0 \|\| file_len > 0x7fffffffL\)' 'CARDOpen/CARDCreate guard ftell range before s32 store'
check_contains 'if \(length < 0 \|\| offset < 0\) return CARD_RESULT_IOERROR;' 'CARDRead/CARDWrite reject negative ranges'
check_contains 'if \(fseek\(slot->fp, offset, SEEK_SET\) != 0\) return CARD_RESULT_IOERROR;' 'CARDRead/CARDWrite reject invalid seek offsets'

check_absent 'fileInfo->length = \(s32\)ftell\(slot->fp\);' 'legacy unchecked ftell narrowing removed from CARDOpen'
