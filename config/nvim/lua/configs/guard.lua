local ft = require("guard.filetype")

if not ft then
  return
end

-- guard owns format-on-save. For filetypes without an explicit formatter below
-- (python, json, svelte, zig, ...) fall back to the attached LSP so we don't run
-- a second format pass from a separate BufWritePre autocmd.
vim.g.guard_config = {
  fmt_on_save = true,
  lsp_as_default_formatter = true,
}

ft("lua"):fmt("stylua")

ft("typescriptreact"):fmt("prettier"):lint("eslint")
ft("typescript"):fmt("prettier"):lint("eslint")
ft("javascript"):fmt("prettier"):lint("eslint")
