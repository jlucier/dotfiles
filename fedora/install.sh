#! /bin/bash -e
#
# An auto setup script for taking a server install -> a "desktop environment" with my stuff set up.
# WIP

repo=$(pwd)

dnf_setup() {
    sudo cp $repo/fedora/dnf.conf /etc/dnf/
    # add rpm fusion repos
    fv=$(rpm -E %fedora)
    sudo dnf install -y \
        dnf-plugins-core \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$fv.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fv.noarch.rpm

    sudo dnf group install -y "C Development Tools and Libraries"
    sudo dnf update --refresh
}

hardo_de() {
    # still don't have gnome-keyring fully working, might just swap to sddm
    sudo dnf install -y \
        picom \
        sxhkd \
        bspwm \
        polybar \
        dunst \
        nitrogen \
        arc-theme \
        lxappearance \
        thunar \
        bluez \
        blueman \
        arandr \
        xset \
        xss-lock \
        xsecurelock \
        brightnessctl \
        pavucontrol \
        playerctl \
        pulseaudio-utils \
        NetworkManager NetworkManager-wifi network-manager-applet \
        lxsession \
        gnome-keyring \
        setxkbmap \
        vim \
        tmux \
        htop \
        xclip \
        sox

    # display manager (ly)
    sudo dnf install -y pam-devel libxcb-devel
    git clone --recurse-submodules https://github.com/fairyglade/ly
    cd ly
    make
    sudo make install installsystemd
    sudo systemctl enable ly.service
    # got strategy from here: https://github.com/fairyglade/ly/issues/433
    sudo semodule -X 300 -i $repo/fedora/ly.pp
    cd ..
    rm -rf ly

    # autorandr
    sudo curl -fLo /usr/local/bin/autorandr \
        https://raw.githubusercontent.com/phillipberndt/autorandr/master/autorandr.py
    sudo chmod +x /usr/local/bin/autorandr

    # rofi
    sudo dnf install -y rofi
    git clone --depth=1 https://github.com/adi1090x/rofi.git
    cd rofi
    ./setup.sh
    cd ..
    # use sudo to skip the prompts about protected files
    sudo rm -r rofi

    # enable graphical login
    sudo systemctl set-default graphical.target
}

install_docker() {
    sudo dnf config-manager --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install -y \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin

    sudo usermod -aG docker $USER
}

fonts() {
    curl -fLo ~/.fonts/"JetBrainsMonoNL Nerd Font Complete.ttf" --create-dirs \
	    https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/NoLigatures/Regular/JetBrainsMonoNLNerdFont-Regular.ttf
    sudo dnf install -y google-noto-emoji-color-fonts
}

dotconfig() {
    mkdir -p ~/.config/ ~/.vim-sess
    ln -s $repo/zshrc ~/.zshrc

    for f in $repo/config/*
    do
        ln -s $f ~/.config/
    done

    # oh my zsh
    sudo dnf install -y zsh sqlite
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    sudo usermod -s $(which zsh) $USER
    if [ -f $repo/jlucier.zsh-theme ]
    then
        ln -s $repo/jlucier.zsh-theme ~/.oh-my-zsh/themes/
    fi

    # tmux
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # nvim
    sudo dnf install -y \
        neovim fzf ripgrep python3-neovim nodejs
    sudo npm install yarn -g
}

install_apps() {
    sudo dnf install -y flatpak firefox

    # alacritty
    sudo dnf install -y alacritty
    sudo update-alternatives --install \
        /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50

    # brave
    sudo dnf config-manager --add-repo \
        https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y brave-browser

    # 1pass
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
    sudo dnf install -y 1password

    # spotify
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.spotify.Client
    # obsidian
    flatpak install -y flathub md.obsidian.Obsidian

}

nvidia() {
    echo INSTALLING NVIDIA DRIVERS
    # Get nvidia container toolkit, using the centos8 repo
    # https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
    curl -s -L \
        https://nvidia.github.io/libnvidia-container/centos8/libnvidia-container.repo | \
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

    sudo dnf clean expire-cache --refresh
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-docker2
}

extras() {
    sudo dnf install -y syncthing jq htop wireguard-tools
    systemctl --user enable --now syncthing.service
}


## MAIN

dnf_setup
# hardo_de
fonts
dotconfig
install_docker
extras
install_apps
# NOTE: comment this out to not install nvidia
nvidia
