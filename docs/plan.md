# The one-click installer: plan

Written 2026-10-05, before building. Grounded in [launcher-requirements.md](launcher-requirements.md); nothing here goes beyond what the launcher was seen to need.

## What the user runs

One double-click: **`Install Monsters & Memories.command`** from the downloaded release (or, from a terminal, `./install.sh`). It opens Terminal, prints what it is about to do, and runs `bin/mam install`. No `.pkg` (would want signing, notarization and `/usr/local`), no app of our own (that is what MnM-on-Mac already is); a shell script is the honest size of this job.

When it finishes there is a second double-clickable, **`Monsters & Memories.command`**, which opens the official launcher the right way. From then on the official launcher is the UI: Login → Install/Update → Play.

## What it installs, and from where

Everything goes into one folder, `MAM_HOME`, default `~/Library/Application Support/MAM-mac/` (overridable with the `MAM_HOME` variable, which is how it is tested). Every download is an HTTPS fetch pinned by SHA-256; nothing is run from the network.

| Piece | Source | Size | Why |
|---|---|---|---|
| Official Mac launcher 0.22.13 | the launcher's own update API → `pub-…r2.dev/launcher_v2/0.22.13/mnm_patcher_app_0.22.13_aarch64.app.tar.gz` | 10 MB | the login/patch UI; left free to self-update (it is in a user-writable folder, so no admin prompt) |
| Wine engine `WS12WineSikarugir10.0_6` | `github.com/Sikarugir-App/Engines` release | ~340 MB | x86_64 Wine with msync; the build proven on this game |
| Sikarugir Template 1.0.18 | `github.com/Sikarugir-App/Template` release | ~80 MB | the engine's support dylibs; also carries Apple D3DMetal 3.0 |
| DXMT 0.80 | `github.com/3Shain/dxmt` release | small | default DirectX 11 → Metal layer, MIT |
| A Wine prefix | made locally: `wineboot --init`, Windows 10, mono/gecko disabled | ~300 MB | the game's C: drive |
| `libmamplay.dylib` | ~60 lines of C in this repo, built with `cc` when Xcode's tools exist, else the prebuilt copy from the release | tiny | turns the launcher's Play button into a Wine launch (see below) |
| `bin/mam` | this repo | — | the command behind both `.command` files: `install`, `doctor`, `launcher`, `play`, `uninstall` |

Apple's D3DMetal (faster on some games, licence-restricted) is **not** installed by default. `mam install --renderer d3dmetal` prints Apple's licence and installs it only after a typed `yes`.

The only thing that can touch the system outside `MAM_HOME` is Rosetta 2, and only on a Mac that lacks it, and only after a y/N: it runs Apple's own `softwareupdate --install-rosetta --agree-to-license`. No Homebrew, no `sudo`, nothing in `/Applications` or `/usr/local`.

## How Play works

The launcher patches the game into `./mnm/` under its working directory and its Play button spawns `./mnm/mnm.exe --token <jwt>` directly, which macOS cannot run. `mam launcher` fixes both:

1. starts the launcher binary with the working directory set to `MAM_HOME/Game/` (so the game lands in `MAM_HOME/Game/mnm/`), and
2. loads `libmamplay.dylib` into it with `DYLD_INSERT_LIBRARIES` (the launcher is ad-hoc signed without hardened runtime, so this is allowed). The dylib interposes `posix_spawn`/`posix_spawnp`; when the launcher spawns `…/mnm.exe`, it spawns `mam play --token <jwt>` instead. The launcher sees a running child and shows "Game is running" as on Windows.

`mam play` is the actual launch: `wine64 mnm.exe -force-d3d11 --token <jwt>` in the prefix, with `WINEARCH=win64 WINEMSYNC=1 WINEDEBUG=-all` and the renderer's `WINEDLLOVERRIDES`. It also works on its own: run without `--token` it reads the JWT the launcher saved in `launcher.db`, so if the shim can't be used (no compiler and no prebuilt dylib, or a future hardened launcher) the user signs in and patches in the launcher, then runs `mam play`. Logs go to `MAM_HOME/Logs/`.

