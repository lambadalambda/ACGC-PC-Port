#!/bin/sh

set -eu

LP64_BUILD_DIR=${1:-/tmp/acgc-p2-config-64}
TIMEOUT_SEC=${2:-20}
BIN="$LP64_BUILD_DIR/bin/AnimalCrossing"
RUN_DIR="$LP64_BUILD_DIR/bin"

if [ ! -x "$BIN" ]; then
    printf '%s\n' "missing lp64 binary: $BIN" >&2
    exit 1
fi

if [ ! -d "$RUN_DIR/rom" ]; then
    printf '%s\n' "missing rom directory: $RUN_DIR/rom" >&2
    exit 1
fi

if ! ls "$RUN_DIR/rom"/*.ciso >/dev/null 2>&1 && ! ls "$RUN_DIR/rom"/*.iso >/dev/null 2>&1 && ! ls "$RUN_DIR/rom"/*.gcm >/dev/null 2>&1; then
    printf '%s\n' "missing disc image (.ciso/.iso/.gcm) in $RUN_DIR/rom" >&2
    exit 1
fi

python3 - "$BIN" "$RUN_DIR" "$TIMEOUT_SEC" <<'PY'
import pathlib
import subprocess
import sys

bin_path = pathlib.Path(sys.argv[1])
run_dir = pathlib.Path(sys.argv[2])
timeout_sec = float(sys.argv[3])

markers = [
    "[PC] boot: entering HotStartEntry loop",
    "[PC] JW_Init3: forest_2nd.arc mounted successfully!",
    "[LOGO] aAL_actor_ct: Animal Logo actor created",
    "[BGM] __Nas_StartSeq ok group=3",
]

try:
    completed = subprocess.run(
        [str(bin_path), "--verbose"],
        cwd=run_dir,
        text=True,
        capture_output=True,
        timeout=timeout_sec,
    )
    output = (completed.stdout or "") + (completed.stderr or "")
    if completed.returncode != 0:
        raise SystemExit(f"title smoke exited early with code {completed.returncode}")
except subprocess.TimeoutExpired as exc:
    output = exc.stdout or ""
    if isinstance(output, bytes):
        output = output.decode("utf-8", errors="replace")

for marker in markers:
    if marker not in output:
        raise SystemExit(f"missing title smoke marker: {marker}")

print(f"[title-smoke] PASS ({timeout_sec:.0f}s timeout)")
PY
