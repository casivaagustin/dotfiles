# General aliases
alias mmv='noglob zmv -W'
alias ls="eza --color=always --long --git --icons=always"
alias projects="cd ~/projects"

# fd/fdfind compatibility
command -v fd &>/dev/null || alias fd="fdfind"
command -v fdfind &>/dev/null || alias fdfind="fd"

# bat/batcat compatibility
command -v batcat &>/dev/null && alias cat="batcat --style=plain"
command -v bat &>/dev/null && alias cat="bat --style=plain"

# Docker
alias dcup="docker compose up"
alias dc="docker compose"
alias dce="docker compose exec"
alias dca="docker compose exec app php artisan"
alias dcapp="docker compose exec app"
alias dcnrd="docker compose exec app npm run dev"
alias artisan="dca"

# Screen/display
alias screenoff="xset dpms force off"
alias hdmionl="xrandr --output HDMI-1-0 --auto --left-of eDP-1"
alias hdmionr="xrandr --output HDMI-1-0 --auto --right-of eDP-1"
alias hdmiont="xrandr --output HDMI-1-0 --auto --top-of eDP-1"
alias hdmioff="xrandr --output HDMI-1-0 --off"
alias hdmionrv="xrandr --output DP-1-2 --auto --rotate left --right-of eDP-1"
alias hdmioffv="xrandr --output DP-1-2 --off"
