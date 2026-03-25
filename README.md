# Animal Crossing PC Port

A native PC port of Animal Crossing (GameCube) built on top of the [ac-decomp](https://github.com/ACreTeam/ac-decomp) decompilation project.

The game's original C code runs natively on x86, with a custom translation layer replacing the GameCube's GX graphics API with OpenGL 3.3.

This repository does not contain any game assets or assembly whatsoever. An existing copy of the game is required.

Supported versions: GAFE01_00: Rev 0 (USA)

## Quick Start (Pre-built Release)

Pre-built releases for this fork are listed on the [Releases](https://github.com/lambadalambda/ACGC-PC-Port/releases) page.

1. Download the latest macOS `.dmg` from [Releases](https://github.com/lambadalambda/ACGC-PC-Port/releases)
2. Open the DMG and move `AnimalCrossing.app` where you want (for example, `Applications`)
3. Place your disc image in `~/Documents/ACGC/` or `~/Documents/ACGC/rom/`
4. Optional runtime folders:
   - saves: `~/Documents/ACGC/save/`
   - HD textures: `~/Documents/ACGC/texture_pack/`
5. Launch `AnimalCrossing.app`

The game reads all assets directly from the disc image at startup. No extraction or preprocessing step is needed.

### Automated master builds

Every push to `master` runs a GitHub Actions macOS build and uploads release artifacts (`.dmg` and `.tar.gz`). The packaged bundle contains only `AnimalCrossing.app` and a short `README.txt`.

- Actions page: https://github.com/lambadalambda/ACGC-PC-Port/actions
- Workflow: `Build macOS Release DMG`

## Building from Source

Only needed if you want to modify the code. Otherwise, use the [pre-built release](https://github.com/lambadalambda/ACGC-PC-Port/releases) above.

### Requirements

- **macOS** (Apple Silicon or Intel)
- **Xcode Command Line Tools**
- **Homebrew**
- **Animal Crossing (USA) disc image** (ISO, GCM, or CISO format)

### Install Build Dependencies

```bash
xcode-select --install
brew install cmake sdl2 make
```

### Build Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/lambadalambda/ACGC-PC-Port.git
   cd ACGC-PC-Port
   ```

2. Build:
   ```bash
   make
   ```

   This configures `pc/build-macos` and enables LP64 bringup mode by default.

3. Place your disc image in the `rom/` folder:
   ```
   pc/build-macos/bin/rom/YourGame.ciso
   ```

   You can also keep it in `~/Documents/ACGC/` or `~/Documents/ACGC/rom/`.

   Save files are stored in `~/Documents/ACGC/save/` and HD texture packs are loaded from
   `~/Documents/ACGC/texture_pack/` (with local `./save/` and `./texture_pack/` fallback for
   terminal-driven builds).

4. Run:
   ```bash
   pc/build-macos/bin/AnimalCrossing
   ```

### Optional Build Overrides

```bash
make BUILD_DIR=pc/build-custom
make CMAKE_OPTIONS='-DPC_EXPERIMENTAL_64BIT=ON -DPC_CONSOLE=ON'
```

### Legacy Windows Helper

The old MSYS2 helper is still available for the 32-bit reference path:

```bash
./build_pc.sh
```

## Controls

Keyboard bindings are customizable via `keybindings.ini` (next to the executable). Mouse buttons (Mouse1/Mouse2/Mouse3) can also be assigned.

### Keyboard (defaults)

| Key | Action |
|-----|--------|
| WASD | Move (left stick) |
| Arrow Keys | Camera (C-stick) |
| Space | A button |
| Left Shift | B button |
| Enter | Start |
| X | X button |
| Y | Y button |
| Q / E | L / R triggers |
| Z | Z trigger |
| I / J / K / L | D-pad (up/left/down/right) |

### Gamepad

SDL2 game controllers are supported with automatic hotplug detection. Button mapping follows the standard GameCube layout.

## Command Line Options

| Flag | Description |
|------|-------------|
| `--verbose` | Enable diagnostic logging |
| `--no-framelimit` | Disable frame limiter (unlocked FPS) |
| `--model-viewer [index]` | Launch debug model viewer (structures, NPCs, fish) |
| `--on-screen-timer` | Show `T+MM:SS` overlay for repro timestamps |
| `--boot-player-select` | Enable experimental player-select boot path |
| `--time H[:M[:S]]` | Override in-game time (examples: `5`, `17:30`, `5:55:00`) |
| `--selftest` | Run startup self-test and exit (assetless sanity check) |

## Settings

Graphics settings are stored in `settings.ini` and can be edited manually or through the in-game options menu:

- Resolution (up to 4K)
- Fullscreen toggle
- VSync
- MSAA (anti-aliasing)
- Texture Loading/Caching (No need to enable if you aren't using a texture pack)

## Texture Packs

Custom textures can be placed in `texture_pack/`. Dolphin-compatible format (XXHash64, DDS).

I highly recommend the following texture pack from the talented artists of Animal Crossing community.

[HD Texture Pack](https://forums.dolphin-emu.org/Thread-animal-crossing-hd-texture-pack-version-23-feb-22nd-2026)

## Save Data

Save files are stored in `save/` using the standard GCI format, compatible with Dolphin emulator saves. Place a Dolphin GCI export in the save directory to import an existing save.

## Credits

This project would not be possible without the work of the [ACreTeam](https://github.com/ACreTeam) decompilation team. Their complete C decompilation of Animal Crossing is the foundation this port is built on.

## AI Notice

AI tools such as Claude were used in this project (PC port code only).
