# dotfiles
Pretty self explanatory.

# Setup
```bash
sudo apt update

ln -s ~/dev/dotfiles/zshrc ~/.zshrc
ln -s ~/dev/dotfiles/tmux.conf ~/.tmux.conf

# oh-my-zsh
sudo apt install zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# nvm + node + yarn
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# nvim
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt install neovim

git clone --recurse-submodules git@github.com:jlucier/dotfiles.git
mkdir -p ~/.config/nvim ~/.vim-sess
sh -c 'curl -fLo .config/nvim/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

ln -s ~/dev/dotfiles/nvim/init.vim ~/.config/nvim/init.vim
ln -s ~/dev/dotfiles/nvim/plugins.vim ~/.config/nvim/
ln -s ~/dev/dotfiles/nvim/coc.vim ~/.config/nvim/coc.vim
ln -s ~/dev/dotfiles/nvim/coc-settings.json ~/.config/nvim/coc-settings.json
```

# Regolith
```
sudo apt install reglith-desktop-standard i3xrocks-temp i3xrocks-disk-capacity \
    i3xrocks-memory
ln -s ~/dev/dotfiles/regolith ~/.config/regolith
```
TODO `xmodmap`
```
clear Lock
keycode 66 = Hyper_L
add mod4 = Hyper_L
```

# Alacritty
- install and build
```bash
# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup override set stable
rustup update stable

# deps + build
sudo apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3
cd alacritty-term/alacritty
cargo build --release
cd ../..

# finish setup
sudo cp target/release/alacritty /usr/local/bin
# configure default terminal application
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/alacritty 50
mkdir -p ~/.config/alacritty/
ln -s ~/dev/dotfiles/alacritty-term/alacritty.yml ~/.config/alacritty/alacritty.yml
```
- to remove `sudo update-alternatives --remove "x-terminal-emulator" "/usr/local/bin/alacritty"`
