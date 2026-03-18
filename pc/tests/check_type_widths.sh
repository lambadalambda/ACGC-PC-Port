#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

types_obj=$(mktemp "${TMPDIR:-/tmp}/acgc-check-types-widths.XXXXXX.o")
pc_types_obj=$(mktemp "${TMPDIR:-/tmp}/acgc-check-pc-types-widths.XXXXXX.o")
trap 'rm -f "$types_obj" "$pc_types_obj"' EXIT

cc -std=c11 -DTARGET_PC -I"$REPO_ROOT/include" -c "$SCRIPT_DIR/check_types_widths.c" -o "$types_obj"
cc -std=c11 -DTARGET_PC -I"$REPO_ROOT/pc/include" -c "$SCRIPT_DIR/check_pc_types_widths.c" -o "$pc_types_obj"
