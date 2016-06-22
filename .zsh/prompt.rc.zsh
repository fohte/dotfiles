add-zsh-hook precmd vcs_info

PROMPT="${fg_bold[blue]}%(5~,.../%3~,%~)${reset_color} ${fg[red]}%#${reset_color} "
RPROMPT=''

zstyle ':vcs_info:git:*' max-exports 1
zstyle ':vcs_info:git:*' check-for-changes true

zstyle ':vcs_info:git:*' stagedstr '*'
zstyle ':vcs_info:git:*' unstagedstr '*'

zstyle ':vcs_info:git:*' formats '%F{red}%u%f%F{yellow}%c%f%F{black}(%m)%f %F{green}%b%f'
zstyle ':vcs_info:git:*' actionformats '%F{red}%u%f%F{yellow}%c%f%F{black}(%m)%f [%a] %F{green}%b%f'

zstyle ':vcs_info:git+set-message:*' hooks \
  git-hooks-begin \
  git-unpushed \
  git-stash-count \

function +vi-git-hooks-begin() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
    return 1
  fi

  hook_com[branch]="${hook_com[branch]}"
  hook_com[misc]=''

  return 0
}

function +vi-git-unpushed() {
  if [[ $(git status -b --porcelain 2> /dev/null | grep '##' | awk '{ print $3 }') = '[ahead' ]]; then

    hook_com[branch]='%F{red}↑%f'${hook_com[branch]}
  fi
}

function +vi-git-stash-count() {
  local stash
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  if [[ ${stash_count} -gt 0 ]]; then
    hook_com[misc]+=${stash_count}
  fi
}
