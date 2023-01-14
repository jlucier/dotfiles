#! /bin/bash -e
#
# An auto setup script for taking a server install -> a "desktop environment" with my stuff set up.
# WIP

NVIDIA=
pkg_manager=

if [ -f /etc/fedora-release ]
then
    pkg_manager=dnf
elif [ -f /etc/debian_version ]
then
    pkg_manager=apt-get
else
    echo Could not detect package manager!
    exit 1
fi

pkg_install() {
    sudo $pkg_manager install -y $@
}

fedora_add_repos() {
    # add rpm fusion repos
    fv=$(rpm -E %fedora)
    sudo dnf install -y \
        dnf-plugins-core \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$fv.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fv.noarch.rpm

    sudo dnf update --refresh
}

install_build_essential() {
    if [ -f /etc/debian_version ]
    then
        sudo apt-get install -y build-essential
    elif [ -f /etc/fedora-release ]
    then
        sudo dnf group install -y "C Development Tools and Libraries"
    fi
}

install_docker() {
    sudo dnf config-manager --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install -y \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

fonts() {
    curl -fLo ~/.fonts/"Hack Nerd Font Complete.otf" --create-dirs \
        https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete%20Mono.ttf?raw=true
}

dotconfig() {
    mkdir -p ~/.config/ ~/.vim-sess
    ln -s $pwd/zshrc ~/.zshrc
    ln -s $pwd/tmux.conf ~/.tmux.conf

    for f in $pwd/config/*
    do
        ln -s $f ~/.config/
    done
}

rofi() {
    sudo dnf install -y rofi
    git clone --depth=1 https://github.com/adi1090x/rofi.git
    cd rofi
    ./setup.sh
    cd ..
    rm -r rofi
}

brave() {
    sudo dnf config-manager --add-repo \
        https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y brave-browser
}

install_nvim() {
    sudo dnf install -y \
        neovim fzf ripgrep python3-neovim nodejs

    sudo npm install yarn -g
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    nvim --headless +PlugInstall +qall
}

ohmyzsh() {
    sudo dnf install -y zsh
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    sudo chsh -s $(which zsh)
}

alacritty() {
    sudo dnf install -y alacritty
    sudo update-alternatives --install \
        /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50
}


## MAIN

fonts
dotconfig

fedora_add_repos

# install core dependencies
install_build_essential
pkg_install \
    `# DE` \
    sddm \
    picom \
    sxhkd \
    bspwm \
    polybar \
    nitrogen \
    thunar \
    bluez \
    arc-theme \
    arandr \
    gnome-control-center \
    NetworkManager NetworkManager-wifi network-manager-applet \
    lxappearance \
    lxsession \
    vim \
    tmux \
    htop \
    xclip

rofi
brave
install_docker
install_nvim
ohmyzsh
alacritty


if [ $NVIDIA ]
then
    echo INSTALLING NVIDIA DRIVERS
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
fi

# enable graphical login
sudo systemctl enable sddm.service
sudo systemctl set-default graphical.target
