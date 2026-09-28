return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" }, -- only loads when you open a .md file
  opts = {
    completions = { lsp = { enabled = true } },
  },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle markdown render" },
  },
}
