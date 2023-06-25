-- Set up global vim things

vim.o.wrap = false
vim.o.relativenumber = true
vim.o.shiftround = true
vim.o.scrolloff = 4

vim.o.cursorline = true
vim.o.colorcolumn = 100
vim.o.nobackup = true
vim.o.noswapfile = true

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
