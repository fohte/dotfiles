source ~/.zinit/bin/zinit.zsh

# Defer plugin loading until after prompt is ready to reduce startup time.
# wait'0a' / '0b' / '0c' controls ordering within the same batch.

zinit ice wait'0a' lucid
zinit light zsh-users/zsh-completions

zinit ice wait'0a' lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# zsh-histdb: load early so command hooks are registered before first command
zinit ice wait'0a' lucid pick"sqlite-history.zsh" src"histdb-interactive.zsh"
zinit light larkery/zsh-histdb

# fzf-tab must load after compinit (compinit runs in .zshrc before zinit)
zinit ice wait'0b' lucid
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# syntax-highlighting: zicompinit/zicdreplay replays compdefs queued by deferred plugins
zinit ice wait'0c' lucid atinit'zicompinit; zicdreplay'
zinit light zsh-users/zsh-syntax-highlighting

# zsh-vimode-visual: deferred; `vivis` keymap bindings are applied via atload'
zinit ice wait'1' lucid atload'source $ZSHRC_ROOT/bindkey/vimode-visual.rc.zsh'
zinit light b4b4r07/zsh-vimode-visual

zinit ice wait'1' lucid pick'*.plugin.zsh'
zinit light pierpo/fzf-docker
