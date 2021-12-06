# for Linuxbrew (Homebrew on Linux)
if [ -d "$HOME/.linuxbrew" ]; then
  export HOMEBREW_PREFIX="$HOME/.linuxbrew";
  export HOMEBREW_CELLAR="$HOME/.linuxbrew/Cellar";
  export HOMEBREW_REPOSITORY="$HOME/.linuxbrew/Homebrew";
  export HOMEBREW_SHELLENV_PREFIX="$HOME/.linuxbrew";
  export PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin${PATH+:$PATH}";
  export MANPATH="$HOME/.linuxbrew/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="$HOME/.linuxbrew/share/info:${INFOPATH:-}";
fi
