#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JUTConsole pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JUTConsole pointer pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JUtility/JUTConsole.cpp" 'JUT_ASSERT\(\(\(\(uintptr_t\)buffer & 0x3u\)\) == 0\);' 'JUTConsole buffer alignment assert uses uintptr_t'
check_absent "src/static/JSystem/JUtility/JUTConsole.cpp" 'JUT_ASSERT\(\( \(u32\)buffer & 0x3 \) == 0\);' 'legacy JUTConsole buffer alignment cast'
