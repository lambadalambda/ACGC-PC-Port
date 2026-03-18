# macOS Port Strategy

Date: 2026-03-18

## Bottom line

After comparing `ACGC-PC-Port`, `../forest`, and `../ac-decomp`, my recommendation is:

- Primary implementation bet for a modern native macOS port: `ACGC-PC-Port`
- Secondary architecture track: `../forest`
- Tooling/reference-only role: `../ac-decomp`

This is not because `ACGC-PC-Port` is cleaner. It is because it is the only repository here that already looks like a real native runtime with working platform surface area: windowing, rendering, timing, audio, input, disc reading, save handling, and boot flow.

`../forest` may still be the better long-term architecture, but in its current checked-out state it is too incomplete and dependency-fragile to be the primary macOS vehicle.

## Repository comparison

| Area | `ACGC-PC-Port` | `../forest` | `../ac-decomp` |
| --- | --- | --- | --- |
| Native runtime completeness | Highest. Real `pc/` runtime layer with SDL2/OpenGL, save, disc, model viewer, texture packs, boot path. | Low today. PC entry files are empty and many Dolphin PC stubs are no-op or failure paths. | Not a native runtime repo. |
| Current configure status on this Mac | Fails immediately because the build hard-requires 32-bit. | Fails immediately because `CMakeLists.txt` forces a missing sibling `../aurora` checkout. | Not relevant to native runtime; macOS is documented as a host for the decomp toolchain. |
| 32-bit enforcement | Explicit and hard. | No hard 32-bit gate found. | No native runtime target here. |
| 64-bit cleanliness | Poor. Type model and platform layer both assume 32-bit addresses. | Also poor. No hard stop, but LP64 and pointer-truncation hazards are still pervasive. | Poor in the same original-code ways. |
| macOS-specific code today | Very little, and some POSIX code is actually Linux/ELF-specific. | Better signs: has `_NSGetExecutablePath` and Mach-O path handling in one PC file. | macOS only appears as a build-host environment. |
| External dependency risk | Lower. Everything important for runtime is in this repo. | Higher. Runtime direction depends heavily on `aurora`, which is not present locally and is currently hardwired as a sibling path. | Medium for tooling, but not relevant to native runtime. |
| Best current role | Primary implementation and validation harness. | Secondary architecture track and future consolidation candidate. | Reference for original code and build-tooling behavior. |

## Why `ACGC-PC-Port` is still the primary bet

### What it already has

`ACGC-PC-Port` already contains the hard parts that are easy to underestimate:

- a real program entry and boot flow in `pc/src/pc_main.c`
- a real rendering path in `pc/src/pc_gx.c`, `pc/src/pc_gx_tev.c`, and related files
- real platform timing, input, audio, and save plumbing in `pc/src/pc_os.c`, `pc/src/pc_audio.c`, `pc/src/pc_pad.c`, `pc/src/pc_card.c`, and `pc/src/pc_m_card.c`
- runtime asset loading and disc image support in `pc/src/pc_assets.c`, `pc/src/pc_disc.c`, and `pc/src/pc_dvd.c`

That means there is already something substantial to preserve, test against, and measure regressions against.

### Why that matters more than architectural cleanliness right now

For a macOS port, runtime completeness matters.

Even though `ACGC-PC-Port` has worse architecture and stronger 32-bit assumptions, it gives a concrete target:

- when boot breaks, there is an existing boot path to compare against
- when audio or input breaks, there is an existing implementation to compare against
- when a 64-bit cleanup changes behavior, there is a known working 32-bit reference path

That makes it the safer primary implementation repo.

## Why `../forest` is not the primary bet yet

`../forest` has attractive traits:

- more modular CMake structure
- no explicit 32-bit configure-time hard stop
- some macOS-aware code in `src/static/dolphin_pc_stubs_gx.cpp`
- less obvious dependence on ELF-specific startup logic

But those positives are outweighed today by three practical risks.

### 1. It is not runtime-complete

- `../forest/src/pc/dol_main.c` is empty
- `../forest/src/pc/rel_main.c` is empty
- `../forest/src/static/dolphin_pc_stubs.c` contains many no-op or failure-return implementations for threads, VI, DVD, alarms, and related systems

So even if it becomes easier to compile, that does not mean it is close to running.

### 2. It is dependency-fragile right now

`../forest/CMakeLists.txt` forces `CPM_aurora_SOURCE` to `../aurora`. On this machine that sibling repo does not exist, so configure fails before deeper portability questions even begin.

That means the current workspace does not provide a self-sufficient native runtime path for `../forest`.

### 3. It still has major 64-bit hazards

`../forest` is better described as "not hard-blocked at configure time" than "64-bit ready."

Examples:

- `../forest/include/dolphin/types.h` still defines `s32` and `u32` as `long`
- `../forest/include/libc/stdint.h` still defines `uintptr_t` as `unsigned long`
- `../forest/CMakeLists.txt` suppresses pointer truncation warnings instead of removing the truncation sites
- `../forest/include/libforest/gbi_extensions.h` still packs host addresses into 32-bit command words with casts like `(unsigned int)addr`

So it still needs substantial ABI and address-model cleanup before modern macOS is realistic.

## Role of `../ac-decomp`

`../ac-decomp` is useful context, but not a competing runtime base.

- It confirms macOS is already treated as a valid developer host for the decomp build workflow.
- It confirms the original codebase carries the same LP64-hostile type and pointer assumptions seen in the port repos.
- It is valuable as a source/reference repo, but not as the place to build a native desktop runtime.

