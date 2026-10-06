# MAM-mac

Play [Monsters & Memories](https://monstersandmemories.com) on a Mac with Apple silicon.

The game's official Mac launcher downloads the Windows version of the game, and macOS can't run that on its own. This installer adds the missing pieces:

- **Wine**, which runs Windows programs on a Mac
- **D3DMetal**, Apple's graphics layer for Windows games
- a small fix so the launcher's **Play** button starts the game through Wine

You still log in, patch and play in the official launcher. This is an unofficial community project.

## What you need

- A Mac with Apple silicon (an M-series chip). Intel Macs won't work, because the official launcher only exists for Apple silicon.
- macOS 15 Sequoia or later. Tested on macOS 26 Tahoe with M2 Pro and M4 Max chips.
- A Monsters & Memories account with an active subscription.
- At least 11 GB of free disk space: 1.7 GB for the tools and 8.7 GB for the game (its size in October 2026). More is better: the installer warns when less than 20 GB is free.
- Apple's command line developer tools, which the Play button fix is built with. If your Mac doesn't have them yet, the `git` command below offers to install them.
- Rosetta 2. If it's missing, the installer asks before adding it.

## Install

1. Open Terminal and download the installer into a folder of its own:

   ```
   git clone https://github.com/Therianulf/MAM-mac.git ~/MAM-mac-installer
   ```

   If macOS offers to install the command line developer tools, accept, wait for them to finish, then run the command again. Keep this folder: the Monsters & Memories app runs from it. If you move it, run the installer again from the new place.

2. Run the installer:

   ```
   cd ~/MAM-mac-installer
   ./install.sh
   ```

   Double-clicking **Install Monsters & Memories.command** in that folder does the same. It checks your Mac, downloads about 270 MB, verifies every download, and sets everything up in `~/MAM-mac`. You don't need an admin password. Along the way:
   - It shows Apple's licence for D3DMetal. Type `yes` to accept it. Without it, the installer stops ([see below](#when-something-goes-wrong) for the alternative).
   - If Rosetta 2 is missing, it asks before installing it.

3. When it says **Done**, there's a **Monsters & Memories** app in the Applications folder inside your home folder (`~/Applications`).

## Play

1. Open **Monsters & Memories** from `~/Applications`, or double-click **Monsters & Memories.command** in the installer folder. Either one opens the official launcher, set up for your Mac.
2. Log in with your Monsters & Memories account.
3. The first time, press **Install**. The game is 8.7 GB (about 7 GB to download), so this takes a while.
4. Press **Play**.

After that, open it, press **Update** when there's a patch, then **Play**.

## Updating

- **The game:** the launcher patches it. Press **Update** when it offers one.
- **This installer:**

  ```
  cd ~/MAM-mac-installer
  git pull
  ./install.sh
  ```

  Running the installer again is safe: it keeps the game and your login and only redoes what changed.

## Uninstalling

```
cd ~/MAM-mac-installer
bin/mam uninstall
```

This removes everything the installer put in `~/MAM-mac` and the Monsters & Memories app in `~/Applications`. It asks before it starts, then asks separately:

- whether to delete the game files (8.7 GB);
- whether to delete the launcher's saved data, which holds your saved login. That folder belongs to the official Mac launcher, so any other copy of the launcher on this Mac loses its login too.

Type `y` to delete or press Return to keep. `bin/mam uninstall --yes` deletes all of it, the game and the saved login included, without asking.

Then delete the `~/MAM-mac-installer` folder. Rosetta 2 stays, because it's part of macOS.

## When something goes wrong

Run these from the installer folder (`cd ~/MAM-mac-installer` first).

- **Check your Mac:** `bin/mam doctor` checks everything the installer needs and changes nothing.
- **Play doesn't start the game:** the Play fix needs Apple's command line developer tools. Install them with `xcode-select --install`, then run `./install.sh` again. Until then, once the launcher has installed the game, `bin/mam play` starts it from Terminal using your saved login.
- **"The saved login has expired":** open the launcher and log in again.
- **The game closes straight after a patch:** press **Repair** in the launcher. It re-checks the game files and downloads any that are damaged.
- **Low on disk space:** `bin/mam clean` deletes the installer's download cache (about 270 MB). The installer downloads it again the next time it runs.
- **You'd rather not accept Apple's licence, or your Mac is on macOS 14 (14.6 or later):** `./install.sh --renderer dxmt` uses the open-source DXMT graphics layer instead of D3DMetal. It installs, but it hasn't been tested with the game yet.
- **Logs** are in `~/MAM-mac/Logs`. **Never post or share `launcher.log`:** it contains your login token in plain text, so treat it like a password. The other logs can include your account name, so read them before you share them.

`bin/mam help` lists the installer's other commands and options.

## What it puts on your Mac

Everything goes in one folder, `~/MAM-mac`:

| Folder | What's in it | Size |
|---|---|---|
| `Runtime/` | Wine and the graphics layers | 1.1 GB |
| `Prefix/` | the Windows setup Wine runs the game in | 340 MB |
| `Launcher/` | a copy of the official Mac launcher | 19 MB |
| `Game/mnm/` | the game, written there by the launcher | 8.7 GB |
| `downloads/` | the installer's download cache | 270 MB |
| `lib/`, `Logs/`, `config` | the Play fix, logs and your settings | small |

Outside that folder:

- `~/Applications/Monsters & Memories.app`: the app icon. It opens the launcher from `~/MAM-mac`.
- `~/Library/Application Support/com.monstersandmemories.mnm-patcher-app/`: the official launcher's own data, including your saved login. The launcher makes this folder itself.
- Rosetta 2, only if it was missing and you said yes.

Nothing else: no admin password, nothing in `/Applications` or other system folders, no Homebrew.

How it works, in detail: [docs/launcher-requirements.md](docs/launcher-requirements.md) and [docs/plan.md](docs/plan.md).

## Credits and licences

- The approach, including the Play button redirect, follows [seathasky/MnM-on-Mac](https://github.com/seathasky/MnM-on-Mac) (MIT).
- [Wine](https://www.winehq.org) (LGPL), built for macOS by [Sikarugir](https://github.com/Sikarugir-App), along with Sikarugir's support libraries.
- [DXMT](https://github.com/3Shain/dxmt) by 3Shain (MIT).
- D3DMetal by Apple, from the Game Porting Toolkit, under Apple's own licence, which the installer shows you to accept.
- Monsters & Memories and its launcher are by Niche Worlds Cult. This project is not affiliated with them.
