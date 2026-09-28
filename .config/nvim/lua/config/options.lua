vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4

opt.clipboard = "unnamedplus"
opt.updatetime = 300
opt.undofile = true
opt.splitright = true
opt.splitbelow = true

opt.ignorecase = true
opt.smartcase = true

vim.diagnostic.config({
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  virtual_text = { prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = "󰌵 ",
    },
  },
  float = {
    border = "rounded",
    source = "always",
  },
})

