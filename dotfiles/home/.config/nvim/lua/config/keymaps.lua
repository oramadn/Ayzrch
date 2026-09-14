-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
-- Shows the error message in a floating window
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror' })

-- Exit terminal mode in the builtin terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<leader>T', ':15split | terminal<CR>i', { noremap = true, silent = true })

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Yank file path
vim.keymap.set('n', '<leader>yp', function()
  local path = vim.fn.expand('%:p:.')
  vim.fn.setreg('+', path)
  print('Yanked: ' .. path)
end, { desc = '[Y]ank file:[P]ath' })

-- Yank file path + line number
vim.keymap.set('n', '<leader>yl', function()
  local path = vim.fn.expand '%:p:.'
  local line = vim.fn.line '.'
  local text = path .. ':' .. line
  vim.fn.setreg('+', text)
  print('Yanked: ' .. text)
end, { desc = '[Y]ank file:[L]ine' })

vim.keymap.set('n', '<leader>vc', function()
  vim.cmd 'vsplit'
  vim.cmd 'terminal nvim ~/.config/nvim'
end, { desc = 'Edit Neovim config' })
