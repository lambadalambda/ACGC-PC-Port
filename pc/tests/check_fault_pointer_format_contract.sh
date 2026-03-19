#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing fault pointer format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy fault pointer format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/libforest/fault.c" 'OSReport\(VT_COL\(RED, WHITE\) "fault_AddClient: %p は既にリスト中にある\\n" VT_RST, \(void\*\)client\);' 'fault add-client report uses %p'
check_contains "src/static/libforest/fault.c" 'fault_Printf\("CallBack \(%d/%d\) %p %p %08x\\n", index\+\+, this->num_clients, \(void\*\)client,' 'fault callback report uses %p for client pointers'

check_absent "src/static/libforest/fault.c" 'OSReport\(VT_COL\(RED, WHITE\) "fault_AddClient: %08x は既にリスト中にある\\n" VT_RST, client\);' 'legacy add-client pointer format'
check_absent "src/static/libforest/fault.c" 'fault_Printf\("CallBack \(%d/%d\) %08x %08x %08x\\n", index\+\+, this->num_clients, client, client->msg, client->param\);' 'legacy callback pointer format'
