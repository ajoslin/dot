vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
local api = require("nvim-tree.api")

require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filesystem_watchers = { enable = false },
  filters = {
    -- dotfiles = true,
    git_ignored = false,
  },
  on_attach = function(bufnr)
    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end
    -- api.config.mappings.default_on_attach(bufnr)
    vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "L", api.node.open.vertical, opts("Open VSplit"))
    vim.keymap.set("n", "h", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts("CD"))
    vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts("Open: In Place"))
    vim.keymap.set("n", "<C-k>", api.node.show_info_popup, opts("Info"))
    vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts("Rename: Omit Filename"))
    vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
    vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Open Preview"))
    vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts("Next Sibling"))
    vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts("Previous Sibling"))
    vim.keymap.set("n", ".", api.node.run.cmd, opts("Run Command"))
    vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("Up"))
    vim.keymap.set("n", "a", api.fs.create, opts("Create"))
    vim.keymap.set("n", "bd", api.marks.bulk.delete, opts("Delete Bookmarked"))
    vim.keymap.set("n", "bt", api.marks.bulk.trash, opts("Trash Bookmarked"))
    vim.keymap.set("n", "bmv", api.marks.bulk.move, opts("Move Bookmarked"))
    vim.keymap.set("n", "B", api.tree.toggle_no_buffer_filter, opts("Toggle Filter: No Buffer"))
    vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
    vim.keymap.set("n", "C", api.tree.toggle_git_clean_filter, opts("Toggle Filter: Git Clean"))
    vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts("Prev Git"))
    vim.keymap.set("n", "]c", api.node.navigate.git.next, opts("Next Git"))
    vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
    vim.keymap.set("n", "E", api.tree.expand_all, opts("Expand All"))
    vim.keymap.set("n", "e", api.fs.rename_basename, opts("Rename: Basename"))
    vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts("Next Diagnostic"))
    vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts("Prev Diagnostic"))
    vim.keymap.set("n", "F", api.live_filter.clear, opts("Clean Filter"))
    vim.keymap.set("n", "f", api.live_filter.start, opts("Filter"))
    vim.keymap.set("n", "g?", api.tree.toggle_help, opts("Help"))
    vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
    vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, opts("Toggle Filter: Dotfiles"))
    vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, opts("Toggle Filter: Git Ignore"))
    vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts("Last Sibling"))
    vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts("First Sibling"))
    vim.keymap.set("n", "m", api.marks.toggle, opts("Toggle Bookmark"))
    vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "O", api.node.open.no_window_picker, opts("Open: No Window Picker"))
    vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))
    vim.keymap.set("n", "P", api.node.navigate.parent, opts("Parent Directory"))
    vim.keymap.set("n", "q", api.tree.close, opts("Close"))
    vim.keymap.set("n", "r", api.fs.rename, opts("Rename"))
    vim.keymap.set("n", "R", api.tree.reload, opts("Refresh"))
    vim.keymap.set("n", "s", api.node.run.system, opts("Run System"))
    vim.keymap.set("n", "S", api.tree.search_node, opts("Search"))
    vim.keymap.set("n", "u", api.fs.rename_full, opts("Rename: Full Path"))
    vim.keymap.set("n", "U", api.tree.toggle_custom_filter, opts("Toggle Filter: Hidden"))
    vim.keymap.set("n", "W", api.tree.collapse_all, opts("Collapse"))
    vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
    vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
    vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
    vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, opts("CD"))

    -- vim.api.nvim_buf_set_keymap(
    --   bufnr,
    --   "n",
    --   "l",
    --   ":lua require('tree-config').edit_or_open()<CR>",
    --   { noremap = true, silent = true }
    -- )
    -- vim.api.nvim_buf_set_keymap(
    --   bufnr,
    --   "n",
    --   "L",
    --   ":lua require('tree-config').vsplit_preview()<CR>",
    --   { noremap = true, silent = true }
    -- )
    -- vim.api.nvim_buf_set_keymap(
    --   bufnr,
    --   "n",
    --   "h",
    --   ":lua require('tree-config').collapse()<CR>",
    --   { noremap = true, silent = true }
    -- )
  end,
})

local function toggle_tree()
  if api.tree.is_visible() then
    api.tree.close()
  else
    api.tree.open({ path = vim.fn.getcwd() })
  end
end
vim.keymap.set("n", "<leader>pt", toggle_tree, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>pv", function()
  if api.tree.is_visible() then
    api.tree.focus()
  else
    toggle_tree()
  end
end)
vim.keymap.set("n", "<leader>fn", function()
  api.tree.find_file({ open = true })
  api.tree.focus()
end)

-- "---------------NerdTree
-- autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
-- " autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
-- " If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
-- " autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
-- "     \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
-- " let NERDTreeWinPos='right'
-- let NERDTreeMapActivateNode='l'
-- let NERDTreeMapJumpParent='h'
-- let NERDTreeShowHidden=1
-- "--------------- end nerdtree
-- nnoremap <leader>pt :NERDTreeToggle<cr>
-- nnoremap <leader>pv :NERDTreeVCS<cr>
-- nnoremap <leader>ff :wLeaderfFiler %:p:h<cr>
-- nnoremap <leader>fn :NERDTreeFind<cr>
return {
  edit_or_open = function()
    local node = api.tree.get_node_under_cursor()

    if node ~= nil and node.nodes ~= nil then
      if node.nodes ~= nil then
        -- expand or collapse folder
        api.node.open.edit()
      else
        -- open file
        api.node.open.edit()
        -- Close the tree if file was opened
        -- api.tree.close()
      end
    end
  end,
  vsplit_preview = function()
    local node = api.tree.get_node_under_cursor()

    if node.nodes ~= nil then
      -- expand or collapse folder
      api.node.open.edit()
    else
      -- open file as vsplit
      api.node.open.vertical()
    end

    -- Finally refocus on tree if it was lost
    api.tree.focus()
  end,
  collapse = function()
    local node = api.tree.get_node_under_cursor()

    if node ~= nil then
      api.node.open.edit()
    end
  end,
}
