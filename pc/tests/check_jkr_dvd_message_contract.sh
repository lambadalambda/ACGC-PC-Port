#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JKR DVD message contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JKR DVD message pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'static OSMessage JKRDvdFile_ResultMessage\(s32 result\)' 'JKRDvdFile encodes async results through helper'
check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'static s32 JKRDvdFile_ResultValue\(OSMessage msg\)' 'JKRDvdFile decodes async results through helper'
check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'return \(OSMessage\)\(intptr_t\)result;' 'JKRDvdFile helper uses intptr_t to encode async results'
check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'return \(s32\)\(intptr_t\)msg;' 'JKRDvdFile helper uses intptr_t to decode async results'
check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'return JKRDvdFile_ResultValue\(m\);' 'JKRDvdFile sync decodes result through helper'
check_contains "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'OSSendMessage\(&static_cast<JKRDvdFileInfo\*>\(info\)->mFile->mDvdMessageQueue, JKRDvdFile_ResultMessage\(result\),' 'JKRDvdFile callback sends encoded result'

check_absent "src/static/JSystem/JKernel/JKRDvdFile.cpp" 'return \(s32\)\(intptr_t\)m;' 'legacy direct result decode'
check_absent "src/static/JSystem/JKernel/JKRDvdFile.cpp" '\(OSMessage\)result' 'legacy direct result encode'
