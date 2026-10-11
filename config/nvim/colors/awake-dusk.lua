vim.cmd("highlight clear")
vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "awake-dusk"

local c = {
  bg = "#151a21",
  panel = "#1e252d",
  raised = "#28313a",
  selection = "#39434c",
  border = "#47515a",
  fg = "#dbd9ce",
  muted = "#9da3ab",
  dim = "#66717f",
  sand = "#e8be79",
  sunlit = "#f4cb90",
  terracotta = "#ee9066",
  rose = "#f27983",
  mauve = "#d975a1",
  haze = "#95a5d9",
  cyan = "#7eccd7",
  sage = "#b1cf93",
}

local ansi = {
  c.bg,
  c.rose,
  c.sage,
  c.sand,
  c.haze,
  c.mauve,
  c.cyan,
  c.fg,
  c.dim,
  "#fa9188",
  "#bdde9c",
  c.sunlit,
  "#acbee4",
  "#e68eb3",
  "#9adddf",
  "#f0eee2",
}

for index, color in ipairs(ansi) do
  vim.g["terminal_color_" .. index - 1] = color
end

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
  vim.api.nvim_set_hl(0, group, { link = target })
end

hi("Normal", { fg = c.fg })
hi("NormalNC", { fg = c.fg })
hi("NormalFloat", { fg = c.fg, bg = c.panel })
hi("FloatBorder", { fg = c.border, bg = c.panel })
hi("FloatTitle", { fg = c.sand, bg = c.panel, bold = true })
hi("EndOfBuffer", { fg = c.bg })
hi("NonText", { fg = c.dim })
hi("Whitespace", { fg = c.dim })
hi("SpecialKey", { fg = c.dim })
hi("Directory", { fg = c.cyan })
hi("Title", { fg = c.sand, bold = true })
hi("Question", { fg = c.sage })
hi("MoreMsg", { fg = c.cyan })
hi("ModeMsg", { fg = c.fg })
hi("WarningMsg", { fg = c.sand })
hi("ErrorMsg", { fg = c.rose, bold = true })

hi("Cursor", { fg = c.bg, bg = c.sand })
hi("CursorIM", { fg = c.bg, bg = c.cyan })
hi("CursorLine", { bg = c.panel })
hi("CursorColumn", { bg = c.panel })
hi("CursorLineNr", { fg = c.sand, bg = c.panel, bold = true })
hi("LineNr", { fg = c.dim })
hi("SignColumn", {})
hi("FoldColumn", { fg = c.muted })
hi("ColorColumn", { bg = c.panel })
hi("WinSeparator", { fg = c.border })
hi("VertSplit", { fg = c.border })
hi("StatusLine", { fg = c.fg, bg = c.raised })
hi("StatusLineNC", { fg = c.muted, bg = c.panel })
hi("WinBar", { fg = c.fg, bg = c.panel })
hi("WinBarNC", { fg = c.muted, bg = c.panel })
hi("TabLine", { fg = c.muted, bg = c.panel })
hi("TabLineSel", { fg = c.fg, bg = c.raised, bold = true })
hi("TabLineFill", {})
hi("Visual", { bg = c.selection })
hi("VisualNOS", { bg = c.selection })
hi("Search", { fg = c.bg, bg = c.sand })
hi("IncSearch", { fg = c.bg, bg = c.terracotta, bold = true })
hi("CurSearch", { fg = c.bg, bg = c.rose, bold = true })
hi("Substitute", { fg = c.bg, bg = c.rose })
hi("MatchParen", { fg = c.cyan, bg = c.raised, bold = true })
hi("Pmenu", { fg = c.fg, bg = c.panel })
hi("PmenuSel", { fg = c.fg, bg = c.selection, bold = true })
hi("PmenuSbar", { bg = c.raised })
hi("PmenuThumb", { bg = c.muted })
hi("WildMenu", { fg = c.bg, bg = c.sand })
hi("Folded", { fg = c.muted, bg = c.panel })
hi("Conceal", { fg = c.haze })
hi("QuickFixLine", { bg = c.raised, bold = true })
hi("SpellBad", { undercurl = true, sp = c.rose })
hi("SpellCap", { undercurl = true, sp = c.cyan })
hi("SpellLocal", { undercurl = true, sp = c.mauve })
hi("SpellRare", { undercurl = true, sp = c.sage })

