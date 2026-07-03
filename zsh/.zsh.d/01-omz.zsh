# Oh My Zsh configuration
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

if [[ "Darwin" == $(uname -s) ]]; then
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
        tmux
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
fi

source $ZSH/oh-my-zsh.sh
