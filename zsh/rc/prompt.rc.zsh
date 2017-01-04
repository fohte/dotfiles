setopt prompt_subst

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
  if is_ssh_running; then
    status_color='red'
  else
    status_color='blue'
  fi
  echo -n "%{$fg[$status_color]%}>%{$reset_color%}>"
}

dir='%{$fg[magenta]%}%~%{$reset_color%}'
branch='$(git_current_branch)'
privileges='$(dynamic_privilege)'

PROMPT="
$dir $branch
$privileges "
