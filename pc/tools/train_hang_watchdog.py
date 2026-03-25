#!/usr/bin/env python3

"""Compatibility wrapper for the renamed repro watchdog.

Use `pc/tools/repro_watchdog.py` for new commands.
"""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("repro_watchdog.py")), run_name="__main__")
