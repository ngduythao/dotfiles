# POWERLEVEL10K - Instant Prompt
# Keep this near the top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# OH MY ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-autosuggestions
  zsh-z
)


# COMPLETIONS
# Add before Oh My Zsh runs compinit
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi


source "$ZSH/oh-my-zsh.sh"
# POWERLEVEL10K
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"


# FZF
# Ctrl+R -> fuzzy history search
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi


# NVM - LAZY LOAD
# No load NVM when open terminal.
# Only loading when using node/npm/npx/nvm/corepack.

export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unset -f nvm node npm npx corepack

  [[ -s "$NVM_DIR/nvm.sh" ]] &&
    source "$NVM_DIR/nvm.sh"

  [[ -s "$NVM_DIR/bash_completion" ]] &&
    source "$NVM_DIR/bash_completion"
}

nvm() {
  _load_nvm
  nvm "$@"
}

node() {
  _load_nvm
  node "$@"
}

npm() {
  _load_nvm
  npm "$@"
}

npx() {
  _load_nvm
  npx "$@"
}

corepack() {
  _load_nvm
  corepack "$@"
}


# BUN
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"


# DENO
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"


# PNPM
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# JAVA
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"


# OTHER TOOLS
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
# psql and pg_dump: libpq is keg-only because it would clash with a full
# PostgreSQL install.
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"


# DOCKER CLEAN
# WARNING: removes containers, images, volumes and unused networks
docker-clean() {
  echo "Stop containers..."
  docker stop $(docker ps -aq) 2>/dev/null

  echo "Delete containers..."
  docker rm $(docker ps -aq) 2>/dev/null

  echo "Delete images..."
  docker rmi $(docker images -q) -f 2>/dev/null

  echo "Delete volumes..."
  docker volume prune -f 2>/dev/null

  echo "Delete networks..."
  docker network prune -f 2>/dev/null

  echo "Clean up Docker..."
  docker system prune -a -f --volumes 2>/dev/null
}


# ALIASES

alias c='clear'

alias cs='cursor'
alias cs2='cursor --user-data-dir ~/.cursor-profile2'

alias d='docker'
alias dl='docker-clean'

alias k='kubectl'
alias h='helm'
alias s='skaffold'

alias lg='lazygit'
alias ld='lazydocker'

# SYNTAX HIGHLIGHTING
# Keep this LAST
[[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"