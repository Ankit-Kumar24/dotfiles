local state_file = vim.fn.stdpath("state") .. "/colorscheme"
local default = "gruvbox"

local themes = {
  "gruvbox",
  "tokyonight-night", "tokyonight-moon", "tokyonight-storm",
  "catppuccin-mocha", "catppuccin-macchiato", "catppuccin-frappe",
  "rose-pine", "rose-pine-moon",
  "kanagawa-wave", "kanagawa-dragon",
}

-- Floats (NormalFloat) are left alone so popups stay readable.
local transparent_groups = {
  "Normal", "NormalNC", "SignColumn", "LineNr", "EndOfBuffer", "FoldColumn",
  "NormalFloat", "FloatBorder", "Pmenu",
  -- blink (some themes style these directly instead of linking)
  "BlinkCmpMenu", "BlinkCmpMenuBorder",
  "BlinkCmpDoc", "BlinkCmpDocBorder",
  "BlinkCmpSignatureHelp", "BlinkCmpSignatureHelpBorder",
}

vim.g.transparent = true

local function apply_transparency()
  if not vim.g.transparent then return end
  for _, group in ipairs(transparent_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    if hl.bg or hl.ctermbg then
      hl.bg, hl.ctermbg = nil, nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
  callback = function(args)
    vim.schedule(apply_transparency)
    vim.fn.writefile({ args.match }, state_file)
  end,
})

-- Load saved theme, fall back to default if missing/broken
local ok, saved = pcall(vim.fn.readfile, state_file)
local name = (ok and saved[1]) or default
if not pcall(vim.cmd.colorscheme, name) then
  vim.cmd.colorscheme(default)
end

-- :Theme -> compact picker, live preview, Esc restores the original
vim.api.nvim_create_user_command("Theme", function()
  local original = vim.g.colors_name
  local confirmed = false

  Snacks.picker.pick({
    title = "Themes",
    items = vim.tbl_map(function(t) return { text = t } end, themes),
    format = "text",
    layout = { preset = "select" },
    on_change = function(_, item)
      if item then pcall(vim.cmd.colorscheme, item.text) end
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      if item then vim.cmd.colorscheme(item.text) end
    end,
    on_close = function()
      if not confirmed and original then
        vim.cmd.colorscheme(original)
      end
    end,
  })
end, {})

-- :TransparentToggle -> glass on/off inside nvim
vim.api.nvim_create_user_command("TransparentToggle", function()
  vim.g.transparent = not vim.g.transparent
  vim.cmd.colorscheme(vim.g.colors_name) -- reload to restore/clear bg
end, {})
