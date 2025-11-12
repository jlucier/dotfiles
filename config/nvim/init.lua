vim.g.mapleader = " "

vim.o.splitbelow = true
vim.o.splitright = true
vim.o.history = 1000
vim.o.undolevels = 1000
vim.o.wrap = false
vim.o.backup = false
vim.o.swapfile = false

-- numbers
vim.o.number = true
vim.o.relativenumber = true

-- indent
vim.o.expandtab = true
vim.o.shiftround = true
vim.o.smartindent = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

-- visual
vim.o.signcolumn = "yes"
vim.o.relativenumber = true
vim.o.scrolloff = 4
vim.o.title = true
vim.o.visualbell = true
-- vim.o.noerrorbells = true
vim.o.showmatch = true
vim.o.cursorline = true
-- vim.o.colorcolumn = 100

-- search
vim.o.ignorecase = true
vim.o.smartcase = true

-- responsive
vim.o.updatetime = 250
vim.o.timeoutlen = 300

local autocmd = vim.api.nvim_create_autocmd
local onsave = vim.api.nvim_create_augroup("onsave", { clear = true })

-- Strip trailing whitespace
autocmd({ "BufWritePre" }, {
  group = onsave,
  callback = function()
    local l = vim.fn.line(".")
    local c = vim.fn.col(".")
    vim.cmd("%s/\\s\\+$//e")
    vim.fn.cursor(l, c)
  end,
})

-- format on save
autocmd({ "BufWritePre" }, {
  group = onsave,
  callback = function()
    vim.lsp.buf.format()
  end,
})

-- tab settings
autocmd({ "FileType" }, {
  callback = function(opts)
    local ft = vim.bo[opts.buf].filetype
    if ft == "cpp" or ft == "python" then
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
    end
  end,
})

-- Set *rc files to bash syntax if no other filetype detected
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*rc",
  callback = function()
    if vim.bo.filetype == "" then
      vim.bo.filetype = "bash"
    end
  end,
})

require("plugins")
require("mappings").setup()

vim.cmd.colorscheme("catppuccin-mocha")
