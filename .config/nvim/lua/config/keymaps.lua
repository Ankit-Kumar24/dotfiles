local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Source current file
map("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Source current file" })

-- Keybinds for toggling things
map("n", "<leader>tt", "<cmd>TransparentToggle<cr>", { desc = "Transparency" })
map("n", "<leader>tf", "<cmd>FormatToggle<cr>", { desc = "Format on save" })
map("n", "<leader>tc", function()
  vim.g.completion_disabled = not vim.g.completion_disabled
  vim.notify("Completion: " .. (vim.g.completion_disabled and "off" or "on"))
end, { desc = "Completion" })

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
