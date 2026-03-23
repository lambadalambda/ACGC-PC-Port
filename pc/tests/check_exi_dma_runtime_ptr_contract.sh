#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing EXI DMA pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy EXI DMA pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/exi/EXIBios.c" '#include "pc_runtime_ptr.h"' 'EXIBios includes runtime checked narrowing helper'
check_contains "src/static/dolphin/exi/EXIBios.c" '__EXIRegs\[\(chan \* 5\) \+ 1\] = PC_RUNTIME_U32_PTR\(buf\) & 0x03FFFFE0;' 'EXIDma register write uses checked narrowing'
check_contains "src/static/dolphin/exi/EXIBios.c" 'if \(exi->tcCallback != NULL\)' 'EXIDma callback check avoids pointer truncation cast'

check_absent "src/static/dolphin/exi/EXIBios.c" '__EXIRegs\[\(chan \* 5\) \+ 1\] = \(u32\)buf & 0x03FFFFE0;' 'legacy EXIDma raw pointer cast'
check_absent "src/static/dolphin/exi/EXIBios.c" 'if \(\(u32\)exi->tcCallback\)' 'legacy EXIDma callback pointer cast'
