# dotfiles
Pretty self explanatory.

## Setup
```bash
sudo apt install neovim
git clone --recurse-submodules git@github.com:jlucier/dotfiles.git
mkdir -p ~/.config/nvim/autoload ~/.config/nvim/bundle ~/.config/nvim/sessions
curl -LSso ~/.config/nvim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

ln -s ~/dev/dotfiles/bundle ~/.config/nvim/bundle
ln -s ~/dev/dotfiles/init.vim ~/.config/nvim/init.vim
ln -s ~/dev/dotfiles/zshrc ~/.zshrc
```

## Build YCM
```bash
sudo apt-get install build-essential cmake python3-dev
./build-ycm.sh
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
