-- Lives at $XDG_CONFIG_HOME/nvim (symlinked there by install.sh), so Neovim
-- already puts this dir's lua/ on package.path and rtp without extra setup.
require("settings")

if not vim.g.vscode then return end
require("vscode_config")
require('fold_config').setup()


vim.o.ignorecase = true -- Ignore case in search patterns
vim.o.smartcase = true -- Override 'ignorecase' if search pattern contains upper case characters

local is_vscode = function() return vim.g.vscode ~= nil end

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({{import = "vscode_plugins"}})

require("mini.surround").setup()

print("Larry's nv4vs config (⌐■_■)-🖥️")
