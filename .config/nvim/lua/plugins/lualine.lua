local function diff_source()
  local g = vim.b.gitsigns_status_dict
  if g then
    return { added = g.added, modified = g.changed, removed = g.removed }
  end
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      component_separators = "",
      section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" },
      disabled_filetypes = { statusline = { "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = {
        "branch",
        { "diff", source = diff_source },
      },
      lualine_c = {
        { "filename", path = 1 },
        "diagnostics",
      },
      lualine_x = { "filetype" },
      lualine_y = {}, -- empty on purpose: leaving it out brings back lualine's default "progress"
      lualine_z = { "location" },
    },
  },
}
