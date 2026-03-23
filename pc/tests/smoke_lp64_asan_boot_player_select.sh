#!/bin/sh

set -eu

LP64_ASAN_BUILD_DIR=${1:-/tmp/acgc-p2-config-64-asan}
ASSET_RUN_DIR=${2:-/tmp/acgc-p2-config-64/bin}
TIMEOUT_SEC=${3:-30}

BIN="$LP64_ASAN_BUILD_DIR/bin/AnimalCrossing"

if [ ! -x "$BIN" ]; then
    printf '%s\n' "missing lp64 asan binary: $BIN" >&2
    exit 1
fi

if [ ! -d "$ASSET_RUN_DIR/rom" ]; then
    printf '%s\n' "missing rom directory: $ASSET_RUN_DIR/rom" >&2
    exit 1
fi

if ! ls "$ASSET_RUN_DIR/rom"/*.ciso >/dev/null 2>&1 && ! ls "$ASSET_RUN_DIR/rom"/*.iso >/dev/null 2>&1 && ! ls "$ASSET_RUN_DIR/rom"/*.gcm >/dev/null 2>&1; then
    printf '%s\n' "missing disc image (.ciso/.iso/.gcm) in $ASSET_RUN_DIR/rom" >&2
    exit 1
fi

python3 - "$BIN" "$ASSET_RUN_DIR" "$TIMEOUT_SEC" <<'PY'
import pathlib
import subprocess
import sys

bin_path = pathlib.Path(sys.argv[1])
run_dir = pathlib.Path(sys.argv[2])
timeout_sec = float(sys.argv[3])

markers = [
    "[PC] boot: entering HotStartEntry loop",
    "[PC] mainproc: calling graph_proc directly (single-threaded)...",
    "[PC] graph_proc: boot-player-select requested; using default scene chain",
]

try:
    completed = subprocess.run(
        [str(bin_path), "--verbose", "--boot-player-select"],
        cwd=run_dir,
        text=True,
        capture_output=True,
        timeout=timeout_sec,
    )
    output = (completed.stdout or "") + (completed.stderr or "")
    if completed.returncode != 0:
        raise SystemExit(f"asan boot-player-select smoke exited early with code {completed.returncode}")
except subprocess.TimeoutExpired as exc:
    stdout = exc.stdout or ""
    stderr = exc.stderr or ""
    if isinstance(stdout, bytes):
        stdout = stdout.decode("utf-8", errors="replace")
    if isinstance(stderr, bytes):
        stderr = stderr.decode("utf-8", errors="replace")
    output = stdout + stderr

for marker in markers:
    if marker not in output:
        raise SystemExit(f"missing asan boot-player-select smoke marker: {marker}")

if "AddressSanitizer" in output:
    raise SystemExit("asan boot-player-select smoke reported AddressSanitizer errors")

print(f"[asan-boot-player-select-smoke] PASS ({timeout_sec:.0f}s timeout)")
PY
