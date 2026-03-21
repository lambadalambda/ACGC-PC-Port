#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
EMU64_FILE="$REPO_ROOT/src/static/libforest/emu64/emu64.c"
UTILITY_FILE="$REPO_ROOT/src/static/libforest/emu64/emu64_utility.c"

if ! rg -q 'now_setimg\.setimg2\.imgaddr\s*=\s*this->seg2k0\(setimg2->imgaddr\)\s*;' "$EMU64_FILE"; then
    printf '%s\n' 'missing emu64 setimg seg2k0 cast cleanup contract' >&2
    exit 1
fi

if rg -q 'now_setimg\.setimg2\.imgaddr = \(u32\)this->seg2k0\(setimg2->imgaddr\);' "$EMU64_FILE"; then
    printf '%s\n' 'legacy emu64 setimg u32 cast still present' >&2
    exit 1
fi

if ! rg -q 'u32\s+resolved\s*=\s*this->segments\[seg\]\s*\+\s*offset\s*;' "$UTILITY_FILE"; then
    printf '%s\n' 'missing emu64 utility resolved segment cast cleanup contract' >&2
    exit 1
fi

if rg -q 'u32 resolved = \(u32\)this->segments\[seg\] \+ offset;' "$UTILITY_FILE"; then
    printf '%s\n' 'legacy emu64 utility resolved segment u32 cast still present' >&2
    exit 1
fi

if ! rg -q 'k0\s*=\s*this->segments\[\(segadr >> 24\) & 0xF\]\s*\+\s*\(segadr & 0xFFFFFF\)\s*;' "$UTILITY_FILE"; then
    printf '%s\n' 'missing emu64 utility k0 segment cast cleanup contract' >&2
    exit 1
fi

if rg -q 'k0 = \(u32\)this->segments\[\(segadr >> 24\) & 0xF\] \+ \(segadr & 0xFFFFFF\);' "$UTILITY_FILE"; then
    printf '%s\n' 'legacy emu64 utility k0 u32 cast still present' >&2
    exit 1
fi
