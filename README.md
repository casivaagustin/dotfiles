# Dotfiles

These are my dot files, this repo is desinged to be used be my and just me. This readme is for me to don't forget 
how it works and how to use it.

To start, Clone this repo into ~/dotfiles

## One-command install

Runs everything on Manjaro/Arch, Ubuntu/Debian, and macOS. Detects the OS,
installs packages from `deps/<manager>.txt`, sets up oh-my-zsh + powerlevel10k +
zsh plugins, clones the Ultimate VIM and LazyVim starters, stows every package,
and installs editor extensions. Safe to re-run.

```
cd ~/dotfiles
./install.sh
```

Package lists live in `deps/`:

- `deps/apt.txt`    — Ubuntu / Debian
- `deps/pacman.txt` — Manjaro / Arch
- `deps/brew.txt`   — macOS (Homebrew)

Edit those files to add or drop dependencies.

## Manual usage

If you just want to re-apply the stow packages without touching dependencies,
enter the dotfiles directory and run

`stow DIRECTORY`

Where DIRECTORY is some of the directories that holds the configs to each tool.

Some of them it might require some additional installation.

# Install Before

- fzf
- fd
- bat
- delta 
- eza
- stow
- wish
- tk
- libnotify-bin
- libnotify4
- btop
- htop
- mc
- ncdu
- tmux

## Ubuntu Install

  `sudo apt install zsh fzf bat delta eza fd-find stow wish libnotify-bin libnotify4 btop htop nc ncdu tmux`

## OSX

```
    cd ~
	brew install htop bat fzf fd delta eza stow tmux btop htop mc
	git clone https://github.com/zsh-users/zsh-autosuggestions 
	git clone https://github.com/zsh-users/zsh-syntax-highlighting
   	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git 
   	brew tap homebrew/cask-fonts\nbrew install font-meslo-lg-nerd-font
``` 

## O-my-ZSH and power10k

```
cd ~
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

# zsh

Install

```
cd ~/dotfiles
stow zsh
```

# p10k

Install 

```
cd ~/dotfiles
stow p10k
```

# tmux

# vim

Install Ultimate VIM first

```
cd ~
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
cd ~/dotfiles
stow vim
```

# nvim

```
cd ~
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
cd ~/dotfiles
stow nvim
```

# Fonts

Install with 

  `stow fonts`

On Linux Run

  `fc-cache -fv`
  
On OSX, install the fonts and set the font in your terminal profile (iterm2 > settings> profile)

```
   brew tap homebrew/cask-fonts\nbrew install font-meslo-lg-nerd-font
```

# Links and more info

- https://www.youtube.com/watch?v=y6XCebnB9gs
- https://www.youtube.com/watch?v=NoFiYOqnC4o&t=10s
- https://www.youtube.com/watch?v=mmqDYw9C30I
- https://www.josean.com/posts/7-amazing-cli-tools


