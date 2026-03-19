#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing mail pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy mail pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/game/m_mail.c" 'u8\* end_p = str \+ size;' 'mail end pointer uses byte pointer arithmetic'
check_contains "src/game/m_mail.c" 'if \(\*end_p != end_char\) \{' 'mail terminator check dereferences byte pointer directly'

check_absent "src/game/m_mail.c" 'u32 end_p = size \+ \(u32\)str;' 'legacy mail end pointer cast'
check_absent "src/game/m_mail.c" 'if \(\*\(u8\*\)end_p != end_char\) \{' 'legacy mail dereference cast'
