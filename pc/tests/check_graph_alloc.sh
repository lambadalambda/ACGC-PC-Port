#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

graph_bin=$(mktemp "${TMPDIR:-/tmp}/acgc-check-graph-alloc.XXXXXX")
trap 'rm -f "$graph_bin"' EXIT

cc -std=c11 -D_LANGUAGE_C -DTARGET_PC -DPC_EXPERIMENTAL_64BIT -I"$REPO_ROOT/include" -I"$REPO_ROOT/pc/include" \
    -Werror=pointer-to-int-cast -Werror=int-to-pointer-cast -Werror=int-conversion \
    "$SCRIPT_DIR/check_graph_alloc.c" -o "$graph_bin"

"$graph_bin"
