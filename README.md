# MAM-mac

A one-click installer for the tooling that gets Monsters and Memories running "natively" on an Apple-Silicon Mac.

Created 2026-10-05 by command-control at the owner's request. Verified the same day on an M4 Max running macOS 26.7.1: install, login, the 8.7 GB patch, the launcher's Play button and the game itself under D3DMetal all worked with no issues.

## The objective (the owner's words, 2026-10-05)

> i just read that monsters and memories has a mac launcher option now: https://account.monstersandmemories.com/launcher but it requires wine and proton. start a new repo called MAM-mac, the objective of this repo is to be the one click installer for the tooling to get Monsters and memories running "natively" on mac

## What the launcher turned out to need

The official Mac download is a native Apple-Silicon launcher that downloads and patches the **Windows** game client; its Play button then tries to run `mnm.exe` directly, which macOS cannot do. It ships no Wine and no Proton (Proton is Linux-only). So "the tooling" is a Wine runtime for Apple Silicon with a DirectX 11 → Metal layer, a Wine prefix, a wrapper that starts the launcher in the right folder, and a redirect of that one `mnm.exe` spawn into Wine. Details and sources: [docs/launcher-requirements.md](docs/launcher-requirements.md). Design: [docs/plan.md](docs/plan.md).

## Use

Needs an Apple-Silicon Mac on macOS 15 or newer (14.6 with `--renderer dxmt`), a Monsters & Memories account with a subscription, and about 3 GB for the tooling plus whatever the game needs. Intel Macs are out: the official launcher only exists for Apple Silicon.

1. Download or clone this folder and keep it; it is the program.
2. Double-click **`Install Monsters & Memories.command`**. It installs everything into `~/MAM-mac` — a Wine engine, Apple's D3DMetal graphics layer (you are shown Apple's licence and type `yes`), a Wine prefix and the official launcher — and puts a **Monsters & Memories** icon in `~/Applications`. Nothing goes anywhere else; no admin password. If your Mac lacks Rosetta 2 it asks before running Apple's installer for it.
3. Open **Monsters & Memories** (the icon, or `Monsters & Memories.command`). In the official launcher: log in, press Install, wait, press Play.

From a terminal the same thing is `bin/mam install`, `bin/mam launcher`, `bin/mam doctor` (checks only), `bin/mam play` (starts the game from the saved login without the launcher), `bin/mam uninstall`.

## Credits

The runtime recipe and the Play redirect follow [seathasky/MnM-on-Mac](https://github.com/seathasky/MnM-on-Mac) (MIT). Wine engine by [Sikarugir](https://github.com/Sikarugir-App), DXMT by [3Shain](https://github.com/3Shain/dxmt), D3DMetal by Apple (Game Porting Toolkit, under its own licence). Monsters & Memories is by Niche Worlds Cult; this project is not affiliated with them.
