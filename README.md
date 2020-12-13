# dotfiles
Pretty self explanatory.

## Setup
```bash
git clone --recurse-submodules git@github.com:jlucier/dotfiles.git
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# TODO symlink *rc -> ~/.*rc

# build YCM
sudo apt-get install build-essential cmake python3-dev
cd ~/.vim/bund/YouCompleteMe
python3 install.py --clangd-completer --ts-completer
```

## Nvim
- sudo apt install neovim
