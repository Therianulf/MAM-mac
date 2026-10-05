# MAM-mac

One-click installer for the tooling that runs Monsters & Memories on an Apple-Silicon Mac: the official native launcher plus a self-contained Wine runtime. Owner: Benjamin Larson. Coordinator: command-control.

## Rules

- Initial work commits and pushes straight to `main`; no pull request until command-control relays "we're done". Feature branches start once a first working version exists.
- Nothing this repo does may change the Mac it runs on outside `MAM_HOME`: no `sudo`, no Homebrew, nothing in `/Applications` or `/usr/local`. Rosetta 2 is the one exception and only after a y/N.
- Test with `MAM_HOME` pointed at `.local/mam` under the repo or a temp folder. Never open the launcher window or the game from an agent session; the live test is the owner's, from his own account. Never sign in to his account.
- Every download is HTTPS and pinned by SHA-256 in `bin/mam`; nothing fetched is executed without a hash check.
- Separate STATED (a source says it), OBSERVED (read from the binary) and INFERRED (our reading) in every doc.
- Report milestones to `command-control-9c` by messenger and `command-control+claude` by letter.

## Documents

- [docs/launcher-requirements.md](docs/launcher-requirements.md) — what the Mac launcher is, does and needs, with sources.
- [docs/plan.md](docs/plan.md) — the installer design, checks, removal, and the owner's open questions.

## Tooling

- `bin/mam` — the installer and launcher wrapper (`install`, `doctor`, `launcher`, `play`, `uninstall`). Not built yet; see the plan.
