local state_path = vim.fn.stdpath 'data' .. '/autoformat_status'

local function save_format_state(disabled)
  local f = io.open(state_path, 'w')
  if f then
    f:write(tostring(disabled))
    f:close()
  end
end

local function load_format_state()
  local f = io.open(state_path, 'r')
  if f then
    local content = f:read '*all'
    f:close()
    return content == 'true'
  end
  return false
end

vim.g.disable_autoformat = load_format_state()

return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
      {
        '<leader>tf',
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          save_format_state(vim.g.disable_autoformat)

          if vim.g.disable_autoformat then
            print 'Autoformat: DISABLED (Persistent)'
          else
            print 'Autoformat: ENABLED (Persistent)'
          end
        end,
        mode = 'n',
        desc = '[T]oggle Autoformat (Global/Persistent)',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

        local disable_filetypes = { c = true, cpp = true, ruby = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        end

        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },
}
