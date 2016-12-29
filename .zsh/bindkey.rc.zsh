# vi mode settings
bindkey -v
bindkey '^?' backward-delete-char

bindkey -r '^G'

fzf-git-nocommit-file() {
  local selected
  selected=($(git status -s | fzf-tmux -m --ansi --preview "git diff --color \$(echo {} | awk '{ print \$2 }')" | awk '{ print $2 }'))
  LBUFFER="${LBUFFER}${selected}"
}
zle -N fzf-git-nocommit-file
bindkey '^G^T' fzf-git-nocommit-file

fzf-git-log() {
  local selected
  selected=($(git log --pretty=format:'%C(yellow)%h%C(reset) %s %C(green)%an%C(reset)' | fzf-tmux --ansi --preview "git diff --color \$(echo {} | awk '{ print \$1 \"^ \" \$1 }')" | awk '{ print $1 }'))
  LBUFFER="${LBUFFER}${selected}"
}
zle -N fzf-git-log
bindkey '^G^L' fzf-git-log
