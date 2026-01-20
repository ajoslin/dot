-- OpenCode.nvim configuration
-- See https://github.com/NickvanDyke/opencode.nvim for more options

-- Configure snacks.nvim for input and picker (only if loaded)
local snacks_ok, snacks = pcall(require, "snacks")
if snacks_ok then
  snacks.setup({
    input = {},
    picker = {},
    terminal = {},
  })
end

-- Configure opencode.nvim
vim.g.opencode_opts = {
  -- Your configuration, if any — see defaults at:
  -- https://github.com/NickvanDyke/opencode.nvim/blob/main/lua/opencode/config.lua
  
  -- Example: Use snacks provider (default if snacks is available)
  -- provider = {
  --   enabled = "snacks",
  -- },
}

-- Required for automatic buffer reloading when opencode edits files
vim.o.autoread = true