hi("Comment", { fg = c.muted, italic = true })
hi("Constant", { fg = c.mauve })
hi("String", { fg = c.sage })
hi("Character", { fg = c.sage })
hi("Number", { fg = c.haze })
hi("Boolean", { fg = c.mauve })
hi("Float", { fg = c.haze })
hi("Identifier", { fg = c.fg })
hi("Function", { fg = c.haze })
hi("Statement", { fg = c.rose })
hi("Conditional", { fg = c.rose, italic = true })
hi("Repeat", { fg = c.rose, italic = true })
hi("Label", { fg = c.sand })
hi("Operator", { fg = c.haze })
hi("Keyword", { fg = c.rose, italic = true })
hi("Exception", { fg = c.terracotta, italic = true })
hi("PreProc", { fg = c.mauve })
hi("Include", { fg = c.rose })
hi("Define", { fg = c.rose })
hi("Macro", { fg = c.terracotta })
hi("Type", { fg = c.sand })
hi("StorageClass", { fg = c.sand })
hi("Structure", { fg = c.sand })
hi("Typedef", { fg = c.sand })
hi("Special", { fg = c.cyan })
hi("SpecialChar", { fg = c.terracotta })
hi("Delimiter", { fg = c.muted })
hi("Underlined", { fg = c.cyan, underline = true })
hi("Error", { fg = c.rose, bold = true })
hi("Todo", { fg = c.sand, bg = c.panel, bold = true })

link("@comment", "Comment")
hi("@comment.documentation", { fg = c.sage, italic = true })
hi("@comment.error", { fg = c.bg, bg = c.rose, bold = true })
hi("@comment.warning", { fg = c.bg, bg = c.sand, bold = true })
hi("@comment.todo", { fg = c.bg, bg = c.cyan, bold = true })
hi("@comment.note", { fg = c.bg, bg = c.haze, bold = true })

link("@variable", "Identifier")
hi("@variable.builtin", { fg = c.cyan, italic = true })
hi("@variable.parameter", { fg = c.mauve })
hi("@variable.parameter.builtin", { fg = c.terracotta, italic = true })
hi("@variable.member", { fg = c.sunlit })
hi("@module", { fg = c.cyan })
hi("@module.builtin", { fg = c.cyan, italic = true })
link("@constant", "Constant")
hi("@constant.builtin", { fg = c.terracotta })
hi("@constant.macro", { fg = c.mauve, bold = true })

link("@string", "String")
hi("@string.documentation", { fg = c.sage, italic = true })
hi("@string.regexp", { fg = c.mauve })
hi("@string.escape", { fg = c.terracotta, bold = true })
hi("@string.special", { fg = c.cyan })
hi("@string.special.symbol", { fg = c.cyan })
hi("@string.special.url", { fg = c.cyan, underline = true })
link("@character", "Character")
hi("@character.special", { fg = c.terracotta })
link("@boolean", "Boolean")
link("@number", "Number")
hi("@number.float", { fg = c.haze })

link("@type", "Type")
hi("@type.builtin", { fg = c.cyan })
hi("@type.definition", { fg = c.sand, bold = true })
hi("@attribute", { fg = c.terracotta })
hi("@attribute.builtin", { fg = c.mauve })
hi("@property", { fg = c.sunlit })
hi("@field", { fg = c.sunlit })

link("@function", "Function")
link("@function.call", "Function")
hi("@function.builtin", { fg = c.terracotta })
hi("@function.macro", { fg = c.mauve })
link("@function.method", "Function")
link("@function.method.call", "Function")
link("@method", "Function")
link("@method.call", "Function")
hi("@constructor", { fg = c.sand })
link("@operator", "Operator")

