return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "javascript", "typescript", "tsx", "json", "html", "css",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact", "json", "html", "css" },
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
}
