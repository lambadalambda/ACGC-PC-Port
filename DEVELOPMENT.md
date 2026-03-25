# Development Workflow Notes

This file documents reproducible runtime logging commands used for LP64/portability investigations.

## Repro Watchdog

- Primary script: `pc/tools/repro_watchdog.py`
- Legacy alias (kept for compatibility): `pc/tools/train_hang_watchdog.py`

Use the repro watchdog to run the game, capture combined stdout/stderr logs, and auto-stop on common soft-hang signatures instead of force-quitting manually.

## Recommended LP64 Repro Command (Autopress)

Use this for deterministic intro progression and long run capture:

```bash
python3 pc/tools/repro_watchdog.py \
  --workdir /tmp/acgc-p2-config-64/bin \
  --log /tmp/acgc_lp64_repro_$(date +%Y%m%d_%H%M%S).log \
  --timeout-seconds 480 \
  env \
    PC_AUTOPRESS_A=1 \
    PC_AUTOPRESS_START=1 \
    PC_AUTOPRESS_START_START=3600 \
    PC_AUTOPRESS_START_EVERY=120 \
    PC_AUTOPRESS_START_HOLD=2 \
    ./AnimalCrossing -v --on-screen-timer
```

Notes:
- `--on-screen-timer` draws `T+MM:SS` (or `T+HH:MM:SS`) to make bug timestamps easy to report.
- Delayed START avoids skipping past early text-entry stages.

## Manual Repro Command

Use this when you want full manual control:

```bash
python3 pc/tools/repro_watchdog.py \
  --workdir /tmp/acgc-p2-config-64/bin \
  --log /tmp/acgc_lp64_manual_$(date +%Y%m%d_%H%M%S).log \
  --timeout-seconds 600 \
  ./AnimalCrossing -v --on-screen-timer
```

## Useful Log Extraction Commands

```bash
rg "\[SCENE_MODE\]" /tmp/acgc_lp64_repro_*.log
rg "\[PC\]\[emu64\]\[zero\]" /tmp/acgc_lp64_repro_*.log | wc -l
```

## What To Include With a Bug Report

For each repro, include:
- exact command used
- log file path
- save context (fresh save vs existing town)
- short step list
- timestamp from on-screen timer where issue appears (for example: `T+08:14`)
