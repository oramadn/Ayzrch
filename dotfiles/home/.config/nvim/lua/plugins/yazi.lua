return {
  {
    'mikavilpas/yazi.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = {
      { 'nvim-lua/plenary.nvim', lazy = true },
    },
    keys = {
      { '<leader>-', '<cmd>Yazi<cr>', desc = 'Open yazi at the current file' },
      { '<leader>cw', '<cmd>Yazi cwd<cr>', desc = 'Open yazi in cwd' },
      { '<c-up>', '<cmd>Yazi toggle<cr>', desc = 'Resume yazi session' },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = '<f1>',
      },
    },
  },
}
