# Check if the shell is running in interactive mode
if [[ $- == *i* ]]; then
  source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null
fi

source "$HOME/.fzf/shell/key-bindings.zsh"
