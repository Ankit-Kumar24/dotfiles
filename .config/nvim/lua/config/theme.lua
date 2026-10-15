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

local transparent_groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "EndOfBuffer",
  "FoldColumn",
  -- "NormalFloat",
  -- "FloatBorder",
  "Pmenu",
  -- blink (some themes style these directly instead of linking)
  "BlinkCmpMenu",
  "BlinkCmpDoc",
  "BlinkCmpSignatureHelp",
}

local glass_borders = {
  "BlinkCmpMenuBorder",
  "BlinkCmpDocBorder",
  "BlinkCmpSignatureHelpBorder",
  "BlinkCmpDocSeparator",
}
local border_color_from = "Comment"

local blink_fallback = {
  BlinkCmpMenu = "Pmenu",
  BlinkCmpDoc = "NormalFloat",
  BlinkCmpSignatureHelp = "NormalFloat",
}

vim.g.transparent = true

local function apply_transparency()
  if not vim.g.transparent then
    return
  end

  for _, group in ipairs(transparent_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    if vim.tbl_isempty(hl) and blink_fallback[group] then
      hl = vim.api.nvim_get_hl(0, { name = blink_fallback[group], link = false })
    end
    if hl.bg or hl.ctermbg then
      hl.bg, hl.ctermbg = nil, nil
      vim.api.nvim_set_hl(0, group, hl --[[@as vim.api.keyset.highlight]])
    end
  end

  local fg = vim.api.nvim_get_hl(0, { name = border_color_from, link = false }).fg
  if fg then
    for _, group in ipairs(glass_borders) do
      vim.api.nvim_set_hl(0, group, { fg = fg })
    end
  end
end

local function save_theme(name)
  pcall(vim.fn.writefile, { name }, state_file)
end

-- Scheduled so it runs after themes that set highlights in their own
-- ColorScheme handlers (e.g. catppuccin).
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
  callback = function()
    vim.schedule(apply_transparency)
  end,
})

-- Load saved theme, fall back to default if missing/broken
local ok, saved = pcall(vim.fn.readfile, state_file)
local name = (ok and saved[1]) or default
if not pcall(vim.cmd.colorscheme, name) then
  vim.cmd.colorscheme(default)
end

-- :Theme -> compact picker, live preview, Enter saves, Esc restores
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
      if item and pcall(vim.cmd.colorscheme, item.text) then
        save_theme(item.text)
      elseif original then
        pcall(vim.cmd.colorscheme, original)
      end
    end,
    on_close = function()
      if not confirmed and original then
        pcall(vim.cmd.colorscheme, original)
      end
    end,
  })
end, {})

-- :TransparentToggle -> glass on/off inside nvim (session only)
vim.api.nvim_create_user_command("TransparentToggle", function()
  vim.g.transparent = not vim.g.transparent
  vim.cmd.colorscheme(vim.g.colors_name) -- reload to restore/clear bg
end, {})
