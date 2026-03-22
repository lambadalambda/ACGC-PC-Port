#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio ARQ pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio ARQ pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/jaudio_NES/internal/heapctrl.c" '#define JAUDIO_ARQ_PTR\(ptr\) pc_aram_host_addr_encode\(ptr\)' 'heapctrl pointer helper'
check_contains "src/static/jaudio_NES/internal/dvdthread.c" '#define JAUDIO_ARQ_PTR\(ptr\) pc_aram_host_addr_encode\(ptr\)' 'dvdthread pointer helper'

check_absent "src/static/jaudio_NES/internal/heapctrl.c" '\(u32\)&msgQueue' 'heapctrl message queue cast'
check_absent "src/static/jaudio_NES/internal/heapctrl.c" '\(u32\)dmabuffer' 'heapctrl dma buffer cast'
check_absent "src/static/jaudio_NES/internal/dvdthread.c" '\(u32\)buf' 'dvdthread buffer cast'
check_absent "src/static/jaudio_NES/internal/dvdthread.c" '\(u32\)call' 'dvdthread call cast'
