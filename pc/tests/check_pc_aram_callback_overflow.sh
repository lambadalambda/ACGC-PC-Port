#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
SDL_CFLAGS=$(pkg-config --cflags sdl2)

test_bin=$(mktemp "${TMPDIR:-/tmp}/acgc-check-pc-aram-callback-overflow.XXXXXX")
trap 'rm -f "$test_bin"' EXIT

cc -std=c11 -D_LANGUAGE_C -DTARGET_PC -DPC_EXPERIMENTAL_64BIT -I"$REPO_ROOT/include" -I"$REPO_ROOT/pc/include" \
    -I"$REPO_ROOT/pc/lib/glad/include" $SDL_CFLAGS \
    "$SCRIPT_DIR/check_pc_aram_callback_overflow.c" "$REPO_ROOT/pc/src/pc_aram.c" -o "$test_bin"

set +e
"$test_bin" >/dev/null 2>&1
status=$?
set -e

if [ "$status" -eq 0 ]; then
    printf '%s\n' 'expected ARQPostRequest overflow narrowing to abort' >&2
    exit 1
fi
