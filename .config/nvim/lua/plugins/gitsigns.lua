return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
      end

      -- Hunk navigation
      map("n", "]h", function()
        gs.nav_hunk("next")
      end, "Next hunk")
      map("n", "[h", function()
        gs.nav_hunk("prev")
      end, "Prev hunk")

      -- Hunk actions
      map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("n", "<leader>gB", gs.blame, "Blame file")
      map("n", "<leader>gd", gs.diffthis, "Diff this")

      -- Text object: vih / dih / yih = the hunk under the cursor
      map({ "o", "x" }, "ih", gs.select_hunk, "Inner hunk")
    end,
  },
}
