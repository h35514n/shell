Shell Config
============

Portable Bash, Zsh, Git, and tmux configuration plus a collection of
fzf-driven helper scripts. Designed to drop into a remote Linux box
(AWS, GCP, GitHub Codespaces) and bring an ergonomic shell environment
with a small dependency set.

The repo's tracked config files (`zshrc`, `bashrc`, `env.sh`,
`gitconfig`, `tmux.conf`) are treated as **reference files** by the
setup script --- it never modifies or symlinks them. Instead, it writes
small shim files into `$HOME` that set up the environment and `source`
the repo's files.

Requirements
------------

- Zsh 5.8 or newer recommended; Bash 4 or newer for the Bash config.
- Required CLI tools: `git`, `curl`, `tmux`, `fzf`, `ripgrep`, `bat`,
  `trash` (from `trash-cli` --- the `rm` alias in `env.sh` wraps it),
  `xclip` (used by the cross-platform `pbcopy`/`pbpaste` shims in
  `utils/`), `eza` (installed by `script/setup` via the package manager
  on Debian 13+ / Ubuntu 24.04+ / Fedora 38+, or as a prebuilt binary on
  older distros).
- Recommended local tools:
  - Diffs: `git-delta`
  - Go (>= 1.24) to build `share/pd`, the directory-jump helper used
    by the `cd()` override in `zshrc`. See *Notes* below.
  - Ruby for `pp` (`pretty-print-path`) and the tmux `bind-key N`
    rename helper, which uses `random-phrase`. Install
    `spicy-proton` (`gem install spicy-proton`) for `random-phrase`.
  - Linting/formatting: `shellcheck`, `shfmt`, `jq`, `yamllint`
  - Tags: `universal-ctags`

Fresh Setup
-----------

Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`,
`zsh-vim-mode`), `fzf` shell integration, the `pd` directory helper, and the
tmux plugins (`tpm`, `tmux-open`, `tmux-prefix-highlight`, `tmux-urlview`)
are vendored under `share/` as git submodules. Clone the repo with
submodules so `share/` is populated:

``` sh
git clone --recurse-submodules <url>
# or, on an existing checkout:
git submodule update --init --recursive
```

If this repo is itself a submodule of a parent dotfiles repo, clone the
parent with `--recurse-submodules` so nested submodules come down in one
pass.

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
CLI dependencies and writes shim files into `$HOME`:

- `~/.zshenv` --- exports `SHELL_CONFIG_DIR`, `DOTFILES_DIR`,
  `MACHINE` (defaults to `linux`, leaves any pre-existing value
  alone), and prepends `${SHELL_CONFIG_DIR}/{git,tmux,utils}` to `PATH`
  (idempotently). No repo `zshenv` is shipped, so this shim is
  self-contained.
- `~/.zshrc` --- sources the repo's `zshrc` (env already set by
  `.zshenv`).
- `~/.bashrc` --- exports the same vars as `.zshenv` and then `source`s
  the repo's `bashrc`.
- `~/.tmux.conf` --- runs `set-environment -g SHELL_CONFIG_DIR ...`
  and `source-file` the repo's `tmux.conf`. tmux expands
  `${SHELL_CONFIG_DIR}` when loading plugins from `share/`.
- `~/.gitconfig` --- receives a `[include] path = ...` entry via
  `git config --global --add include.path` so the repo's `gitconfig` is
  merged on top of whatever the host already has (existing `user.name`,
  `user.email`, etc. are preserved).

Existing rc files that are not already shims get backed up to
`.bak.YYYYMMDDHHMMSS` before being replaced. Re-running `script/setup`
detects its own marker comment and regenerates in place without piling
up backups.

If the repo lives outside `$HOME/.dotfiles` and the parent dotfiles tree
isn't present, `script/setup` also writes an empty stub at
`${DOTFILES_DIR}/env/setup.sh` (default `$HOME/.dotfiles/env/setup.sh`)
so that `bashrc`'s unconditional `source` line doesn't error. Override
with `--dotfiles-dir DIR` if your parent dotfiles live elsewhere.

Manual Setup
------------

Install the base packages with your package manager
(`bash zsh tmux git curl fzf ripgrep bat eza trash-cli xclip`), then
create the shims yourself, replacing `/abs/path/to/shell` with the
absolute path to this checkout.

`~/.zshenv`:

``` sh
export SHELL_CONFIG_DIR="/abs/path/to/shell"
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export MACHINE="${MACHINE:-linux}"
case ":$PATH:" in
  *":$SHELL_CONFIG_DIR/git:"*) ;;
  *) export PATH="$SHELL_CONFIG_DIR/git:$SHELL_CONFIG_DIR/tmux:$SHELL_CONFIG_DIR/utils:$PATH" ;;
