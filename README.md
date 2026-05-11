Shell Config
============

Portable Bash, Zsh, Git, and tmux configuration plus a collection of
fzf-driven helper scripts. Designed to drop into a remote Linux box
(AWS, GCP, GitHub Codespaces) and bring an ergonomic shell environment
with a small dependency set.

The repo's tracked config files (`zshrc`, `zshenv`, `bashrc`,
`gitconfig`) are treated as **reference files**. They are never modified
or symlinked by the setup script. Instead, the setup script writes small
shim files into `$HOME` that set up the environment and `source` the
repo's files.

Requirements
------------

- Zsh 5.8 or newer recommended; Bash 4 or newer for the Bash config.
- Required CLI tools: `git`, `curl`, `tmux`, `fzf`, `ripgrep`, `bat`.
- Recommended local tools:
  - Diffs: `git-delta`
  - Linting/formatting: `shellcheck`, `shfmt`, `jq`, `yamllint`
  - Tags: `universal-ctags`

Fresh Setup
-----------

On a remote Linux VM, run the setup script from this directory:

``` sh
script/setup
```

For optional linters, formatters, and the like, use:

``` sh
script/setup --with-language-tools
```

The script supports Debian/Ubuntu via `apt-get` and Red
Hat/Amazon/Fedora style hosts via `yum` or `dnf`. It installs the base
CLI dependencies and writes four shim files into `$HOME`:

- `~/.zshenv`, `~/.zshrc`, `~/.bashrc` --- small wrappers that export
  `SHELL_CONFIG_DIR`, `DOTFILES_DIR`, prepend `${SHELL_CONFIG_DIR}/git`
  and `${SHELL_CONFIG_DIR}/tmux` to `PATH`, and then `source` the repo's
  reference config.
- `~/.gitconfig` --- receives a `[include] path = ...` entry via
  `git config --global --add include.path` so the repo's `gitconfig` is
  merged on top of whatever the host already has (existing `user.name`,
  `user.email`, etc. are preserved).

Existing shell rc files that are not already shims get backed up to
`.bak.YYYYMMDDHHMMSS` before being replaced. Re-running `script/setup`
detects its own marker comment and regenerates in place without piling
up backups.

If the repo lives outside `$HOME/.dotfiles` and the parent dotfiles tree
isn't present, `script/setup` also writes an empty stub at
`${DOTFILES_DIR}/env/setup.sh` (default `$HOME/.dotfiles/env/setup.sh`)
so that the unconditional `source` line in `zshenv`/`bashrc` doesn't
error. Override with `--dotfiles-dir DIR` if your parent dotfiles live
elsewhere.

Manual Setup
------------

Install the base packages with your package manager
(`bash zsh tmux git curl fzf ripgrep bat`), then create the four shims
yourself, replacing `/abs/path/to/shell` with the absolute path to this
checkout:

`~/.zshenv`:

``` sh
export SHELL_CONFIG_DIR="/abs/path/to/shell"
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
path=("$SHELL_CONFIG_DIR/git" "$SHELL_CONFIG_DIR/tmux" $path)
export PATH
[ -r "$SHELL_CONFIG_DIR/zshenv" ] && . "$SHELL_CONFIG_DIR/zshenv"
```

`~/.zshrc`:

``` sh
[ -r "$SHELL_CONFIG_DIR/zshrc" ] && . "$SHELL_CONFIG_DIR/zshrc"
```

`~/.bashrc`:

``` sh
export SHELL_CONFIG_DIR="/abs/path/to/shell"
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export PATH="$SHELL_CONFIG_DIR/git:$SHELL_CONFIG_DIR/tmux:$PATH"
[ -r "$SHELL_CONFIG_DIR/bashrc" ] && . "$SHELL_CONFIG_DIR/bashrc"
```

Include the repo's `gitconfig` into the host's `~/.gitconfig`:

``` sh
git config --global --add include.path /abs/path/to/shell/gitconfig
```

Useful Commands
---------------

Git helpers (live in `git/`, exposed via the gitconfig aliases):

- `git sf`: fzf-pick modified files (`git-select-files`)
- `git co-`: checkout the file(s) you pick with fzf
- `git revf`: reset + checkout the file(s) you pick with fzf
- `git cob` / `git coba`: fzf-pick a branch to check out
  (`git-checkout-branch`)
- `git bc` / `git bcl`: create a branch with/without remote
- `git sha` / `git ahs`: fzf-pick a commit sha (forward / reversed)
- `git cm` / `git cmt` / `git cmf`: quick / tagged / fixup commits
- `git cmg`: AI-generated commit message via OpenAI
  (`git-commit-generator`)
- `git cli` / `git clo`: clock-in / clock-out time-tracking commits
- `git up` / `git squash`: fetch + rebase / fetch + interactive rebase
- `git rmc`: remove a commit by sha
- `git bdo`: prune local branches whose remotes are gone

Tmux helpers (live in `tmux/`, on `$PATH` via the shims):

- `mx`: tmux + tmuxinator wrapper for managing sessions and templates
- `tmux-attach-or-create`: attach to a session named after the cwd or
  create it
- `mx-fzf-preview`: fzf preview helper used by `mx`

Notes
-----

- The repo's config files are never modified by `script/setup`. All
  host-specific environment setup lives in the shims and in the setup
  script itself.
- Debian/Ubuntu ships `bat` as `batcat`. If `bat` isn't on `$PATH`,
  alias or symlink it: `ln -s "$(command -v batcat)" ~/.local/bin/bat`.
- `git-delta` is not in the default apt/dnf repos and is left to install
  manually (https://github.com/dandavison/delta/releases). Without it,
  the gitconfig's `pager.diff = delta` falls back to git's built-in
  pager.
- This repo is intended to be added as a submodule under a parent
  dotfiles repo. When it stands alone, `script/setup` creates an empty
  stub at `${DOTFILES_DIR}/env/setup.sh` so the configs' unconditional
  source line doesn't error.
- The setup script does not run `chsh`. If you want zsh as your login
  shell on the remote box, run `chsh -s "$(command -v zsh)"` yourself.
