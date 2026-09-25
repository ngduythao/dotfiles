#!/usr/bin/env bash
# Set up a new Mac from this repo. Safe to re-run: every step skips what is already installed.
#
#   git clone https://github.com/ngduythao/dotfiles.git ~/Desktop/dotfiles
#   ~/Desktop/dotfiles/bootstrap.sh
#
# Order matters: the Brewfile has cargo and npm entries, so Rust and Node come before
# `brew bundle`. Installers that like to edit shell profiles are told not to, because those
# profiles are symlinks into this repo and already set PATH.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(zsh wezterm tmux claude)
NODE_VERSION=24

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
has() { command -v "$1" >/dev/null 2>&1; }

step "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  echo "Finish the Command Line Tools installer, then run this script again."
  exit 1
fi

step "Homebrew"
if ! has brew && [[ ! -x /opt/homebrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

step "Rust (for the Brewfile's cargo entries)"
if [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"

step "nvm and Node $NODE_VERSION (for the Brewfile's npm entries)"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  # PROFILE=/dev/null: zsh/.zshrc already lazy-loads nvm.
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
fi
set +u # nvm.sh reads unset variables
# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
set -u

step "Brewfile"
brew bundle --file="$DOTFILES/Brewfile"

step "Oh My Zsh, Powerlevel10k and plugins"
ZSH_DIR="$HOME/.oh-my-zsh"
if [[ ! -d "$ZSH_DIR" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
clone_once() { [[ -d "$2" ]] || git clone --depth=1 "$1" "$2"; }
clone_once https://github.com/romkatv/powerlevel10k.git "$ZSH_DIR/custom/themes/powerlevel10k"
clone_once https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_DIR/custom/plugins/zsh-autosuggestions"
clone_once https://github.com/agkozak/zsh-z.git "$ZSH_DIR/custom/plugins/zsh-z"

step "Link dotfiles with stow"
# Stow refuses to replace real files, so move any that are in the way (for example the
# ~/.zshrc Oh My Zsh just wrote) to <name>.backup.<time>.
stamp="$(date +%Y%m%d%H%M%S)"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r -d '' src; do
    rel="${src#"$DOTFILES/$pkg/"}"
    target="$HOME/$rel"
    [[ -e "$target" || -L "$target" ]] || continue
    [[ "$(realpath "$target" 2>/dev/null)" == "$DOTFILES/"* ]] && continue
    echo "backing up $target"
    mv "$target" "$target.backup.$stamp"
  done < <(find "$DOTFILES/$pkg" -type f -print0)
done
stow --dir="$DOTFILES" --target="$HOME" --restow "${PACKAGES[@]}"

step "Foundry"
if [[ ! -x "$HOME/.foundry/bin/foundryup" ]]; then
  # foundryup itself, without the installer that appends PATH to zsh/.zshenv (already there).
  mkdir -p "$HOME/.foundry/bin"
  curl -fsSL https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/foundryup \
    -o "$HOME/.foundry/bin/foundryup"
  chmod +x "$HOME/.foundry/bin/foundryup"
fi
has forge || "$HOME/.foundry/bin/foundryup"

step "Slither"
export PATH="$HOME/.local/bin:$PATH"
has slither || pipx install slither-analyzer

step "Claude Code"
has claude || curl -fsSL https://claude.ai/install.sh | bash
# Marketplaces and plugins come from claude/.claude/settings.json, so installing a plugin on
# any machine (which writes that file) is enough for every other machine after a pull.
settings="$DOTFILES/claude/.claude/settings.json"
jq -r '.extraKnownMarketplaces // {} | to_entries[] | select(.value.source.source == "github") | .value.source.repo' "$settings" |
  while read -r repo; do
    claude plugin marketplace add "$repo" </dev/null || warn "marketplace $repo not added"
  done
jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$settings" |
  while read -r plugin; do
    claude plugin install "$plugin" </dev/null || warn "plugin $plugin not installed"
  done

step "Done"
cat <<'EOF'
Open a new terminal to load the linked shell config.
Still manual: `gh auth login`, `claude` to sign in, Docker Desktop's first launch, SSH keys.
EOF
