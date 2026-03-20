#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/static/jaudio_NES/internal/system.c"

if ! rg -q 'DMA Warning: SrcAddr %p is not align32\\n", \(void\*\)SrcAddr' "$FILE"; then
    printf '%s\n' 'missing jaudio fastcopy SrcAddr pointer format contract' >&2
    exit 1
fi

if ! rg -q 'DMA Warning: Length  %lu is not align32\\n", \(unsigned long\)Length' "$FILE"; then
    printf '%s\n' 'missing jaudio fastcopy length width format contract' >&2
    exit 1
fi

if ! rg -q 'DMA Warning: DestAdd %p is not align32\\n", \(void\*\)DestAdd' "$FILE"; then
    printf '%s\n' 'missing jaudio fastcopy DestAdd pointer format contract' >&2
    exit 1
fi

if rg -q 'DMA Warning: SrcAddr %d is not align32\\n", SrcAddr' "$FILE"; then
    printf '%s\n' 'legacy jaudio fastcopy SrcAddr integer format still present' >&2
    exit 1
fi

if rg -q 'DMA Warning: Length  %d is not align32\\n", Length' "$FILE"; then
    printf '%s\n' 'legacy jaudio fastcopy length integer format still present' >&2
    exit 1
fi

if rg -q 'DMA Warning: DestAdd %d is not align32\\n", DestAdd' "$FILE"; then
    printf '%s\n' 'legacy jaudio fastcopy DestAdd integer format still present' >&2
    exit 1
fi
