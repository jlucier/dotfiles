# Setup
1. Install
```
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim nodejs npm fzf ripgrep python3-neovim nodejs
sudo npm install -g neovim
mkdir -p ~/.config/
cp -r config/nvim ~/.config
```
2. [Optional] Remap `vim` to `nvim` with the below in your `~/.bashrc`
```
alias vim='nvim'
```
3. Open vim (run `nvim` or `vim` if you set up an alias)
  - A number of things will auto install in a popup window and also the status bar
  - When they finish, just hit `q`
  - Once everything chills out, run `:MasonInstallAll
