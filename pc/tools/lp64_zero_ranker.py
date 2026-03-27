#!/usr/bin/env python3

import argparse
import glob
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
ZERO_RE = re.compile(r"\[PC\]\[emu64\]\[zero\].*?sym=([^+\s]+)")
GFX_DEF_RE = re.compile(r"\b(?:extern\s+)?Gfx\s+([A-Za-z_]\w*)\s*\[\s*\]\s*=\s*\{")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Rank LP64 zero-pointer symbols by likely patch priority using "
            "runtime logs + static source metadata."
        )
    )
    parser.add_argument(
        "--log",
        action="append",
        default=["log_runs/*.log"],
        help="Log file path or glob (may be passed multiple times)",
    )
    parser.add_argument(
        "--include-dir",
        action="append",
        default=[
            "src/data/field/bg/acre",
            "src/data/model",
            "src/data/npc/model/mdl",
        ],
        help="Directory to scan for Gfx symbols (may be passed multiple times)",
    )
    parser.add_argument(
        "--symbol-prefix",
        action="append",
        default=[],
        help="Only include symbols that start with one of these prefixes",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=30,
        help="Number of ranked file rows to print",
    )
    parser.add_argument(
        "--only-missing-helper",
        action="store_true",
        help="Only show files without guarded LP64 patch helpers",
    )
    parser.add_argument(
        "--only-loader",
        action="store_true",
        help="Only show files that have a _pc_load_ loader",
    )
    parser.add_argument(
        "--show-symbols",
        action="store_true",
        help="Show top matched symbols per file",
    )
    return parser.parse_args()


def expand_logs(patterns: list[str]) -> list[Path]:
    logs: list[Path] = []
    for pattern in patterns:
        abs_pattern = str((REPO_ROOT / pattern).resolve()) if not Path(pattern).is_absolute() else pattern
        matches = sorted(Path(p) for p in glob.glob(abs_pattern))
        logs.extend(matches)
    return logs


def parse_zero_counts(log_paths: list[Path], prefixes: list[str]) -> Counter:
    counts: Counter = Counter()
    for path in log_paths:
        try:
            data = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue

        for line in data.splitlines():
            match = ZERO_RE.search(line)
            if not match:
                continue
            symbol = match.group(1)
            if prefixes and not any(symbol.startswith(prefix) for prefix in prefixes):
                continue
            counts[symbol] += 1
    return counts


def build_symbol_map(include_dirs: list[str]) -> dict[str, Path]:
    symbol_map: dict[str, Path] = {}
    for rel_dir in include_dirs:
        root = REPO_ROOT / rel_dir
        if not root.exists():
            continue
        for source in root.rglob("*.c"):
            try:
                text = source.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            for symbol in GFX_DEF_RE.findall(text):
                symbol_map.setdefault(symbol, source)
    return symbol_map


def file_metadata(path: Path) -> tuple[bool, bool]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    has_loader = "_pc_load_" in text
    has_helper = "PC_EXPERIMENTAL_64BIT" in text and "pc_patch_" in text
    return has_loader, has_helper


def generator_fixup_count(path: Path) -> int:
    cmd = [
        sys.executable,
        str(REPO_ROOT / "pc/tools/gen_gfx_w1_fixups.py"),
        "--source",
        str(path.relative_to(REPO_ROOT)),
    ]
    proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        return 0
    count = 0
    for line in proc.stdout.splitlines():
        if line and not line.startswith("# source:"):
            count += 1
    return count


def score_row(hits: int, fixups: int, has_loader: bool, has_helper: bool) -> int:
    score = hits * 100 + min(fixups, 200)
    score += 50 if has_loader else -200
    score += 20 if not has_helper else -20
    return score


def main() -> int:
    args = parse_args()

    logs = expand_logs(args.log)
    if not logs:
        print("no logs matched", file=sys.stderr)
        return 1

    symbol_counts = parse_zero_counts(logs, args.symbol_prefix)
    if not symbol_counts:
        print("no zero-pointer symbols found", file=sys.stderr)
        return 2

    symbol_map = build_symbol_map(args.include_dir)

    file_symbols: dict[Path, list[tuple[str, int]]] = defaultdict(list)
    unresolved: Counter = Counter()
    for symbol, hits in symbol_counts.items():
        source = symbol_map.get(symbol)
        if source is None:
            unresolved[symbol] = hits
            continue
        file_symbols[source].append((symbol, hits))

    rows = []
    for source, symbol_hits in file_symbols.items():
        hits = sum(hit for _, hit in symbol_hits)
        has_loader, has_helper = file_metadata(source)
        if args.only_loader and not has_loader:
            continue
        if args.only_missing_helper and has_helper:
            continue
        fixups = generator_fixup_count(source)
        score = score_row(hits, fixups, has_loader, has_helper)
        rows.append((score, hits, fixups, has_loader, has_helper, source, sorted(symbol_hits, key=lambda x: -x[1])))

    rows.sort(key=lambda row: (-row[0], -row[1], str(row[5])))

    print(f"logs={len(logs)} symbols={sum(symbol_counts.values())} unique_symbols={len(symbol_counts)}")
    print("score hits fixups loader helper file")
    for score, hits, fixups, has_loader, has_helper, source, syms in rows[: args.top]:
        print(
            f"{score:5d} {hits:4d} {fixups:6d} "
            f"{str(has_loader):>6s} {str(has_helper):>6s} {source.relative_to(REPO_ROOT)}"
        )
        if args.show_symbols:
            summary = ", ".join(f"{name}:{count}" for name, count in syms[:5])
            print(f"      symbols: {summary}")

    if unresolved:
        print("unresolved symbols:")
        for symbol, hits in unresolved.most_common(min(15, len(unresolved))):
            print(f"  {hits:4d} {symbol}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
