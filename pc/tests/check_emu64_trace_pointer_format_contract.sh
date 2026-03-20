#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing emu64 trace pointer-format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy emu64 trace pointer format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/libforest/emu64/emu64.c" 'EMU64_INFOF\("%p:", \(void\*\)this->gfx_p\);' 'command trace prints gfx_p with %p'

check_absent "src/static/libforest/emu64/emu64.c" 'EMU64_INFOF\("%08x:", this->gfx_p\);' 'legacy gfx_p %08x trace removed'
