#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing EXI UART pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy EXI UART pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/exi/EXIUart.c" 'start = \(char\*\)buf;' 'uart buffer start uses host pointer'
check_contains "src/static/dolphin/exi/EXIUart.c" 'while \(ptr - start < len\) \{' 'uart newline scan uses pointer diff'

check_absent "src/static/dolphin/exi/EXIUart.c" 'while \(\(u32\)ptr - \(u32\)buf < len\) \{' 'legacy uart pointer truncation'
