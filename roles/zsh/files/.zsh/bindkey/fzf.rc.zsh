bindkey -r '^G'

_append_to_lbuffer() {
  if [ "${LBUFFER[-1]}" != ' ' ]; then
    LBUFFER="${LBUFFER} "
  fi
  LBUFFER="${LBUFFER}${1}"
}

fzf-git-nocommit-file() {
  local selected
  selected=($(git status -s | fzf -m --ansi | awk '{ print $2 }'))

  if [ -z "${selected}" ]; then
    return
  fi

  _append_to_lbuffer "${selected}"
}
zle -N fzf-git-nocommit-file
bindkey '^G^T' fzf-git-nocommit-file

fzf-git-log() {
  local selected
  selected=($(git log --pretty=format:'%C(yellow)%h%C(reset) %s %C(green)%an%C(reset)' | fzf --ansi | awk '{ print $1 }'))

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
    fzf -m --ansi | \
    sed -e 's/^* //g' | \
    awk '{ print $1 }'
  )

  if [ -z "${selected}" ]; then
    return
  fi

  _append_to_lbuffer "${selected}"
}
zle -N fzf-git-branch
bindkey '^G^B' fzf-git-branch