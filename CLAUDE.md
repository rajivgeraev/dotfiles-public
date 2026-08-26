# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [chezmoi](https://www.chezmoi.io)-managed dotfiles repository for macOS, paired with Homebrew. It is the
chezmoi *source directory* — files here use chezmoi's naming conventions and are not the literal files that end
up on disk. There is no build/lint/test suite; changes are validated by rendering/diffing/applying via chezmoi
and by exercising the resulting shell config.

## chezmoi naming conventions

Source files here use standard chezmoi naming: `dot_foo` → `~/.foo`, `private_foo` → mode `0600`, `*.tmpl` →
rendered as a Go template before being written, `run_once_*`/`run_onchange_*`/`before_`/`after_` → scripts (execution order below). The
full general reference for chezmoi's naming attributes lives in project memory (bootstrapped fresh per
machine — see the last section) rather than being duplicated here.

- `.chezmoiignore` also excludes `.keep`, the marker that makes git track otherwise-empty directories
  (`dev/gh`, `dev/sandbox`, `sync/obsidian`). chezmoi creates the directory but never copies the marker.
  This is the documented way to get an empty directory; an earlier `.chezmoikeep` name worked only by
  accident — `.chezmoi*` is a reserved prefix — and `chezmoi doctor` flagged it as a suspicious entry.
- `.chezmoiignore` currently excludes `README.md`, `Brewfile`, `CLAUDE.md`, `CLAUDE.ru.md` — these live in the
  repo for documentation/bundling but aren't dotfiles themselves.
- `.chezmoi.toml.tmpl` is chezmoi's own config template (rendered once at `chezmoi init` into
  `~/.config/chezmoi/chezmoi.toml`), holding template `[data]` (name/email). It deliberately has no `[age]` section — see Secrets below.

Optional-tool config is gated at shell **runtime**, not at chezmoi template-render time — deliberately not
`{{ if lookPath }}`/`{{ if stat }}` in a `.tmpl`. Each tool's shell integration lives in its own file under
`dot_config/zsh/conf.d/<tool>.zsh`, guarded by its own first line (`command -v <tool> >/dev/null 2>&1 || return`,
or `[[ -d ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/<formula> ]] || return` for a Homebrew-installed directory, as
done for antidote). `dot_zshrc` lists which `conf.d` files to source in plain `typeset -a` arrays (not a glob)
and sources them in a loop; the arrays are an explicit allowlist so a stray file accidentally left in `conf.d/`
is never picked up.

