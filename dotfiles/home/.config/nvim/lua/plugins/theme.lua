return {
  {
    'rebelot/kanagawa.nvim',
    priority = 900,
    config = function()
      require('kanagawa').setup {
        compile = false,
        undercurl = true,
        commentStyle = { italic = false },
        functionStyle = {},
        keywordStyle = { italic = false },
        statementStyle = { bold = false },
        typeStyle = {},
        transparent = false,
        dimInactive = false,
        terminalColors = true,
        theme = 'wave',
        background = { dark = 'wave', light = 'lotus' },
      }

      vim.cmd.colorscheme 'kanagawa'
    end,
  },
  {
    'marko-cerovac/material.nvim',
    priority = 900,
    config = function()
      vim.g.material_style = 'deep ocean'

      require('material').setup {
        contrast = {
          terminal = false,
          sidebars = false,
          floating_windows = false,
          cursor_line = false,
          lsp_virtual_text = false,
          non_current_windows = false,
          filetypes = {},
        },
        styles = {
          comments = {},
          strings = {},
          keywords = {},
          functions = {},
          variables = {},
          operators = {},
          types = {},
        },
        custom_highlights = {
          Cursor = { fg = '#000000', bg = '#FFFFFF' },
          TermCursor = { fg = '#000000', bg = '#FFFFFF' },
          ['@property'] = { fg = '#e6e6ca' },
          ['@variable.member'] = { fg = '#e6e6ca' },
          ['@lsp.type.property'] = { fg = '#e6e6ca' },
        },
        plugins = {
          'blink',
          'gitsigns',
          'neogit',
          'telescope',
          'which-key',
          'neogit',
        },
        disable = {
          background = false,
        },
      }
    end,
  },
}
