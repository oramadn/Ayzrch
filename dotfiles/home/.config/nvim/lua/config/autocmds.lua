-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Switching themes
vim.api.nvim_create_user_command('Theme', function(opts)
  vim.cmd('colorscheme ' .. opts.args)
end, {
  nargs = 1,
  complete = 'color',
})

-- Run RSpec
vim.api.nvim_create_user_command('RSpec', function(opts)
  local target = opts.args ~= '' and opts.args or 'spec'
  vim.cmd '15split'
  vim.cmd('terminal bundle exec rspec ' .. target)
  vim.cmd 'startinsert'
end, {
  nargs = '?',
  complete = 'file',
})

-- Run current file spec
vim.api.nvim_create_user_command('RSpecFile', function()
  vim.cmd '15split'
  vim.cmd('terminal bundle exec rspec ' .. vim.fn.expand '%')
  vim.cmd 'startinsert'
end, {})

-- added env files to sh lsp
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '.env', '.env.*', '.envrc', 'env.example' },
  callback = function()
    vim.bo.filetype = 'sh'
  end,
})