This is the approach MnM-on-Mac v1 took (MIT, credited in the repo); its own shim is 58 lines. We write ours.

## What it checks first (`mam doctor`, also run by install)

- Apple Silicon: refuses on Intel — there is no Intel launcher build.
- macOS 14.6 or newer (the engine's stated floor).
- Rosetta 2 (`arch -x86_64 /usr/bin/true`); offers to install it if missing.
- Free disk: at least 3 GB for the tooling, and a loud note that the game itself comes on top (size unknown until the owner's first patch).
- Reachability of `github.com`, `account.monstersandmemories.com` and the `r2.dev` host.
- The macOS tools it uses: `curl`, `tar`, `shasum`, `sqlite3`, `cc` (optional).
- Already-present tooling (CrossOver, Whisky, Homebrew Wine, GPTK, a launcher in `/Applications`): reported, never used, never touched.

## A machine that already has some of it

- Re-running `mam install` is idempotent: cached downloads are re-hashed and skipped, an unpacked runtime is skipped, an existing prefix is kept. `--reinstall` redoes the runtime, `--reset-prefix` rebuilds the prefix (game files untouched).
- A launcher the owner already opened by hand shares the same `launcher.db` (same bundle id, same app-data folder), so its saved login carries over. Any game files it wrote are wherever its working directory was; `mam install --game-dir <folder>` adopts an existing folder that contains `mnm/mnm.exe`.
- Other Wine installs are ignored on purpose; this stays self-contained so it can be removed cleanly.

## Removal

`mam uninstall` deletes `MAM_HOME` (runtime, prefix, launcher copy, shim, logs) and asks two separate y/N questions before deleting the game files (large) and the launcher's own data folder (holds the saved login). Rosetta 2 is an Apple component and stays. Nothing else was changed, so nothing else to undo.

## What the user still does by hand

- Buy the subscription ($15/month) and have the account.
- Sign in inside the launcher; press Install the first time, Update after patches, Repair if the game exits with Unity code 53 after an update.
- Type `yes` to Apple's licence if they choose D3DMetal; answer y/N for Rosetta if their Mac lacks it.
- If the `.command` file came through a browser, right-click → Open once (Gatekeeper); a `git clone` needs nothing.

## Testing without changing this Mac

`MAM_HOME=<repo>/.local/mam` (gitignored) or a temp folder. `mam install` end to end (downloads, hashes, unpack, prefix); `wine64 --version` and `wine64 cmd /c ver` inside the prefix (console only, no window); `mam play --dry-run` printing the exact command; a shim test that spawns a fake `mnm.exe` through a tiny host program. The launcher window and the game are opened only by the owner, from his own account.

## Not in scope, on purpose

CrossOver (commercial, not redistributable), Apple's GPTK `.dmg` (login-gated download), Homebrew, Intel Macs, the Windows launcher under Wine (MnM-on-Mac v2's path: patched Wine DLLs and an injected rendering bridge — only worth it if the Mac launcher proves unable to log in or patch).

## Questions only the owner can answer

1. Have you already opened the Mac launcher by hand, and did it sign in and patch the game? (0.22.13 is seven months behind the Windows launcher; only a live login tells us it still works.)
2. Default renderer: DXMT (open source, no licence prompt) or Apple D3DMetal (licence prompt, often faster)?
3. Install home: hidden-but-standard `~/Library/Application Support/MAM-mac`, or a visible `~/MAM-mac`?
4. Apple Silicon only is a hard limit of the official launcher — acceptable, or should the README say so and stop there?
5. On a Mac without Rosetta 2, may the installer run Apple's Rosetta install after a y/N? (Yours already has it.)
6. Roughly how big is the game folder on your Windows PC? (Sets the disk check; your Mac has about 15 GB free.)
7. Is the double-clickable `.command` file enough, or do you also want a "Monsters & Memories" icon placed in `~/Applications` (user-level, no admin)?
8. If the Mac launcher turns out unable to log in or patch today, should MAM-mac take on the Windows-launcher-under-Wine path, or point users at MnM-on-Mac (MIT) for that case?
