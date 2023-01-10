source ~/.zinit/bin/zinit.zsh

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure

zinit light b4b4r07/zsh-vimode-visual

zinit ice pick'*.plugin.zsh'
zinit light pierpo/fzf-docker
