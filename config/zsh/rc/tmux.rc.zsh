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

# Publish the current directory's git-worktree name to a tmux window option so
# window-status-format can read it via #{@window-dir-info} without spawning a
# process on every status redraw.
_set_tmux_window_dir_info() {
  [[ -z "$TMUX" ]] && return
  [[ -z "$TMUX_PANE" ]] && return
  local info=''
  # A git worktree's `.git` is a file starting with `gitdir:`, not a directory.
  if [[ -f .git ]]; then
    local gitline
    read -r gitline < .git
    [[ "$gitline" == gitdir:* ]] && info=" ${PWD:t}"
  fi
  tmux set-option -w -t "$TMUX_PANE" @window-dir-info "$info"
}
chpwd_functions+=(_set_tmux_window_dir_info)
_set_tmux_window_dir_info
