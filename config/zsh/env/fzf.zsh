export FZF_DEFAULT_COMMAND='rg --files --hidden --no-messages'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
has fd && export FZF_ALT_C_COMMAND='fd . -t d'
export FZF_DEFAULT_OPTS='--cycle --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'
export FZF_CTRL_T_OPTS='--preview "fzf-preview file {}"'
export FZF_ALT_C_OPTS='--preview "fzf-preview dir {}"'
export FZF_CTRL_R_OPTS='--preview "fzf-preview command {}" --preview-window=wrap'

# Disable fzf-tmux usage in keybindings
export FZF_TMUX=0

# Enable tmux integration when in tmux
if [ -n "$TMUX" ]; then
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --tmux center,50%"
fi


source <(fzf --zsh)
