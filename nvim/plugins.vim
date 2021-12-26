call plug#begin()
" editing
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'numToStr/Comment.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'folke/which-key.nvim'

" git
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'

" IDE
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-project.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ahmedkhalf/project.nvim'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'glepnir/dashboard-nvim'

" aesthetic
Plug 'nvim-lualine/lualine.nvim'
Plug 'morhetz/gruvbox'
Plug 'LunarVim/onedarker.nvim'
Plug 'kyazdani42/nvim-web-devicons'

call plug#end()

lua require('nvim-autopairs').setup{}
lua require('Comment').setup()
lua << EOF
  require("which-key").setup {
      timeoutlen = 150
  }
EOF

lua require('gitsigns').setup()
lua require('telescope').setup()
lua require('telescope').load_extension('fzf')
lua require('telescope').load_extension('project')
lua require("project_nvim").setup{}
lua require("nvim-tree").setup{}
lua require('lualine').setup()
let g:dashboard_default_executive ='telescope'

source $HOME/.config/nvim/coc.vim

lua << EOF
-- Ripped from LunarVim
local _, builtin = pcall(require, "telescope.builtin")

-- Smartly opens either git_files or find_files, depending on whether the working directory is
-- contained in a Git repo.
function _G.find_project_files()
  local ok = pcall(builtin.git_files)

  if not ok then
    builtin.find_files()
  end
end

vim.api.nvim_set_keymap('n', '<leader>ff', ":lua find_project_files()<cr>", {noremap = true})
EOF

" nnoremap <leader>ff <cmd>Telescope git_files<cr>
nnoremap <leader>fp <cmd>Telescope project<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

nnoremap <leader>t <cmd>NvimTreeFindFileToggle<CR>

nnoremap <leader>ss <cmd>SessionSave<CR>
nnoremap <leader>sl <cmd>SessionLoad<CR>
