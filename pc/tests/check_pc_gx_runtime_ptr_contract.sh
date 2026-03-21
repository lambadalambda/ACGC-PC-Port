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

check_contains "pc/src/pc_gx_texture.c" '#define TEXOBJ_IMAGE_PTR_HI\s+18' 'GXTexObj stores host image pointer high word'
check_contains "pc/src/pc_gx_texture.c" '#define TLUTOBJ_DATA_HI\s+3' 'GXTlutObj stores host data pointer high word'
check_contains "pc/src/pc_gx_texture.c" 'static void texobj_set_image_ptr\(u32\* o, const void\* image_ptr\)' 'GXTexObj image pointer split helper'
check_contains "pc/src/pc_gx_texture.c" 'static void\* texobj_get_image_ptr\(const u32\* o\)' 'GXTexObj image pointer reconstruction helper'
check_contains "pc/src/pc_gx_texture.c" 'static void tlutobj_set_data_ptr\(u32\* o, const void\* data_ptr\)' 'GXTlutObj data pointer split helper'
check_contains "pc/src/pc_gx_texture.c" 'static const void\* tlutobj_get_data_ptr\(const u32\* o\)' 'GXTlutObj data pointer reconstruction helper'
check_contains "pc/src/pc_gx_texture.c" 'uintptr_t image_ptr_key = \(uintptr_t\)image_ptr;' 'texture cache key keeps image pointer host-width'
check_contains "pc/src/pc_gx_texture.c" 'uintptr_t tlut_ptr_key = 0;' 'texture cache key keeps TLUT pointer host-width'
check_contains "pc/src/pc_gx_texture.c" 'tlut_ptr_key = \(uintptr_t\)g_gx\.tlut\[tlut_name\]\.data;' 'texture cache TLUT pointer key stays host-width'
check_contains "pc/include/pc_gx_internal.h" 'void   pc_gx_efb_capture_store\(uintptr_t dest_ptr, GLuint gl_tex\);' 'EFB capture store pointer key uses uintptr_t'
check_contains "pc/include/pc_gx_internal.h" 'GLuint pc_gx_efb_capture_find\(uintptr_t data_ptr\);' 'EFB capture lookup pointer key uses uintptr_t'
check_contains "pc/src/pc_gx.c" 'uintptr_t dest_ptr;' 'EFB capture table stores host-width destination pointer'
check_contains "pc/src/pc_gx.c" 'void pc_gx_efb_capture_store\(uintptr_t dest_ptr, GLuint gl_tex\)' 'EFB capture store function accepts host-width pointer key'
check_contains "pc/src/pc_gx.c" 'GLuint pc_gx_efb_capture_find\(uintptr_t data_ptr\)' 'EFB capture lookup function accepts host-width pointer key'
check_contains "pc/src/pc_gx.c" 'pc_gx_efb_capture_store\(\(uintptr_t\)dest, efb_tex\);' 'EFB capture store passes host pointer without narrowing'
check_contains "src/static/dolphin/gx/GXTexture.c" '#include "pc_runtime_ptr.h"' 'GXTexture runtime pointer helper include'
check_contains "src/static/dolphin/gx/GXTexture.c" 'imagePtr = PC_RUNTIME_U32_PTR\(image_ptr\);' 'GXTexture image pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXTexture.c" 'imageBase = \(imagePtr >> 5\) & 0x01FFFFFF;' 'GXTexture image base uses checked-narrowed pointer'
check_contains "src/static/dolphin/gx/GXTexture.c" 'lutAddr = PC_RUNTIME_U32_PTR\(lut\);' 'GXTexture TLUT pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXTexture.c" 'SET_REG_FIELD\(0x481, t->loadTlut0, 21, 0, \(lutAddr & 0x3FFFFFFF\) >> 5\);' 'GXTexture TLUT register uses checked-narrowed pointer'
check_contains "src/static/dolphin/gx/GXFifo.c" '#include "pc_runtime_ptr.h"' 'GXFifo runtime pointer helper include'
check_contains "src/static/dolphin/gx/GXFifo.c" 'baseAddr = PC_RUNTIME_U32_PTR\(base\);' 'GXFifo base pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXFifo.c" 'readAddr = PC_RUNTIME_U32_PTR\(readPtr\);' 'GXFifo read pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXFifo.c" 'writeAddr = PC_RUNTIME_U32_PTR\(writePtr\);' 'GXFifo write pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXAttr.c" '#include "pc_runtime_ptr.h"' 'GXAttr runtime pointer helper include'
check_contains "src/static/dolphin/gx/GXAttr.c" 'baseAddr = PC_RUNTIME_U32_PTR\(base_ptr\);' 'GXAttr array base pointer checked narrowing'
check_contains "src/static/dolphin/gx/GXAttr.c" 'phyAddr = baseAddr & 0x3FFFFFFF;' 'GXAttr physical address uses checked-narrowed pointer'

check_absent "pc/src/pc_gx_texture.c" 'o\[TEXOBJ_IMAGE_PTR\] = PC_RUNTIME_U32_PTR\(image_ptr\);' 'legacy checked narrowing in GXTexObj image pointer storage'
check_absent "pc/src/pc_gx_texture.c" 'tlut_ptr_key = PC_RUNTIME_U32_PTR\(g_gx\.tlut\[tlut_name\]\.data\);' 'legacy checked narrowing in TLUT cache key'
check_absent "pc/src/pc_gx_texture.c" 'o\[TLUTOBJ_DATA\] = PC_RUNTIME_U32_PTR\(lut\);' 'legacy checked narrowing in GXTlutObj data pointer storage'
check_absent "pc/src/pc_gx.c" 'pc_gx_efb_capture_store\(PC_RUNTIME_U32_PTR\(dest\), efb_tex\);' 'legacy checked narrowing in EFB capture store'
check_absent "src/static/dolphin/gx/GXTexture.c" '\(u32\)image_ptr' 'raw GXTexture image pointer cast'
check_absent "src/static/dolphin/gx/GXTexture.c" '\(u32\)lut' 'raw GXTexture TLUT pointer cast'
check_absent "src/static/dolphin/gx/GXFifo.c" '\(u32\)base' 'raw GXFifo base pointer cast'
check_absent "src/static/dolphin/gx/GXFifo.c" '\(u32\)readPtr' 'raw GXFifo read pointer cast'
check_absent "src/static/dolphin/gx/GXFifo.c" '\(u32\)writePtr' 'raw GXFifo write pointer cast'
check_absent "src/static/dolphin/gx/GXAttr.c" '\(u32\)base_ptr' 'raw GXAttr base pointer cast'
