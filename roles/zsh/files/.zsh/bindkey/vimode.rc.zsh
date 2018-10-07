bindkey -v

autoload -Uz surround

zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround

bindkey -a -r s
bindkey -a sr change-surround
bindkey -a sd delete-surround
bindkey -a sa add-surround

autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done

autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

bindkey -M vivis 'sa ' vi-visual-surround-space
bindkey -M vivis 'sa"' vi-visual-surround-dquote
bindkey -M vivis "sa'" vi-visual-surround-squote
bindkey -M vivis 'sa(' vi-visual-surround-parenthesis
bindkey -M vivis 'sa)' vi-visual-surround-parenthesis
