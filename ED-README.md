# Setup
1. Install
```
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim nodejs npm fzf ripgrep python3-neovim golang unzip
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
  - Once everything chills out, run `:MasonInstallAll`
  - When those things finish, you're ready to rock

# Personalize
Change whatever you want, colorschemes are fun! You can add new stuff in `plugins.lua`. We use a plugin manager
called `lazy.nvim` which automatically installs whatever you put in there.


# Core Plugins + Useful Commands
Your "leader" key is `<space>`, most useful commands begin with a press of the spacebar.

Additionally, there is a plugin called `which-key` installed. At any time, you can run `:WhichKey` to see available
commands. It presents commands hierarchically. For example, a command like `d e` starts with `d` so it's nested under the `d`
submenu and the actual command is shown next to the final key `e` that you'd press to execute it. Additionally, if you type
a partial command and pause, which key will pop up there too, showing you what you can type next to do things.

You can more quickly move between splits with just `<C-h>`, `<C-l>`, `<C-j>`, `<C-k>` instead of `<C-w>` + a direction.

Check out the `mappings.lua` for more stuff, below are the essentials.

## Nvim tree
https://github.com/nvim-tree/nvim-tree.lua

`<leader>tt` - There's a file tree plugin installed. Launch it and close it with `<space>+t t`. It's pretty intuitive
to navigate. Hit `enter` to open a file, `<C-v>` to open it in a vertical split, `<C-h>` for horizontal. You can also
add new files, directories, delete them, etc.

## nvim-telescope
https://github.com/nvim-telescope/telescope.nvim

Telescope is kinda crazy, it can do everything. The two things I use constantly are the following:

`<leader>ff` - Telescope find files
Nvim tries to figure out what the "root directory" of your "project" is when you open a file. Generally, it'll figure
it out based on where there's a `.git` directory, so it tends to be right.

This command will open a window with a text input
for you to find files within your project directory. The text input is automatically in `insert` mode so you can just start typing.
You can hit `Escape` to exit `insert` mode and navigate the matching files. This is a much faster way to jump between files than
using the file tree because you can "fuzzy search" and find what you want. You can open files in buffers using the same
commands as with the file tree.

`<leader>fg` - Telescope grep
Similarly, this command will open a window, but instead of a fuzzy search for finding files it lets you perform
project wide `grep`. You can search here for whatever, and scrub through matches with a preview on the right, and open the buffers
at the matching line. Again, you can open files in buffers using the same commands as with the file tree.

## nvim-lspconfig (+ others)
Nvim has an LSP client built into it. We use `nvim-lspconfig` to manage configuration of servers. It comes with some good default
configurations for tons of servers.

Language Server Protocol (LSP) is a newly standardized protocol for "language servers" to provide formatting, linting, static analysis,
code actions, and other functionality to an editor which acts more like a "frontend". This is really cool, because it separates
the language specific stuff from you actual editor and standardizes the interface. This has made it soooo much easier for things like
VSCode and neovim to provide all the features of a fully baked, language specific IDE.

There's a plugin called `mason-nvim`, it helps you install language servers. They are mostly `nodejs` packages installed separately
from `nvim`. You already used that to get set up. We installed `gopls` (among one or two others), which is the standard go language
server.

Language servers automatically run when you open a file of a type it handles. When you're in a buffer with a language server running,
you'll have additional things available.
- Format on save should work automatically.
- Type checking and other static any
- Auto complete will actually be smart

Here are some commands:

`K` - LSP Hover (aka bring up information on something from your LSP)
This will show info on a function or library or some entity under your cursor. Just capital K.

`<leader>/` (or `gcc`) - Comment a line
This can be run in normal mode to comment one line, or in visual to comment multiple.


`gd` - Goto definition
Go to the definition (if the language server can find it) of the token under your cursor.

`[d` & `]d` - Navigate to next or previous error.
If you have any linter, analyzer, or other issues you can navigate between them.

`<leader>f` - Show the LSP error of the line under your cursor in a floating window.
The errors from the language server are displayed inline, but sometimes they are long. This will pop them up into a window that makes
easer to read.

`<leader>rn` - Rename something
With your cursor over a variable, function, class, or whathaveyou, enter this command to rename it intelligently. Change the name
in the little popup and hit enter.

`<leader>ca` - Code actions
Some language servers provide "code actions" like sorting imports or fixing other problems. If any are available, this will show a prompt
to execute them.
