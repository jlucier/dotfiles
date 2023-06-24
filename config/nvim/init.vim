let mapleader=' '
set spell
set hidden
set nowrap        " don't wrap lines
set tabstop=4     " a tab is four spaces
set expandtab     " make tabs spaces
set copyindent    " copy the previous indentation on autoindenting
set number        " always show line numbers
set relativenumber " show relative numbers
set shiftwidth=4  " number of spaces to use for autoindenting
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch     " set show matching parenthesis
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase, case-sensitive otherwise
set scrolloff=8   " keep the cursor more centered in the screen
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep
set cursorline           " highline the current line

set nobackup
set noswapfile
set updatetime=250
set timeoutlen=300
set sessionoptions+=tabpages,resize

set colorcolumn=100 " ruler

" Splitting
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

source $HOME/.config/nvim/plugins.vim

" General

" String trailing whitespace
" autocmd BufWritePre * %s/\s\+$//e
function! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
augroup docker
    au!
    autocmd BufNewFile,BufRead Dockerfile* set syntax=dockerfile
augroup END

autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
autocmd FileType go,javascript,typescript,typescriptreact,html,toml,yaml,json setlocal shiftwidth=2 tabstop=2

" Allow extra machine specific config
" https://devel.tech/snippets/n/vIIMz8vZ/load-vim-source-files-only-if-they-exist/
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction

call SourceIfExists("$HOME/.extra_vimrc")

" custom mksession command
function! SessionSave(name)
    exe 'mksession! '.fnameescape("~/.vim-sess/".a:name)
endfunction
command! -nargs=1 SessSave :call SessionSave(<f-args>)
