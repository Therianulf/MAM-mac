# MAM-mac

One-click installer for the tooling that runs Monsters & Memories on an Apple-Silicon Mac: the official native launcher plus a self-contained Wine runtime. Owner: Benjamin Larson. Coordinator: command-control.

## Rules

- Initial work commits and pushes straight to `main`; no pull request, version, tag or release step without the owner. Feature branches start once a first working version exists.
- Nothing this repo does may change the Mac it runs on outside `MAM_HOME` (default `~/MAM-mac`) and the user-level `~/Applications/Monsters & Memories.app`: no `sudo`, no Homebrew, nothing in `/Applications` or `/usr/local`. Rosetta 2 is the one exception and only after a y/N.
- Test with `MAM_HOME=$PWD/.local/mam` (gitignored) and `--no-app`. Never open the launcher window or the game from an agent session; the live test is the owner's, from his own account. Never sign in to his account.
- Every download is HTTPS and pinned by SHA-256 in `bin/mam`; nothing fetched is unpacked without a hash check. Apple's D3DMetal is installed only after the user types `yes` to its licence (`--yes` counts as that).
- Do not edit `bin/mam` while an install is running: bash reads the script incrementally.
- Separate STATED (a source says it), OBSERVED (read from the binary) and INFERRED (our reading) in every doc.
- Report milestones to `command-control-9c` by messenger and `command-control+claude` by letter.

## Documents

- [docs/launcher-requirements.md](docs/launcher-requirements.md) — what the Mac launcher is, does and needs, with sources.
- [docs/plan.md](docs/plan.md) — the installer design, the owner's answers, and the fallback stage (Windows launcher under Wine) to build only if the live test fails.

## Tooling

- `bin/mam` — the whole installer: `doctor`, `install`, `launcher`, `play`, `clean`, `uninstall`, `wine`, `env`, `version`; pins, layout and the Wine environment live at its top. `bin/mam help` lists options.
- `shim/mamplay.c` — the `posix_spawn` interposer that turns the launcher's Play into `mam play`; `shim/test_host.c` stands in for the launcher in tests.
- `tests/shim_test.sh` — builds the shim and proves the redirect without any launcher or Wine.
- `tests/install_test.sh` — end to end in a temp `MAM_HOME`, ending in `uninstall`; `MAM_CACHE=$PWD/.local/mam/downloads` skips the 270 MB fetch.
- `Install Monsters & Memories.command`, `Monsters & Memories.command`, `install.sh` — the double-click and terminal entry points; each is one `exec bin/mam …` line.
