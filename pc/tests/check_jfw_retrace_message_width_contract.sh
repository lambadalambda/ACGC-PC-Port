#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JFW retrace message width contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JFW retrace message cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JFramework/JFWDisplay.cpp" '#include "pc_runtime_ptr.h"' 'JFWDisplay uses runtime checked narrowing helper'
check_contains "src/static/JSystem/JFramework/JFWDisplay.cpp" 'return PC_RUNTIME_U32_PTR\(msg\);' 'retrace message decode uses checked narrowing'

check_absent "src/static/JSystem/JFramework/JFWDisplay.cpp" 'return \(u32\)\(uintptr_t\)msg;' 'legacy retrace message decode cast removed'
