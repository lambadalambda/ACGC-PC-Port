#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing emu64 debug pointer-format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy emu64 debug pointer formatting: $label" >&2
        exit 1
    fi
}

check_contains "src/static/libforest/emu64/emu64.c" 'this->Printf0\("%d %p\\n", i, \(void\*\)this->DL_stack\[i\]\);' 'DL stack logging uses %p'

check_absent "src/static/libforest/emu64/emu64.c" '\(u32\)this->DL_stack\[i\]' 'DL stack logging no longer truncates pointers to u32'
check_absent "src/static/libforest/emu64/emu64.c" 'this->Printf0\("%d %08x %08x\\n", i, \(u32\)this->DL_stack\[i\], convert_partial_address\(\(u32\)this->DL_stack\[i\]\)\);' 'legacy DL stack %08x formatter removed'
