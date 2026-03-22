#!/usr/bin/env python3

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Optional, Set, Tuple


REPO_ROOT = Path(__file__).resolve().parents[2]
MARKER = "PC_GBI_STATIC_PTR("


def find_matching(text: str, start: int, open_ch: str, close_ch: str) -> int:
    depth = 0
    i = start

    while i < len(text):
        ch = text[i]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1

    raise ValueError(f"unmatched {open_ch} starting at index {start}")


def split_top_level_entries(initializer: str) -> List[str]:
    entries = []
    current = []
    paren = 0
    brace = 0
    bracket = 0

    for ch in initializer:
        if ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
        elif ch == "," and paren == 0 and brace == 0 and bracket == 0:
            entry = "".join(current).strip()
            if entry:
                entries.append(entry)
            current = []
            continue

        current.append(ch)

    tail = "".join(current).strip()
    if tail:
        entries.append(tail)

    return entries


def extract_marker_args(entry: str) -> List[str]:
    args = []
    search_from = 0

    while True:
        pos = entry.find(MARKER, search_from)
        if pos < 0:
            break

        arg_start = pos + len(MARKER)
        depth = 1
        i = arg_start
        while i < len(entry):
            ch = entry[i]
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1

        if depth != 0:
            raise ValueError("unterminated PC_GBI_STATIC_PTR(...) marker")

        raw = entry[arg_start:i]
        norm = re.sub(r"\s+", " ", raw).strip()
        args.append(norm)
        search_from = i + 1

    return args


def extract_macro_arg(entry: str, macro_name: str, arg_index: int) -> Optional[str]:
    stripped = entry.strip()
    prefix = f"{macro_name}("
    if not stripped.startswith(prefix):
        return None

    open_paren = stripped.find("(")
    close_paren = find_matching(stripped, open_paren, "(", ")")
    args_text = stripped[open_paren + 1:close_paren]
    args = split_top_level_entries(args_text)

    if arg_index >= len(args):
        return None

    return re.sub(r"\s+", " ", args[arg_index]).strip()


def extract_fixups(preprocessed: str, symbol_filter: Optional[Set[str]]) -> List[Tuple[str, int, str]]:
    pattern = re.compile(r"(?:extern\s+)?Gfx\s+([A-Za-z_]\w*)\s*\[\s*\]\s*=\s*\{")
    fixups = []
    pos = 0

    while True:
        match = pattern.search(preprocessed, pos)
        if not match:
            break

        symbol = match.group(1)
        open_brace = preprocessed.find("{", match.end() - 1)
        close_brace = find_matching(preprocessed, open_brace, "{", "}")

        if symbol_filter is None or symbol in symbol_filter:
            body = preprocessed[open_brace + 1:close_brace]
            entries = split_top_level_entries(body)
            for idx, entry in enumerate(entries):
                args = extract_marker_args(entry)
                if not args:
                    vtx_arg = extract_macro_arg(entry, "gsSPVertex", 0)
                    if vtx_arg is not None:
                        args = [vtx_arg]
                for arg in args:
                    fixups.append((symbol, idx, arg))

        pos = close_brace + 1

    return fixups


def preprocess_source(source: Path) -> str:
    compiler = shutil.which("clang") or shutil.which("cc")
    if compiler is None:
        raise RuntimeError("no C preprocessor found (clang/cc)")

    wrapper = (
        "#define PC_STATIC_PTR_H\n"
        "#define PC_STATIC_U32_PTR(ptr) PC_GBI_STATIC_PTR(ptr)\n"
        "#define TARGET_PC 1\n"
        "#define PC_EXPERIMENTAL_64BIT 1\n"
        f"#include \"{source}\"\n"
    )

    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as tmp:
        tmp.write(wrapper)
        wrapper_path = Path(tmp.name)

    cmd = [
        compiler,
        "-E",
        "-P",
        "-I",
        str(REPO_ROOT / "include"),
        "-I",
        str(REPO_ROOT),
        str(wrapper_path),
    ]

    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    finally:
        wrapper_path.unlink(missing_ok=True)

    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate LP64 Gfx w1 pointer-fixup assignments from preprocessed static display lists."
    )
    parser.add_argument("--source", required=True, help="Path to a C source file under the repo")
    parser.add_argument(
        "--symbol",
        action="append",
        help="Optional Gfx symbol filter (may be passed multiple times)",
    )
    args = parser.parse_args()

    source = Path(args.source)
    if not source.is_absolute():
        source = (REPO_ROOT / source).resolve()

    if not source.exists():
        print(f"error: source not found: {source}", file=sys.stderr)
        return 1

    preprocessed = preprocess_source(source)
    symbol_filter = set(args.symbol) if args.symbol else None
    fixups = extract_fixups(preprocessed, symbol_filter)

    print(f"# source: {source.relative_to(REPO_ROOT)}")
    for symbol, idx, expr in fixups:
        print(f"{symbol}[{idx}].words.w1 = pc_gbi_ptr_encode({expr});")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
