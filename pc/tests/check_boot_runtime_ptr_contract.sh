#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

check_contains() {
    file=$1
    pattern=$2
    label=$3

    if ! rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "missing boot pointer contract: $label" >&2
        exit 1
    fi
}

check_absent() {
    file=$1
    pattern=$2
    label=$3

    if rg -q "$pattern" "$REPO_ROOT/$file"; then
        printf '%s\n' "unexpected legacy boot pointer format: $label" >&2
        exit 1
    fi
}

check_contains "src/static/boot.c" 'OSReport\("module=%p\\n", \(void\*\)module\);' 'boot module report uses %p'
check_contains "src/static/boot.c" 'OSReport\("サウンドアリーナ %08x 使用 bss=%p\\n", module->bssSize, \(void\*\)bss\);' 'boot bss report uses %p'
check_contains "src/static/boot.c" 'OSReport\("ARENA %p-%p" VT_RST "\\n", arenalo, arenahi\);' 'boot arena report uses %p'
check_contains "src/static/boot.c" 'OSReport\("OSGetSaveRegion %p %p\\n", start, end\);' 'save region report uses %p'
check_contains "src/static/boot.c" 'OSReport\("\[PC\] boot: entering HotStartEntry loop \(entry=%p\)\.\.\.\\n", HotStartEntry\);' 'HotStartEntry report uses %p'
check_contains "src/static/boot.c" 'OSReport\("ホットスタート\(%p\)\\n", HotStartEntry\);' 'hot start loop report uses %p'
check_contains "src/static/dolphin/os/OSError.c" 'OSReport\("%p:   0x%08x    0x%08x\\n", \(void\*\)p, p\[0\], p\[1\]\);' 'OSError stack report uses %p'
check_contains "src/executor.c" 'OSReport\("%p:   0x%08x    0x%08x\\n", \(void\*\)p, p\[0\], p\[1\]\);' 'executor stack report uses %p'

check_absent "src/static/boot.c" 'OSReport\("module=%08x\\n", module\);' 'legacy module report'
check_absent "src/static/boot.c" 'OSReport\("ARENA %08x-%08x" VT_RST "\\n", arenalo, arenahi\);' 'legacy arena report'
check_absent "src/static/boot.c" 'OSReport\("OSGetSaveRegion %08x %08x\\n", start, end\);' 'legacy save region report'
check_absent "src/static/boot.c" 'OSReport\("\[PC\] boot: entering HotStartEntry loop \(entry=%08x\)\.\.\.\\n", \(u32\)HotStartEntry\);' 'legacy HotStartEntry report'
check_absent "src/static/dolphin/os/OSError.c" 'OSReport\("0x%08x:   0x%08x    0x%08x\\n", p, p\[0\], p\[1\]\);' 'legacy OSError stack report'
check_absent "src/executor.c" 'OSReport\("0x%08x:   0x%08x    0x%08x\\n", p, p\[0\], p\[1\]\);' 'legacy executor stack report'
