# Keybindings for the `vivis` keymap provided by b4b4r07/zsh-vimode-visual.
# Sourced via zinit's atload' ice after the plugin is loaded to keep the
# `vivis` keymap available when these bindkey calls run.
bindkey -M vivis 'sa ' vi-visual-surround-space
bindkey -M vivis 'sa"' vi-visual-surround-dquote
bindkey -M vivis "sa'" vi-visual-surround-squote
bindkey -M vivis 'sa(' vi-visual-surround-parenthesis
bindkey -M vivis 'sa)' vi-visual-surround-parenthesis
