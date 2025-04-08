local ft = require("guard.filetype")

if not ft then
  return
end

ft("lua"):fmt("stylua")

ft("typescriptreact"):fmt("prettier"):lint("eslint")
ft("typescript"):fmt("prettier"):lint("eslint")
ft("javascript"):fmt("prettier"):lint("eslint")
