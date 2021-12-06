if [ type -a 'nvim' 2>&1 > /dev/null ]; then
  export EDITOR='nvim'
else
  export EDITOR='vim'
fi
