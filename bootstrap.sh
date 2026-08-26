#!/bin/bash
#
# bootstrap.sh — the one imperative step, run once on a clean machine.
#
# Installs the things chezmoi cannot: the compiler toolchain, the package
# manager, and the packages themselves. Everything declarative and
# version-controlled — dotfiles, themes, macOS defaults — belongs to the
# second step, `chezmoi init --apply`, and is deliberately not done here.
#
# The split exists because installing software is a one-shot imperative act,
# while chezmoi models a desired end state it can converge to repeatedly.
# Mixing them made `chezmoi verify` report on package installation, and made
# a single flaky cask download abort the entire dotfiles restore.
#
# Usage:
#   ./bootstrap.sh                 # fetch Brewfile from the public repository
#   ./bootstrap.sh path/to/Brewfile  # use a local Brewfile instead
#
# Safe to re-run: every step checks whether it is already done, and
# `brew bundle` skips what is already installed.

set -uo pipefail

readonly BREWFILE_URL="https://raw.githubusercontent.com/rajivgeraev/dotfiles-public/main/Brewfile"
readonly REPO_URL="https://github.com/rajivgeraev/dotfiles-public.git"

# Downloaded Brewfile is kept, not cleaned up on exit: if `brew bundle` fails
# partway the retry command below has to point at a file that still exists.
readonly BREWFILE_CACHE="${TMPDIR:-/tmp}/dotfiles-Brewfile"

say()  { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die()  { printf '!! %s\n' "$*" >&2; exit 1; }

case "${1:-}" in
  -h|--help)
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

[ "$(uname -s)" = "Darwin" ] || die "macOS only — this machine reports $(uname -s)."

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools
#
# Required before anything else: Homebrew needs a compiler, and chezmoi falls
# back to its limited builtin git when /usr/bin/git is absent.
#
# `xcode-select --install` hands control straight back and does the work in a
# separate GUI window, so the script has to poll rather than wait on it. This
# is the one step macOS offers no way to fully automate.
# ---------------------------------------------------------------------------
if xcode-select -p >/dev/null 2>&1; then
  say "Xcode Command Line Tools: already installed."
else
  say "Xcode Command Line Tools not found — starting the installer."
  xcode-select --install >/dev/null 2>&1 || true
  say "A system installer window has opened. Click through it; this script waits."

  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  say "Xcode Command Line Tools: installed."
fi

# ---------------------------------------------------------------------------
# 2. Homebrew
#
# Its installer needs sudo to create the prefix, and prompts for the password
# itself. That prompt belongs here, in a script the user invoked knowingly —
# not buried inside `chezmoi apply`, where it is unclear what wants privileges.
#
# Apple Silicon uses /opt/homebrew, Intel /usr/local. A freshly installed brew
# is not yet on PATH for this process, so the prefix is probed explicitly.
# ---------------------------------------------------------------------------
activate_brew() {
  command -v brew >/dev/null 2>&1 && return 0
  local prefix
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}

if activate_brew; then
  say "Homebrew: already installed ($(brew --version | head -1))."
else
  say "Homebrew not found — installing. The installer will ask for your password."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew installation failed. Fix the error above and re-run this script."

  activate_brew || die "Homebrew installed but no brew binary found in /opt/homebrew or /usr/local."
  say "Homebrew: installed."
fi

# ---------------------------------------------------------------------------
# 3. Packages
#
# A local Brewfile may be passed as the first argument, which is also how this
# script gets tested without reaching the network.
# ---------------------------------------------------------------------------
if [ -n "${1:-}" ]; then
  [ -f "$1" ] || die "No such Brewfile: $1"
  brewfile="$1"
  say "Using local Brewfile: $brewfile"
else
  say "Fetching Brewfile..."
  curl -fsSL "$BREWFILE_URL" -o "$BREWFILE_CACHE" \
    || die "Could not download the Brewfile. Check your network and re-run."
  brewfile="$BREWFILE_CACHE"
fi

say "Installing packages and applications — this is the long part."
say "karabiner-elements installs from a .pkg and will ask for your password once."
say "The other casks are plain .app bundles and need no privileges."

if brew bundle --verbose --file="$brewfile"; then
  say "Packages: all installed."
else
  # Deliberately not fatal. A failed cask is almost always a network hiccup,
  # and it must not stop the user from restoring their configuration — every
  # tool is gated behind `command -v` in conf.d, so a missing one simply
  # stays switched off until it is installed.
  warn ""
  warn "Some packages did not install — usually a network failure."
  warn "This does not block the next step: configs do not depend on them,"
  warn "and any tool that is missing just stays disabled in the shell."
  warn ""
  warn "Retry:      brew bundle --verbose --file=$brewfile"
  warn "See what is missing: brew bundle check --verbose --file=$brewfile"
  warn ""
fi

# ---------------------------------------------------------------------------
# Done — hand over to chezmoi.
#
# Intentionally stops here instead of chaining into chezmoi: the two phases
# are separate on purpose, and the second one should be started knowingly.
# ---------------------------------------------------------------------------
cat <<EOF

==> Bootstrap complete.

    Next, restore the configuration:

      sh -c "\$(curl -fsLS get.chezmoi.io)" -- init --apply $REPO_URL

    Then place the secrets, which are not in the repository:

      ~/.local/share/chezmoi/restore-secrets.sh /path/to/backup/secrets

EOF
