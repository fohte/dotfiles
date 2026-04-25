# Set tmux pane title to current working directory on every prompt.
# Workaround for tmux-resurrect: an empty pane_title corrupts the save file
# (consecutive tab delimiters get collapsed by `IFS=$'\t' read`), which causes
# pane_current_path to be lost on restore. Keeping the title non-empty avoids it.
# Refs: https://github.com/tmux-plugins/tmux-resurrect/pull/564
_set_tmux_pane_title() {
  [[ -z "$TMUX" ]] && return
  print -Pn '\e]2;%~\a'
}
precmd_functions+=(_set_tmux_pane_title)
