#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing famicom pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy famicom pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "src/static/Famicom/famicom.cpp" 'famicomCommon\.memcard_game_header\.comment_img_size = \(u32\)\(data - data_p\);' 'comment image size uses byte-pointer diff'
check_contains "src/static/Famicom/famicom.cpp" 'FamicomSaveDataHeader\* read_save_header = \(FamicomSaveDataHeader\*\)\(\(u8\*\)buf \+ status\.offsetData\);' 'save header lookup uses byte-pointer arithmetic'
check_contains "src/static/Famicom/famicom.cpp" '\*size = \(u32\)\(data_p - dst\);' 'banner size uses byte-pointer diff'
check_contains "src/static/Famicom/famicom.cpp" '\*size_p = \(u32\)\(data_p - dst\);' 'icon size uses byte-pointer diff'
check_contains "src/static/Famicom/famicom.cpp" 'OSReport\("err code=%d \(0x%x\), %p,%p,%p,%p,%p,%p\\n", reset_res, reset_res, \(void\*\)famicomCommon\.wp,' 'reset failure report uses %p for pointer fields'

check_absent "src/static/Famicom/famicom.cpp" 'famicomCommon\.memcard_game_header\.comment_img_size = \(u32\)data - \(u32\)data_p;' 'legacy comment image size cast'
check_absent "src/static/Famicom/famicom.cpp" 'FamicomSaveDataHeader\* read_save_header = \(FamicomSaveDataHeader\*\)\(\(u32\)buf \+ status\.offsetData\);' 'legacy save header cast'
check_absent "src/static/Famicom/famicom.cpp" '\*size = \(u32\)data_p - \(u32\)dst;' 'legacy banner size cast'
check_absent "src/static/Famicom/famicom.cpp" '\*size_p = \(u32\)data_p - \(u32\)dst;' 'legacy icon size cast'
check_absent "src/static/Famicom/famicom.cpp" 'OSReport\("err code=%d \(0x%x\), %x,%x,%x,%x,%x,%x\\n",' 'legacy reset failure pointer formatting'
