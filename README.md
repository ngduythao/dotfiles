# Dotfiles

Personal Zsh, WezTerm, tmux, and Claude Code configuration for macOS

## Setup

```zsh
brew install stow tmux
cd ~/dotfiles
stow --target="$HOME" zsh wezterm tmux claude
```

Back up conflicting target files before running Stow.