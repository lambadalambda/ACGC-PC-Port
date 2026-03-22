#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JUTGamePadRecordBase contract: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JUtility/JUTGamePad.cpp" 'JUTGamePadRecordBase::JUTGamePadRecordBase\(' 'record base constructor definition'
check_contains "src/static/JSystem/JUtility/JUTGamePad.cpp" 'JUTGamePadRecordBase::~JUTGamePadRecordBase\(' 'record base destructor definition'