Sourcing happens in **two phases** with `compinit` between them, because fzf-tab has to load after `compinit`
but before any plugin that wraps zle widgets. Phase 1 (`zsh_conf_pre`, currently just `antidote-pre`) loads
`.zsh_plugins.txt`, which holds only completion plugins marked `kind:fpath`. Phase 2 (`zsh_conf_post`, starting
with `antidote-post`) loads `.zsh_plugins_post.txt` — fzf-tab first, then autosuggestions and
syntax-highlighting last. Order within a phase is still irrelevant; order inside `.zsh_plugins_post.txt` is not.
Follow this pattern when adding config for a new optional CLI tool. This replaced an earlier `lookPath`-in-template
design specifically because `lookPath` checks chezmoi's *own process* `$PATH`, frozen at the moment `chezmoi
apply` started — on a from-scratch bootstrap, `bootstrap.sh` installs Homebrew and every tool moments before
chezmoi even runs, so a template-time check would go stale and render the block empty. A runtime `command -v` check is evaluated fresh every shell startup, so it's correct on the very first
pass regardless of install order — see the memory note on this redesign for the full reasoning.

## Application order

Day-to-day command reference (`chezmoi diff`/`apply`/`edit`/`add`/`update`) is in `README.md`'s "Рабочий
процесс" section, not repeated here. What matters for correctness, and *is* repo-specific:

All scripts live in `.chezmoiscripts/`, so they execute normally but create no entries in the target state.

**Installing software is not chezmoi's job.** `bootstrap.sh` at the repository root is a separate,
imperative step run once on a clean machine: Xcode CLT, Homebrew, then `brew bundle` against `Brewfile`.
It is listed in `.chezmoiignore` so it never lands in `$HOME`. The split exists because installation is a
one-shot imperative act while chezmoi models a desired end state it converges to repeatedly — while they
were merged, `chezmoi verify` reported on package installation and one flaky cask aborted the whole restore.

`chezmoi apply`/`init --apply` therefore runs: regular files, templates and externals first, then the two
`after_` scripts in numeric order — `run_onchange_after_20-rebuild-bat-cache.sh.tmpl` (`bat cache --build`,
triggered by hashes of `.chezmoiexternal.toml` and the syntax file) and
`run_onchange_after_30-set-macos-defaults.sh.tmpl` (`defaults write` for Finder/Dock/menu bar/system sound).
Numeric prefixes state the order outright instead of relying on ASCII sorting of names; the gap at `10-` is
where the Brewfile script used to be.

Themes are declared in `.chezmoiexternal.toml` rather than downloaded by a script: chezmoi caches them,
verifies their contents on every apply/diff/verify, and a network hiccup no longer aborts the whole apply.
The bat cache rebuild is `after_` on purpose — it must see the theme and syntax files already on disk;
relying on ASCII ordering for that was fragile.

This repository is **public and contains no secrets at all** — not in plaintext, and not encrypted either.
Encryption protects contents, but published ciphertext is downloadable forever and decrypts retroactively
on any future key leak; not publishing it is strictly simpler. `age` encryption was deliberately removed
when the repository was made public, so there is no `key.txt`, no `encrypted_*.age` files and no `[age]`
section in `.chezmoi.toml.tmpl`.

Three files are treated as secrets and live in a password manager instead, restored by `restore-secrets.sh`
(which also sets mode 0600, a job chezmoi used to do via the `private_` prefix):

- `~/.config/rclone/rclone.conf` — tokens and passwords for remote storage
- `~/.local/share/atuin/key` — Atuin's E2E sync key; without it `atuin login` cannot decrypt cloud history
  even with the correct password. The account *password* is not stored anywhere in this repo either;
  `atuin login` has no token auth, only `-u`/`-p`/`-k`, so it is typed interactively at restore time.
- `~/.ssh/id_ed25519_gh` — the private SSH key. Its `.pub` counterpart and `~/.ssh/config` are not secrets
  and stay in the repository.

**Before running `chezmoi add`, open the file and check it.** Beyond obvious credentials, treat anything
that discloses infrastructure as a secret too: rclone remote names, server hostnames, cloud provider names.
That class of leak is why `sync-mac.sh` was dropped when this repository was created — it named the storage
provider and the exact remote path layout. If a new secret appears, add its path to `ITEMS` in
`restore-secrets.sh` rather than to the source state.

## Managed tools/stack

- Shell: zsh with antidote (plugin manager), starship (prompt), atuin (history, Catppuccin Mocha Mauve theme,
  cloud sync logged in — see Encryption above for its key) — all Catppuccin Mocha themed.
- Full CLI/GUI package list is `Brewfile`, not repeated here — read it directly rather than trusting this file
  to stay in sync with it.
- Of the GUI casks, only Ghostty, Zed (`dot_config/zed/`), Claude Code's global settings
  (`dot_claude/settings.json` — global preferences only: `theme`, `tui`, `model`, `language`, `voice`;
  *not* the rest of `~/.claude/` which is session/telemetry
  runtime state and must never be added wholesale), and Karabiner-Elements (`dot_config/karabiner/karabiner.json`
  — Cmd-tap layout switching; macOS permissions/Accessibility/driver-extension setup is manual and documented in
  `karabiner-recovery.md`, not automatable) have chezmoi-managed config; the rest have none worth
  version-controlling (checked their prefs domains/Application Support — either pure UI/session state or, for
  Easydict, mixed in with a full translation history that must not go in git). Re-verify this by checking the
  app's actual prefs/Application Support before assuming "no config" still holds for a newly-added cask.
- `dot_zshenv` holds the environment variables every zsh must see — the four XDG base directories and
  `$ZDOTDIR` derived from `XDG_CONFIG_HOME`. They belong here, not in `dot_zshrc`, because `.zshrc` is read
  only by interactive shells, leaving scripts, LaunchAgents and `zsh -c` without them. Keep this file free of
  aliases, output and slow calls.
- `$ZDOTDIR` is set to `~/.config/zsh` (in `dot_zshenv`), so zsh's own dotfiles live under
  `dot_config/zsh/` (`dot_zprofile`, `dot_zshrc`, `conf.d/*.zsh`, `dot_zsh_plugins{,_post}.txt` for antidote), not at
  `~/.zshrc`.
- `zconf` (defined at the bottom of `dot_zshrc`) is a convenience shell function: `zconf` opens the zshrc
  source for editing via `chezmoi edit`, `zconf -r` re-sources the current zshrc.
- `git` identity comes from `dot_config/git/config.tmpl` using `.name`/`.email` already declared in
  `.chezmoi.toml.tmpl`'s `[data]` — no separate manual step needed.
- `~/dev/{sandbox,gh}` and `~/sync/obsidian` are recreated empty via `.chezmoikeep` marker files (chezmoi's
  mechanism for committing otherwise-untrackable empty directories) — intentionally *not* `exact_`, so chezmoi
  never deletes anything a human later puts in them.

## Claude Code memory for this project

Auto memory here stays at Claude Code's default location (`~/.claude/projects/<project>/memory/`) — deliberately
*not* relocated into the repo. The default is already scoped per-project (keyed to this repo, shared by every
session run in this directory, never entering git) and needs no settings override to satisfy "written once,
available to the whole project, not just one session." If this ever needs revisiting, the reasoning is in
project memory rather than repeated here.

## New machine / new session bootstrap

`README.md`'s restore walkthrough ends with launching `claude` inside this directory on the freshly-restored
machine. Memory (see above) is machine-local and won't exist yet there, even though this file will (it travels
with the git clone).

If project memory is empty or missing topics at the start of a session here, bootstrap it in this order —
once per machine (check what's already there first; don't re-fetch a topic that already has a memory note):

1. **Claude Code itself, first.** Research current official best practices (`CLAUDE.md` structure/size, auto
   memory conventions, effective workflow patterns) from Anthropic's official docs and save them to memory
   before anything else — this should shape how the rest of the bootstrap, and future work here, gets done.
2. **Every tool this repo manages, not just chezmoi.** Read `Brewfile` directly to get the current CLI/GUI
   tool list — don't hardcode it here, it changes as the Brewfile does. For chezmoi and each tool, check
   whether memory already has a note; research and save one for whatever's missing. Weight effort by how much
   a tool's behavior/defaults actually shift or matter here: chezmoi, atuin, starship, antidote, yazi,
   and yazi are worth a real research pass; extremely stable, well-known tools (curl, rsync, git, gh)
   just need a quick current-syntax sanity check, not a full manual.

The point of doing this at all is not relying on possibly-stale trained knowledge — defaults and features
shift between releases for chezmoi and for these tools. Keeping memory out of git and rebuilding it per
machine is deliberate; the cost is paying that research once per new machine, not once per session.

## Language note

`README.md` is written in Russian; keep documentation edits there consistent with that.

`CLAUDE.ru.md` is a human-readable Russian translation of this file (`CLAUDE.md`), for the repo owner to read
— it is not itself read as instructions by Claude Code. **Whenever `CLAUDE.md` is edited, update
`CLAUDE.ru.md` in the same change** with a matching, accurate translation of whatever changed — don't let it
drift out of sync. This applies in every session, not just the one where this rule was written.
