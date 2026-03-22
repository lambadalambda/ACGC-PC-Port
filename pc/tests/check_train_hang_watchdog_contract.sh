#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WATCHDOG="$REPO_ROOT/pc/tools/train_hang_watchdog.py"

check_contains() {
    local file="$1"
    local pattern="$2"
    local desc="$3"

    if ! rg -q -- "$pattern" "$file"; then
        printf '%s\n' "missing contract: $desc ($file)" >&2
        exit 1
    fi
}

check_contains "$WATCHDOG" 'start-gate-timeout' 'watchdog supports fallback monitor arming'
check_contains "$WATCHDOG" 'queue-streak-seconds' 'watchdog supports sustained queue streak detection'
check_contains "$WATCHDOG" 'queue-rw-stuck-seconds' 'watchdog supports queue rw-stall detection'
check_contains "$WATCHDOG" 'entropy-max-unique' 'watchdog supports low-entropy loop detection'
check_contains "$WATCHDOG" 'select\.select' 'watchdog uses polling rather than blocking readline loop'

printf '%s\n' 'check_train_hang_watchdog_contract: OK'
