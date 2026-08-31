return {
  'mikavilpas/yazi.nvim',
  version = '*',
  event = 'VeryLazy',
  cond = vim.fn.executable 'yazi' == 1,
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    {
      '<leader>e',
      '<cmd>Yazi<cr>',
      desc = '[E]xplore files at the current buffer',
      mode = { 'n', 'v' },
    },
  },
  opts = {
    -- Make Yazi the directory browser while Telescope remains the fuzzy picker.
    open_for_directories = true,
  },
  init = function()
    -- Yazi handles directory buffers, so loading netrw would duplicate the role.
    vim.g.loaded_netrwPlugin = 1
  end,
}
