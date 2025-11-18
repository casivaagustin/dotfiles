# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="gentoo"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
if [[ "Darwin" == `uname -s` ]] ; then
    plugins=(
        git 
        macos 
        docker 
        brew 
        tmux
        drush 
        virtualenv
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
else
    plugins=(
        git 
        docker 
        #docker-compose
        tmux
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
fi

# Customize to your needs...
if [[ "Darwin" == `uname -s` ]] ; then
    if [[ "arm64" == `arch` ]] ; then
        BREW_PATH="/opt/homebrew/bin"
        export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
        export PUPPETEER_EXECUTABLE_PATH=`which chromium`
    else
        BREW_PATH="/usr/local/homebrew/bin"
    fi
    export PATH="$BREW_PATH:$PATH"
fi
export PATH="$HOME/bin:$HOME/.mcv/bin:$PATH"

source $ZSH/oh-my-zsh.sh

autoload -U zmv
alias mmv='noglob zmv -W'

[[ -f $HOME/.profile ]] && source $HOME/.profile

if [[ "Darwin" == `uname -s` ]] ; then
    export NVM_DIR="$HOME/.nvm"
    if [[ "arm64" == `arch` ]] ; then
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    else
        [ -s "/usr/local/opt/nvm/nvm.sh"  ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
        [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
    fi
    bindkey -e
    bindkey '^[[1;9C' forward-word
    bindkey '^[[1;9D' backward-word
    bindkey '\e\e[D' backward-word
    bindkey '\e\e[C' forward-word
    #alias python=/usr/local/bin/python3
else
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
fi

# Vi mode baby! https://dougblack.io/words/zsh-vi-mode.html
#bindkey -v

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# Bind Home and End keys properly
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line


function zle-line-init zle-keymap-select {
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
    RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
#export KEYTIMEOUT=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[[ -f "$HOME/.zshrc.local" ]] && source $HOME/.zshrc.local

if [[ -d "$HOME/.pyenv" ]] ; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
# Create alias for fd if it is not already defined
command -v fd &>/dev/null || alias fd="fdfind"
# Create alias for cat if 'bat' or 'batcat' exists
command -v batcat &>/dev/null && alias cat="batcat"
command -v bat &>/dev/null && alias cat="bat"



eval "$(fzf --zsh)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

alias dcup="docker compose up"
alias dc="docker compose"
alias dce="docker compose exec"
alias dca="docker compose exec app php artisan"
alias dcapp="docker compose exec app"
alias dcnrd="docker compose exec app npm run dev"
alias artisan="dca"
