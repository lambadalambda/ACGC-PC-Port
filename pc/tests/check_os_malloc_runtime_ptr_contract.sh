#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing __osMalloc pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy __osMalloc pointer truncation: $label" >&2
        exit 1
    fi
}

FILE="src/static/libc64/__osMalloc.c"

check_contains "$FILE" '#define OS_MALLOC_DATA2BLOCK\(data\) \(\(OSMemBlock\*\)\(\(uintptr_t\)\(data\) - sizeof\(OSMemBlock\)\)\)' 'data-to-block conversion uses uintptr_t'
check_contains "$FILE" '#define OS_MALLOC_NEXTMEMBLOCK\(block\) \(\(OSMemBlock\*\)\(\(uintptr_t\)\(block\) \+ sizeof\(OSMemBlock\) \+ \(block\)->size\)\)' 'next-block conversion uses uintptr_t'
check_contains "$FILE" 'uintptr_t block_addr;' 'add-block temporary address type'
check_contains "$FILE" 'block_addr = ALIGN_NEXT\(\(uintptr_t\)base, 32\);' 'add-block alignment uses uintptr_t'
check_contains "$FILE" 'align_size = ALIGN_PREV\(size - \(s32\)\(block_addr - \(uintptr_t\)base\), 32\);' 'add-block size adjustment uses pointer diff'
check_contains "$FILE" 'remain = \(u32\)\(\(\(uintptr_t\)block \+ sizeof\(OSMemBlock\)\) & mask\);' 'aligned alloc remain uses uintptr_t'
check_contains "$FILE" 'aligned_block = \(OSMemBlock\*\)\(\(uintptr_t\)block \+ alignment_bytes\);' 'aligned alloc rebuilds pointer from uintptr_t'
check_contains "$FILE" 'new_next = \(OSMemBlock\*\)\(\(uintptr_t\)block \+ full_size\);' 'aligned alloc split pointer uses uintptr_t'
check_contains "$FILE" 'next = \(OSMemBlock\*\)\(\(uintptr_t\)block \+ block->size - size\);' 'reverse alloc split pointer uses uintptr_t'
check_contains "$FILE" 'OSMemBlock\* new_next = \(OSMemBlock\*\)\(\(uintptr_t\)next \+ need_size\);' 'realloc grow split pointer uses uintptr_t'
check_contains "$FILE" 'OSMemBlock\* new_next = \(OSMemBlock\*\)\(\(uintptr_t\)orig_block \+ full_size\);' 'realloc shrink split pointer uses uintptr_t'
check_contains "$FILE" 'new_next = \(OSMemBlock\*\)\(\(uintptr_t\)orig_block \+ full_size\);' 'realloc tail split pointer uses uintptr_t'
check_contains "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "緊急事態！メモリリーク発見！ \(block=%p\)\\n" VT_RST, \(void\*\)block->next\);' 'next-block leak report uses %p'
check_contains "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "緊急事態！メモリリーク検出！ \(block=%p s=%p e=%p p=%p\)\\n" VT_RST,' 'free-block leak report uses %p'
check_contains "$FILE" 'OSReport\("アリーナの内容 \(%p\)\\n", \(void\*\)arena\);' 'arena display uses %p'
check_contains "$FILE" 'void\* block_end = \(void\*\)\(\(uintptr_t\)block \+ sizeof\(OSMemBlock\) \+ block->size\);' 'arena display computes block end with uintptr_t'
check_contains "$FILE" 'OSReport\("%p-%p%c %s %08x", \(void\*\)block, block_end, next == NULL \? '\''\$'\'' : \(next->prev != block \? '\''!'\'' : '\'' '\''\),' 'arena display prints block range with %p'
check_contains "$FILE" 'OSReport\("%p Block Invalid\\n", \(void\*\)block\);' 'invalid block report uses %p'
check_contains "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "おおっと！！ \(%p %08x\)\\n" VT_RST, \(void\*\)block, block->magic\);' 'arena check uses %p'

check_absent "$FILE" '#define OS_MALLOC_DATA2BLOCK\(data\) \(\(OSMemBlock\*\)\(\(u32\)\(data\) - sizeof\(OSMemBlock\)\)\)' 'legacy data-to-block cast'
check_absent "$FILE" '#define OS_MALLOC_NEXTMEMBLOCK\(block\) \(\(OSMemBlock\*\)\(\(u32\)\(block\) \+ sizeof\(OSMemBlock\) \+ \(block\)->size\)\)' 'legacy next-block cast'
check_absent "$FILE" 'block = \(OSMemBlock\*\)ALIGN_NEXT\(\(u32\)base, 32\);' 'legacy add-block alignment cast'
check_absent "$FILE" 'align_size = ALIGN_PREV\(size - \(\(u32\)block - \(u32\)base\), 32\);' 'legacy add-block size cast'
check_absent "$FILE" 'remain = \(\(u32\)block \+ sizeof\(OSMemBlock\)\) & mask;' 'legacy aligned alloc remain cast'
check_absent "$FILE" 'aligned_block = \(OSMemBlock\*\)\(\(u32\)block \+ alignment_bytes\);' 'legacy aligned alloc pointer cast'
check_absent "$FILE" 'new_next = \(OSMemBlock\*\)\(\(u32\)block \+ full_size\);' 'legacy aligned alloc split cast'
check_absent "$FILE" 'next = \(OSMemBlock\*\)\(\(u32\)block \+ block->size - size\);' 'legacy reverse alloc split cast'
check_absent "$FILE" 'OSMemBlock\* new_next = \(OSMemBlock\*\)\(\(u32\)next \+ need_size\);' 'legacy realloc grow split cast'
check_absent "$FILE" 'OSMemBlock\* new_next = \(OSMemBlock\*\)\(\(u32\)orig_block \+ full_size\);' 'legacy realloc shrink split cast'
check_absent "$FILE" 'new_next = \(OSMemBlock\*\)\(\(u32\)orig_block \+ full_size\);' 'legacy realloc tail split cast'
check_absent "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "緊急事態！メモリリーク発見！ \(block=%08x\)\\n" VT_RST, block->next\);' 'legacy next-block leak report'
check_absent "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "緊急事態！メモリリーク検出！ \(block=%08x s=%08x e=%08x p=%08x\)\\n" VT_RST, block, s, e, p\);' 'legacy free-block leak report'
check_absent "$FILE" 'OSReport\("アリーナの内容 \(0x%08x\)\\n", arena\);' 'legacy arena pointer display'
check_absent "$FILE" 'OSReport\("%08x-%08x%c %s %08x", \(u32\)block, \(u32\)block \+ sizeof\(OSMemBlock\) \+ block->size,' 'legacy arena range truncation'
check_absent "$FILE" 'OSReport\("%08x Block Invalid\\n", block\);' 'legacy invalid block report'
check_absent "$FILE" 'OSReport\(VT_COL\(RED, WHITE\) "おおっと！！ \(%08x %08x\)\\n" VT_RST, block, block->magic\);' 'legacy arena check report'
