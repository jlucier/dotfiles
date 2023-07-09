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

local servers = { "html", "cssls", "tsserver" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    capabilities = capabilities,
  })
end

-- lspconfig.pyright.setup { blabla}
-- TODO setup project local

local perch_docker = os.getenv("PERCH_IMAGE_REPO") .. ":dev"
local home = os.getenv("HOME")

lspconfig.pylsp.setup({
  cmd = {
    "docker",
    "run",
    "-i",
    "--rm",
    "-v",
    home .. "/code/:/home/perch/code/:ro",
    "-v",
    home .. "/code/:" .. home .. "/code/:ro",
    perch_docker,
    "pylsp",
    "--log-file",
    "/tmp/lsp_python.log",
  },
  settings = {
    pylsp = {
      enable = true,
      configurationSources = { "flake8" },
      plugins = {
        autopep8 = {
          enabled = false,
        },
        pycodestyle = {
          enabled = false,
        },
        pyflakes = {
          enabled = false,
        },
        flake8 = {
          enabled = true,
          config = "/home/perch/code/perch_utils/.flake8",
        },
      },
    },
  },
})

lspconfig.clangd.setup({
  cmd = {
    "docker",
    "run",
    "--rm",
    "-i",
    "-v",
    home .. "/code/:/home/perch/code/:ro",
    "-v",
    home .. "/code/:" .. home .. "/code/:ro",
    perch_docker,
    "/usr/lib/llvm-10/bin/clangd",
    "--background-index",
  },
  settings = {
    rootPatterns = { "compile_commands.json" },
    clangd = {
      filetypes = { "c", "cc", "cpp", "c++" },
      initializationOptions = {
        cacheDirectory = "/tmp/clangd",
      },
    },
  },
})

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

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { cword })
  vim.api.nvim_buf_set_keymap(
    buf,
    "i",
    "<CR>",
    string.format("<cmd>lua Rename.dorename(%d)<CR>", win),
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    buf,
    "n",
    "<ESC>",
    string.format("<cmd>lua vim.api.nvim_win_close(%d, true)<CR>", win),
    { silent = true }
  )
end

_G.Rename = Rename
