#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
FILE="pc/src/pc_dvd.c"

check_contains() {
    pattern=$1
    label=$2

    if ! rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "missing pc_dvd bounds contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    pattern=$1
    label=$2

    if rg -q "$pattern" "$REPO_ROOT/$FILE"; then
        printf '%s\n' "unexpected legacy pc_dvd narrowing pattern: $label" >&2
        exit 1
    fi
}

check_contains '#include <limits.h>' 'UINT32_MAX guard include present'
check_contains 'if \(len < 0 \|\| \(unsigned long\)len > UINT32_MAX\)' 'host file length guard prevents overflow into u32'
check_contains 'if \(length < 0 \|\| offset < 0\)' 'DVDReadPrio rejects negative length/offset'

check_absent 'len = \(u32\)ftell\(fp\);' 'legacy unchecked ftell narrowing removed'
