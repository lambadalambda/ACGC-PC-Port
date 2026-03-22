# AGENTS.md

This file applies to the whole repository.

## Mission

Preserve the existing working 32-bit PC port while making disciplined progress toward a 64-bit-clean codebase and, eventually, modern macOS support.

Modern macOS support is not a small platform shim. Treat it as a 64-bit portability effort first.

## Read These First

- `README.md` for the current supported user-facing build and run flow.
- `pc/DOCUMENTATION.md` for runtime architecture and the current PC port layer.
- `docs/macos_port_assessment.md` for the current macOS blocker analysis.
- `docs/macos_port_strategy.md` for the recommended repo strategy and prioritized blocker list.
- `docs/lp64_findings.md` for a running log of LP64 issues, fixes, and validation notes.

## Core Working Rules

- Keep changes small, topical, and reversible.
- Prefer root-cause fixes over compatibility casts, warning suppression, or workaround layering.
- Preserve the current 32-bit path as a reference until 64-bit bringup is proven.
- Do not silently widen scope. If a task grows, split it into follow-up commits.
- Avoid incidental formatting churn.
- Do not hand-edit generated files when the real source of truth is a generator.
- When modifying code, add concise intent comments for non-obvious or diagnostic logic so later sessions can evaluate whether the change worked.

## TDD First

Use TDD whenever practical: red -> green -> refactor.

There is no strong automated test harness in this repo today, so apply TDD in the broadest useful sense:

- Start with the smallest failing check that proves the bug or missing behavior.
- Then make it pass with the smallest reasonable change.
- Then refactor only after the check stays green.

Acceptable "red" steps in this repo include:

- a small host-side unit test for a pure helper
- a compile-time assertion for ABI or type-width invariants
- a targeted build failure that demonstrates a portability regression
- a focused regression harness for byte-swap, address translation, or parsing logic
- a scripted smoke check for startup or asset-loading behavior when unit tests are not realistic

When code is difficult to unit-test directly, such as SDL/GL startup, emu64 integration, or low-level memory layout, do not skip the red step. First create or document the smallest reproducible failing check you can.

Prefer tests and checks that do not require game assets.

## Commit Discipline

Commit early and often in small, topical commits.

- One commit should do one thing.
- Separate test creation, behavior changes, and refactors whenever possible.
- If a change is risky, split it into at least: failing check, fix, cleanup.
- Keep commit messages short, imperative, and specific.
- Avoid mixing unrelated docs, generated files, and code changes in the same commit unless they are inseparable.

Good examples:

- `tests: add width checks for PC typedefs`
- `pc: allow guarded 64-bit configure path`
- `emu64: remove pointer truncation in seg2k0 helper`
- `docs: update macOS blocker checklist`

## Porting Priorities

For modern macOS work, follow this order unless a task clearly depends on another:

1. Fix the type model and `uintptr_t` usage.
2. Remove hard 32-bit configure and compile gates in a guarded way.
3. Eliminate host-pointer-in-`u32` behavior and other truncation hazards.
4. Redesign seg2k0 and address disambiguation logic.
5. Add macOS-specific runtime work such as Mach-O handling and SDL/GL setup.
6. Validate behavior against the existing 32-bit reference path.

Do not hide pointer-width bugs with casts or warning suppressions.

## Repository-Specific Guidance

- `pc/` is the native runtime layer and is the main place for desktop-port work.
- Much of `src/` is decomp-derived code. Touch it carefully and only when a PC-port fix truly belongs there.
- `pc/src/pc_assets.c` and `pc/include/pc_assets.h` are generated. Prefer changing `pc/tools/gen_runtime_assets.py` or the source patterns that feed it.
- Shaders in `pc/shaders/` are runtime-loaded and required.
- `pc/CMakeLists.txt` intentionally avoids a default optimized build because higher optimization levels expose undefined behavior. Do not change optimization defaults casually.

## Risky Areas

Changes in the files below have broad blast radius and should get especially tight checks:

- `include/types.h`
- `include/dolphin/types.h`
- `include/libc/stdint.h`
- `include/libforest/gbi_extensions.h`
- `pc/include/pc_platform.h`
- `pc/include/pc_types.h`
- `pc/src/pc_main.c`
- `pc/src/pc_os.c`
- `src/static/libforest/emu64/emu64_utility.c`

When touching address-model code, make truncation explicit only as a temporary diagnostic step, not as the final fix.

## Platform Guidance

- The current documented target is Windows i686.
- Linux i686 is also an intended path.
- Modern macOS is 64-bit only, and Apple Silicon cannot use the current 32-bit model at all.
- Avoid introducing new dependencies on ELF parsing, `VirtualQuery`, low-address `mmap` tricks, or other OS-specific memory introspection in shared code unless they are behind a clear abstraction.
- When possible, make 64-bit fixes testable on x86_64 Linux before depending on macOS-only behavior.

## Documentation Expectations

Update docs when conclusions, workflows, or porting guidance change.

Keep a running findings log in `docs/lp64_findings.md` so portability learnings are not lost.

If `docs/lp64_findings.md` does not exist yet, create it as part of your first LP64 investigation/fix in the session.

For each LP64-related bug fix or investigation result, add a concise entry with:

- symptom/signature (error text, symbol, stack, or log marker)
- root cause (confirmed or current best hypothesis)
- fix approach and touched files
- verification performed and follow-up work (if any)

Most relevant files:

- `docs/macos_port_assessment.md`
- `docs/macos_port_strategy.md`
- `docs/lp64_findings.md`
- `pc/DOCUMENTATION.md`

If a workaround is temporary, say so clearly and note what must happen to remove it.

## Default Verification

- For doc-only changes, verify links, file names, and instructions.
- For build-system changes, run the smallest relevant configure or build check available.
- For code changes, report exactly what was verified and what remains unverified.
- When full runtime verification is not possible locally, leave behind a concrete next validation step.

## Things Not To Commit

- game assets, disc images, or extracted proprietary content
- local build outputs
- one-off debugging edits that are not part of the intended change
- generated noise unrelated to the task at hand
