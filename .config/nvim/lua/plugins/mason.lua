return {
  "mason-org/mason.nvim",
  dependencies = { "WhoIsSethDaniel/mason-tool-installer.nvim" },
  opts = {
    ui = { border = "rounded" },
  },
  config = function(_, opts)
    require("mason").setup(opts)

    require("mason-tool-installer").setup({
      ensure_installed = {
        -- LSP servers
        "lua-language-server",
        "typescript-language-server",
        "eslint-lsp",
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
        "css-lsp",
        "html-lsp",
        -- Formatters / linters
        "stylua",
        "shfmt",
        "shellcheck",
        "prettierd",
        "prettier",
      },
    })
  end,
}
