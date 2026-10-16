vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:2"
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
opt.swapfile = false

opt.laststatus = 3
opt.showmode = false

vim.diagnostic.config({
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  virtual_text = { prefix = "●" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "\u{f057} ",
      [vim.diagnostic.severity.WARN] = "\u{f071} ",
      [vim.diagnostic.severity.INFO] = "\u{f05a} ",
      [vim.diagnostic.severity.HINT] = "\u{f0335} ",
    },
  },
  float = {
    border = "rounded",
    source = "if_many",
  },
})

-- Remote-plugin providers: unused (all plugins are Lua)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