## Recommended strategy

### Primary path

Treat `ACGC-PC-Port` as the implementation repo for modern macOS bringup.

### Secondary path

Treat `../forest` as a parallel de-risking and architecture track, not as the first place to spend macOS implementation time.

### Practical interpretation

- Fix and prove the 64-bit/address-model work in `ACGC-PC-Port`
- Use `../forest` to identify reusable abstractions and a possible future consolidation path
- Do not block macOS progress on `../forest` becoming runtime-complete first

## Concrete 64-bit blocker checklist for `ACGC-PC-Port`

The checklist below is prioritized in the order I would attack it.

### P0 - Keep a working reference path while adding 64-bit bringup

- Keep the existing 32-bit build working as a known-good reference while 64-bit cleanup is in progress.
- Make 64-bit an explicit bringup mode rather than immediately replacing the current ship path.

### P1 - Fix the type model first

Files to audit first:

- `include/types.h`
- `include/dolphin/types.h`
- `pc/include/pc_types.h`
- `include/libc/stdint.h`

Goals:

- stop defining `u32` and `s32` as `unsigned long` and `signed long` for PC builds
- use fixed-width integer types for PC builds
- use a real `uintptr_t` for PC builds everywhere
- make truncation explicit so the compiler can point out the dangerous sites

### P2 - Remove the 32-bit hard gates

Files:

- `pc/CMakeLists.txt`
- `pc/include/pc_platform.h`

Goals:

- convert the hard 32-bit requirement into a guarded bringup path
- allow 64-bit configuration and compilation while keeping the old 32-bit mode available

### P3 - Eliminate host-pointer-in-32-bit-field behavior

This is the keystone issue.

Representative files:

- `include/libforest/gbi_extensions.h`
- `src/static/dolphin/os/OSAlloc.c`
- `src/static/dolphin/os/OSMemory.c`
- `src/static/dolphin/gx/GXFifo.c`
- `src/static/JSystem/JKernel/JKRExpHeap.cpp`
- `src/static/JSystem/JKernel/JKRAram.cpp`
- `src/static/JSystem/JKernel/JKRAramStream.cpp`

Goals:

- stop storing host pointers in 32-bit command words and engine fields
- define a deliberate 64-bit-safe representation for runtime addresses
- decide which addresses are true console-style segment/offset values and which are host pointers

### P4 - Redesign seg2k0 and address disambiguation

Files:

- `pc/src/pc_main.c`
- `pc/src/pc_os.c`
- `src/static/libforest/emu64/emu64_utility.c`

Problems to remove:

- ELF-specific executable image probing
- dependence on `VirtualQuery`
- low-address reservation assumptions
- the idea that success depends on the OS mapping memory in a 32-bit-friendly region

Target end state:

- no ELF dependency on macOS
- no Windows-only `VirtualQuery` leak in the generic PC path
- no reliance on `MAP_FIXED_NOREPLACE` low-address reservations for correctness

### P5 - Add the real macOS platform work after the address model is fixed

Files:

- `pc/src/pc_main.c`
- `pc/src/pc_os.c`
- `pc/include/pc_platform.h`

Main tasks:

- replace ELF logic with Mach-O/dyld logic or remove the need for that logic entirely
- add a reliable macOS OpenGL context creation path
- handle macOS-specific SDL/GL attributes and packaging assumptions
- validate file paths, save locations, and app working-directory assumptions on macOS

### P6 - Validate behavior against the existing 32-bit reference

Suggested checkpoints:

- boot to first interactive scene
- load assets from disc image and extracted data paths
- verify audio and controller input
- verify save load/write flow
- verify rendering and texture-pack behavior

## Shared blockers regardless of which repo wins long-term

These apply to both `ACGC-PC-Port` and `../forest`, and are reflected in `../ac-decomp` as well.

1. `u32`/`s32` versus host ABI types: LP64 and LLP64 safety needs to be explicit.
2. Pointer truncation as design: host pointers cannot live in 32-bit display-list words and heap metadata.
3. Address-space assumptions: low-address reservation strategies are fragile on modern macOS.
4. OS-specific memory/introspection APIs: Windows `VirtualQuery`, Linux `/proc/self/maps`, and ELF parsing all need abstraction or removal.
5. Generated-header and dependency reproducibility: missing external pieces like `aurora` or generated console headers can block progress before runtime issues are even reached.
6. Compile success is not runtime success: stubs and warning suppressions can hide that core systems still do nothing.

## `forest` de-risk sprint

If the team still wants to test whether `../forest` should become the long-term primary repo, the right next step is a short de-risk sprint rather than a full migration.

I would time-box the following:

1. Make `aurora` fetchable or vendored so `../forest` configures reproducibly.
2. Ensure all required generated headers are present in a clean checkout.
3. Give `../forest` a minimal real PC entry path instead of empty `src/pc/*.c` entry files.
4. Replace enough no-op stubs to prove logging, asset access, timing, and one visible frame on a desktop host.
5. Reassess only after that point whether `../forest` is truly on a better macOS trajectory.

If that sprint does not produce a minimally real runtime quickly, `../forest` should remain the secondary track.

## Critical-advisor check

I asked `@critical-advisor` to review the revised comparison and strategy.

The main conclusions from that review were:

- the comparison is broadly sound
- `../forest` should not be over-credited as "64-bit ready"
- `ACGC-PC-Port` is still the safer primary macOS implementation bet today because it already has the runtime surface area
- the strongest long-term posture is to use `ACGC-PC-Port` for implementation and validation, while using `../forest` as a secondary de-risking track
