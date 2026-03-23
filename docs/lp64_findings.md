# LP64 Findings Log

This file tracks LP64 (64-bit host pointer-width) investigations and fixes so portability learnings do not get lost across sessions.

## 2026-03-22 - gSetImage pointer-word encoding

- Symptom/signature: `gSetImage` packed image pointers with `_g->words.w1 = (unsigned int)(i);`, which can truncate host pointers on LP64 and feed bad `G_SET*IMG` addresses into emu64/RDP paths.
- Root cause: macro bypassed the LP64-aware pointer word encoder (`GBI_PTR_WORD`) already used elsewhere.
- Fix approach and touched files:
  - switched `gSetImage` to `_g->words.w1 = GBI_PTR_WORD(i);` in `include/PR/gbi.h`
  - added contract check `pc/tests/check_gbi_setimage_ptr_word_contract.sh`
- Verification and follow-up:
  - `sh pc/tests/check_gbi_setimage_ptr_word_contract.sh` passes
  - full `pc/tests/check_*contract.sh` pass set still succeeds
  - both LP64 builds (`/tmp/acgc-p2-config-64`, `/tmp/acgc-p2-config-64-asan`) and title smokes pass
  - continue validating long autopress transition runs for remaining start-game stability issues

## 2026-03-22 - ef_shadow_in display-list vertex fixup index

- Symptom/signature: deterministic start transition repro (`PC_AUTOPRESS_A=1`) still reported `[PC][emu64][zero] G_VTX ... sym=ef_shadow_in_modelT+0x70`.
- Root cause: LP64 helper patched `ef_shadow_in_modelT[13].words.w1`, but the `gsSPVertex` command is at index 14 (offset `0x70`).
- Fix approach and touched files:
  - corrected fixup index to `ef_shadow_in_modelT[14].words.w1` in `src/data/model/ef_shadow_in2.c`
  - updated contract in `pc/tests/check_ef_shadow_out_ptr_patch_contract.sh`
- Verification and follow-up:
  - `sh pc/tests/check_ef_shadow_out_ptr_patch_contract.sh` passes
  - rebuilt both LP64 binaries and reran title smokes successfully
  - repro log `/tmp/acgc_lp64_asan_150s_after_ef_shadow_index_fix.log` shows `zero_count=0`
  - crash persists after transition, now dominated by heap/alignment issues described below

## 2026-03-22 - open investigation: JKRExpHeap misalignment after high-address arena fallback

- Symptom/signature:
  - during title -> scene transition, runtime prints `[PC] WARNING: VirtualAlloc at high address failed, falling back to malloc (seg2k0 may misfire)`
  - then UBSAN reports repeated `JKRExpHeap::CMemBlock` misaligned accesses (for example at `src/static/JSystem/JKernel/JKRExpHeap.cpp:857`)
  - process exits with signal 11 before stable gameplay bringup
- Root cause (current hypothesis): low-address arena fallback path can leave heap metadata or derived block pointers in a state that violates LP64 alignment assumptions for `CMemBlock`.
- Fix approach (next): instrument/guard heap block alignment at allocation/link points and trace the first bad block producer, then apply a root-cause alignment fix instead of suppressing UBSAN.
- Verification status:
  - reproduced in `/tmp/acgc_lp64_asan_150s_after_ef_shadow_index_fix.log`
  - not fixed yet; this remains the current high-priority blocker after clearing known zero-operand DL pointers in this transition path.

## 2026-03-22 - os round macros truncated host pointers on LP64

- Symptom/signature:
  - ASAN run crashed in audio DMA path with low host pointers (`0x06xxxxxx`) and invalid destination accesses during early startup.
  - LP64 guards in JAUDIO load/DMA path flagged suspicious low pointers before crash.
- Root cause: `OSRoundUp32B` / `OSRoundDown32B` in `include/dolphin/os/OSUtil.h` cast through `u32`, truncating 64-bit host addresses.
- Fix approach and touched files:
  - switched both macros to `uintptr_t` math in `include/dolphin/os/OSUtil.h`
  - added `pc/tests/check_os_round_alignment_macros_contract.sh`
