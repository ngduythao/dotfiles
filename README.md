# Dotfiles

Personal Zsh, WezTerm, and tmux configuration for macOS (Apple Silicon).

## Setup

Install GNU Stow and the required tools:

```zsh
brew install stow tmux
cd ~/dotfiles
stow zsh wezterm tmux
```

Existing target files must be backed up or removed before running `stow`.
