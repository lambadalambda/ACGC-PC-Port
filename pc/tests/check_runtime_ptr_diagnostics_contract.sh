#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/include/pc_runtime_ptr.h"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$FILE"; then
        printf '%s\n' "missing runtime pointer diagnostics contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    pattern=$1
    label=$2

    if rg -q "$pattern" "$FILE"; then
        printf '%s\n' "unexpected legacy runtime pointer contract: $label" >&2
        exit 1
    fi
}

check_contains 'pc_runtime_u32_ptr_checked_at\(uintptr_t value, const char\* expr, const char\* file, int line\)' 'checked helper records expression and callsite'
check_contains '\[PC\]\[LP64\] PC_RUNTIME_U32_PTR overflow:' 'overflow path emits LP64 diagnostic marker'
check_contains '#define PC_RUNTIME_U32_PTR\(value\) pc_runtime_u32_ptr_checked_at\(\(uintptr_t\)\(value\), #value, __FILE__, __LINE__\)' 'macro passes expression and source location'

check_absent 'pc_runtime_u32_ptr_checked\(uintptr_t value\)' 'legacy helper signature removed'
