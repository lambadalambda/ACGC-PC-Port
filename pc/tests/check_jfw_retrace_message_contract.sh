#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing JFW retrace message contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy JFW retrace message pattern: $label" >&2
        exit 1
    fi
}

check_contains "src/static/JSystem/JUtility/JUTVideo.cpp" 'static OSMessage JUTVideo_retrace_message\(u32 retraceCount\)' 'JUTVideo encodes retrace count through helper'
check_contains "src/static/JSystem/JUtility/JUTVideo.cpp" 'OSSendMessage\(&sManager->mMessageQueue, JUTVideo_retrace_message\(retraceCount\), OS_MESSAGE_NOBLOCK\);' 'JUTVideo sends encoded retrace message'
check_contains "src/static/JSystem/JFramework/JFWDisplay.cpp" 'static u32 JFWDisplay_retrace_message_count\(OSMessage msg\)' 'JFWDisplay decodes retrace message through helper'
check_contains "src/static/JSystem/JFramework/JFWDisplay.cpp" '\(s32\)\(JFWDisplay_retrace_message_count\(msg\) - nextCount\) < 0' 'JFWDisplay compares decoded retrace counts'
check_contains "src/static/JSystem/JFramework/JFWDisplay.cpp" 'nextCount = JFWDisplay_retrace_message_count\(msg\) \+ uVar1;' 'JFWDisplay advances decoded retrace count'

check_absent "src/static/JSystem/JUtility/JUTVideo.cpp" 'OSSendMessage\(&sManager->mMessageQueue, \(void\*\)retraceCount, OS_MESSAGE_NOBLOCK\);' 'legacy raw retrace send cast'
check_absent "src/static/JSystem/JFramework/JFWDisplay.cpp" 'nextCount = \(u32\)\(\(uintptr_t\)msg \+ uVar1\);' 'legacy raw retrace receive decode'
