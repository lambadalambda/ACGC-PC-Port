#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/game/m_scene.c"

if ! rg -q '#include "pc_runtime_ptr.h"' "$FILE"; then
    printf '%s\n' 'missing m_scene runtime narrowing helper include' >&2
    exit 1
fi

if ! rg -q 'size\s*=\s*PC_RUNTIME_U32_PTR\(' "$FILE"; then
    printf '%s\n' 'missing m_scene object-exchange size checked narrowing contract' >&2
    exit 1
fi

if ! rg -q 'play->object_exchange.max_ram_address\s*-\s*' "$FILE"; then
    printf '%s\n' 'missing m_scene max/next exchange range expression contract' >&2
    exit 1
fi

if rg -q 'size\s*=\s*\(u32\)\s*\(' "$FILE"; then
    printf '%s\n' 'legacy m_scene direct u32 narrowing cast still present' >&2
    exit 1
fi
