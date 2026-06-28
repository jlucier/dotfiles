-- Shared configuration
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local function disable_format(client)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
end

-- Set consistent position encoding for all LSP clients
-- Use only UTF-16 to ensure all clients use the same encoding
capabilities.general = capabilities.general or {}
capabilities.general.positionEncodings = { "utf-16" }

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

-- Set default capabilities for all LSP servers using wildcard config
vim.lsp.config["*"] = {
  capabilities = capabilities,
}

-- Only configure servers that need custom settings
vim.lsp.config.lua_ls = {
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
}

-- Disable formatting for ts_ls when it attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ts_ls" then
      disable_format(client)
    end
  end,
})

-- Try to load project-specific LSP configuration (kept out of tree)
-- If it exists, it will handle Python and C/C++ setup
-- Otherwise, use standard vim.lsp.enable for all servers
local has_project_lsp, project_lsp = pcall(require, "perch_lsp")

if has_project_lsp then
  -- Project-specific LSP setup (handles pyright/clangd in Docker for perch projects)
  project_lsp.setup_lsp(capabilities)
else
  -- Standard LSP setup for Python and C/C++
  vim.lsp.enable({ "pyright", "clangd" })
end

-- Enable other simple LSPs (including ruff for all Python projects)
-- gopls omitted: requires the `go` toolchain. Add it back here when Go is set up.
vim.lsp.enable({ "ruff", "ansiblels", "jsonls", "lua_ls", "ts_ls", "zls", "svelte", "cmake" })

-- Compact view of every running client: name, root dir, the launch command
-- (shows the docker image + mounts for perch clients), and the python paths sent.
vim.api.nvim_create_user_command("LspStatus", function()
  local clients = vim.lsp.get_clients()
  if vim.tbl_isempty(clients) then
    print("No active LSP clients")
    return
  end
  for _, client in ipairs(clients) do
    print(("● %s  (root: %s)"):format(client.name, client.root_dir or "n/a"))
    print("  cmd: " .. vim.inspect(client.config.cmd))
    local py = vim.tbl_get(client.config, "settings", "python")
    if py then
      print("  pythonPath: " .. tostring(py.pythonPath))
      local extra = vim.tbl_get(py, "analysis", "extraPaths")
      if extra then
        print("  extraPaths: " .. vim.inspect(extra))
      end
    end
  end
end, {})

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
