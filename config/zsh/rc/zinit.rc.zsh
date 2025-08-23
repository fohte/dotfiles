source ~/.zinit/bin/zinit.zsh

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

zinit light b4b4r07/zsh-vimode-visual

zinit ice pick'*.plugin.zsh'
zinit light pierpo/fzf-docker

zinit load azu/ni.zsh

# replace zsh's default completion selection menu with fzf
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# zsh-histdb - SQLite-backed command history
zinit ice pick"sqlite-history.zsh" src"histdb-interactive.zsh"
zinit light larkery/zsh-histdb
