#! /bin/bash -e

sudo dnf update
sudo dnf install dnf-plugins-core

# font
mkdir -p ~/.fonts
curl -fLo ~/.fonts/"Hack Nerd Font Complete.otf" \
    https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete%20Mono.ttf?raw=true

# set up configs
mkdir -p ~/.config/ ~/.vim-sess
ln -s ~/dev/dotfiles/zshrc ~/.zshrc
ln -s ~/dev/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/dev/dotfiles/config/* ~/.config/

# brave
sudo dnf config-manager --add-repo \
    https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# docker
sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

# install dependencies

sudo dnf group install "C Development Tools and Libraries"
sudo dnf install -y \
    `# DE` \
    sddm \
    picom \
    sxhkd \
    bspwm \
    polybar \
    rofi \
    nitrogen \
    dunst \
    thunar \
    bluez \
    NetworkManager NetworkManager-wifi network-manager-applet \
    brave-browser \
    lxappearance \
    lxsession \
    `# tools` \
    zsh \
    alacritty \
    neovim fzf ripgrep python3-neovim nodejs \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin

# finish nvim
sudo npm install yarn -g
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim --headless +PlugInstall +qall

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo update-alternatives --install \
    /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50

sudo systemctl enable sddm.service
sudo systemctl set-default graphical.target
