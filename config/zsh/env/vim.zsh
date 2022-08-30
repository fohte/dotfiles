if [ type -a 'nvim' 2>&1 > /dev/null ]; then
  export EDITOR="$(which nvim)"
else
  export EDITOR="$(which vim)"
fi
