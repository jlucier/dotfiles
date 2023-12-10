local lspconfig = require("lspconfig")

local capabilities = require("cmp_nvim_lsp").default_capabilities()

capabilities.textDocument.completion.completionItem = {
	documentationFormat = { "markdown", "plaintext" },
	snippetSupport = true,
	preselectSupport = true,
	insertReplaceSupport = true,
	labelDetailsSupport = true,
	deprecatedSupport = true,
	commitCharactersSupport = true,
	tagSupport = { valueSet = { 1 } },
	resolveSupport = {
		properties = {
			"documentation",
			"detail",
			"additionalTextEdits",
		},
	},
}

lspconfig.gopls.setup({
	capabilities = capabilities,
})

lspconfig.lua_ls.setup({
	capabilities = capabilities,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					[vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
				},
				maxPreload = 100000,
				preloadFileSize = 10000,
			},
		},
	},
})

-- Rename functionality

local Rename = {}

Rename.dorename = function(win)
	local new_name = vim.trim(vim.fn.getline("."))
	vim.api.nvim_win_close(win, true)
	vim.lsp.buf.rename(new_name)
end

Rename.open = function()
	local opts = {
		relative = "cursor",
		row = 0,
		col = 0,
		width = 30,
		height = 1,
		style = "minimal",
		border = "single",
	}
	local cword = vim.fn.expand("<cword>")
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, opts)
	local dorename = string.format("<cmd>lua Rename.dorename(%d)<CR>", win)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { cword })
	-- when hitting enter in either normal or insert mode, do the rename
	vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", dorename, { silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", dorename, { silent = true })
	-- when hitting escape in normal, exit
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<ESC>",
		string.format("<cmd>lua vim.api.nvim_win_close(%d, true)<CR>", win),
		{ silent = true }
	)
end

_G.Rename = Rename
