local state_file = vim.fn.stdpath("state") .. "/colorscheme"
local default = "gruvbox"

local themes = {
  "gruvbox",
  "tokyonight-night",
  "tokyonight-moon",
  "tokyonight-storm",
  "catppuccin-mocha",
  "catppuccin-macchiato",
  "catppuccin-frappe",
  "rose-pine",
  "rose-pine-moon",
  "kanagawa-wave",
  "kanagawa-dragon",
  "vague",
}

-- Background removed from these (floats included).
local transparent_groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "EndOfBuffer",
  "FoldColumn",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  -- some themes style blink directly instead of linking
  "BlinkCmpMenu",
  "BlinkCmpDoc",
  "BlinkCmpSignatureHelp",
}

-- Completion borders: dim color, no background.
local glass_borders = {
  "BlinkCmpMenuBorder",
  "BlinkCmpDocBorder",
  "BlinkCmpSignatureHelpBorder",
  "BlinkCmpDocSeparator",
}

vim.g.transparent = true

local function get_hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false }) --[[@as vim.api.keyset.highlight]]
end

local function apply_transparency()
  -- Keep a solid copy of the float colors for LSP hover / diagnostics (below)
  vim.api.nvim_set_hl(0, "SolidFloat", get_hl("NormalFloat"))
  vim.api.nvim_set_hl(0, "SolidFloatBorder", get_hl("FloatBorder"))

  if not vim.g.transparent then
    return
  end

  for _, group in ipairs(transparent_groups) do
    local hl = get_hl(group)
    if hl.bg or hl.ctermbg then
      hl.bg, hl.ctermbg = nil, nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end

  local dim = get_hl("Comment").fg
  for _, group in ipairs(glass_borders) do
    vim.api.nvim_set_hl(0, group, { fg = dim })
  end
end

-- Scheduled so it runs after themes' own ColorScheme handlers (e.g. catppuccin)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
  callback = function()
    vim.schedule(apply_transparency)
  end,
})

-- Load saved theme, fall back to default if missing/broken
local ok, saved = pcall(vim.fn.readfile, state_file)
if not pcall(vim.cmd.colorscheme, ok and saved[1] or default) then
  vim.cmd.colorscheme(default)
end

-- LSP hover (K) and diagnostic float (<C-w>d) stay solid. Delete to make them glass.
local open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.util.open_floating_preview = function(...)
  local buf, win = open_floating_preview(...)
  vim.wo[win].winhighlight = "Normal:SolidFloat,FloatBorder:SolidFloatBorder"
  return buf, win
end

-- :Theme -> live preview, Enter saves, Esc restores
vim.api.nvim_create_user_command("Theme", function()
  local original = vim.g.colors_name
  local confirmed = false

  require("snacks").picker.pick({
    title = "Themes",
    items = vim.tbl_map(function(t)
      return { text = t }
    end, themes),
    format = "text",
    layout = { preset = "select" },
    on_change = function(_, item)
      if item then
        pcall(vim.cmd.colorscheme, item.text)
      end
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      if item then
        pcall(vim.cmd.colorscheme, item.text)
      end
      pcall(vim.fn.writefile, { vim.g.colors_name }, state_file)
    end,
    on_close = function()
      if not confirmed then
        pcall(vim.cmd.colorscheme, original)
      end
    end,
  })
end, {})

-- :TransparentToggle -> glass on/off for this session
vim.api.nvim_create_user_command("TransparentToggle", function()
  vim.g.transparent = not vim.g.transparent
  vim.cmd.colorscheme(vim.g.colors_name)
end, {})
