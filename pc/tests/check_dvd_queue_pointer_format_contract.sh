#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing DVD queue pointer-format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy DVD queue pointer formatting: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/dvd/dvdqueue.c" 'OSReport\("%p: Command: %s ", \(void\*\)q, CommandNames\[q->command\]\);' 'queue block pointer uses %p'
check_contains "src/static/dolphin/dvd/dvdqueue.c" 'OSReport\("Disk offset: %d, Length: %d, Addr: %p\\n", q->offset, q->length, q->addr\);' 'command address uses %p'

check_absent "src/static/dolphin/dvd/dvdqueue.c" 'OSReport\("0x%08x: Command: %s ", q, CommandNames\[q->command\]\);' 'legacy queue block %08x format removed'
check_absent "src/static/dolphin/dvd/dvdqueue.c" 'OSReport\("Disk offset: %d, Length: %d, Addr: 0x%08x\\n", q->offset, q->length, q->addr\);' 'legacy command addr %08x format removed'
