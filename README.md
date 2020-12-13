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