- Verification and follow-up:
  - full contract suite passes
  - both LP64 builds succeed
  - ASAN no longer trips the prior low-pointer DMA guard crash

## 2026-03-22 - train transition and Rover model display-list pointer coverage

- Symptom/signature:
  - deterministic transition showed `[PC][emu64][zero]` hits on train-transition symbols and then on Rover/NPC symbols (`*_xct_model`, `*_kab_model`).
  - train appeared, but Rover/cat rendering remained missing.
- Root cause: LP64 static pointer words are zeroed by design (`PC_STATIC_U32_PTR=0`), requiring per-file runtime fixups for affected display lists.
- Fix approach and touched files:
  - train transition fixup helpers added/invoked in:
    - `src/data/field/bg/acre/rom_train_in/rom_train_in.c`
    - `src/data/model/rom_train_out.c`
    - `src/data/model/obj_romtrain_door.c`
    - `src/actor/ac_train_window.c`
    - `src/actor/ac_train_door.c`
  - Rover/NPC helpers regenerated from source macros (not hand-indexed) with `pc/tools/gen_gfx_w1_fixups.py` for:
    - `src/data/npc/model/mdl/xct_1.c`
    - `src/data/npc/model/mdl/kab_1.c`
  - added contracts:
    - `pc/tests/check_train_transition_ptr_patch_contract.sh`
    - `pc/tests/check_train_npc_model_ptr_patch_contract.sh`
- Verification and follow-up:
  - `[PC][emu64][zero]` hits for `xct`/`kab` symbols are gone in deterministic LP64 repro logs.
  - remaining zero hits are now localized to UI/effect symbols (`con_*`, `ef_ha01_00_modelT`).

## 2026-03-22 - train-scene ASAN crash chain in dialogue/audio paths

- Symptom/signature:
  - after entering train scene (`[SCENE_MODE] 3 -> 4`), ASAN reported successive global-buffer-overflows in:
    - `Na_VoiceSe` (`game64.c_inc:2918`, `SHIIN2BOIN[a]`)
    - `aNPC_check_manpu_demoCode` (`ac_npc_talk.c_inc:337`, `eff_idx_*[last_order]`)
    - `Na_SysLevStart` (`game64.c_inc:3416`, `sou_sys_lev[i]._1++`)
- Root cause:
  - unchecked table indexing for dynamic dialogue/voice values.
  - confirmed index-variable bug in system level loop (`i` used where `j` was intended).
- Fix approach and touched files:
  - `src/static/jaudio_NES/game/game64.c_inc`
    - guard `SHIIN2BOIN` lookup with `a < ARRAY_COUNT(SHIIN2BOIN)` and fallback to `0`
    - fix `Na_SysLevStart` loop to increment `sou_sys_lev[j]._1`
  - `src/actor/npc/ac_npc_talk.c_inc`
    - bounds-check and sanitize `order` / `last_order` against effect-table size before indexing
  - added contracts:
    - `pc/tests/check_voice_shiin2boin_bounds_contract.sh`
    - `pc/tests/check_npc_talk_demo_code_bounds_contract.sh`
    - `pc/tests/check_sys_lev_counter_bounds_contract.sh`
- Verification and follow-up:
  - ASAN run `/tmp/acgc_lp64_asan_240s_autopress3s_after_syslev_fix.log` no longer aborts with those crashes.
  - LP64 release still shows train-scene hang signature described below.

## 2026-03-22 - train-hang watchdog and current status

- Symptom/signature:
  - LP64 release can enter prolonged train-scene stall pattern requiring manual force-quit, with repeated `SendStart::Mesg Full Queue`.
- Tooling/fix approach:
  - added `pc/tools/train_hang_watchdog.py` to auto-terminate on a train-hang signature:
    - waits for `[SCENE_MODE] 3 -> 4`
    - kills process after configurable `SendStart::Mesg Full Queue` threshold
  - added temporary queue diagnostics in `src/static/jaudio_NES/internal/sub_sys.c` for full-queue events.
- Verification and follow-up:
  - watchdog reproduces/terminates the LP64 release stall without manual intervention.
  - diagnostic full-queue lines show `reset_status=0`, `reset_timer=0`, and `thread_cmd_proc_mq.validCount=64` at saturation.
  - open follow-up: identify why command-queue notifications stop draining in release timing while ASAN timing avoids saturation.