esac
```

`~/.zshrc`:

``` sh
[ -r "$SHELL_CONFIG_DIR/zshrc" ] && . "$SHELL_CONFIG_DIR/zshrc"
```

`~/.bashrc`:

``` sh
export SHELL_CONFIG_DIR="/abs/path/to/shell"
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
export MACHINE="${MACHINE:-linux}"
case ":$PATH:" in
  *":$SHELL_CONFIG_DIR/git:"*) ;;
  *) export PATH="$SHELL_CONFIG_DIR/git:$SHELL_CONFIG_DIR/tmux:$SHELL_CONFIG_DIR/utils:$PATH" ;;
esac
[ -r "$SHELL_CONFIG_DIR/bashrc" ] && . "$SHELL_CONFIG_DIR/bashrc"
```

`~/.tmux.conf`:

``` tmux
set-environment -g SHELL_CONFIG_DIR "/abs/path/to/shell"
source-file "/abs/path/to/shell/tmux.conf"
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

Util helpers (live in `utils/`, on `$PATH` via the shims):

- `pbcopy` / `pbpaste`: cross-platform clipboard shims. Branch on
  `$MACHINE` --- `linux` calls `xclip`, `apple`/`intel-mac` call the
  macOS builtins. The shim exports `MACHINE=linux` on remote hosts.
- `pretty-print-path` (alias: `pp`): print `$PATH` / `$MANPATH` /
  `$CDPATH` one entry per line. Needs Ruby.
- `random-phrase`: emit a random two-word phrase (used by the tmux
  `bind-key N` rename binding). Needs Ruby + the `spicy-proton` gem.

Tmux helpers (live in `tmux/`, on `$PATH` via the shims):

- `mx`: tmux + tmuxinator wrapper for managing sessions and templates
- `tmux-attach-or-create`: attach to a session named after the cwd or
  create it
- `mx-fzf-preview`: fzf preview helper used by `mx`

The `tmux.conf` shipped with this repo rebinds the prefix to `Ctrl-a`
(default is `Ctrl-b`) and loads tpm + the vendored plugins under
`share/` (`tmux-open`, `tmux-prefix-highlight`, `tmux-urlview`). The
plugins are run-shell'd directly, so no `prefix + I` bootstrap is
needed unless you add a new entry to `@tpm_plugins`. `bind-key N`
calls an external `random-phrase` command to rename the session;
install it separately or rebind to taste.

Notes
-----

- Vendored plugin/runtime dependencies live under `share/` as git
  submodules: `zsh-autosuggestions`, `zsh-syntax-highlighting`,
  `zsh-vim-mode`, `fzf`, `pd`, `tpm`, `tmux-open`,
  `tmux-prefix-highlight`, `tmux-urlview`. `zshrc` sources them from
  `$SHELL_CONFIG_DIR/share/...` rather than `$XDG_DATA_HOME`, so no XDG
  data layout is required on the host.
- The repo's config files are never modified by `script/setup`. All
  host-specific environment setup lives in the shims and in the setup
  script itself.
- Debian/Ubuntu ships `bat` as `batcat`. If `bat` isn't on `$PATH`,
  alias or symlink it: `ln -s "$(command -v batcat)" ~/.local/bin/bat`.
- `git-delta` is not in the default apt/dnf repos and is left to install
  manually (https://github.com/dandavison/delta/releases). Without it,
  the gitconfig's `pager.diff = delta` falls back to git's built-in
  pager.
- `share/pd` is a small Go program (the `pd` directory-jump helper used
  by the `cd()` override in `zshrc`). It's not built by `script/setup`
  because it pulls in Go and a handful of Go modules. To build it:

    ``` sh
    cd "$SHELL_CONFIG_DIR/share/pd"
    go build -o "$HOME/.local/bin/pd"
    ```

  Requires Go >= 1.24 (`share/pd/go.mod` pins `go 1.24.2`, toolchain
  `go1.24.5`). Without `pd` on `$PATH`, `zshrc`'s `cd()` falls back to
  the builtin --- everything still works, you just lose the fuzzy
  directory matching.
- This repo is intended to be added as a submodule under a parent
  dotfiles repo. When it stands alone, `script/setup` creates an empty
  stub at `${DOTFILES_DIR}/env/setup.sh` so `bashrc`'s unconditional
  source line doesn't error.
- The setup script does not run `chsh`. If you want zsh as your login
  shell on the remote box, run `chsh -s "$(command -v zsh)"` yourself.
