local lspconfig = require("lspconfig")

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local perch_dev = (os.getenv("PERCH_IMAGE_REPO") or "") .. ":dev"
local home = os.getenv("HOME")
local base_perch_docker_cmd = {
  "docker",
  "run",
  "-i",
  "--rm",
  "-v",
  home .. "/code/:/home/perch/code/:ro",
  "-v",
  home .. "/code/:" .. home .. "/code/:ro",
}

local function get_perch_docker_image(root_dir)
  local docker_image = nil

  if string.find(root_dir, "perch_utils") then
    docker_image = perch_dev
  end

  return docker_image
end

local function concat(t1, t2)
  local t3 = {}
  for _, v in pairs(t1) do
    table.insert(t3, v)
  end
  for _, v in pairs(t2) do
    table.insert(t3, v)
  end
  return t3
end

local function disable_format(client)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
end

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

lspconfig.ts_ls.setup({
  capabilities = capabilities,
  -- let null-ls do formatting for javascript
  on_attach = disable_format,
})

lspconfig.zls.setup({
  capabilities = capabilities,
})

-- TODO this works for detecting what repo I want, but it does not spawn
-- a new server per root directory as it seems it should
lspconfig.pylsp.setup({
  capabilities = capabilities,
  on_new_config = function(new_config, new_root_dir)
    local docker_image = get_perch_docker_image(new_root_dir)
    if docker_image ~= nil then
      new_config.cmd = concat(base_perch_docker_cmd, {
        docker_image,
        "pylsp",
        "--log-file",
        "/tmp/lsp_python.log",
      })
    else
      new_config.enabled = false
    end
  end,
  settings = {
    pylsp = {
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
          enabled = false,
        },
      },
    },
  },
})

lspconfig.ruff.setup({
  capabilities = capabilities,
})

lspconfig.pyright.setup({
  capabilities = capabilities,
  on_new_config = function(new_config, new_root_dir)
    local docker_image = get_perch_docker_image(new_root_dir)
    if docker_image ~= nil then
      new_config.enabled = false
      -- new_config.cmd = concat(base_perch_docker_cmd, {
      --   "perch:pyright",
      --   "pyright-langserver",
      --   "--stdio",
      -- })
    end
  end,
})

lspconfig.clangd.setup({
  capabilities = capabilities,
  -- -- don't autoformat my cpp
  -- on_attach = disable_format,
  on_new_config = function(new_config, new_root_dir)
    local docker_image = get_perch_docker_image(new_root_dir)
    if docker_image ~= nil then
      new_config.cmd = concat(base_perch_docker_cmd, {
        perch_dev,
        "/usr/lib/llvm-10/bin/clangd",
        "--background-index",
        "--clang-tidy",
      })
    end
  end,
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
