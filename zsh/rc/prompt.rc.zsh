autoload -U promptinit; promptinit

function exist_prompt_theme() {
  prompt -l | sed -n 2P | tr ' ' '\n' | grep -e "^$1\$" > /dev/null 2>&1
  return $?
}

if ! exist_prompt_theme 'pure'; then
  printf "${fg[red]}Not found pure prompt theme. Install pure? [y/N]: ${reset_color}"
  if read -q; then
    echo; npm install -g pure-prompt && promptinit
  else
    echo;
  fi
fi

if exist_prompt_theme 'pure'; then
  prompt pure
fi
