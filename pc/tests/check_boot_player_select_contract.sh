#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PC_MAIN_C="$REPO_ROOT/pc/src/pc_main.c"
GRAPH_C="$REPO_ROOT/src/graph.c"

python3 - "$PC_MAIN_C" "$GRAPH_C" <<'PY'
import sys

pc_main_path, graph_path = sys.argv[1], sys.argv[2]
pc_main = open(pc_main_path, encoding="utf-8", errors="replace").read()
graph = open(graph_path, encoding="utf-8", errors="replace").read()

required_main = [
    "g_pc_boot_player_select",
    "--boot-player-select",
]
for token in required_main:
    if token not in pc_main:
        print(f"missing contract: {token} in {pc_main_path}", file=sys.stderr)
        raise SystemExit(1)

required_graph = [
    "g_pc_boot_player_select",
    "boot-player-select requested; using default scene chain",
]
for token in required_graph:
    if token not in graph:
        print(f"missing contract: {token} in {graph_path}", file=sys.stderr)
        raise SystemExit(1)

if "boot override ->" in graph:
    print(f"stale direct-scene override marker remains in {graph_path}", file=sys.stderr)
    raise SystemExit(1)

print("check_boot_player_select_contract: OK")
PY
