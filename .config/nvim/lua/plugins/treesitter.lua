return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      -- web
      "javascript",
      "typescript",
      "tsx",
      "json",
      "html",
      "css",
      -- config / system (niri is kdl)
      "lua",
      "bash",
      "kdl",
      "toml",
      "yaml",
      -- docs / neovim itself
      "markdown",
      "markdown_inline",
      "vim",
      "vimdoc",
      "query",
    })

    -- Start treesitter for any filetype that has a parser; silently skip the rest
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
