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
