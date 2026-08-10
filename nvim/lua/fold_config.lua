local M = {}

function M.setup()
  -- Only execute keymaps if running inside the vscode-neovim extension
  if not vim.g.vscode then
    return
  end

  local vscode = require('vscode')

  -- Helper function to trigger VSCode actions cleanly
  local function vscode_action(cmd)
    return function()
      vscode.action(cmd)
    end
  end

  local opts = { noremap = true, silent = true }

  -- Standard Vim folding commands mapped to VSCode actions
  vim.keymap.set('n', 'zc', vscode_action('editor.fold'), vim.tbl_extend('force', opts, { desc = 'Fold code' }))
  vim.keymap.set('n', 'zo', vscode_action('editor.unfold'), vim.tbl_extend('force', opts, { desc = 'Unfold code' }))
  vim.keymap.set('n', 'za', vscode_action('editor.toggleFold'), vim.tbl_extend('force', opts, { desc = 'Toggle fold' }))
  vim.keymap.set('n', 'zM', vscode_action('editor.foldAll'), vim.tbl_extend('force', opts, { desc = 'Fold all' }))
  vim.keymap.set('n', 'zR', vscode_action('editor.unfoldAll'), vim.tbl_extend('force', opts, { desc = 'Unfold all' }))

  -- Recursive fold/unfold
  vim.keymap.set('n', 'zC', vscode_action('editor.foldRecursively'), vim.tbl_extend('force', opts, { desc = 'Fold recursively' }))
  vim.keymap.set('n', 'zO', vscode_action('editor.unfoldRecursively'), vim.tbl_extend('force', opts, { desc = 'Unfold recursively' }))

  -- Fold level mappings (z1 to z5)
  for i = 1, 5 do
    vim.keymap.set('n', 'z' .. i, vscode_action('editor.foldLevel' .. i), vim.tbl_extend('force', opts, { desc = 'Fold Level ' .. i }))
  end

  -- Fold current Visual Mode selection (useful when combined with Tree-sitter textobjects)
  vim.keymap.set('v', 'zc', vscode_action('editor.createFoldingRangeFromSelection'), vim.tbl_extend('force', opts, { desc = 'Fold selected range' }))
end

return M
