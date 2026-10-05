# What the Mac launcher needs

Researched 2026-10-05. Three kinds of evidence, kept apart:

- **STATED** — an official source says it (quoted, with the URL).
- **OBSERVED** — read from the launcher bundle itself (`Monsters & Memories.app.tar.gz`, downloaded from the official link and inspected on disk: `Info.plist`, `lipo`, `codesign`, `otool`, symbol and string dumps, the brotli-decoded embedded frontend). The launcher was never run.
- **INFERRED** — our reading. Marked as such.

## The short version

1. The official Mac download is a native Apple-Silicon launcher, not a game. It downloads and patches the **Windows** game client into a folder, and its Play button then tries to run `mnm.exe` directly, which macOS cannot do.
2. The launcher ships **no Wine and no Proton** and knows nothing about either. Proton does not exist for macOS; the word on the launcher page is aimed at Linux users.
3. So "the tooling" is: a Wine runtime for Apple Silicon (x86_64 Wine under Rosetta 2) with a DirectX 11 → Metal layer, a Wine prefix, a wrapper that starts the launcher in the right working directory, and a redirect of that one `mnm.exe` spawn into Wine.

## 1. What the download is

- **STATED** — https://account.monstersandmemories.com/launcher (public, no login): "Windows is the primary supported platform for the game client. Mac and Linux users can use the launcher for compatibility-layer workflows." / "Mac (Launcher only) — .app.tar.gz — use with Wine, CrossOver, Proton, or similar compatibility tooling."
- **STATED** — the Mac link on that page: `https://pub-f06cad9ebbcd412bb0f4ff64f0f6a3d7.r2.dev/launcher_v2/installer/Monsters%20%26%20Memories.app.tar.gz` (9.9 MB).
- **OBSERVED** — that tarball unpacks to `mnm_patcher_app.app`: bundle id `com.monstersandmemories.mnm-patcher-app`, executable `Contents/MacOS/mnm_launcher`, version **0.20.3**, **arm64 only** (no Intel slice), ad-hoc signed, not notarized, no hardened runtime. It is a Tauri 2.8.5 app (Rust + WebKit), author string "Niche Worlds Cult", description "A launcher and patcher for Monsters & Memories".
- **STATED** — the launcher's own update API, `https://account.monstersandmemories.com/api/launcher/update?target=darwin-aarch64&current_version=0.0.0`, answers version **0.22.13**, published **2026-03-05**, file `launcher_v2/0.22.13/mnm_patcher_app_0.22.13_aarch64.app.tar.gz`. `target=darwin-x86_64` returns nothing. For comparison: Windows 0.24.6 (2026-10-01), Linux 0.22.14 (2026-03-06).
- **INFERRED** — there is no Intel Mac build, and the Mac launcher is about seven months behind the Windows one.

## 2. What the launcher does, and does not do

- **OBSERVED** — IPC commands behind the UI: `load_database`, `save_variable` (`remember`, `username`, `token`), `get_game_state`, `patch` (with `gamePath: "./mnm/"`, `chunksUrl`, `manifestUrl`, `validate`), `cancel_patch`, `start_game`, `is_game_running`, `fetch_rss`. Buttons: Login, Install, Update, Play, Repair, Logout. No settings screen, no folder picker, no platform branching.
- **OBSERVED** — login: `POST https://account2.monstersandmemories.com/api/account/login` → a JWT stored as `token` in `launcher.db` (SQLite, tables `settings(variable,value)` and `game_versions(slug,version)`) in the app data directory, which for this bundle id is `~/Library/Application Support/com.monstersandmemories.mnm-patcher-app/`. Game versions and patch URLs come from `/api/game/versions?token=`.
- **OBSERVED** — patching writes the game to **`./mnm/`, relative to the launcher process's working directory**. The code never sets or changes that directory. Files are validated with xxh3 hashes against a manifest (`game.db` in the game folder); "Repair" re-validates and re-downloads.
- **OBSERVED** — Play is `start_game { directory: "./mnm/", executable: "mnm.exe", token }`, implemented as `Command::new("./mnm//mnm.exe").arg("--token").arg(token).spawn()`. The child is kept so `is_game_running` can poll it.
- **OBSERVED** — the only other things it runs: `/usr/bin/open` (for links), and its self-updater (Tauri updater 2.9.0, minisign-signed, which uses an admin-privileges AppleScript only when the bundle is not writable). `--stinky-cheese` skips the update check. `MNM_LOCAL_SERVER` is a developer switch.
- **OBSERVED** — not present anywhere in the binary or frontend: `wine`, `WINEPREFIX`, `crossover`, `proton`, `umu`, `gptk`, `D3DMetal`, `dxvk`, `dxmt`, `rosetta`, `arch -x86_64`.
- **INFERRED** — on a Mac, opened from Finder, the working directory is `/`, so patching into `/mnm/` fails, and even with a good working directory Play fails with an exec-format error because `mnm.exe` is a Windows PE. The Mac launcher has no working play path of its own; "use with Wine…" means a wrapper has to supply one.

