local actions = require "telescope.actions"
require("telescope").setup {
  defaults = {
    -- Your defaults config goes in here
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = false,
        ["<C-p>"] = false,
        ["<esc>"] = actions.close,
      },
    }
  },
  -- pickers = {
  --   lsp = {
  --     theme = 'get_cursor'
  --   }
  -- },
  extensions = {
    -- Your extension config goes in here
  }
}
