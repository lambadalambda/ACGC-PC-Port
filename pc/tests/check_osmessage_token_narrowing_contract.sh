#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing OSMessage token narrowing contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy OSMessage token decode cast: $label" >&2
        exit 1
    fi
}

check_contains "src/irqmgr.c" '#include "pc_runtime_ptr.h"' 'irqmgr includes runtime checked narrowing helper'
check_contains "src/static/initial_menu.c" '#include "pc_runtime_ptr.h"' 'initial_menu includes runtime checked narrowing helper'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" '#include "pc_runtime_ptr.h"' 'sub_sys includes runtime checked narrowing helper'
check_contains "src/static/jaudio_NES/internal/system.c" '#include "pc_runtime_ptr.h"' 'jaudio system includes runtime checked narrowing helper'
check_contains "src/irqmgr.c" 'return PC_RUNTIME_U32_PTR\(msg\);' 'irqmgr token decode uses checked narrowing'
check_contains "src/static/initial_menu.c" 'return PC_RUNTIME_U32_PTR\(msg\);' 'initial_menu token decode uses checked narrowing'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'msg_token = PC_RUNTIME_U32_PTR\(msg\);' 'sub_sys spec-change token decode uses checked narrowing'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'Nap_AudioPortProcess\(PC_RUNTIME_U32_PTR\(msg\)\);' 'sub_sys command queue token decode uses checked narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'preload_idx = PC_RUNTIME_U32_PTR\(preload_msg\);' 'jaudio system preload queue token decode uses checked narrowing'
check_contains "src/static/jaudio_NES/internal/system.c" 'u32 ret = PC_RUNTIME_U32_PTR\(ret_msg\);' 'jaudio system MK queue token decode uses checked narrowing'

check_absent "src/irqmgr.c" 'return \(u32\)\(uintptr_t\)msg;' 'legacy irqmgr token decode cast removed'
check_absent "src/static/initial_menu.c" 'return \(u32\)\(uintptr_t\)msg;' 'legacy initial_menu token decode cast removed'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" '\(u32\)\(uintptr_t\)msg' 'legacy sub_sys token decode cast removed'
check_absent "src/static/jaudio_NES/internal/system.c" '\(u32\)\(uintptr_t\)preload_msg' 'legacy jaudio preload token decode cast removed'
check_absent "src/static/jaudio_NES/internal/system.c" '\(u32\)\(uintptr_t\)ret_msg' 'legacy jaudio MK token decode cast removed'
