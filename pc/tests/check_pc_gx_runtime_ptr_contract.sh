#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing PC GX runtime pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy PC GX pointer cast: $label" >&2
        exit 1
    fi
}

check_contains "pc/src/pc_gx_texture.c" 'o\[TEXOBJ_IMAGE_PTR\] = PC_RUNTIME_U32_PTR\(image_ptr\);' 'GXInitTexObj image pointer'
check_contains "pc/src/pc_gx_texture.c" 'o\[TEXOBJ_IMAGE_PTR\] = PC_RUNTIME_U32_PTR\(image_ptr\);' 'GXInitTexObjData image pointer'
check_contains "pc/src/pc_gx_texture.c" 'tlut_ptr_key = PC_RUNTIME_U32_PTR\(g_gx\.tlut\[tlut_name\]\.data\);' 'texture cache TLUT pointer key'
check_contains "pc/src/pc_gx_texture.c" 'o\[TLUTOBJ_DATA\] = PC_RUNTIME_U32_PTR\(lut\);' 'GXInitTlutObj data pointer'
check_contains "pc/src/pc_gx.c" 'pc_gx_efb_capture_store\(PC_RUNTIME_U32_PTR\(dest\), efb_tex\);' 'EFB capture destination pointer'

check_absent "pc/src/pc_gx_texture.c" '\(u32\)\(uintptr_t\)image_ptr' 'raw texture image pointer cast'
check_absent "pc/src/pc_gx_texture.c" '\(u32\)\(uintptr_t\)g_gx\.tlut\[tlut_name\]\.data' 'raw TLUT pointer key cast'
check_absent "pc/src/pc_gx_texture.c" '\(u32\)\(uintptr_t\)lut' 'raw TLUT object data cast'
check_absent "pc/src/pc_gx.c" 'pc_gx_efb_capture_store\(\(u32\)\(uintptr_t\)dest, efb_tex\);' 'raw EFB destination cast'
