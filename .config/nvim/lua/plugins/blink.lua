return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = { "rafamadriz/friendly-snippets" },
  opts_extend = { "sources.default" },
  opts = {
    keymap = { preset = "default" },

    appearance = {
      nerd_font_variant = "mono",
    },

    completion = {
      menu = {
        border = "rounded",
        draw = { 
            treesitter = { "lsp" } },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = { border = "rounded" },
      },
      ghost_text = { enabled = true },
    },

    signature = {
      enabled = true,
      window = { border = "rounded" },
    },

    cmdline = {
      completion = { menu = { auto_show = true } },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        snippets = {
          should_show_items = function(ctx)
            return ctx.trigger.initial_kind ~= "trigger_character"
          end,
        },
      },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
