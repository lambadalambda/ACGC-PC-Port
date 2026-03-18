# macOS Port Assessment

Date: 2026-03-18

## Executive assessment

This repository is not currently close to running on modern macOS.

The PC port is still built around a 32-bit address model, with Windows as the primary target and Linux i686 as a secondary target. The main macOS blocker is no longer configuration alone; it is the remaining runtime portability work needed to make the guarded 64-bit path correct.

I verified the current state on this machine:

- `cmake -S pc -B /tmp/acgc-p2-config-64 -DPC_EXPERIMENTAL_64BIT=ON` now configures and builds on this macOS host.
- A direct `cc -m32` link test fails on this arm64 macOS host with `ld: unknown -arch name: armv4t`.

If the goal is modern macOS support, this should be treated as a broader 64-bit portability project, not as a small platform shim.

I also reviewed the sibling repositories `../ac-decomp` and `../forest`. They add useful context, but they do not materially change that conclusion.

## Current repo state

The codebase already has a meaningful cross-platform foundation:

- The port layer uses SDL2 for windowing, input, and audio.
- Rendering is OpenGL-based through GLAD, not DirectX-only.
- There are already non-Windows code paths for signals, directory scanning, and `mmap`.
- `pc/DOCUMENTATION.md` explicitly lists Linux i686 as supported.
- The build is CMake-based, which is a good starting point for adding another host platform.

However, the user-facing build and docs are still Windows-first:

- `README.md` only documents MSYS2/MinGW32.
- `build_pc.sh` only supports `MINGW32` and outputs `AnimalCrossing.exe`.
- There is no macOS toolchain file, build script, or CI path.

## Related repositories

I also looked at the sibling repositories `../ac-decomp` and `../forest` to see whether they change the macOS outlook.

### `../ac-decomp`

This repo does not weaken the assessment. It mostly confirms the original decompilation project's toolchain expectations.

- Its macOS support is for using macOS as a host to run the decomp build flow, not for a native macOS game runtime.
- `ac-decomp/README.md` documents macOS setup in terms of `ninja` plus `wine-crossover`, which is consistent with "build the GameCube decomp on macOS" rather than "run a native PC port on macOS".
- It still contains the same family of 32-bit and LP64-hostile assumptions, including `s32`/`u32` defined as `long` in `ac-decomp/include/dolphin/types.h` and `ac-decomp/include/types.h`.
- It also still has direct pointer-to-`u32` style logic in engine code such as `ac-decomp/src/static/dolphin/os/OSAlloc.c` and related SDK/JSystem code.

Takeaway: `ac-decomp` confirms that macOS is already a viable developer host for the decomp toolchain, but it does not provide evidence that the native PC runtime problem is smaller than it appears in this repo.

### `../forest`

This repo is more interesting strategically. It looks like a newer or alternate PC-port direction, but it still does not overturn the assessment.

Positive signals:

- `forest/CMakeLists.txt` is more explicitly cross-platform-minded than this repo's build files.
- It enables position-independent code and appears to be structured around reusable libraries plus thin PC entry points.
- It does not hard-stop on 64-bit pointer size in the same immediate way as this repository.

Reasons it still does not change the conclusion:

- In the checked-out state here, `forest/src/pc/dol_main.c` and `forest/src/pc/rel_main.c` are empty, so it does not present a complete runnable native runtime path yet.
- It still defines `s32` and `u32` as `long` in `forest/include/dolphin/types.h`, which is an LP64 hazard on macOS and Linux x86_64.
- It defines `uintptr_t` as `unsigned long` in `forest/include/libc/stdint.h`, which is another sign that the project is still carrying platform-width assumptions instead of using fixed-width types cleanly.
- `forest/CMakeLists.txt` suppresses pointer truncation warnings rather than removing the underlying issue.
- `forest/include/types.h` still pulls in Windows-specific machinery such as `<intrin.h>`, `_byteswap_*`, and `__declspec` under `TARGET_PC`.

Takeaway: `forest` may be a better long-term architectural base than forcing this repo forward unchanged, but it is not currently a drop-in answer for macOS support. It still appears to need substantial 64-bit cleanup and platform-neutralization work.

### Net effect of reviewing both sibling repos

The sibling repos slightly refine the strategic recommendation, but they do not change the headline conclusion.

- `ac-decomp` says: macOS as a host environment is already normal for the decomp toolchain.
- `forest` says: there may be a more promising future port architecture than the current `ACGC-PC-Port`, but it is not mature enough yet to count as existing macOS support.
- Neither repo provides evidence that modern macOS support is a small patch set.

## Hard blockers for macOS

### 1. The port is no longer hard-blocked at build time, but it is still not 64-bit-correct

This is the biggest issue.

- `pc/CMakeLists.txt` now exposes a guarded `PC_EXPERIMENTAL_64BIT` bringup mode instead of hard-stopping on LP64.
- `pc/include/pc_platform.h` now allows that guarded mode on 64-bit hosts.
- `include/PR/gbi.h`, `include/libforest/gbi_extensions.h`, and `include/m_scene.h` still rely on compile-only zero placeholders for static 32-bit pointer fields under LP64, guarded by `pc/tests/check_static_ptr_contract.sh`.

That means:

- Modern macOS can now build the guarded bringup path, but runtime correctness is still unproven.
- Apple Silicon is no longer blocked at configure time, but it is still blocked by the remaining address-model and pointer-representation work.
- Even on Intel macOS, the current problem is now runtime correctness rather than simply getting CMake to accept a 64-bit host.

