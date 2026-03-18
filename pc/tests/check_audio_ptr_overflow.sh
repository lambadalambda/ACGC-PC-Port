#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

test_bin=$(mktemp "${TMPDIR:-/tmp}/acgc-check-audio-ptr-overflow.XXXXXX")
trap 'rm -f "$test_bin"' EXIT

cc -std=c11 -D_LANGUAGE_C -DTARGET_PC -DPC_EXPERIMENTAL_64BIT -I"$REPO_ROOT/include" -I"$REPO_ROOT/pc/include" \
    "$SCRIPT_DIR/check_audio_ptr_overflow.c" -o "$test_bin"

if "$test_bin"; then
    printf '%s\n' 'expected audio pointer parameter overflow narrowing to abort' >&2
    exit 1
fi
