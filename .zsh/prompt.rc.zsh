dir="%{$fg[cyan]%}%(5~,.../%3~,%~)%{$reset_color%}"
privileges="%{$fg[red]%}%#%{$reset_color%}"
host="%m"
user="%n"
machine_info="%{$fg[magenta]%}$user@$host%{$reset_color%}"

PROMPT="$machine_info $privileges "
RPROMPT="$dir"
