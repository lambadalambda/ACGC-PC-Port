#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing exception pointer format contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy exception pointer format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/dolphin/os/OSContext.c" 'OSReport\("------------------------- Context %p -------------------------\\n", \(void\*\)context\);' 'OSDumpContext header uses %p'
check_contains "src/static/dolphin/os/OSContext.c" 'for \(i = 0, p = \(u32\*\)context->gpr\[1\]; p && \(uintptr_t\)p != \(uintptr_t\)0xffffffffu && i\+\+ < 16; p = \(u32\*\)\*p\)' 'OSDumpContext stack walk uses uintptr_t sentinel compare'
check_contains "src/static/dolphin/os/OSContext.c" 'OSReport\("%p:   0x%08x    0x%08x\\n", \(void\*\)p, p\[0\], p\[1\]\);' 'OSDumpContext stack trace uses %p'

check_contains "src/static/JSystem/JUtility/JUTException.cpp" '\(stackPointer != nullptr\) && \(\(uintptr_t\)stackPointer != \(uintptr_t\)0xFFFFFFFFu\) && \(i\+\+ < 0x10\)' 'JUTException stack walk uses uintptr_t sentinel compare'
check_contains "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("%p:  %08X    %08X\\n", \(void\*\)stackPointer, stackPointer\[0\], stackPointer\[1\]\);' 'JUTException stack trace uses %p'
check_contains "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("CONTEXT:%p  \(%s EXCEPTION\)\\n", \(void\*\)context, sCpuExpName\[error\]\);' 'JUTException main info uses %p for context'
check_contains "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("\*\*\*\*\*\*\*\* EXCEPTION OCCURRED! \*\*\*\*\*\*\*\*\\nFrameMemory:%p\\n", \(void\*\)getFrameMemory\(\)\);' 'JUTException frame memory uses %p'

check_absent "src/static/dolphin/os/OSContext.c" 'OSReport\("------------------------- Context 0x%08x -------------------------\\n", context\);' 'legacy OSDumpContext header format'
check_absent "src/static/dolphin/os/OSContext.c" '\(u32\)p != 0xffffffff' 'legacy OSDumpContext stack walk cast'
check_absent "src/static/dolphin/os/OSContext.c" 'OSReport\("0x%08x:   0x%08x    0x%08x\\n", p, p\[0\], p\[1\]\);' 'legacy OSDumpContext stack trace format'

check_absent "src/static/JSystem/JUtility/JUTException.cpp" '\(stackPointer != \(u32\*\)0xFFFFFFFF\)' 'legacy JUTException stack walk sentinel'
check_absent "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("%08X:  %08X    %08X\\n", stackPointer, stackPointer\[0\], stackPointer\[1\]\);' 'legacy JUTException stack trace format'
check_absent "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("CONTEXT:%08XH  \(%s EXCEPTION\)\\n", context, sCpuExpName\[error\]\);' 'legacy JUTException context format'
check_absent "src/static/JSystem/JUtility/JUTException.cpp" 'sConsole->print_f\("\*\*\*\*\*\*\*\* EXCEPTION OCCURRED! \*\*\*\*\*\*\*\*\\nFrameMemory:%XH\\n", getFrameMemory\(\)\);' 'legacy JUTException frame memory format'
