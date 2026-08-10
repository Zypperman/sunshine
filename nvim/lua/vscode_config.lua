local vscode = require("vscode")
vim.g.mapleader = " "

-- Spelling & Quick Fix
-- This tells Neovim where to save the downloaded dictionary files

-- 1. Force Neovim's internal spell engine OFF
vim.opt.spell = false

-- 2. Use a direct VSCodeNotify call for zg
-- We use 'expr = true' or a function to ensure Neovim doesn't run the built-in zg
vim.keymap.set('n', 'zg', function()
    vim.fn.VSCodeNotify('cSpell.addWordToDictionary')
end, {silent = true, noremap = true})

vim.keymap.set('n', 'z=',
               function() vim.fn.VSCodeNotify('cSpell.suggestSpelling') end,
               {silent = true, noremap = true})

-- Jump to next spelling error (]s)
vim.keymap.set('n', ']s', function()
    vim.fn.VSCodeNotify('cSpell.goToNextSpellingIssue')
end, {silent = true})

-- Jump to previous spelling error ([s)
vim.keymap.set('n', '[s', function()
    vim.fn.VSCodeNotify('cSpell.goToPreviousSpellingIssue')
end, {silent = true})

-- Navigation
vim.keymap.set("n", "<C-u>",
               function() vscode.action("editor.action.scrollLineUp") end)
vim.keymap.set("n", "<C-d>",
               function() vscode.action("editor.action.scrollLineDown") end)

-- Multi-Cursor
vim.keymap.set("n", "<C-k>",
               function() vscode.action("editor.action.insertCursorAbove") end)
vim.keymap.set("n", "<C-j>",
               function() vscode.action("editor.action.insertCursorBelow") end)

-- Leader Mappings
local explorer_focused = false
vim.keymap.set("n", "<leader>e", function()
    if explorer_focused then
        vscode.action("workbench.action.focusActiveEditorGroup")
    else
        vscode.action("workbench.action.focusFilesExplorer")
    end
    explorer_focused = not explorer_focused
end)
vim.keymap.set("n", "<leader>fr",
               function() vscode.action("workbench.action.findInFiles") end)
vim.keymap.set("x", "gc",
               function() vscode.action("editor.action.commentLine") end)
vim.keymap.set("n", "gcc",
               function() vscode.action("editor.action.commentLine") end)

-- Always show current mode in VS Code status bar
local function update_mode_status()
    local mode_map = {
        n = "NORMAL",
        i = "INSERT",
        v = "VISUAL",
        V = "V-LINE",
        ["\22"] = "V-BLOCK",
        c = "COMMAND",
        R = "REPLACE",
        s = "SELECT",
        S = "S-LINE",
        t = "TERMINAL"
    }
    local mode = vim.fn.mode()
    local label = mode_map[mode] or mode
    vscode.eval(
        '(async () => { const vsc = require("vscode"); if (!globalThis._modeItem) { globalThis._modeItem = vsc.window.createStatusBarItem(vsc.StatusBarAlignment.Left, -1000); globalThis._modeItem.show(); } globalThis._modeItem.text = "-- ' ..
            label .. ' --"; })()')
end

vim.api.nvim_create_autocmd({
    "ModeChanged", "InsertEnter", "InsertLeave", "CmdlineEnter", "CmdlineLeave"
}, {callback = update_mode_status})

-- Set NORMAL on startup
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function() vim.defer_fn(update_mode_status, 100) end
})
