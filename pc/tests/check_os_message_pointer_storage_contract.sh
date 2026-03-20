#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing OSMessage pointer-storage contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy OSMessage pointer truncation: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/os/OSMessage.c" 'mq->msgArray\[lastIndex\] = msg;' 'OSSendMessage stores OSMessage directly'
check_contains "src/static/dolphin/os/OSMessage.c" '\*msg = mq->msgArray\[mq->firstIndex\];' 'OSReceiveMessage loads OSMessage directly'
check_contains "src/static/dolphin/os/OSMessage.c" 'mq->msgArray\[mq->firstIndex\] = msg;' 'OSJamMessage stores OSMessage directly'

check_absent "src/static/dolphin/os/OSMessage.c" '\(\(u32\*\)mq->msgArray\)\[lastIndex\] = \(u32\)msg;' 'legacy OSSendMessage u32 storage cast'
check_absent "src/static/dolphin/os/OSMessage.c" '\*\(u32\*\)msg = \(\(u32\*\)mq->msgArray\)\[mq->firstIndex\];' 'legacy OSReceiveMessage u32 load cast'
check_absent "src/static/dolphin/os/OSMessage.c" '\(\(u32\*\)mq->msgArray\)\[mq->firstIndex\] = \(u32\)msg;' 'legacy OSJamMessage u32 storage cast'
