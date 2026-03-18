#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio bank pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio bank pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/channel.c" '#define JAUDIO_U32_ADDR_PTR\(type, value\) \(\(type\*\)\(uintptr_t\)\(u32\)\(value\)\)' 'channel bank pointer reconstruction helper'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.percussion\[idx\] = JAUDIO_U32_ADDR_PTR\(perctable, table\);' 'channel percussion bank pointer'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.effects\[idx\] = \*JAUDIO_U32_ADDR_PTR\(percvoicetable, table\);' 'channel effects bank pointer'
check_contains "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.instruments\[idx\] = JAUDIO_U32_ADDR_PTR\(voicetable, table\);' 'channel instrument bank pointer'

check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.percussion\[idx\] = \(perctable\*\)table;' 'legacy channel percussion cast'
check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.effects\[idx\] = \*\(percvoicetable\*\)table;' 'legacy channel effects cast'
check_absent "src/static/jaudio_NES/internal/channel.c" 'AG.voice_info\[bankId\]\.instruments\[idx\] = \(voicetable\*\)table;' 'legacy channel instrument cast'