## 2026-03-22 - watchdog v2 for flaky train-hang detection

- Symptom/signature:
  - first watchdog revision was inconsistent: some runs detected quickly, while others reached only hard timeout.
  - root issue was signature brittleness: it depended on one gate (`[SCENE_MODE] 3 -> 4`) and one absolute counter (`SendStart::Mesg Full Queue` occurrences).
- Root cause:
  - queue-full log rate varies significantly across runs/builds, so a fixed count threshold is not stable.
  - some runs can miss/shift the scene gate marker timing, leaving detection disarmed too long.
- Fix approach and touched files:
  - rewrote `pc/tools/train_hang_watchdog.py` as a multi-signal state machine with explicit intent comments:
    - arm on scene gate **or** fallback `--start-gate-timeout`
    - use time-window queue pressure checks (`--queue-window-seconds`, rate/min-events)
    - detect sustained queue-full streaks (`--queue-streak-seconds`, gap/min-events)
    - detect saturated queue r/w stalls from detailed lines (`valid/r/w` parsing)
    - detect low-entropy repetitive loops under queue pressure
    - keep legacy `--queue-full-threshold` as optional compatibility mode
    - use `select` polling so watchdog timers still advance during low-output periods
  - clarified queue diagnostic intent comment in `src/static/jaudio_NES/internal/sub_sys.c`.
- Verification and follow-up:
  - release repro with watchdog v2 auto-terminates on hang signature without manual force-quit.
  - ASAN repro in same window tends to hit watchdog timeout rather than queue-pressure signature, which matches earlier build-dependent behavior.
  - remaining follow-up: tune defaults (`queue-rate`, streak duration, entropy thresholds) against a healthy non-hang train run to reduce false positives.

## 2026-03-23 - train intro NPC setup returned undefined status

- Symptom/signature:
  - in `SCENE_START_DEMO` (scene 15), train intro could appear to hang with missing character flow and rapid repeating voice/talk sounds.
  - progression commonly stopped after `[SCENE_MODE] 3 -> 4` in automated repro windows.
- Root cause:
  - `aNPC_setupActor_proc` in `src/actor/npc/ac_npc_ctrl.c_inc` was declared `int` but had no explicit `return`.
  - callers depend on this boolean status to advance intro setup paths; relying on fallthrough from the final call is undefined behavior and can desync control flow on modern 64-bit builds.
- Fix approach and touched files:
  - made `aNPC_setupActor_proc` explicitly return `aNPC_setupActor_sub(...)`.
  - added contract `pc/tests/check_npc_setup_actor_return_contract.sh`.
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes with the new contract.
  - both LP64 builds still pass (`/tmp/acgc-p2-config-64`, `/tmp/acgc-p2-config-64-asan`).
  - train intro progression reported as playing out correctly after the fix.
  - keep monitoring long train-flow runs to determine whether any independent queue-pressure stall remains after this control-flow fix.

## 2026-03-23 - dialogue/choice speech-bubble display lists had zero LP64 pointers

- Symptom/signature:
  - dialogue text rendered, but speech-bubble/window geometry was missing (for example train cat dialogue and K.K. conversations).
  - emu64 diagnostics repeatedly reported zero pointer words on `con_*` symbols:
    - `con_kaiwa2_modelT`
    - `con_kaiwaname_modelT`
    - `con_sentaku2_modelT`
- Root cause:
  - these UI display lists still carried static pointer words for texture/vtx commands.
  - under LP64 static-pointer mode, those `w1` fields were left zero unless explicitly rehydrated at runtime.
- Fix approach and touched files:
  - added guarded one-time LP64 pointer rehydration helpers and call sites in:
    - `src/game/m_msg_data.c_inc`
    - `src/game/m_msg_draw_window.c_inc`
    - `src/game/m_choice_draw.c_inc`
  - added contract `pc/tests/check_msg_choice_window_ptr_patch_contract.sh`.
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes.
  - both LP64 builds succeed.
  - repro log `/tmp/acgc_lp64_msg_choice_bubble_fix_120s.log` shows no `con_*` zero-pointer diagnostics.
  - in-run confirmation: speech bubbles now render again while text remains correct.

