set nocp
call pathogen#infect()
syntax on
filetype plugin indent on

"colorscheme Benokai
colorscheme Tomorrow-Night

set hidden
set nowrap        " don't wrap lines
set tabstop=4     " a tab is four spaces
set expandtab
set backspace=indent,eol,start
                    " allow backspacing over everything in insert mode
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set number        " always show line numbers
set relativenumber " show relative numbers
set shiftwidth=4  " number of spaces to use for autoindenting
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch     " set show matching parenthesis
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase,
                    "    case-sensitive otherwise
set smarttab      " insert tabs on the start of a line according to
                    "    shiftwidth, not tabstop
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep

set nobackup
set noswapfile
set updatetime=250
set sessionoptions+=tabpages,resize

set colorcolumn=105

" Splitting
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|build|node_modules|perch_runtime|dev_containers/*|flow-typed|Pods)$',
  \ 'file': '\v\.(exe|so|dll|ipynb)$',
  \ }
let g:ctrlp_root_markers = ['fitcon5']
let g:ycm_enable_diagnostic_highlighting = 0

" String trailing whitespace
" autocmd BufWritePre * %s/\s\+$//e
function! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
augroup twig_ft
    au!
    autocmd BufNewFile,BufRead *.launch set syntax=xml
augroup END
augroup docker
    au!
    autocmd BufNewFile,BufRead Dockerfile* set syntax=dockerfile
augroup END

autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
autocmd FileType javascript,html,toml,yaml setlocal shiftwidth=2 tabstop=2

python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

" https://devel.tech/snippets/n/vIIMz8vZ/load-vim-source-files-only-if-they-exist/
" Function to source only if file exists {
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction
" }

call SourceIfExists("$HOME/.extra_vimrc")

" Git Gutter"
highlight clear SignColumn
highlight GitGutterAdd ctermfg=darkgreen
highlight GitGutterChange ctermfg=yellow
highlight GitGutterDelete ctermfg=red
highlight GitGutterChangeDelete ctermfg=yellow
