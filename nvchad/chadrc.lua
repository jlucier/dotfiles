---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "gruvchad",
	theme_toggle = { "gruvchad", "one_light" },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = {
	general = {
		n = {
			[";"] = { ":", "enter command mode", opts = { nowait = true } },
			["<leader>cn"] = { "<Plug>(coc-rename)", "Coc rename" },
		},
	},
}
return M
