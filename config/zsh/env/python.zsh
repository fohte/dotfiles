export RYE_HOME="$HOME/.rye"

# Sourcing the env file is the recommended and most robust way to set up rye.
if [ -f "$RYE_HOME/env" ]; then
  source "$RYE_HOME/env"
fi
