return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-mini/mini.nvim',
  },
  opts = {
    -- Keep raw Markdown visible in insert mode.
    render_modes = { 'n', 'c', 't' },
  },
}
