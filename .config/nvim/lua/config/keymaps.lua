local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Diagnostic
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message" })

-- LSP (buffer-local, only where a server is attached)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_keymaps", { clear = true }),
  callback = function(args)
    local function bmap(lhs, rhs, desc)
      map("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end

    bmap("gd", vim.lsp.buf.definition, "Go to definition")
    bmap("gD", vim.lsp.buf.declaration, "Go to declaration")
  end,
})
