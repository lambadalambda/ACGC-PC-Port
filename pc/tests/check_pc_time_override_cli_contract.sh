#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
PC_MAIN_C="$REPO_ROOT/pc/src/pc_main.c"
PC_OS_C="$REPO_ROOT/pc/src/pc_os.c"
README_MD="$REPO_ROOT/README.md"

if ! rg -q 'int[[:space:]]+g_pc_min_override[[:space:]]*=[[:space:]]*-1;' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main minute override global' >&2
    exit 1
fi

if ! rg -q 'int[[:space:]]+g_pc_sec_override[[:space:]]*=[[:space:]]*-1;' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main second override global' >&2
    exit 1
fi

if ! rg -q 'printf\("  --time H\[:M\[:S\]\][[:space:]]+Override in-game time \(e\.g\. 5, 17:30, 5:55:00\)\\n"\);' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main --time extended help text contract' >&2
    exit 1
fi

if ! rg -q 'sscanf\(argv\[i \+ 1\], "%d:%d:%d", &h, &m, &s\);' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main --time H:M:S parse contract' >&2
    exit 1
fi

if ! rg -q 'if \(m >= 0 && m <= 59\) g_pc_min_override = m;' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main minute range assignment contract' >&2
    exit 1
fi

if ! rg -q 'if \(s >= 0 && s <= 59\) g_pc_sec_override = s;' "$PC_MAIN_C"; then
    printf '%s\n' 'missing pc_main second range assignment contract' >&2
    exit 1
fi

if ! rg -q 'if \(g_pc_min_override >= 0\)' "$PC_OS_C"; then
    printf '%s\n' 'missing pc_os minute override application contract' >&2
    exit 1
fi

if ! rg -q 'if \(g_pc_sec_override >= 0\)' "$PC_OS_C"; then
    printf '%s\n' 'missing pc_os second override application contract' >&2
    exit 1
fi

if ! rg -q '^\| `--time H\[:M\[:S\]\]` \| Override in-game time \(examples: `5`, `17:30`, `5:55:00`\) \|$' "$README_MD"; then
    printf '%s\n' 'missing README --time H[:M[:S]] command-line docs contract' >&2
    exit 1
fi

printf '%s\n' 'check_pc_time_override_cli_contract: OK'
