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
vim.opt.listchars = { tab = ">> ", trail = "·", nbsp = "␣" }

vim.opt.cmdheight = 1 -- i feel like this at the moment...
vim.opt.scrolloff = 0

vim.g.netrw_liststyle = 3

vim.opt.completeopt = "menu,popup,noselect" -- should have been default, shame

vim.opt.termguicolors = true -- fixed colors in tmux along with tmux conf

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

        -- LUA
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


        -- GO
        vim.lsp.config["gopls"] = {
                -- Command and arguments to start the server.
                cmd = { "gopls" }, -- gopls should be on path

                -- Filetypes to automatically attach to.
                filetypes = { "go", "gomod", "gowork", "gotmpl" },

                root_markers = { "go.mod", "go.work"},
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

        -- JAVA
        vim.lsp.config("jdtls", {
                cmd = { "jdtls" }, -- install this on your system first...
                filetypes = {"java"},
                root_markers = {"myjavaroot","pom.xml", "build.gradle", "build.xml"}, --order matters
                settings = {
                        java = {
                                -- Custom eclipse.jdt.ls options go here
                        },
                },
        })
        -- disabling auto start for now since it is
        -- riddling workspace folders everywhere, todo find perm fix
        vim.lsp.enable("jdtls", false)


        -- WEB
        vim.lsp.config("vscode-html-language-server", {
                cmd = { "vscode-html-language-server", "--stdio" },
                filetypes = { "html" },
        })
        vim.lsp.enable("vscode-html-language-server")

        vim.lsp.config("vscode-css-language-server", {
                cmd = { "vscode-css-language-server", "--stdio" },
                filetypes = { "css" },
        })
        vim.lsp.enable("vscode-css-language-server")

        vim.lsp.config("vscode-json-language-server", {
                cmd = { "vscode-json-language-server", "--stdio" },
                filetypes = { "json" },
        })
        vim.lsp.enable("vscode-json-language-server")

        -- TODO FIX ESLINT
        vim.lsp.config("vscode-eslint-language-server", {
                cmd = { "vscode-eslint-language-server", "--stdio" },
                filetypes = {"js"},
                root_markers = { },
        })
        vim.lsp.enable("vscode-eslint-language-server")




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
                        vim.diagnostic.config({ virtual_text = true, virtual_lines = false, float = true })
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
                },

                {
    "iamcco/markdown-preview.nvim",
        enabled = false,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
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

print("meow meow init.lua")
