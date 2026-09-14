return {
  'catgoose/nvim-colorizer.lua',
  event = 'BufReadPre',
  config = function()
    require('colorizer').setup {
      filetypes = {
        'css',
        'scss',
        'html',
        'javascript',
        'typescript',
        'javascriptreact',
        'typescriptreact', -- .tsx
      },
      user_commands = true,
      user_default_options = {
        names = false,

        RGB = true,
        RGBA = true,
        RRGGBB = true,
        RRGGBBAA = true,
        AARRGGBB = true,

        rgb_fn = true,
        hsl_fn = true,
        oklch_fn = true,

        css = true,
        css_fn = true,

        tailwind = 'both',

        mode = 'virtualtext',
        virtualtext = '█',
        virtualtext_inline = 'after',
        virtualtext_mode = 'foreground',
      },
    }
  end,
}
