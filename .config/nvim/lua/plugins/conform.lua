local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true })
			end,
			mode = { "n", "v" },
			desc = "Format buffer/selection",
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

		vim.api.nvim_create_user_command("FormatToggle", function()
			vim.g.disable_autoformat = not vim.g.disable_autoformat
			vim.notify("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
		end, {})
	end,
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			javascript = prettier,
			javascriptreact = prettier,
			typescript = prettier,
			typescriptreact = prettier,
			json = prettier,
			jsonc = prettier,
			css = prettier,
			html = prettier,
			yaml = prettier,
			markdown = prettier,
		},
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = function()
			if vim.g.disable_autoformat then
				return
			end
			return { timeout_ms = 500 }
		end,
	},
}