## 2026-03-23 - `ef_ha` effect display list carried zero LP64 pointers

- Symptom/signature:
  - after speech-bubble fixes, emu64 zero-pointer diagnostics still reported two hits:
    - `ef_ha01_00_modelT+0x20`
    - `ef_ha01_00_modelT+0x38`
- Root cause:
  - the `ef_ha` effect model display list (`src/data/model/ef_ha01_00.c`) still held static texture/vertex pointer words in `w1`.
  - LP64 static-pointer mode left those words zero until runtime patching.
- Fix approach and touched files:
  - added guarded one-time patch helper `pc_patch_ef_ha01_00_modelT()` in `src/data/model/ef_ha01_00.c`.
  - invoked the helper from the draw path in `src/effect/ef_ha.c` before `gSPDisplayList`.
  - added contract `pc/tests/check_ef_ha01_model_ptr_patch_contract.sh`.
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes with the new contract.
  - both LP64 builds succeed.
  - repro log `/tmp/acgc_lp64_ef_ha_ptr_fix_120s.log` shows no `\[PC\]\[emu64\]\[zero\]` events.
  - continue scanning future logs for any remaining non-`con_*` zero-pointer symbols.

## 2026-03-23 - naming/editor UI display lists had unresolved LP64 pointers

- Symptom/signature:
  - longer train-to-name-entry repros showed large `\[PC\]\[emu64\]\[zero\]` clusters in UI symbols:
    - `nam_win_*`, `mra_win_*`, `rst_win_*`
    - `kai_sousa_*`, `lat_sousa_spT_model`
- Root cause:
  - multiple naming/editor window and keyboard display lists still used static pointer words in `w1`, including nested `gsSPDisplayList` chains and texture/vertex commands.
  - LP64 static-pointer mode left those words unresolved until explicit runtime patching.
- Fix approach and touched files:
  - added LP64 one-time helper patches for naming windows:
    - `src/data/model/nam_win.c`
    - `src/data/model/mra_win.c`
    - `src/data/model/rst_win.c`
  - added LP64 one-time helper patches for editor overlays:
    - `src/data/model/kai_sousa.c`
    - `src/data/model/lat_sp.c`
    - wired helper invocation in `src/game/m_editor_ovl.c`
  - added contracts:
    - `pc/tests/check_name_window_ptr_patch_contract.sh`
    - `pc/tests/check_editor_overlay_ptr_patch_contract.sh`
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes.
  - both LP64 builds succeed.
  - post-fix repros removed all `nam_win_*`, `mra_win_*`, `rst_win_*`, `kai_sousa_*` zero-pointer hits.

## 2026-03-23 - train reaction effects (`warau`/`shock`/`hirameki`) had zero LP64 pointers

- Symptom/signature:
  - train-scene reaction overlays were missing (for example Rover laugh "ha ha" and idea/surprise effects), with zero-pointer diagnostics in:
    - `ef_warau01_*_modelT`
    - `ef_shock01_00_modelT`
    - `ef_hirameki01_den_modelT`
    - `ef_hirameki01_hikari_modelT`
- Root cause:
  - effect model display lists still carried static texture/vertex pointer words in `w1`.
- Fix approach and touched files:
  - added guarded one-time LP64 patch helpers in model files:
    - `src/data/model/ef_warau01_00.c`
    - `src/data/model/ef_shock01_00.c`
    - `src/data/model/ef_hirameki01_den.c`
  - invoked those helpers in effect draw paths:
    - `src/effect/ef_warau.c`
    - `src/effect/ef_shock.c`
    - `src/effect/ef_hirameki_den.c`
    - `src/effect/ef_hirameki_hikari.c`
  - added contracts:
    - `pc/tests/check_ef_warau_model_ptr_patch_contract.sh`
    - `pc/tests/check_ef_reaction_ptr_patch_contract.sh`
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes.
  - both LP64 builds succeed.
  - repro log `/tmp/acgc_lp64_post_reaction_fix_240s.log` shows no `\[PC\]\[emu64\]\[zero\]` events.

