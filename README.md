# dotfiles
Pretty self explanatory.

# Setup
```bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt install neovim
git clone --recurse-submodules git@github.com:jlucier/dotfiles.git
mkdir -p ~/.config/nvim ~/.vim-sess
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'


ln -s ~/dev/dotfiles/bundle ~/.config/nvim/bundle
ln -s ~/dev/dotfiles/nvim/init.vim ~/.config/nvim/init.vim
ln -s ~/dev/dotfiles/coc-settings.json ~/.config/nvim/coc-settings.json
ln -s ~/dev/dotfiles/zshrc ~/.zshrc
ln -s ~/dev/dotfiles/tmux.conf ~/.tmux.conf
```

# LunarVim
```
bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)
```

# CoC
- install nodejs with nvm
- Next:
```
curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
cd bundle/coc.nvim
yarn install
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
