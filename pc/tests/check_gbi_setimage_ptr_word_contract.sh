#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GBI_H="$REPO_ROOT/include/PR/gbi.h"

if ! rg -q '_g->words\.w1 = GBI_PTR_WORD\(i\);' "$GBI_H"; then
    printf '%s\n' 'missing contract: gSetImage must encode w1 via GBI_PTR_WORD(i)' >&2
    exit 1
fi

if rg -q '_g->words\.w1 = \(unsigned int\)\(i\);' "$GBI_H"; then
    printf '%s\n' 'failing contract: gSetImage still truncates pointer via unsigned int cast' >&2
    exit 1
fi

printf '%s\n' 'check_gbi_setimage_ptr_word_contract: OK'
