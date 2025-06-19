-- Bootstrap lazy.nvim
--
-- --------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" },
			{ "\nPress any key to exit..." } }, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"
-- --------------------------------------------------------------------------------------

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "number"
vim.opt.colorcolumn = "80" -- this is outrageous
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.winborder = "rounded"
vim.opt.list = true
--vim.opt.listchars = { tab = ">> ", trail = "·", nbsp = "␣" }

vim.opt.cmdheight = 1 -- i feel like this at the moment...
vim.opt.scrolloff = 0

vim.g.netrw_liststyle = 3

vim.opt.completeopt = "menu,noselect" -- should have been default, shame

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- WRAP ALL LSP RELATED FEATURES...
function MyLspConfig()
	vim.lsp.config["luals"] = {
		-- Command and arguments to start the server.
		cmd = { "lua-language-server" },

		-- Filetypes to automatically attach to.
		filetypes = { "lua" },

		-- Sets the "root directory" to the parent directory of the file in the
		-- current buffer that contains either a ".luarc.json" or a
		-- ".luarc.jsonc" file. Files that share a root directory will reuse
		-- the connection to the same LSP server.
		root_markers = { ".luarc.json", ".luarc.jsonc" },

		-- Specific settings to send to the server. The schema for this is
		-- defined by the server. For example the schema for lua-language-server
		-- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
		settings = {
			Lua = {
				runtime = {
					version = "LuaJIT",
				}
			}
		}
	}
	vim.lsp.enable("luals")

	vim.lsp.config["gopls"] = {
		-- Command and arguments to start the server.
		cmd = { "gopls" },

		-- Filetypes to automatically attach to.
		filetypes = { "go", "gomod", "gowork", "gotmpl" },

		root_markers = { "go.mod", "go.work", ".git" },
		single_file_support = true,
		settings = {
			gopls = {
				analyses = {
					unusedparams = true,
				},
				staticcheck = true,
				gofumpt = true,
			},
		}
	}
	vim.lsp.enable("gopls")

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("my.lsp", {}),
		callback = function(args)
			local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
			if client:supports_method("textDocument/implementation") then
				-- Create a keymap for vim.lsp.buf.implementation ...
			end

			-- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
			if client:supports_method("textDocument/completion") then
				-- Optional: trigger autocompletion on EVERY keypress. May be slow!
				-- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
				-- client.server_capabilities.completionProvider.triggerCharacters = chars
				vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
			end

			--try using gq instead, vimionic
			if client:supports_method("textDocument/formatting") then
				-- Create a keymap
				vim.keymap.set({ "n", "v" }, "<leader>lf", function()
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
					print("INFO: lsp formatted")
				end, { buffer = args.buf })
			end

			--[[
		-- dont want this..TODO
		-- Auto-format ("lint") on save.
		-- Usually not needed if server supports "textDocument/willSaveWaitUntil".
		if not client:supports_method("textDocument/willSaveWaitUntil")
			and client:supports_method("textDocument/formatting") then
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("my.lsp", { clear = false }),
				buffer = args.buf,
				callback = function()
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end
		--]]
			vim.diagnostic.config({ virtual_text = true})
		end,
	})
end

MyLspConfig() -- important

