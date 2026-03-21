#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing emu64 seg2k0 pointer contract: $label" >&2
        exit 1
    fi
}

check_contains "pc/include/pc_platform.h" 'void\* pc_os_get_arena_base\(void\);' 'arena base export declaration'
check_contains "pc/include/pc_platform.h" 'u32\s+pc_os_get_arena_size\(void\);' 'arena size export declaration'
check_contains "pc/src/pc_os.c" 'void\* pc_os_get_arena_base\(void\) \{ return arena_memory; \}' 'arena base export definition'
check_contains "pc/src/pc_os.c" 'u32\s+pc_os_get_arena_size\(void\) \{ return PC_MAIN_MEMORY_SIZE; \}' 'arena size export definition'
check_contains "include/pc_static_ptr.h" '#define PC_STATIC_U32_PTR\(ptr\) 0u' 'LP64 static pointer words use zero placeholder'

check_contains "src/static/libforest/emu64/emu64_utility.c" 'static uintptr_t pc_seg2k0_arena_translate\(u32 phys_addr\)' 'arena translation helper'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'static bool pc_gbi_ptr_in_map_range\(uintptr_t value\)' 'GBI map range guard helper'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'static bool pc_gbi_ptr_in_gx_state\(uintptr_t value\)' 'GX state range guard helper'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'if \(pc_gbi_ptr_in_map_range\(decoded\) \|\| pc_gbi_ptr_in_gx_state\(decoded\)\)' 'decoded key suspicious target guard'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'if \(\(segadr & ~PC_GBI_PTR_KEY_MASK\) == PC_GBI_PTR_KEY_TAG\)' 'unknown GBI key guard'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'if \(segadr >= 0x80000000u && segadr < 0xC0000000u\)' 'K0/K1 translation branch'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'u32 phys_addr = segadr & 0x1FFFFFFFu;' 'K0 physical offset extraction'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'if \(segadr < 0x03000000u\)' 'raw physical offset translation branch'
check_contains "src/static/libforest/emu64/emu64_utility.c" 'pc_seg2k0_trace\("k0-unmapped", segadr, 0, phys_addr, this->segments\[0\]\);' 'K0 unresolved diagnostic'

check_contains "src/static/libforest/emu64/emu64.c" 'static bool pc_tlut_probe_first_word\(const void\* addr, u16\* out_word\)' 'TLUT probe guard helper'
check_contains "src/static/libforest/emu64/emu64.c" 'if \(addr_bits >= 0x80000000u && addr_bits < 0xC0000000u\)' 'TLUT probe rejects unresolved K0/K1'
check_contains "src/static/libforest/emu64/emu64.c" 'if \(!pc_tlut_probe_first_word\(tlut_addr, &first\)\)' 'type2 TLUT same-address guarded probe'
check_contains "src/static/libforest/emu64/emu64.c" 'if \(pc_tlut_probe_first_word\(aligned_addr, &first_word\)\)' 'type2 TLUT post-load guarded probe'
check_contains "src/static/libforest/emu64/emu64.c" 'if \(!pc_tlut_probe_first_word\(\(void\*\)addr, &first\)\)' 'type1 TLUT same-address guarded probe'
