#!/usr/bin/env python3

import argparse
import ast
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Optional, Set, Tuple


REPO_ROOT = Path(__file__).resolve().parents[2]
MARKER = "PC_GBI_STATIC_PTR("
IDENTIFIER_RE = re.compile(r"\b[A-Za-z_]\w*\b")
FALLBACK_MACRO_ARGS = [
    ("gsSPVertex", 0),
    ("gsSPMatrix", 0),
    ("gsSPDisplayList", 0),
    ("gsSPBranchList", 0),
]
TYPE_TOKENS = {
    "Mtx",
    "Vtx",
    "Gfx",
    "LookAt",
    "Hilite",
    "u8",
    "u16",
    "u32",
    "u64",
    "s8",
    "s16",
    "s32",
    "s64",
    "uintptr_t",
    "size_t",
    "unsigned",
    "signed",
    "char",
    "short",
    "int",
    "long",
    "const",
    "volatile",
    "struct",
    "sizeof",
}
SEGMENT_BASE_RE = re.compile(r"^\(\(([A-Za-z_]\w*)\*\)\(\(\((0x[0-9A-Fa-f]+)\) << 24\) \+ \((.+)\)\)\)$")
SEGMENT_INDEXED_RE = re.compile(
    r"^&\(\(([A-Za-z_]\w*)\*\)\(\(\((0x[0-9A-Fa-f]+)\) << 24\) \+ \((.+)\)\)\)\[(\d+)\]$"
)
TYPE_SIZE_BYTES = {
    "u8": 1,
    "s8": 1,
    "char": 1,
    "u16": 2,
    "s16": 2,
    "u32": 4,
    "s32": 4,
    "Gfx": 8,
    "Vtx": 16,
    "Mtx": 64,
}
SEGMENT_SYMBOL_VALUES = {
    "SOFTSPRITE_MTX_SEG": 0x07,
    "ANIME_1_TXT_SEG": 0x08,
    "ANIME_2_TXT_SEG": 0x09,
    "ANIME_3_TXT_SEG": 0x0A,
    "ANIME_4_TXT_SEG": 0x0B,
    "ANIME_5_TXT_SEG": 0x0C,
    "ANIME_6_TXT_SEG": 0x0D,
}
SEGMENT_ADDR_RE = re.compile(r"^SEGMENT_ADDR\(\s*([^,]+)\s*,\s*(.+)\)\s*$")


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
                    for macro_name, arg_index in FALLBACK_MACRO_ARGS:
                        macro_arg = extract_macro_arg(entry, macro_name, arg_index)
                        if macro_arg is not None:
                            args = [macro_arg]
                            break
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


def try_parse_int(text: str) -> Optional[int]:
    stripped = text.strip()
    if not stripped:
        return None
    try:
        return int(stripped, 0)
    except ValueError:
        return None


def format_offset(value: int) -> str:
    return f"0x{value:X}"


def segment_addr_expr(expr: str) -> Optional[str]:
    indexed = SEGMENT_INDEXED_RE.match(expr)
    if indexed:
        elem_type = indexed.group(1)
        seg = indexed.group(2)
        base_offset = indexed.group(3).strip()
        index = int(indexed.group(4))

        elem_size = TYPE_SIZE_BYTES.get(elem_type)
        if elem_size is None:
            return None

        base_val = try_parse_int(base_offset)
        if base_val is not None:
            total = base_val + (index * elem_size)
            return f"SEGMENT_ADDR({seg}, {format_offset(total)})"

        if index == 0:
            return f"SEGMENT_ADDR({seg}, {base_offset})"

        return f"SEGMENT_ADDR({seg}, ({base_offset}) + ({index} * {elem_size}))"

    base = SEGMENT_BASE_RE.match(expr)
    if base:
        seg = base.group(2)
        offset = base.group(3).strip()
        offset_val = try_parse_int(offset)
        if offset_val is not None:
            return f"SEGMENT_ADDR({seg}, {format_offset(offset_val)})"
        return f"SEGMENT_ADDR({seg}, {offset})"

    if "<<" in expr and "24" in expr:
        value = eval_int_expr(expr)
        if value is not None and 0 <= value <= 0xFFFFFFFF:
            seg = (value >> 24) & 0xFF
            off = value & 0x00FFFFFF
            if seg != 0:
                return f"SEGMENT_ADDR(0x{seg:X}, {format_offset(off)})"

    return None


