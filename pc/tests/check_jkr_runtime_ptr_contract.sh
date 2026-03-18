#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing checked runtime pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRAram.cpp" '#define JKR_ARAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRAram host address'
check_contains "src/static/JSystem/JKernel/JKRAramStream.cpp" '#define JKR_ARAM_STREAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRAramStream host address'
check_contains "src/static/JSystem/JKernel/JKRDvdAramRipper.cpp" '#define JKR_DVD_ARAM_HOST_ADDR\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDvdAramRipper host address'
check_contains "src/static/JSystem/JKernel/JKRDvdAramRipper.cpp" '#define JKR_DVD_ARAM_CALLBACK_ARG\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDvdAramRipper callback argument'
check_contains "src/static/JSystem/JKernel/JKRDecomp.cpp" '#define JKR_DECOMP_CALLBACK_ARG\(ptr\) PC_RUNTIME_U32_PTR\(ptr\)' 'JKRDecomp callback argument'
