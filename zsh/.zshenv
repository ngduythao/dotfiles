export PATH="$PATH:$HOME/.foundry/bin"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# The newest nvm Node on PATH for every shell, including the non-interactive ones tools such as
# Claude Code run, where .zshrc functions do not exist.
export NVM_DIR="$HOME/.nvm"
_nvm_node=( "$NVM_DIR"/versions/node/v*(N-/nOn) )
(( ${#_nvm_node} )) && export PATH="${_nvm_node[1]}/bin:$PATH"
unset _nvm_node