def is_segment_constant_expr(expr: str) -> bool:
    if "SEGMENT_ADDR(" in expr:
        return True

    tokens = IDENTIFIER_RE.findall(expr)
    for token in tokens:
        if token not in TYPE_TOKENS:
            return False

    return True


def format_fixup(symbol: str, idx: int, expr: str) -> str:
    if is_segment_constant_expr(expr):
        segment_expr = segment_addr_expr(expr)
        if segment_expr is not None:
            return f"{symbol}[{idx}].words.w1 = {segment_expr};"
        return f"{symbol}[{idx}].words.w1 = (unsigned int)(uintptr_t)({expr});"
    return f"{symbol}[{idx}].words.w1 = pc_gbi_ptr_encode({expr});"


def render_helper_block(guard_line: str, helper_name: str, storage: str, fixups: List[Tuple[str, int, str]]) -> str:
    sig = f"{storage}void {helper_name}(void)"
    lines = [
        guard_line,
        f"{sig} {{",
        "    static int s_patched = FALSE;",
        "",
        "    if (s_patched) {",
        "        return;",
        "    }",
        "",
    ]

    for symbol, idx, expr in fixups:
        lines.append(f"    {format_fixup(symbol, idx, expr)}")

    lines.extend(
        [
            "",
            "    s_patched = TRUE;",
            "}",
            "#else",
            f"{sig} {{",
            "}",
            "#endif",
        ]
    )

    return "\n".join(lines)


def find_helper_block(source_text: str, helper_name: str) -> Tuple[str, str, Tuple[int, int]]:
    pattern = re.compile(
        rf"(?P<guard>^#if[^\n]*PC_EXPERIMENTAL_64BIT[^\n]*$)\n"
        rf"(?P<sig>(?:static\s+)?void\s+{re.escape(helper_name)}\s*\(\s*void\s*\))\s*\{{.*?\n\}}\n"
        rf"#else\n"
        rf"(?:static\s+)?void\s+{re.escape(helper_name)}\s*\(\s*void\s*\)\s*\{{\n\}}\n"
        rf"#endif",
        re.DOTALL | re.MULTILINE,
    )

    match = pattern.search(source_text)
    if not match:
        raise RuntimeError(f"could not locate replaceable helper block for {helper_name}")

    sig = match.group("sig")
    storage = "static " if sig.startswith("static ") else ""
    return match.group("guard"), storage, match.span()


def replace_helper_block(source_text: str, span: Tuple[int, int], replacement_block: str) -> str:
    return source_text[:span[0]] + replacement_block + source_text[span[1]:]


def helper_fixup_lines(helper_block: str) -> List[str]:
    lines = []
    for line in helper_block.splitlines():
        stripped = line.strip()
        if ".words.w1 =" in stripped and stripped.endswith(";"):
            lines.append(stripped)
    return lines


def eval_int_expr(expr: str) -> Optional[int]:
    expanded = expr
    for type_name, size in TYPE_SIZE_BYTES.items():
        expanded = re.sub(rf"\bsizeof\s*\(\s*{re.escape(type_name)}\s*\)", str(size), expanded)

    for seg_name, seg_value in SEGMENT_SYMBOL_VALUES.items():
        expanded = re.sub(rf"\b{re.escape(seg_name)}\b", str(seg_value), expanded)

    if not re.match(r"^[0-9A-Fa-fxX()+\-*/%<>&|^~\s]+$", expanded):
        return None

    try:
        parsed = ast.parse(expanded, mode="eval")
    except SyntaxError:
        return None

    def _eval(node: ast.AST) -> int:
        if isinstance(node, ast.Expression):
            return _eval(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, int):
            return int(node.value)
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
            val = _eval(node.operand)
            return val if isinstance(node.op, ast.UAdd) else -val
        if isinstance(node, ast.BinOp):
            left = _eval(node.left)
            right = _eval(node.right)
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if isinstance(node.op, (ast.Div, ast.FloorDiv)):
                if right == 0:
                    raise ZeroDivisionError
                return left // right
            if isinstance(node.op, ast.Mod):
                if right == 0:
                    raise ZeroDivisionError
                return left % right
            if isinstance(node.op, ast.LShift):
                return left << right
            if isinstance(node.op, ast.RShift):
                return left >> right
            if isinstance(node.op, ast.BitAnd):
                return left & right
            if isinstance(node.op, ast.BitOr):
                return left | right
            if isinstance(node.op, ast.BitXor):
                return left ^ right
        raise ValueError("unsupported expression")

    try:
        return _eval(parsed)
    except Exception:
        return None


