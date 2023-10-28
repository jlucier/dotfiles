local present, null_ls = pcall(require, "null-ls")

if not present then
  return
end

local b = null_ls.builtins

local sources = {
  -- python
  -- b.formatting.black,
  -- b.diagnostics.flake8,
  b.diagnostics.mypy,

  -- js / ts
  b.formatting.prettier,
  b.diagnostics.eslint,

  -- other
  b.formatting.stylua,
}

null_ls.setup({
  debug = true,
  sources = sources,
})
