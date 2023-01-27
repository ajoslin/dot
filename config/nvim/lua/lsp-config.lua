local null_ls = require("null-ls")
local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
require("prettier").setup({
  bin = "prettierd", -- or `'prettierd'` (v0.22+)
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
})

local async = event == "BufWritePost"
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.rustfmt,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.code_actions.eslint_d,
  },
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<Leader>cf", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })

      -- format on save
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
      vim.api.nvim_create_autocmd(event, {
        buffer = bufnr,
        group = group,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr, async = async })
        end,
        desc = "[lsp] format on save",
      })
    end

    if client.supports_method("textDocument/rangeFormatting") then
      vim.keymap.set("x", "<Leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })
    end
  end,
})

require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "sumneko_lua", "tailwindcss" },
})

require("lspconfig").graphql.setup({})
require("lspconfig").prismals.setup({})
require("lspconfig").gopls.setup({})
require("lspconfig").sumneko_lua.setup({})
require("lspconfig").tailwindcss.setup({
  on_attach = function(client, bufnr)
    require("tailwindcss-colors").buf_attach(bufnr)
  end,
})
require("tailwindcss-colors").setup({})
-- require'lspconfig'.tailwindcss.setup{}

require("nvim-treesitter.configs").setup({
  context_commentstring = {
    enable = true,
  },
  autotag = {
    enable = true,
  },
})

require("colorizer").setup()

local cmpCapabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

require("typescript").setup({
  disable_commands = false, -- prevent the plugin from creating Vim commands
  debug = false, -- enable debug logging for commands
  go_to_source_definition = {
    fallback = true, -- fall back to standard LSP definition on failure
  },
  server = { -- pass options to lspconfig's setup method
    -- on_attach = ...,
    capabitilies = cmpCapabilities,
    -- on_attach = function(client, bufnr)
    --   -- disable tsserver formatting if you plan on formatting via null-ls
    --   client.server_capabilities.document_formatting = false
    --   -- define an alias
    --   -- vim.cmd("command! -buffer Formatting lua vim.lsp.buf.formatting()")
    -- end,
  },
})

-- use .ts snippets in .tsx files
vim.g.vsnip_filetypes = {
  typescriptreact = { "typescript" },
}
-- require('trouble').setup()
require("lspsaga").init_lsp_saga({
  border_style = "single",
  code_action_prompt = {
    enable = false,
  },
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  signs = {
    severity_limit = "Warning",
  },
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 2,
    severity_limit = "Warning",
  },
})

require("lspkind").init({
  preset = "codicons",
})
