#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing OS stack pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy OS stack pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "include/dolphin/os/OSContext.h" 'uintptr_t OSGetStackPointer\(void\);' 'OSGetStackPointer header uses uintptr_t'
check_contains "src/static/dolphin/os/OSContext.c" 'asm uintptr_t OSGetStackPointer\(\)' 'OSGetStackPointer implementation uses uintptr_t'
check_contains "pc/src/pc_os.c" 'uintptr_t OSGetStackPointer\(void\) \{ return \(uintptr_t\)&arena_memory; /\* dummy \*/ \}' 'PC stack pointer stub uses uintptr_t'
check_contains "src/static/boot.c" 'memset\(basenext, 0xfd, \(size_t\)\(\(u8\*\)base - \(u8\*\)basenext\)\);' 'boot stack fill uses pointer diff'
check_contains "src/static/dolphin/os/OSError.c" 'for \(i = 0, p = \(u32\*\)OSGetStackPointer\(\); p && \(uintptr_t\)p != \(uintptr_t\)0xffffffffu && i\+\+ < 16; p = \(u32\*\)\*p\)' 'OSError stack walk uses uintptr_t sentinel compare'
check_contains "src/executor.c" 'for \(i = 0, p = \(u32\*\)OSGetStackPointer\(\); p && \(uintptr_t\)p != \(uintptr_t\)0xffffffffu && i\+\+ < 16; p = \(u32\*\)\*p\)' 'executor stack walk uses uintptr_t sentinel compare'
check_contains "src/static/dolphin/os/OSThread.c" '#include "pc_runtime_ptr.h"' 'OSThread includes runtime pointer helper'
check_contains "src/static/dolphin/os/OSThread.c" 'sp = \(uintptr_t\)stack;' 'OSCreateThread stack math starts at host-width pointer'
check_contains "src/static/dolphin/os/OSThread.c" 'OSInitContext\(&thread->context, PC_RUNTIME_U32_PTR\(func\), PC_RUNTIME_U32_PTR\(sp\)\);' 'OSCreateThread context setup uses runtime pointer contract'
check_contains "src/static/dolphin/os/OSThread.c" 'thread->stackEnd.*\(u32\*\)\(\(u8\*\)stack - stackSize\);' 'OSCreateThread stackEnd uses host pointer arithmetic'

check_absent "include/dolphin/os/OSContext.h" 'u32 OSGetStackPointer\(void\);' 'legacy OSGetStackPointer u32 return'
check_absent "src/static/boot.c" 'memset\(basenext, 0xfd, \(u32\)base - \(u32\)basenext\);' 'legacy boot stack fill cast'
check_absent "src/static/dolphin/os/OSThread.c" 'sp = \(u32\)stack;' 'legacy OSCreateThread stack pointer truncation'
check_absent "src/static/dolphin/os/OSThread.c" 'thread->stackEnd\s*=\s*\(void\*\)\(\(unsigned int\)stack - stackSize\);' 'legacy OSCreateThread stackEnd truncation'
