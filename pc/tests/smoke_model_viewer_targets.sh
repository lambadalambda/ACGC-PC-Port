#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MODEL_VIEWER_SRC="$REPO_ROOT/pc/src/pc_model_viewer.c"

BIN_DIR="/tmp/acgc-p2-config-64-asan/bin"
TIMEOUT_SECONDS=12
declare -a TARGET_NAMES=()

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --bin-dir DIR     Directory containing AnimalCrossing binary
                    (default: /tmp/acgc-p2-config-64-asan/bin)
  --timeout SEC     Per-model timeout in seconds (default: 12)
  --name NAME       Model name from pc_model_viewer table (repeatable)
  --help            Show this help

If no --name is supplied, defaults are:
  - Train Engine
  - Train Car
  - Train Door
  - Keitai (On)
  - Keitai (Off)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bin-dir)
            BIN_DIR="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --name)
            TARGET_NAMES+=("$2")
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ${#TARGET_NAMES[@]} -eq 0 ]]; then
    TARGET_NAMES=("Train Engine" "Train Car" "Train Door" "Keitai (On)" "Keitai (Off)")
fi

BIN_PATH="$BIN_DIR/AnimalCrossing"
if [[ ! -x "$BIN_PATH" ]]; then
    echo "binary not found or not executable: $BIN_PATH" >&2
    exit 1
fi

if [[ ! -f "$MODEL_VIEWER_SRC" ]]; then
    echo "model viewer source not found: $MODEL_VIEWER_SRC" >&2
    exit 1
fi

declare -A NAME_TO_INDEX=()
while IFS=$'\t' read -r idx name; do
    NAME_TO_INDEX["$name"]="$idx"
done < <(
    python3 - "$MODEL_VIEWER_SRC" <<'PY'
import re
import sys

source_path = sys.argv[1]
text = open(source_path, encoding="utf-8", errors="replace").read()

start_marker = "static const MVModelEntry s_model_table[] = {"
start = text.find(start_marker)
if start < 0:
    raise SystemExit("could not locate model-viewer table")

table = text[start + len(start_marker):]
end = table.find("};")
if end < 0:
    raise SystemExit("could not locate end of model-viewer table")

table = table[:end]

names = re.findall(r'\{\s*"([^"]+)"\s*,', table)
for i, name in enumerate(names):
    print(f"{i}\t{name}")
PY
)

failures=0
for name in "${TARGET_NAMES[@]}"; do
    idx="${NAME_TO_INDEX[$name]:-}"
    if [[ -z "$idx" ]]; then
        echo "missing model-viewer entry: $name" >&2
        failures=$((failures + 1))
        continue
    fi

    safe_name="$(printf '%s' "$name" | tr -cs 'A-Za-z0-9' '_' | sed 's/^_\+//;s/_\+$//')"
    log_path="/tmp/acgc_model_viewer_${idx}_${safe_name}.log"

    python3 - "$BIN_PATH" "$BIN_DIR" "$idx" "$log_path" "$TIMEOUT_SECONDS" <<'PY'
import subprocess
import sys

bin_path, workdir, index, log_path, timeout = sys.argv[1:]
cmd = [bin_path, "--model-viewer", index, "-v", "--no-framelimit"]

with open(log_path, "w", encoding="utf-8") as log:
    proc = subprocess.Popen(cmd, cwd=workdir, stdout=log, stderr=subprocess.STDOUT)
    try:
        proc.wait(timeout=float(timeout))
    except subprocess.TimeoutExpired:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
PY

    if rg -q "AddressSanitizer|global-buffer-overflow|ABORTING|ERROR: AddressSanitizer" "$log_path"; then
        echo "[FAIL] $name (idx=$idx): ASan crash marker found ($log_path)" >&2
        failures=$((failures + 1))
        continue
    fi

    if rg -q "\\[PC\\]\\[emu64\\]\\[zero\\]" "$log_path"; then
        echo "[FAIL] $name (idx=$idx): unresolved emu64 pointer found ($log_path)" >&2
        failures=$((failures + 1))
        continue
    fi

    if ! rg -q "\\[ModelViewer\\] Initialized" "$log_path"; then
        echo "[FAIL] $name (idx=$idx): model viewer did not initialize ($log_path)" >&2
        failures=$((failures + 1))
        continue
    fi

    echo "[OK] $name (idx=$idx)"
done

if [[ $failures -ne 0 ]]; then
    echo "smoke_model_viewer_targets: FAILED ($failures issue(s))" >&2
    exit 1
fi

echo "smoke_model_viewer_targets: OK"