The project is now plausible as a guarded modern macOS bringup target, but not yet as a supported macOS runtime.

### 2. The POSIX path assumes ELF, not Mach-O

The non-Windows path is not actually generic Unix; parts of it are Linux/ELF-specific.

- `pc/include/pc_platform.h` includes `<elf.h>` for non-Windows builds.
- `pc/src/pc_main.c` uses `dladdr()` and then parses `Elf32_Ehdr` and `Elf32_Phdr` to compute the executable image range.
- The local macOS SDK does not provide `elf.h`.

On macOS, this logic would need a Mach-O implementation instead, likely using dyld APIs and Mach-O load commands, or a different strategy entirely for the seg2k0/image-range problem.

### 3. Memory reservation logic is Linux-oriented

`pc/src/pc_os.c` tries to reserve the main arena at fixed low addresses to avoid collisions with N64/GameCube-style address ranges.

The current non-Windows path:

- uses `mmap()` directly,
- defines `MAP_FIXED_NOREPLACE` locally if it is missing,
- relies on Linux-like fixed-address reservation behavior.

That is risky on macOS:

- `MAP_FIXED_NOREPLACE` is not a native macOS contract,
- low-address reservation behavior is not something I would trust to line up cleanly across Apple toolchains,
- Apple Silicon adds another layer of uncertainty around the assumed process address layout.

Even if the project were made 64-bit-clean, this part would still need a macOS-specific implementation or redesign.

### 4. macOS OpenGL context requirements are not handled

`pc/src/pc_main.c` requests an SDL OpenGL 3.3 core context, but does not include the usual macOS-specific forward-compatible handling.

Current behavior:

- sets major version 3, minor version 3,
- requests `SDL_GL_CONTEXT_PROFILE_CORE`,
- does not set `SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG`.

That may be fine on Windows/Linux, but macOS OpenGL context creation is more particular. Even after the 32-bit issue is solved, the GL setup likely needs a macOS branch for reliable context creation and testing.

## Important positives

This is not a dead-end codebase from a portability perspective.

The repo already has several traits that help:

- SDL2 is already the abstraction layer for video, input, controller support, and audio.
- The renderer is already a platform-neutral OpenGL translation layer from GX.
- Filesystem and save code already have both Windows and POSIX branches.
- Crash handling already has a non-Windows signal-based path.

So the project is not "Windows-only" in design. The real problem is that it is "32-bit i686-oriented," and modern macOS is not.

## What this means in practice

### Best interpretation of the current state

The current codebase appears to be in this state:

- Windows i686: primary and documented target.
- Linux i686: secondary target with working portability work already started.
- macOS: not currently supported, not documented, and blocked by architecture assumptions.

### Realistic effort estimate shape

The shortest path to any macOS result depends on what "macOS" means:

#### Legacy Intel macOS only

Potentially possible with a smaller scope, but still non-trivial.

Likely work items:

- replace ELF-specific image-range code,
- replace or rework low-address arena reservation,
- add macOS OpenGL context handling,
- create a legacy 32-bit build recipe and dependency setup.

This path would still target an obsolete platform range and would not help Apple Silicon.

#### Modern macOS, including Apple Silicon

This is a much larger effort.

Likely work items:

- audit and remove pointer truncation assumptions,
- make the port layer 64-bit safe,
- revisit address translation and arena layout assumptions,
- add Mach-O-aware runtime/image detection,
- add macOS-specific GL setup and validation,
- test for new undefined-behavior fallout on a 64-bit compiler/ABI.

That is a genuine platform and architecture port, not a minor compatibility patch.

## Recommended next steps

For the repo-to-repo comparison, implementation recommendation, and prioritized blocker checklist, see `docs/macos_port_strategy.md`.

### Recommended direction

If the real target is current macOS on real user machines, I would not start with ad hoc macOS fixes.

I would treat the work in this order:

1. Decide whether the target is legacy Intel macOS or modern macOS.
2. Decide whether this repository or `../forest` is the intended long-term base for native desktop work.
3. If the target is modern macOS, define the work as a 64-bit portability effort first.
4. Use the existing Linux/POSIX path as the base, then add a macOS-specific layer where Linux assumptions leak through.

### Concrete first engineering tasks

If proceeding toward modern macOS, the first tasks I would queue are:

1. Audit and catalog all pointer-to-`u32` and address-truncation assumptions.
2. Identify which of those are local fixes versus architectural assumptions.
3. Decide whether those fixes should happen in this repo or be aligned with `../forest` so work is not duplicated.
4. Replace the ELF-based image-range code with a platform abstraction.
5. Prototype a macOS-safe arena reservation strategy.
6. Add a macOS OpenGL context creation path and smoke test window/context startup.

### Strategic note

If the team wants the lowest-risk path to eventual macOS support, an intermediate x86_64 Linux cleanup may be the best forcing function. Many of the same 64-bit issues should surface there in a friendlier environment before adding macOS-specific constraints.

## Files that most strongly shape this assessment

- `README.md`
- `build_pc.sh`
- `pc/CMakeLists.txt`
- `pc/DOCUMENTATION.md`
- `pc/include/pc_platform.h`
- `pc/src/pc_main.c`
- `pc/src/pc_os.c`
