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

() {
  # mise's aqua backend does not generate a shim for fzf, and the
  # `mise hook-env` that would add installs/... to PATH runs on precmd —
  # after .zshenv. Glob the installs dir directly to resolve the binary.
  local -a matches
  () {
    # (n) sorts lexicographically unless numeric_glob_sort is set, so
    # "0.9.0" would otherwise outrank "0.44.0".
    setopt local_options numeric_glob_sort
    matches=(${MISE_DATA_DIR}/installs/aqua-junegunn-fzf/*/fzf(NOn))
  }
  local fzf_bin="${matches[1]:-$(command -v fzf)}"
  [[ -n $fzf_bin ]] || return
  cache_source fzf-zsh "$fzf_bin" -- "$fzf_bin" --zsh
}