## 2026-03-23 - ASan crash at name-entry caused by unterminated display list

- Symptom/signature:
  - ASan build crashed near name-entry transition with:
    - `AddressSanitizer: global-buffer-overflow` in `emu64_taskstart_r` (`emu64.c:6093`)
    - read immediately past global `ledit_common_mode` in `src/data/model/rst_win.c`
- Root cause:
  - `ledit_common_mode` lacked `gsSPEndDisplayList()`, so the display-list interpreter ran past list bounds into adjacent global/redzone memory.
  - same path also still exposed unresolved LP64 pointers for `main1_keitai1_model` / `main2_keitai1_model` in the keitai model path.
- Fix approach and touched files:
  - terminated `ledit_common_mode` with `gsSPEndDisplayList()` in `src/data/model/rst_win.c`.
  - added LP64 patch helper for keitai model display lists in `src/data/model/tol_keitai_1.c`.
  - invoked keitai helper from draw path in `src/actor/tool/ac_t_keitai.c`.
  - added contracts:
    - `pc/tests/check_ledit_common_mode_termination_contract.sh`
    - `pc/tests/check_keitai_model_ptr_patch_contract.sh`
- Verification and follow-up:
  - full contract sweep (`pc/tests/check_*contract.sh`) passes.
  - both LP64 builds succeed.
  - long ASan repro `/tmp/acgc_lp64_asan_post_name_crash_fix_320s.log` reaches timeout with no ASan abort and no `\[PC\]\[emu64\]\[zero\]` hits.

## 2026-03-23 - added fast model-viewer smoke loop for LP64 iteration speed

- Symptom/signature:
  - intro-driven LP64 repros are slow (multi-minute) when triaging rendering/pointer regressions.
- Root cause:
  - no short-cycle harness existed to validate high-risk train/name-entry model assets without replaying full intro flow.
- Fix approach and touched files:
  - extended model viewer coverage to include keitai tool model entries and LP64 patch hooks for train/keitai display lists in `pc/src/pc_model_viewer.c`.
  - added fast smoke script `pc/tests/smoke_model_viewer_targets.sh` (targeted `--model-viewer` runs, ASan/zero-pointer log checks).
  - documented usage in `README.md` and `pc/DOCUMENTATION.md`.
- Verification and follow-up:
  - `bash pc/tests/smoke_model_viewer_targets.sh --bin-dir /tmp/acgc-p2-config-64-asan/bin --timeout 10` passes.
  - `bash pc/tests/smoke_model_viewer_targets.sh --bin-dir /tmp/acgc-p2-config-64/bin --timeout 8` passes.
  - this loop covers model/pointer regressions for train and keitai quickly; scene-scripted behavior/effect timing still requires runtime intro/path repros.

## 2026-03-23 - added `--boot-player-select` for faster train-flow debugging

- Symptom/signature:
  - even with autopress and watchdog tooling, intro/title path setup can add significant wall-clock delay before train/name-entry regressions become observable.
- Root cause:
  - there was no CLI fast path to skip first/title scenes while still keeping normal in-game scene transitions (`player_select -> select -> play`) for scripted train-flow checks.
- Fix approach and touched files:
  - added CLI flag parsing and help text for `--boot-player-select` in `pc/src/pc_main.c`.
  - added global flag declaration in `pc/include/pc_platform.h`.
  - routed `graph_proc` initial game selection to `game_dlftbls[6]` (`player_select`) when enabled in `src/graph.c`.
  - documented the flag in `README.md` and `pc/DOCUMENTATION.md`.
  - added contract `pc/tests/check_boot_player_select_contract.sh`.
- Verification and follow-up:
  - `sh pc/tests/check_boot_player_select_contract.sh` passes.
  - both LP64 builds succeed (`/tmp/acgc-p2-config-64`, `/tmp/acgc-p2-config-64-asan`).
  - `/tmp/acgc-p2-config-64/bin/AnimalCrossing --help` shows the new flag.
  - next step: wire a dedicated smoke script preset around `--boot-player-select` to benchmark train/name-entry time-to-signal against existing watchdog runs.
