#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN="$REPO_ROOT/pc/tools/gen_gfx_w1_fixups.py"

for source in "$REPO_ROOT"/src/data/npc/model/mdl/*.c; do
    stem="$(basename "$source" .c)"
    helper="pc_patch_${stem}_models"
    rel_source="src/data/npc/model/mdl/${stem}.c"

    python3 "$GEN" --source "$rel_source" --check-helper "$helper" >/dev/null

    if ! rg -q "${helper}\\(\\);" "$source"; then
        printf '%s\n' "missing NPC loader helper call: ${helper} (${rel_source})" >&2
        exit 1
    fi
done

printf '%s\n' 'check_train_npc_model_ptr_patch_contract: OK'