## 3. What the game client needs

- **STATED** — the game is Unity: "The servers live both within and apart from Unity" (https://monstersandmemories.com/updates/update-10-quick-tech-overview); upgraded to Unity 6 (https://monstersandmemories.com/updates/update-46-january-amp-february-2025). A screenshot filename in Update 52 reads "Unity 6.0 (6000.0.59f2) _DX11_".
- **INFERRED** — the Windows client renders through DirectX 11 (the `_DX11_` editor title; the community launcher passes `-force-d3d11`).
- **STATED** — Windows requirements (https://monstersandmemories.com/early-access-faq): Windows 10 21H1+, 16 GB RAM, "NVIDIA GeForce GTX 1060 (6 GB VRAM) or equivalent".
- **STATED** — no named anti-cheat product in any official source. The Master User Agreement (https://account2.monstersandmemories.com/policy/mau) says the game "MAY MONITOR YOUR COMPUTER … MEMORY FOR UNAUTHORIZED THIRD PARTY PROGRAMS"; it says nothing about compatibility layers.
- **STATED** — networking is "reliable UDP … LiteNetLib" (Update 10).
- **STATED** — business model: "$15 USD a month", "no box price"; Early Access launched 2026-10-01 (https://monstersandmemories.com/earlyaccess). An account and an active subscription are needed before any of this matters.

## 4. macOS version, chip, Rosetta

- No official source states any of these for Mac.
- **OBSERVED** — the launcher is arm64 only (`LSMinimumSystemVersion 10.13` in its plist is meaningless for an arm64 binary; macOS 11 is the floor in practice).
- **STATED** — every usable Wine build for macOS is x86_64 and needs Rosetta 2 (Gcenx: "built for Intel macOS and requires Rosetta 2"; GPTK README; Sikarugir README). Apple has announced macOS 27 is the final release to support Rosetta in general, with a carve-out for "older, unmaintained gaming titles" whose scope is unstated.
- **STATED** — the proven runtime for this game (see §5) targets macOS 14.0 minimum; Sikarugir's README says 14.6.

## 5. Proven community stack (not official)

[seathasky/MnM-on-Mac](https://github.com/seathasky/MnM-on-Mac) (MIT, v2.0.4 of 2026-09-30, "not affiliated with" the developers) runs this exact game on Apple Silicon. Read in full from a clone; everything below is **STATED** in its code or README:

- Wine engine: Sikarugir `WS12WineSikarugir10.0_6.tar.xz` (x86_64, wine-msync) from `github.com/Sikarugir-App/Engines/releases/download/v1.0/`.
- Support dylibs and Apple **D3DMetal 3.0** (Game Porting Toolkit): Sikarugir `Template-1.0.18.tar.xz` from `github.com/Sikarugir-App/Template/releases/download/v1.0/`.
- Open-source alternative renderer: **DXMT 0.80** (`github.com/3Shain/dxmt/releases/download/v0.80/dxmt-v0.80-builtin.tar.gz`, MIT; later releases move to LGPL). DXVK-macOS 1.10.3 as a third option.
- All downloads are plain tarballs pinned by SHA-256; no Homebrew, no sudo, nothing under `/Applications`. Everything lives under `~/Library/Application Support/MnM on Mac`.
- The game runs as `wine64 mnm.exe -force-d3d11 --token <JWT>` with `WINEARCH=win64`, `WINEMSYNC=1`, `WINEDEBUG=-all`, a plain win10 prefix (`wineboot --init`, `mscoree,mshtml=d`), and per-renderer `WINEDLLOVERRIDES` (`dxgi,d3d11=n,b` plus the D3DMetal `CX_*`/`WINED3DMETAL=1` variables, or `dxgi,d3d11,d3d10core=b` for DXMT). No winetricks, no vcrun, no dotnet.
- Its v1 (1.0.9–1.0.13) used the **native Mac launcher**: started it with cwd set to the game folder and `--stinky-cheese`, and a 58-line `DYLD_INSERT_LIBRARIES` interposer on `posix_spawn`/`posix_spawnp` that swapped the `mnm.exe --token <jwt>` spawn for a Wine launch. Its v2 switched to running the **Windows** launcher under Wine (NSIS install, WebView2, two patched Wine DLLs, an injected rendering bridge) — a far heavier path. The release notes give no reason for the switch; **INFERRED**: the stale Mac launcher (§1) is the likely one.
- Known issues it records: Unity exit code 53 after game updates (fixed by the launcher's Repair), Wine 10 losing Retina mode after display-mode changes, first-time setup 5–15 minutes, Terminal logging costs performance.

## 6. Toolchain state, October 2026 (for choosing a runtime)

| Tool | Version | Form | Needs | Terms |
|---|---|---|---|---|
| Sikarugir engine (ex-Kegworks, ex-Wineskin) | `WS12WineSikarugir10.0_6` (proven with this game); `11.0_1` (2026-10-01) | GitHub `.tar.xz` | Rosetta; macOS 14.6 per README | LGPL (Wine) |
| Sikarugir Template | 1.0.18 (2026-09-18), carries D3DMetal 3.0 | GitHub `.tar.xz` | same | D3DMetal: Apple GPTK licence, non-commercial, user must accept |
| DXMT | 0.80 (2026-04-23) | GitHub `.tar.gz` | — | MIT (last MIT release) |
| Gcenx game-porting-toolkit | 3.0-3 (2026-03-03), 228 MB | GitHub `.tar.xz`; cask | Rosetta; macOS 14 | Apple GPTK licence |
| Gcenx WineHQ macOS builds | stable 11.0_1, devel 11.18 | GitHub `.tar.xz` (Homebrew casks disabled 2026-09-01) | Rosetta; macOS 10.15; GStreamer for media | LGPL |
| CrossOver | 26.3.0 (Wine 11, D3DMetal 3.0) | commercial zip | — | $74/yr; 14-day trial; not redistributable |
| Whisky | archived 2025-05-11 (fork at 3.7.0) | — | — | GPL-3 |
| Proton / umu | — | **Linux only; does not run on macOS** | — | — |

## 7. Still unknown (only a live test or the developers can answer)

- Whether launcher 0.22.13 still logs in and patches the current game (0.30.2.4, 2026-10-04); the login call carries `version: 21` and the Windows launcher is two minor versions ahead.
- The size of the game install.
- Whether the game's memory monitoring objects to Wine. No source says it does.
- Minimum macOS the developers intend for the Mac launcher.

## Sources

Official: account.monstersandmemories.com/launcher, /api/launcher/update (four targets), /community/known_issues, /community/patch_notes; monstersandmemories.com, /earlyaccess, /early-access-faq, /updates (Updates 10, 46, 48, 52); account2.monstersandmemories.com/policy/mau; the launcher tarball itself. Community: github.com/seathasky/MnM-on-Mac (clone, commit 9d91de5), monstersandmemories.miraheze.org/wiki/MnM_on_Linux, firesofheaven.org thread 12362 p.84. Toolchain: github.com/Sikarugir-App (Engines, Template, README), github.com/3Shain/dxmt, github.com/Gcenx (macOS_Wine_builds, game-porting-toolkit, DXVK-macOS, homebrew-wine), developer.apple.com/games/game-porting-toolkit and the GPTK licence text, codeweavers.com (changelog, store), github.com/Whisky-App/Whisky and docs.getwhisky.app/maintenance-notice, github.com/ValveSoftware/Proton (README, issue 1344), github.com/Open-Wine-Components/umu-launcher, developer.apple.com/news (Rosetta end-of-support). Blocked or empty: forum.monstersandmemories.com (JS-only), codeweavers.com compatibility page (403), web.archive.org, YouTube "NEW Launcher is here!" (no metadata).
