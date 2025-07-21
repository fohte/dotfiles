# bind ^F instead of ^T
bindkey -M emacs '^F' fzf-file-widget
bindkey -M vicmd '^F' fzf-file-widget
bindkey -M viins '^F' fzf-file-widget

bindkey -r '^G'

_append_to_lbuffer() {
  if [ "${LBUFFER[-1]}" != ' ' ]; then
    LBUFFER="${LBUFFER} "
  fi
  LBUFFER="${LBUFFER}${1}"
}

fzf-git-nocommit-file() {
  local selected
  selected=($(git status -s | fzf --tmux center,50% -m --ansi --reverse | awk '{ print $2 }'))

  zle reset-prompt

  if [ -z "${selected}" ]; then
    return
  fi

  _append_to_lbuffer "${selected}"
}
zle -N fzf-git-nocommit-file
bindkey '^G^F' fzf-git-nocommit-file

fzf-git-log() {
  local selected
  selected=($(git log --pretty=format:'%C(yellow)%h%C(reset) %s %C(green)%an%C(reset)' |
    fzf --tmux center,50% --ansi --reverse |
    awk '{ print $1 }'))

  zle reset-prompt

  if [ -z "${selected}" ]; then
    return
  fi

  _append_to_lbuffer "${selected}"
}
zle -N fzf-git-log
bindkey '^G^L' fzf-git-log

fzf-git-branch() {
  selected=$(
    git branch -a | \
    fzf --tmux center,50% -m --ansi --reverse | \
    sed -e 's/^* //g' | \
    awk '{ print $1 }'
  )

  zle reset-prompt

  if [ -z "${selected}" ]; then
    return
  fi

  _append_to_lbuffer "${selected}"
}
zle -N fzf-git-branch
bindkey '^G^B' fzf-git-branch
