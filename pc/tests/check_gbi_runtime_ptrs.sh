#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

gbi_obj=$(mktemp "${TMPDIR:-/tmp}/acgc-check-gbi-runtime-ptrs.XXXXXX.o")
trap 'rm -f "$gbi_obj"' EXIT

cc -std=c11 -D_LANGUAGE_C -DTARGET_PC -DPC_EXPERIMENTAL_64BIT -DF3DEX_GBI -I"$REPO_ROOT/include" -I"$REPO_ROOT/pc/include" \
    -Werror=pointer-to-int-cast -Werror=int-to-pointer-cast -Werror=int-conversion -Wno-visibility \
    -c "$SCRIPT_DIR/check_gbi_runtime_ptrs.c" -o "$gbi_obj"