link("@keyword", "Keyword")
hi("@keyword.coroutine", { fg = c.mauve, italic = true })
hi("@keyword.function", { fg = c.rose, italic = true })
hi("@keyword.operator", { fg = c.cyan, italic = true })
hi("@keyword.import", { fg = c.haze, italic = true })
hi("@keyword.type", { fg = c.sand, italic = true })
hi("@keyword.modifier", { fg = c.sand, italic = true })
hi("@keyword.repeat", { fg = c.rose, italic = true })
hi("@keyword.return", { fg = c.terracotta, italic = true })
hi("@keyword.exception", { fg = c.terracotta, italic = true })
hi("@keyword.conditional", { fg = c.rose, italic = true })
hi("@keyword.debug", { fg = c.terracotta, italic = true })
hi("@keyword.directive", { fg = c.mauve, italic = true })
hi("@keyword.directive.define", { fg = c.rose, italic = true })

link("@punctuation.delimiter", "Delimiter")
link("@punctuation.bracket", "Delimiter")
hi("@punctuation.special", { fg = c.mauve })
link("@tag", "Statement")
hi("@tag.builtin", { fg = c.rose })
link("@tag.attribute", "Type")
link("@tag.delimiter", "Delimiter")

hi("@markup.strong", { bold = true })
hi("@markup.italic", { italic = true })
hi("@markup.strikethrough", { strikethrough = true })
hi("@markup.underline", { underline = true })
link("@markup.heading", "Title")
hi("@markup.quote", { fg = c.mauve, italic = true })
hi("@markup.math", { fg = c.cyan })
hi("@markup.environment", { fg = c.sand, italic = true })
link("@markup.link", "Underlined")
link("@markup.link.url", "Underlined")
hi("@markup.link.label", { fg = c.haze })
link("@markup.raw", "String")
link("@markup.raw.block", "String")
link("@markup.list", "Label")
hi("@diff.plus", { fg = c.sage })
hi("@diff.minus", { fg = c.rose })
hi("@diff.delta", { fg = c.sand })

-- ZLS classifies members and calls as variables; keep their Tree-sitter colors.
hi("@lsp.type.variable", {})

hi("DiffAdd", { fg = c.sage, bg = c.panel })
hi("DiffChange", { fg = c.sand, bg = c.panel })
hi("DiffDelete", { fg = c.rose, bg = c.panel })
hi("DiffText", { fg = c.fg, bg = c.selection })
hi("Added", { fg = c.sage })
hi("Changed", { fg = c.sand })
hi("Removed", { fg = c.rose })

hi("DiagnosticError", { fg = c.rose })
hi("DiagnosticWarn", { fg = c.sand })
hi("DiagnosticInfo", { fg = c.cyan })
hi("DiagnosticHint", { fg = c.sage })
hi("DiagnosticOk", { fg = c.sage })
hi("DiagnosticVirtualTextError", { fg = c.rose, bg = c.panel })
hi("DiagnosticVirtualTextWarn", { fg = c.sand, bg = c.panel })
hi("DiagnosticVirtualTextInfo", { fg = c.cyan, bg = c.panel })
hi("DiagnosticVirtualTextHint", { fg = c.sage, bg = c.panel })
hi("DiagnosticUnderlineError", { undercurl = true, sp = c.rose })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = c.sand })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = c.cyan })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = c.sage })
hi("GitSignsAdd", { fg = c.sage })
hi("GitSignsChange", { fg = c.sand })
hi("GitSignsDelete", { fg = c.rose })

hi("TelescopeNormal", { fg = c.fg, bg = c.panel })
hi("TelescopeBorder", { fg = c.border, bg = c.panel })
hi("TelescopePromptNormal", { fg = c.fg, bg = c.raised })
hi("TelescopePromptBorder", { fg = c.border, bg = c.raised })
hi("TelescopePromptTitle", { fg = c.bg, bg = c.sand, bold = true })
hi("TelescopePreviewTitle", { fg = c.bg, bg = c.sage, bold = true })
hi("TelescopeResultsTitle", { fg = c.bg, bg = c.haze, bold = true })
hi("TelescopeSelection", { bg = c.selection, bold = true })
hi("TelescopeMatching", { fg = c.sand, bold = true })
