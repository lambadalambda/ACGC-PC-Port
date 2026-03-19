#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing memcard pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy memcard pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/game/m_card.c" 'bg_info->data = \(void\*\)\(\(char\*\)data \+ ofs\);' 'memcard background transfer uses char pointer arithmetic'
check_contains "src/game/m_card.c" 'if \(buf != NULL && IS_ALIGNED\(\(uintptr_t\)buf, 32\)\) \{' 'memcard foreground buffer alignment uses uintptr_t'
check_absent "src/game/m_card.c" 'bg_info->data = \(void\*\)\(\(u32\)data \+ ofs\);' 'legacy memcard background transfer cast'
check_absent "src/game/m_card.c" 'if \(buf != NULL && IS_ALIGNED\(\(u32\)buf, 32\)\) \{' 'legacy memcard foreground buffer cast'
