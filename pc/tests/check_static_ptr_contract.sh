#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

contract_obj=$(mktemp "${TMPDIR:-/tmp}/acgc-check-static-ptr-contract.XXXXXX.o")
trap 'rm -f "$contract_obj"' EXIT

cc -std=c11 -D_LANGUAGE_C -DTARGET_PC -DPC_EXPERIMENTAL_64BIT -I"$REPO_ROOT/include" -I"$REPO_ROOT/pc/include" \
    -Werror=pointer-to-int-cast -Werror=int-conversion \
    -c "$SCRIPT_DIR/check_static_ptr_contract.c" -o "$contract_obj"
