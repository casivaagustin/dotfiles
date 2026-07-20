# Powerlevel10k instant prompt disabled (causes backspace issues before first command).
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Use %x (this file), not $0 — on startup $0 is "zsh" and :A resolves via $PWD,
# so terminals opened outside $HOME silently skip .zsh.d (no prompt/history).
ZSHD="${${(%):-%x}:A:h}/.zsh.d"

# Source all config files in order
for config_file in "$ZSHD"/*.zsh(N); do
  source "$config_file"
done

# Source OS-specific overrides
if [[ "Darwin" == $(uname -s) ]]; then
  [[ -f "$ZSHD/os/osx.zsh" ]] && source "$ZSHD/os/osx.zsh"
else
  [[ -f "$ZSHD/os/linux.zsh" ]] && source "$ZSHD/os/linux.zsh"
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        [[ -f "$ZSHD/os/debian.zsh" ]] && source "$ZSHD/os/debian.zsh" ;;
      manjaro|arch)
        [[ -f "$ZSHD/os/manjaro.zsh" ]] && source "$ZSHD/os/manjaro.zsh" ;;
    esac
  fi
fi

# Source host-specific overrides
ZSHHOST="$ZSHD/hosts/$(hostname -s).zsh"
[[ -f "$ZSHHOST" ]] && source "$ZSHHOST"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Source local overrides (not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

if [[ -d "$HOME/.pyenv" ]] ; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

alias ls="eza --color=always --long --git --icons=always"
# Create alias for fd if it is not already defined
command -v fd &>/dev/null || alias fd="fdfind"
command -v fdfind &>/dev/null || alias fdfind="fd"
# Create alias for cat if 'bat' or 'batcat' exists
command -v batcat &>/dev/null && alias cat="batcat --style=plain"
command -v bat &>/dev/null && alias cat="bat --style=plain"



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
alias screenoff="xset dpms force off"
alias hdmionl="xrandr --output HDMI-1-0 --auto --left-of eDP-1"
alias hdmionr="xrandr --output HDMI-1-0 --auto --right-of eDP-1"
alias hdmiont="xrandr --output HDMI-1-0 --auto --top-of eDP-1"
alias hdmioff="xrandr --output HDMI-1-0 --off"
alias hdmionrv="xrandr --output DP-1-2 --auto --rotate left --right-of eDP-1"
alias hdmioffv="xrandr --output DP-1-2 --off"

alias projects="cd ~/projects"

export EDITOR=nvim
export VISUAL=nvim
export BROWSER=brave-browser

# pnpm
export PNPM_HOME="/home/agustin/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
#

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ~/.bashrc or ~/.zshrc
export SDKMAN_AUTO_ENV=true

# opencode
export PATH=/home/agustin/.opencode/bin:$PATH

## Esta sive para usar 1password agent con dbeaver, pero después no anda con teleport.
#export SSH_AUTH_SOCK=~/.1password/agent.sock


# Added by Antigravity CLI installer
export PATH="/home/agustin/.local/bin:$PATH"

export PATH="/home/agustin/.lando/bin:$PATH"; #landopath


# Added by LM Studio CLI tool (lms)
export PATH="$PATH:/home/agustin/.lmstudio/bin"

