#!/usr/bin/env python3

"""Run Animal Crossing with automatic train-scene hang detection.

This watchdog intentionally uses multiple soft-hang signals because the train
stall does not present identically on every run/build:
  - scene gate marker (`[SCENE_MODE] 3 -> 4`) when available
  - sustained `SendStart::Mesg Full Queue` pressure over time windows
  - saturated queue samples with frozen read/write positions
  - low log-template entropy during queue pressure loops

The goal is to stop reproducible train hangs without requiring manual force-quit.
"""

from __future__ import annotations

import argparse
import os
import re
import select
import subprocess
import sys
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path


SCENE_GATE_TOKEN = "[SCENE_MODE] 3 -> 4"
QUEUE_FULL_TOKEN = "SendStart::Mesg Full Queue"

HEX_RE = re.compile(r"0x[0-9a-fA-F]+")
FLOAT_RE = re.compile(r"(?<![A-Za-z_])-?\d+\.\d+")
INT_RE = re.compile(r"(?<![A-Za-z_])-?\d+")
WS_RE = re.compile(r"\s+")

QUEUE_SAMPLE_RE = re.compile(
    r"SendStart::Mesg Full Queue rs=(?P<rs>-?\d+) rt=(?P<rt>-?\d+) "
    r"valid=(?P<valid>\d+) r=(?P<read>\d+) w=(?P<write>\d+)"
)
NEOS_FRAME_RE = re.compile(r"\[NEOS_OUT\]\s+frame=(?P<frame>\d+)")
SCENE_MODE_RE = re.compile(r"\[SCENE_MODE\]\s+(?P<from>-?\d+)\s*->\s*(?P<to>-?\d+)")


@dataclass
class WatchdogState:
    start_time: float
    last_line_ts: float
    last_progress_ts: float

    seen_scene_gate: bool = False
    monitor_armed: bool = False
    arm_reason: str = ""
    monitor_start_ts: float = 0.0

    # Progress markers let us avoid false positives when queues look stressed
    # but frame/scene logs are still advancing.
    last_neos_frame: int | None = None
    current_scene_mode: int | None = None
    scene_mode_since_ts: float | None = None

    # Queue-full tracking uses time windows, not absolute counts.
    queue_full_total: int = 0
    queue_full_times: deque[float] = field(default_factory=deque)
    queue_streak_start_ts: float | None = None
    queue_streak_count: int = 0
    last_queue_full_ts: float | None = None

    # Queue sample diagnostics (valid/r/w) allow us to detect a saturated queue
    # that is no longer making progress even if line rate varies.
    last_queue_valid: int | None = None
    last_queue_rw: tuple[int, int] | None = None
    last_queue_rw_change_ts: float | None = None
    last_queue_sample_ts: float | None = None

    # Template entropy captures tight log loops where lots of lines are emitted
    # but with very little semantic variation.
    templates: deque[tuple[float, str]] = field(default_factory=deque)

    # Keep a short in-memory tail for stop diagnostics.
    tail_lines: deque[str] = field(default_factory=lambda: deque(maxlen=160))


