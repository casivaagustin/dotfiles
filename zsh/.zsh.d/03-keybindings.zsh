# Key bindings
autoload -U zmv

if [[ "Darwin" == $(uname -s) ]]; then
    bindkey -e
    bindkey '^[[1;9C' forward-word
    bindkey '^[[1;9D' backward-word
    bindkey '\e\e[D' backward-word
    bindkey '\e\e[C' forward-word
fi

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# Home and End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Vi mode prompt indicator
function zle-line-init zle-keymap-select {
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
    RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
