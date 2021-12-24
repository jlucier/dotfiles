call plug#begin()
" git
Plug 'airblade/vim-gitgutter'

Plug 'kien/ctrlp.vim'
Plug 'morhetz/gruvbox'
Plug 'neoclide/coc.nvim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" this was kinda nice gruvbox config
let g:gruvbox_italic=1
let g:gruvbox_italicize_strings=1
let g:gruvbox_contrast_dark="hard"
colorscheme gruvbox

set spell
set hidden
set nowrap        " don't wrap lines
set tabstop=4     " a tab is four spaces
set expandtab
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
set sessionoptions+=tabpages,resize

set colorcolumn=100 " ruler

" Splitting
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

" CtrlP
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|build|node_modules|flow-typed|Pods)$',
  \ 'file': '\v\.(exe|so|dll|ipynb)$',
  \ }
let g:ctrlp_root_markers = ['fitcon5']

" Coc
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()

" Airline
let g:airline_powerline_fonts = 1

" General

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
autocmd FileType go,javascript,html,toml,yaml setlocal shiftwidth=2 tabstop=2

" Allow extra machine specific config
" https://devel.tech/snippets/n/vIIMz8vZ/load-vim-source-files-only-if-they-exist/
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction

call SourceIfExists("$HOME/.extra_vimrc")

" custom mksession command
command! -nargs=1 -bang JTest :call mksession <args>