-- Setup lazy.nvim
require("lazy").setup({
	spec = { -- add your plugins here

		{
			"nvim-treesitter/nvim-treesitter",
			enabled = true,
			build = ":TSUpdate",
			config = function()
				local configs = require("nvim-treesitter.configs")
				configs.setup({
					ensure_installed = { "go", "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html", "bash", "java", "python" },
					sync_install = false,
					highlight = {
						enable = true
					},
					indent = {
						enable = true
					}
				})
			end
		},

		{
			"neovim/nvim-lspconfig",
			enabled = false,
			dependencies = {
				{
					"folke/lazydev.nvim",
					ft = "lua", -- only load on lua files
					opts = {
						library = {
							-- See the configuration section for more details
							-- Load luvit types when the `vim.uv` word is found
							{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
						},
					},
				}
			},
			config = function()
				-- :help lspconfig-all
				--require("lspconfig").lua_ls.setup {}
				-- require("lspconfig").gopls.setup {}
				-- require("lspconfig").clangd.setup {}
				-- require("lspconfig").eslint.setup {}
				-- require("lspconfig").jdtls.setup{}
				vim.api.nvim_create_autocmd("LspAttach", {
					callback = function(args)
						local client = vim.lsp.get_client_by_id(args.data.client_id)
						-- :lua vim.print(vim.tbl_keys(vim.lsp.handlers))
						if not client then return end -- sanity...
						if client.supports_method("textDocument/references") then
							vim.keymap.set("n", "<leader>lref", function()
								vim.lsp.buf.references()
								print("INFO: lsp referencesed")
							end, { buffer = args.buf })
						end
						if client.supports_method("textDocument/signatureHelp") then
							vim.keymap.set("i", "<leader>lh", function()
								vim.lsp.buf.signature_help()
								print("INFO: lsp signature help")
							end, { buffer = args.buf })
						end
						if client.supports_method("textDocument/rename") then
							vim.keymap.set("v", "<leader>lrn", function()
								vim.lsp.buf.rename()
								print("INFO: lsp rename")
							end, { buffer = args.buf })
						end
						if client.supports_method("textDocument/publishDiagnostics") then
							vim.keymap.set("n", "<leader>ld", function()
								-- i want to see all ? send scope buffer
								-- TODO isqflist a better way ?
								vim.diagnostic.open_float({ scope = "buffer" })
								print("INFO: lsp diag open float show")
							end, { buffer = args.buf })

							-- these are redundant since nvim dfaults to [d and ]d
							-- pretty nicely...
							--
							-- vim.keymap.set("n", "<leader>ldn", function()
							-- 	vim.diagnostic.goto_next()
							-- 	print("INFO: lsp diag next")
							-- end, { buffer = args.buf })
							--
							-- vim.keymap.set("n", "<leader>ldp", function()
							-- 	vim.diagnostic.goto_prev()
							-- 	print("INFO: lsp diag prev")
							-- end, { buffer = args.buf })
							--
						end
						if client.supports_method("textDocument/formatting") then
							-- at the time of writing,
							-- vim.lsp.buf.format only supports ONE client/lsp,
							-- this force sets it
							-- so that my gq or vim.lsp.buf.format
							--  work using the right formatter using lsp and not the inbuilt one
							-- see help vim.lsp.formatexpr()
							-- UPDATE still doesn't work
							-- UPDATE gq doesn't work
							vim.bo[vim.api.nvim_get_current_buf()].formatexpr =
							"v:lua.vim.lsp.formatexpr(#{timeout_ms:250})"
							-- v should be just the selection...
							vim.keymap.set({ "n", "v" }, "<leader>lf", function()
								vim.lsp.buf.format()
								print("INFO: lsp formatted")
							end, { buffer = args.buf })
						end
						if client.supports_method("textDocument/codeAction") then
							vim.keymap.set("n", "<leader>lca", function()
								vim.lsp.buf.code_action()
								print("INFO: lsp codeActioned")
							end, { buffer = args.buf })
						end
					end,
				})
			end
		},

		{
			"folke/tokyonight.nvim",
			enabled = false,
			lazy = false,
			priority = 1000,
			config = function() end,
			opts = {},
		},

		{
			"bluz71/vim-moonfly-colors",
			name = "moonfly",
			lazy = false,
			priority = 1000,
			config = function() end
		},

		{
			"echasnovski/mini.nvim",
			enabled = false,
			config = function()
				local statusline = require "mini.statusline"
				statusline.setup { use_icons = true }
			end
		}

	}, -- end spec

	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = {
		colorscheme = { "habamax" } -- at the moment overridden by vim colorscheme i set
	},
	-- automatically check for plugin updates
	checker = {
		enabled = true
	}

})

vim.cmd.colorscheme "moonfly"

print("init.lua is aware")