def terminate_process(proc: subprocess.Popen[str], grace_seconds: float) -> None:
    if proc.poll() is not None:
        return

    proc.terminate()

    try:
        proc.wait(timeout=grace_seconds)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Animal Crossing and auto-terminate on train-scene soft-hang signatures."
    )
    parser.add_argument("--workdir", required=True, help="Working directory for the game process")
    parser.add_argument("--log", required=True, help="Path to write combined stdout/stderr log")

    parser.add_argument("--timeout-seconds", type=float, default=300.0, help="Hard timeout for the run")
    parser.add_argument(
        "--start-gate-timeout",
        type=float,
        default=90.0,
        help="Arm monitoring after this many seconds if [SCENE_MODE] 3 -> 4 never appears",
    )
    parser.add_argument(
        "--warmup-seconds",
        type=float,
        default=10.0,
        help="Ignore hang signatures for this duration after monitoring arms",
    )
    parser.add_argument(
        "--no-output-timeout",
        type=float,
        default=0.0,
        help="Terminate if no log line is seen for this long (0 disables)",
    )
    parser.add_argument(
        "--no-progress-timeout",
        type=float,
        default=45.0,
        help="Require no observed progress for this long before queue-pressure hang triggers fire (0 disables)",
    )
    parser.add_argument(
        "--scene4-stall-seconds",
        type=float,
        default=180.0,
        help="Treat prolonged scene-mode 4 residency as potential stall context for hang triggers (0 disables)",
    )
    parser.add_argument(
        "--monitor-max-seconds",
        type=float,
        default=0.0,
        help="Optional cap for monitoring window after arm (0 disables)",
    )

    parser.add_argument("--queue-window-seconds", type=float, default=20.0, help="Window for queue-full rate checks")
    parser.add_argument(
        "--queue-rate-threshold",
        type=float,
        default=1.0,
        help="Queue-full line rate threshold (events/sec) in queue window",
    )
    parser.add_argument(
        "--queue-rate-min-events",
        type=int,
        default=20,
        help="Minimum queue-full events in queue window before rate trigger can fire",
    )
    parser.add_argument(
        "--queue-streak-seconds",
        type=float,
        default=15.0,
        help="Continuous queue-full streak duration needed for hang detection",
    )
    parser.add_argument(
        "--queue-streak-gap-seconds",
        type=float,
        default=2.5,
        help="Gap that breaks queue-full streak continuity",
    )
    parser.add_argument(
        "--queue-streak-min-events",
        type=int,
        default=30,
        help="Minimum events required in a queue-full streak",
    )
    parser.add_argument(
        "--queue-rw-valid",
        type=int,
        default=64,
        help="Queue validCount threshold considered 'saturated' for rw-stuck checks",
    )
    parser.add_argument(
        "--queue-rw-stuck-seconds",
        type=float,
        default=12.0,
        help="Terminate if saturated queue r/w positions do not change for this long",
    )

    parser.add_argument("--entropy-window-seconds", type=float, default=25.0, help="Template entropy window")
    parser.add_argument(
        "--entropy-min-lines",
        type=int,
        default=120,
        help="Minimum lines in entropy window before low-entropy trigger can fire",
    )
    parser.add_argument(
        "--entropy-max-unique",
        type=int,
        default=10,
        help="Maximum unique templates allowed in low-entropy trigger",
    )
    parser.add_argument(
        "--entropy-queue-min-events",
        type=int,
        default=20,
        help="Require at least this many queue-full events when using low-entropy trigger",
    )

    # Backward compatibility with v1 scripts.
    parser.add_argument(
        "--queue-full-threshold",
        type=int,
        default=0,
        help="Legacy absolute queue-full threshold after arm (0 disables)",
    )
    parser.add_argument(
        "--tail-lines",
        type=int,
        default=160,
        help="How many recent lines to keep in memory for stop diagnostics",
    )

    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="Command to run (default: ./AnimalCrossing -v)",
    )
    return parser.parse_args()


def normalize_template(line: str) -> str:
    """Normalize numbers so repeated loops collapse into stable templates."""

    text = line.strip()
    if not text:
        return ""

    text = HEX_RE.sub("0x#", text)
    text = FLOAT_RE.sub("#.#", text)
    text = INT_RE.sub("#", text)
    text = WS_RE.sub(" ", text)
    return text


def prune_times(values: deque[float], now: float, window_seconds: float) -> None:
    while values and (now - values[0]) > window_seconds:
        values.popleft()


def prune_templates(values: deque[tuple[float, str]], now: float, window_seconds: float) -> None:
    while values and (now - values[0][0]) > window_seconds:
        values.popleft()


def arm_monitor(state: WatchdogState, now: float, reason: str) -> None:
    """Reset per-monitor counters so we analyze only the current monitoring phase."""

    state.monitor_armed = True
    state.monitor_start_ts = now
    state.arm_reason = reason
    state.last_progress_ts = now

    state.queue_full_total = 0
    state.queue_full_times.clear()
    state.queue_streak_start_ts = None
    state.queue_streak_count = 0
    state.last_queue_full_ts = None

    state.last_queue_valid = None
    state.last_queue_rw = None
    state.last_queue_rw_change_ts = None
    state.last_queue_sample_ts = None

    state.templates.clear()


