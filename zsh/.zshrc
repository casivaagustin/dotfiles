# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSHD="${0:A:h}/.zsh.d"

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
