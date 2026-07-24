# PATH configuration
if [[ "Darwin" == $(uname -s) ]]; then
    if [[ "arm64" == $(arch) ]]; then
        BREW_PATH="/opt/homebrew/bin"
        export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
        export PUPPETEER_EXECUTABLE_PATH=$(which chromium)
    else
        BREW_PATH="/usr/local/homebrew/bin"
    fi
    export PATH="$BREW_PATH:$PATH"
fi
export PATH="$HOME/bin:$HOME/.mcv/bin:$PATH"

[[ -f $HOME/.profile ]] && source $HOME/.profile

# pnpm
export PNPM_HOME="/home/agustin/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Antigravity CLI
export PATH="$HOME/.local/bin:$PATH"

# Lando
export PATH="$HOME/.lando/bin:$PATH"

# LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