def ingest_line(state: WatchdogState, args: argparse.Namespace, line: str, now: float) -> None:
    state.last_line_ts = now
    state.tail_lines.append(line.rstrip("\n"))

    scene_mode_match = SCENE_MODE_RE.search(line)
    if scene_mode_match:
        state.current_scene_mode = int(scene_mode_match.group("to"))
        state.scene_mode_since_ts = now
        # Scene transition is a strong progression marker.
        state.last_progress_ts = now

    neos_frame_match = NEOS_FRAME_RE.search(line)
    if neos_frame_match:
        neos_frame = int(neos_frame_match.group("frame"))
        if state.last_neos_frame is None or neos_frame > state.last_neos_frame:
            state.last_progress_ts = now
        state.last_neos_frame = neos_frame

    if SCENE_GATE_TOKEN in line:
        state.seen_scene_gate = True
        # Prefer arming from the explicit train-scene gate when available.
        if not state.monitor_armed or state.arm_reason != "scene-gate":
            arm_monitor(state, now, "scene-gate")

    if not state.monitor_armed:
        return

    template = normalize_template(line)
    if template:
        state.templates.append((now, template))

    if QUEUE_FULL_TOKEN in line:
        state.queue_full_total += 1
        state.queue_full_times.append(now)

        if state.last_queue_full_ts is None or (now - state.last_queue_full_ts) > args.queue_streak_gap_seconds:
            state.queue_streak_start_ts = now
            state.queue_streak_count = 1
        else:
            state.queue_streak_count += 1

        state.last_queue_full_ts = now

        sample_match = QUEUE_SAMPLE_RE.search(line)
        if sample_match:
            valid = int(sample_match.group("valid"))
            read_pos = int(sample_match.group("read"))
            write_pos = int(sample_match.group("write"))
            rw = (read_pos, write_pos)

            state.last_queue_valid = valid
            state.last_queue_sample_ts = now

            if state.last_queue_rw != rw:
                state.last_queue_rw = rw
                state.last_queue_rw_change_ts = now


def format_metrics(
    state: WatchdogState,
    args: argparse.Namespace,
    now: float,
    queue_recent_count: int,
    queue_rate: float,
    queue_streak_age: float,
    rw_stuck_age: float,
    no_progress_age: float,
    scene4_age: float,
    entropy_unique: int,
    entropy_lines: int,
) -> str:
    monitor_age = now - state.monitor_start_ts if state.monitor_armed else 0.0
    valid = state.last_queue_valid if state.last_queue_valid is not None else -1
    scene_mode = state.current_scene_mode if state.current_scene_mode is not None else -1
    neos_frame = state.last_neos_frame if state.last_neos_frame is not None else -1
    return (
        f"arm={state.arm_reason} monitor={monitor_age:.1f}s "
        f"scene={scene_mode} scene4_age={scene4_age:.1f}s neos_frame={neos_frame} no_progress={no_progress_age:.1f}s "
        f"q_total={state.queue_full_total} q_recent={queue_recent_count}/{args.queue_window_seconds:.1f}s "
        f"q_rate={queue_rate:.2f}/s q_streak={queue_streak_age:.1f}s/{state.queue_streak_count} "
        f"q_valid={valid} q_rw_stuck={rw_stuck_age:.1f}s "
        f"entropy={entropy_unique}/{entropy_lines}"
    )


