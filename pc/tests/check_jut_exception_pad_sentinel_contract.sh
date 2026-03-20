#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JUTException pad sentinel contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JUTException pad sentinel: $label" >&2
        exit 1
    fi
}

check_contains "include/JSystem/JUtility/JUTException.h" 'setGamePad\(\(JUTGamePad\*\)-1\);' 'enterAllPad uses all-ones pointer sentinel'
check_contains "src/static/JSystem/JUtility/JUTException.cpp" 'if \(mGamePad == \(JUTGamePad\*\)-1\)' 'isEnablePad compares with all-ones sentinel'
check_contains "src/static/JSystem/JUtility/JUTException.cpp" 'if \(mGamePad == \(JUTGamePad\*\)-1\) \{' 'readPad compares with all-ones sentinel'

check_absent "src/static/JSystem/JUtility/JUTException.cpp" '\(JUTGamePad\*\)0xFFFFFFFF' 'legacy uppercase 32-bit sentinel removed'
check_absent "src/static/JSystem/JUtility/JUTException.cpp" '\(JUTGamePad\*\)0xffffffff' 'legacy lowercase 32-bit sentinel removed'
