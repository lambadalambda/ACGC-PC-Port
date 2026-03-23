#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

python3 "$GEN" --source src/data/npc/model/mdl/xct_1.c --check-helper pc_patch_xct_1_models >/dev/null
python3 "$GEN" --source src/data/npc/model/mdl/kab_1.c --check-helper pc_patch_kab_1_models >/dev/null

printf '%s\n' 'check_train_npc_model_ptr_patch_contract: OK'
