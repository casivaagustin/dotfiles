# NVM — lazy-loaded (sourcing nvm.sh eagerly adds ~7s)
export NVM_DIR="$HOME/.nvm"
# Put nvm's default node on PATH so node/npm resolve without loading nvm
_nvm_node_dirs=("$NVM_DIR"/versions/node/v*(NOn))
(( ${#_nvm_node_dirs} )) && path=("${_nvm_node_dirs[1]}/bin" $path)
unset _nvm_node_dirs
_load_nvm() {
  unset -f nvm node npm npx corepack 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
}
nvm()      { _load_nvm; nvm "$@"; }
node()     { _load_nvm; node "$@"; }
npm()      { _load_nvm; npm "$@"; }
npx()      { _load_nvm; npx "$@"; }
corepack() { _load_nvm; corepack "$@"; }

# pyenv — lazy-loaded
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    _load_pyenv() {
      unset -f pyenv 2>/dev/null
      eval "$(command pyenv init -)"
    }
    pyenv() { _load_pyenv; pyenv "$@"; }
fi

# SDKMAN — lazy-loaded
export SDKMAN_DIR="$HOME/.sdkman"
export SDKMAN_AUTO_ENV=true
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    _load_sdkman() {
      unset -f sdk java javac gradle maven 2>/dev/null
      source "$SDKMAN_DIR/bin/sdkman-init.sh"
    }
    sdk()    { _load_sdkman; sdk "$@"; }
    java()   { _load_sdkman; java "$@"; }
    javac()  { _load_sdkman; javac "$@"; }
    gradle() { _load_sdkman; gradle "$@"; }
    maven()  { _load_sdkman; maven "$@"; }
fi

# fzf
eval "$(fzf --zsh)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

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
