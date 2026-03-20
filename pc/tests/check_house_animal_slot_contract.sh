#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="$REPO_ROOT/src/actor/ac_house.c"

if ! rg -q '#define aHUS_GET_ANIMAL_P\(h\) \(Save_GetPointer\(animals\[aHUS_GET_ANIMAL_IDX\(h\)\]\)\)' "$FILE"; then
    printf '%s\n' 'missing house animal slot lookup contract' >&2
    exit 1
fi

if rg -q '#define aHUS_SET_ANIMAL_P\(h, v\)' "$FILE"; then
    printf '%s\n' 'legacy house animal pointer setter macro still present' >&2
    exit 1
fi

if rg -q '#define aHUS_GET_ANIMAL_P\(h\) \(\(Animal_c\*\)\(h\)->arg1\)' "$FILE"; then
    printf '%s\n' 'legacy house animal pointer-in-arg1 getter still present' >&2
    exit 1
fi

if rg -q 'aHUS_SET_ANIMAL_P\(house,' "$FILE"; then
    printf '%s\n' 'legacy house animal pointer setter usage still present' >&2
    exit 1
fi