def evaluate_stop(state: WatchdogState, args: argparse.Namespace, now: float) -> tuple[str | None, str]:
    elapsed = now - state.start_time

    if args.timeout_seconds > 0 and elapsed >= args.timeout_seconds:
        return "timeout", f"timeout ({args.timeout_seconds:.1f}s)"

    if args.no_output_timeout > 0 and (now - state.last_line_ts) >= args.no_output_timeout:
        return "timeout", f"no output for {(now - state.last_line_ts):.1f}s"

    if (not state.monitor_armed) and args.start_gate_timeout > 0 and elapsed >= args.start_gate_timeout:
        # If scene gate never appears, still arm monitoring so we are not stuck
        # waiting forever for a single log marker.
        arm_monitor(state, now, "start-gate-timeout")

    if not state.monitor_armed:
        return None, ""

    monitor_age = now - state.monitor_start_ts
    if args.monitor_max_seconds > 0 and monitor_age >= args.monitor_max_seconds:
        return "timeout", f"monitor timeout ({args.monitor_max_seconds:.1f}s after arm)"

    if monitor_age < args.warmup_seconds:
        return None, ""

    no_progress_age = now - state.last_progress_ts
    scene4_age = 0.0
    if state.current_scene_mode == 4 and state.scene_mode_since_ts is not None:
        scene4_age = now - state.scene_mode_since_ts

    prune_times(state.queue_full_times, now, args.queue_window_seconds)
    prune_templates(state.templates, now, args.entropy_window_seconds)

    queue_recent_count = len(state.queue_full_times)
    queue_rate = queue_recent_count / max(args.queue_window_seconds, 0.001)

    queue_streak_age = 0.0
    if (
        state.queue_streak_start_ts is not None
        and state.last_queue_full_ts is not None
        and (now - state.last_queue_full_ts) <= args.queue_streak_gap_seconds
    ):
        queue_streak_age = now - state.queue_streak_start_ts

    rw_stuck_age = 0.0
    if (
        state.last_queue_sample_ts is not None
        and state.last_queue_rw_change_ts is not None
        and state.last_queue_valid is not None
        and state.last_queue_valid >= args.queue_rw_valid
        and state.last_queue_full_ts is not None
        and (now - state.last_queue_full_ts) <= (args.queue_streak_gap_seconds * 2.0)
    ):
        rw_stuck_age = now - state.last_queue_rw_change_ts

    entropy_lines = len(state.templates)
    entropy_unique = len({template for _, template in state.templates}) if entropy_lines else 0
    entropy_low = entropy_lines >= args.entropy_min_lines and entropy_unique <= args.entropy_max_unique

    metrics = format_metrics(
        state,
        args,
        now,
        queue_recent_count,
        queue_rate,
        queue_streak_age,
        rw_stuck_age,
        no_progress_age,
        scene4_age,
        entropy_unique,
        entropy_lines,
    )

    # Guard rail: avoid queue-pressure false positives while the game is still
    # clearly progressing, unless scene 4 has been resident abnormally long.
    no_progress_context = args.no_progress_timeout > 0 and no_progress_age >= args.no_progress_timeout
    scene4_stall_context = args.scene4_stall_seconds > 0 and scene4_age >= args.scene4_stall_seconds
    hang_context = no_progress_context or scene4_stall_context

    # Legacy absolute threshold is optional and disabled by default.
    if args.queue_full_threshold > 0 and state.queue_full_total >= args.queue_full_threshold:
        return "hang", f"legacy queue-full threshold reached ({metrics})"

    if hang_context and rw_stuck_age >= args.queue_rw_stuck_seconds and queue_recent_count >= args.queue_rate_min_events:
        return "hang", f"saturated queue read/write stalled ({metrics})"

    if hang_context and queue_streak_age >= args.queue_streak_seconds and state.queue_streak_count >= args.queue_streak_min_events:
        return "hang", f"sustained queue-full streak ({metrics})"

    if (
        hang_context
        and
        queue_rate >= args.queue_rate_threshold
        and queue_recent_count >= args.queue_rate_min_events
        and entropy_low
        and queue_recent_count >= args.entropy_queue_min_events
    ):
        return "hang", f"queue pressure + low entropy loop ({metrics})"

    return None, ""


def main() -> int:
    args = parse_args()

    command = args.command if args.command else ["./AnimalCrossing", "-v"]
    if command and command[0] == "--":
        command = command[1:]

    if not command:
        print("error: command is empty", file=sys.stderr)
        return 2

    workdir = Path(args.workdir)
    if not workdir.is_dir():
        print(f"error: workdir does not exist: {workdir}", file=sys.stderr)
        return 2

    log_path = Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()

    proc = subprocess.Popen(
        command,
        cwd=str(workdir),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        errors="replace",
    )

    start_time = time.monotonic()
    state = WatchdogState(start_time=start_time, last_line_ts=start_time, last_progress_ts=start_time)
    state.tail_lines = deque(maxlen=max(1, args.tail_lines))

    stop_kind: str | None = None
    stop_reason = ""

    try:
        with log_path.open("w", encoding="utf-8") as log_file:
            assert proc.stdout is not None
            stdout_pipe = proc.stdout

            while True:
                now = time.monotonic()

                stop_kind, stop_reason = evaluate_stop(state, args, now)
                if stop_kind is not None:
                    break

                if proc.poll() is not None:
                    # Drain any buffered output before exiting.
                    line = stdout_pipe.readline()
                    if line:
                        now = time.monotonic()
                        log_file.write(line)
                        ingest_line(state, args, line, now)
                        continue
                    break

                readable, _, _ = select.select([stdout_pipe], [], [], 0.1)
                if not readable:
                    continue

                line = stdout_pipe.readline()
                if not line:
                    continue

                now = time.monotonic()
                log_file.write(line)
                ingest_line(state, args, line, now)
    finally:
        if proc.poll() is None:
            terminate_process(proc, grace_seconds=3.0)

    exit_code = proc.returncode if proc.returncode is not None else 1

    if stop_kind == "hang":
        print(f"[WATCHDOG] Detected train hang signature: {stop_reason}; process terminated.")
        print(f"[WATCHDOG] Log: {log_path}")
        return 124

    if stop_kind == "timeout":
        print(f"[WATCHDOG] Stopped due to {stop_reason}; process terminated.")
        print(f"[WATCHDOG] Log: {log_path}")
        return 124

    print(f"[WATCHDOG] Process exited with code {exit_code}.")
    print(f"[WATCHDOG] Log: {log_path}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
