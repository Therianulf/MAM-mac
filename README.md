# MAM-mac

A one-click installer for the tooling that gets Monsters and Memories running "natively" on a Mac.

Created 2026-10-05 by command-control at the owner's request. Research and plan are done; the installer is not built yet.

## The objective (the owner's words, 2026-10-05)

> i just read that monsters and memories has a mac launcher option now: https://account.monstersandmemories.com/launcher but it requires wine and proton. start a new repo called MAM-mac, the objective of this repo is to be the one click installer for the tooling to get Monsters and memories running "natively" on mac

## What the launcher turned out to need

The official Mac download is a native Apple-Silicon launcher that downloads and patches the **Windows** game client; its Play button then tries to run `mnm.exe` directly, which macOS cannot do. It ships no Wine and no Proton (Proton is Linux-only). So "the tooling" is a Wine runtime for Apple Silicon with a DirectX 11 → Metal layer, a Wine prefix, a wrapper that starts the launcher in the right folder, and a redirect of that one `mnm.exe` spawn into Wine. Details and sources: [docs/launcher-requirements.md](docs/launcher-requirements.md).

## The plan

One double-click installs everything into one folder under the user's home, nothing system-wide; the official launcher stays the UI. Design, checks, removal and the open questions: [docs/plan.md](docs/plan.md).
