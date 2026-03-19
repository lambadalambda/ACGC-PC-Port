#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing irqmgr message contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy irqmgr message pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/irqmgr.c" 'static OSMessage irqmgr_MessageToken\(u32 token\)' 'irqmgr encodes message tokens through helper'
check_contains "src/irqmgr.c" 'static u32 irqmgr_MessageTokenValue\(OSMessage msg\)' 'irqmgr decodes message tokens through helper'
check_contains "src/irqmgr.c" 'osSetTimer\(&this->timer, MSEC\(400\), 0, &this->_msgQueue, irqmgr_MessageToken\(IRQ_PRENMI450_MSG\)\);' 'irqmgr pre-NMI timer uses encoded token'
check_contains "src/irqmgr.c" 'osViSetEvent\(&this->_msgQueue, irqmgr_MessageToken\(IRQ_RETRACE_MSG\), retracecount\);' 'irqmgr retrace event uses encoded token'
check_contains "src/irqmgr.c" 'switch \(irqmgr_MessageTokenValue\(msg\)\) \{' 'irqmgr main loop switches on decoded token'

check_absent "src/irqmgr.c" 'switch \(\(u32\)msg\) \{' 'legacy raw message switch cast'
check_absent "src/irqmgr.c" '\(OSMessage\)IRQ_PRENMI450_MSG' 'legacy pre-NMI message cast'
check_absent "src/irqmgr.c" '\(OSMessage\)IRQ_PRENMI480_MSG' 'legacy delayed pre-NMI message cast'
check_absent "src/irqmgr.c" '\(OSMessage\)IRQ_PRENMI500_MSG' 'legacy final pre-NMI message cast'
check_absent "src/irqmgr.c" '\(OSMessage\)IRQ_RETRACE_MSG' 'legacy retrace event cast'
