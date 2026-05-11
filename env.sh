# shellcheck shell=bash
# shellcheck disable=SC2139
# SC2139: aliases below intentionally expand variables at definition time.
# Shared portable shell config sourced from both `zshrc` and `bashrc`.
# Keep this file bash/zsh-portable: no `setopt`, `bindkey`, `zle`,
# suffix/global aliases (`alias -g`, `alias -s`), `autoload`, or other
# zsh-only constructs. Anything zsh-specific belongs in `zshrc`; anything
# bash-specific belongs in `bashrc`.

# ----- Aliases: file management and navigation -----
alias ..='cd ..; l'
alias ...='cd ../..; l'
alias mkdir='mkdir -p'
alias h='history'
alias dirs='dirs -v'
alias ls='eza --group-directories-first --time-style=long-iso --classify'
alias l='ls'
alias la='ls -a'
alias ld='ls -d .*'
alias ll='ls -l'
alias lla='ls -al'
alias lld='ls -al -d .*'
alias lt='eza --tree --level=3'

# ----- Aliases: safeguards -----
alias rm='trash'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -iv'

# ----- Aliases: highlighting and XDG compliance -----
alias wget="wget --hsts-file=${XDG_CACHE_HOME}/wget/history"
alias bash="bash --init-file ${XDG_CONFIG_HOME}/bash/bashrc"

# ----- Aliases: miscellaneous -----
alias vi='vim -u $XDG_CONFIG_HOME/vim/vimrc.minimal.vim'
alias vin='vim -u NONE'

# ----- Environment: editor and pager -----
export EDITOR="vim"
export PAGER="less"
export LESSOPEN="| src-hilite-lesspipe.sh %s"
export LESS=' --no-init --RAW-CONTROL-CHARS --quit-if-one-screen '

# ----- Functions -----

# Create a directory (replacing spaces with hyphens) and cd into it.
md() {
  local directory_name="${*// /-}"
  mkdir -p "${directory_name}"
  cd "${directory_name}" || return
}

# Create an executable bin file in $DOTFILES_DIR/bin, chmod +x, open in editor.
mkbin() {
  local file="${DOTFILES_DIR}/bin/${1}"
  touch "$file"
  chmod u+x "$file"
  edit "$file"
}
