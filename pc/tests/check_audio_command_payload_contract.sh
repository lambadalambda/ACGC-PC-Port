#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing audio command payload contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy audio command payload pattern: $label" >&2
        exit 1
    fi
}

check_contains "include/jaudio_NES/system.h" 'extern void Nas_SetExtPointer\(s32 type, s32 idx, s32 set_type, u32 param\);' 'system header ext pointer payload type'
check_contains "include/jaudio_NES/channel.h" 'extern s32 OverwriteBank\(s32 type, s32 bankId, s32 idx, u32 voicetable\);' 'channel header bank payload type'
check_contains "src/static/jaudio_NES/internal/system.c" 'void Nas_SetExtPointer\(s32 table_type, s32 idx, s32 param_3, u32 data\)' 'system ext pointer payload type'
check_contains "src/static/jaudio_NES/internal/channel.c" 'extern s32 OverwriteBank\(s32 type, s32 bankId, s32 idx, u32 table\)' 'channel bank payload type'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'OverwriteBank\(port->command.opcode - AUDIOCMD_SET_PERC_BANK, port->command.arg1, port->command.arg2, port->param.asU32\);' 'subsys bank payload uses asU32'
check_contains "src/static/jaudio_NES/internal/sub_sys.c" 'Nas_SetExtPointer\(port->command.arg0, port->command.arg1, port->command.arg2, port->param.asU32\);' 'subsys ext pointer payload uses asU32'

check_absent "include/jaudio_NES/system.h" 'extern void Nas_SetExtPointer\(s32 type, s32 idx, s32 set_type, s32 param\);' 'legacy system header ext pointer type'
check_absent "include/jaudio_NES/channel.h" 'extern s32 OverwriteBank\(s32 type, s32 bankId, s32 idx, s32 voicetable\);' 'legacy channel header bank type'
check_absent "src/static/jaudio_NES/internal/system.c" 'void Nas_SetExtPointer\(s32 table_type, s32 idx, s32 param_3, s32 data\)' 'legacy system ext pointer type'
check_absent "src/static/jaudio_NES/internal/channel.c" 'extern s32 OverwriteBank\(s32 type, s32 bankId, s32 idx, s32 table\)' 'legacy channel bank type'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'OverwriteBank\(port->command.opcode - AUDIOCMD_SET_PERC_BANK, port->command.arg1, port->command.arg2, port->param.asS32\);' 'legacy subsys signed bank payload use'
check_absent "src/static/jaudio_NES/internal/sub_sys.c" 'Nas_SetExtPointer\(port->command.arg0, port->command.arg1, port->command.arg2, port->param.asS32\);' 'legacy subsys signed ext pointer use'