def canonicalize_fixup_line(line: str) -> str:
    stripped = line.strip()
    assign_match = re.match(r"^(\w+\[\d+\]\.words\.w1)\s*=\s*(.+);$", stripped)
    if not assign_match:
        return stripped

    lhs = assign_match.group(1)
    rhs = assign_match.group(2).strip()
    seg_match = SEGMENT_ADDR_RE.match(rhs)
    if not seg_match:
        return stripped

    seg_expr = seg_match.group(1).strip()
    off_expr = seg_match.group(2).strip()

    seg_val = eval_int_expr(seg_expr)
    off_val = eval_int_expr(off_expr)
    if seg_val is None or off_val is None:
        return stripped

    return f"{lhs} = SEGMENT_ADDR(0x{seg_val:X}, 0x{off_val:X});"


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
    parser.add_argument(
        "--emit-helper",
        help="Emit generated assignments inside a guarded patch helper with this function name",
    )
    parser.add_argument(
        "--apply-helper",
        help="Replace an existing guarded helper block in --source with generated assignments",
    )
    parser.add_argument(
        "--check-helper",
        help="Check that an existing guarded helper block matches generated assignments",
    )
    args = parser.parse_args()

    helper_modes = [args.emit_helper, args.apply_helper, args.check_helper]
    if sum(1 for mode in helper_modes if mode is not None) > 1:
        print("error: --emit-helper, --apply-helper, and --check-helper are mutually exclusive", file=sys.stderr)
        return 1

    source = Path(args.source)
    if not source.is_absolute():
        source = (REPO_ROOT / source).resolve()

    if not source.exists():
        print(f"error: source not found: {source}", file=sys.stderr)
        return 1

    preprocessed = preprocess_source(source)
    symbol_filter = set(args.symbol) if args.symbol else None
    fixups = extract_fixups(preprocessed, symbol_filter)

    try:
        source_display = source.relative_to(REPO_ROOT)
    except ValueError:
        source_display = source

    print(f"# source: {source_display}")
    if args.emit_helper:
        helper_block = render_helper_block("#if defined(TARGET_PC) && defined(PC_EXPERIMENTAL_64BIT)", args.emit_helper,
                                           "", fixups)
        print(helper_block)
    elif args.apply_helper:
        source_text = source.read_text(encoding="utf-8", errors="replace")
        guard, storage, span = find_helper_block(source_text, args.apply_helper)
        helper_block = render_helper_block(guard, args.apply_helper, storage, fixups)
        updated = replace_helper_block(source_text, span, helper_block)
        if updated != source_text:
            source.write_text(updated, encoding="utf-8")
        print(f"# updated helper: {args.apply_helper}")
    elif args.check_helper:
        source_text = source.read_text(encoding="utf-8", errors="replace")
        guard, storage, span = find_helper_block(source_text, args.check_helper)
        expected_block = render_helper_block(guard, args.check_helper, storage, fixups)
        expected_lines = [canonicalize_fixup_line(line) for line in helper_fixup_lines(expected_block)]
        actual_lines = [canonicalize_fixup_line(line) for line in helper_fixup_lines(source_text[span[0]:span[1]])]

        if actual_lines != expected_lines:
            print(f"# helper mismatch: {args.check_helper}", file=sys.stderr)

            expected_only = [line for line in expected_lines if line not in actual_lines]
            actual_only = [line for line in actual_lines if line not in expected_lines]

            if expected_only:
                print("# missing lines:", file=sys.stderr)
                for line in expected_only:
                    print(line, file=sys.stderr)

            if actual_only:
                print("# unexpected lines:", file=sys.stderr)
                for line in actual_only:
                    print(line, file=sys.stderr)

            return 2

        print(f"# helper matches: {args.check_helper}")
    else:
        for symbol, idx, expr in fixups:
            print(format_fixup(symbol, idx, expr))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
