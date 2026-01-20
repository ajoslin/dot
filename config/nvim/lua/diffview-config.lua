-- Configure diffview.nvim
local status_ok, diffview = pcall(require, 'diffview')
if not status_ok then
  return
end

diffview.setup({
  diff_binaries = false,    -- Show diffs for binaries
  enhanced_diff_hl = true,  -- Use enhanced diff highlighting
  use_icons = true,         -- Requires nvim-web-devicons
  icons = {                 -- Only applies when use_icons is true.
    folder_closed = "",
    folder_open = "",
  },
  signs = {
    fold_closed = "",
    fold_open = "",
  },
  view = {
    default = {
      layout = "diff2_horizontal",
    },
    merge_tool = {
      layout = "diff3_horizontal",
    },
    file_history = {
      layout = "diff2_horizontal",
    },
  },
  file_panel = {
    listing_style = "tree",             -- One of 'list' or 'tree'
    tree_options = {                    -- Only applies when listing_style is 'tree'
      flatten_dirs = true,              -- Flatten dirs that only contain one single dir
      folder_statuses = "only_folded",  -- One of 'never', 'only_folded' or 'always'.
    },
  },
  file_history_panel = {
    log_options = {
      git = {
        single_file = {
          diff_merges = "combined",
        },
        multi_file = {
          diff_merges = "first-parent",
        },
      },
    },
  },
  keymaps = {
    view = {
      ["<tab>"]      = false,
      ["<s-tab>"]    = false,
      ["gf"]         = false,
      ["<C-w><C-f>"] = false,
      ["<C-w>gf"]    = false,
    },
    file_panel = {
      ["j"]             = false,
      ["k"]             = false,
      ["<cr>"]          = false,
      ["o"]             = false,
      ["<2-LeftMouse>"] = false,
      ["<tab>"]         = false,
      ["<s-tab>"]       = false,
      ["gf"]            = false,
      ["<C-w><C-f>"]    = false,
      ["<C-w>gf"]       = false,
    },
    file_history_panel = {
      ["j"]             = false,
      ["k"]             = false,
      ["<cr>"]          = false,
      ["o"]             = false,
      ["<2-LeftMouse>"] = false,
      ["<tab>"]         = false,
      ["<s-tab>"]       = false,
      ["gf"]            = false,
      ["<C-w><C-f>"]    = false,
      ["<C-w>gf"]       = false,
    },
  },
})

-- Key mappings
-- Toggle diffview open/close
vim.keymap.set('n', '<leader>gd', function()
  local lib = require('diffview.lib')
  local view = lib.get_current_view()
  if view then
    vim.cmd('DiffviewClose')
  else
    vim.cmd('DiffviewOpen')
  end
end, { noremap = true, silent = true, desc = 'Toggle Diffview' })

vim.keymap.set('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { noremap = true, silent = true, desc = 'File history (current)' })
vim.keymap.set('n', '<leader>gH', ':DiffviewFileHistory<CR>', { noremap = true, silent = true, desc = 'File history (all)' })

-- Custom highlight colors (more muted for gruvbox)
vim.api.nvim_set_hl(0, 'DiffAdd', { bg = '#3a4f3a', fg = 'NONE' })
vim.api.nvim_set_hl(0, 'DiffChange', { bg = '#3f4b4f', fg = 'NONE' })
vim.api.nvim_set_hl(0, 'DiffDelete', { bg = '#4f3a3a', fg = '#6c5555' })
vim.api.nvim_set_hl(0, 'DiffText', { bg = '#4f6b4f', fg = 'NONE' })

-- Diffview specific highlights
vim.api.nvim_set_hl(0, 'DiffviewDiffAdd', { bg = '#3a4f3a', fg = 'NONE' })
vim.api.nvim_set_hl(0, 'DiffviewDiffChange', { bg = '#3f4b4f', fg = 'NONE' })
vim.api.nvim_set_hl(0, 'DiffviewDiffDelete', { bg = '#4f3a3a', fg = '#6c5555' })
vim.api.nvim_set_hl(0, 'DiffviewDiffText', { bg = '#4f6b4f', fg = 'NONE' })
