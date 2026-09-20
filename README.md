# Dotfiles

Personal Zsh, WezTerm, tmux, and Claude Code configuration for macOS

## Setup

```zsh
cd ~/dotfiles
brew bundle --file=Brewfile
stow --target="$HOME" zsh wezterm tmux claude
```

Back up conflicting target files before running Stow.