setopt prompt_subst

zle-line-init zle-keymap-select() {
 zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

git_current_branch() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [ -z $branch ]; then
    echo -n ""
  else
    echo -n "[${branch}]"
  fi
}

dynamic_privilege() {
  local status_color
  local vimode_color

  if is_ssh_running; then
    status_color='red'
  else
    status_color='blue'
  fi

  case $KEYMAP in
    vicmd)
      vimode_color=''
      ;;
    viins|main)
      vimode_color='blue'
      ;;
  esac

  echo -n "%{$fg[$status_color]%}>%{$reset_color%}%{$fg[$vimode_color]%}>%{$reset_color%}"
}

dir='%{$fg[magenta]%}%~%{$reset_color%}'
branch='$(git_current_branch)'
privileges='$(dynamic_privilege)'

PROMPT="
$dir $branch
$privileges "
