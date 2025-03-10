require("lsp-file-operations").setup()

local nvim_lsp = require('lspconfig')

local formatters = require("format-on-save.formatters")
require("nvim-treesitter.configs").setup({
  ensure_installed = { "markdown", "lua", "markdown_inline" },
  auto_install = true,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true
  },
  incremental_selection = {
    enable = true
  },
  textobjects = {
    enable = true
  },
})
-- local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
-- parser_config.sql = {
--   install_info = {
--     url = "https://github.com/derekstride/tree-sitter-sql",
--     files = { "src/parser.c" },
--     branch = "main",
--   },
--   used_by = { "typescript", "javascript" }
-- }
-- local injections = require 'vim.treesitter.query'
-- injections.add_predicate("sql-template-literal", function(match, _, _, pred)
--   local node = match[pred[2]]
--   return node:type() == "template_string" and
--       node:prev_sibling() and
--       node:prev_sibling():type() == "comment" and
--       node:prev_sibling():source():match("/%*%s*sql%s*%*/")
-- end)

local biome_formatter = formatters.shell({
  cmd = function()
    local ext = vim.fn.expand("%"):match("^.+(%..+)$")
    return { "bunx", "biome", "format", "--stdin-file-path", "x" .. ext }
  end
})

local rustfmt_formatter = formatters.shell({
  cmd = { "rustfmt", "--emit=stdout" },
  expand_executable = false
})

local gofmt_formatter = formatters.shell({
  cmd = { "gofmt" },
  expand_executable = false
})

require("format-on-save").setup({
  formatter_by_ft = {
    css = formatters.prettierd,
    -- html = biome_formatter,
    -- svg = formatters.prettierd,
    java = formatters.lsp,
    json = biome_formatter,
    lua = formatters.lsp,
    markdown = formatters.lsp,
    openscad = formatters.lsp,
    python = formatters.black,
    rust = rustfmt_formatter,
    scss = formatters.prettierd,
    terraform = formatters.lsp,
    go = gofmt_formatter,
    -- yaml = formatters.prettierd,
    typescript = biome_formatter,
    typescriptreact = biome_formatter,
    javascript = biome_formatter,
    javascriptreact = biome_formatter,
  },
})

require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "tailwindcss" }
})

require("colorizer").setup()

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  signs = {
    severity_limit = "Warning",
  },
  underline = true,
  update_in_insert = true,
  virtual_text = {
    spacing = 2,
    severity_limit = "Warning",
  },
})

require("lspkind").init({
  preset = "codicons",
})

require("highlight-undo").setup({
  duration = 300,
  undo = {
    hlgroup = "HighlightUndo",
    mode = "n",
    lhs = "u",
    map = "undo",
    opts = {},
  },
  redo = {
    hlgroup = "HighlightUndo",
    mode = "n",
    lhs = "<C-r>",
    map = "redo",
    opts = {},
  },
  highlight_for_count = true,
})

-- Setup nvim-cmp.
local cmp = require("cmp")
local cmpCapabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

cmp.setup({
  completion = {
    completeopt = "menu,menuone,noinsert",
  },
  formatting = {
    format = require("lspkind").cmp_format(),
  },
  mapping = {
    ["<C-j>"] = cmp.mapping.select_next_item(),
    ["<C-k>"] = cmp.mapping.select_prev_item(),
    ["<C-y>"] = cmp.config.disable,                      -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ["<C-l>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    ["<Tab>"] = cmp.config.disable,
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "path" },
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }),
})

require('git-conflict').setup()

require('typescript-tools').setup({
  capabilities = cmpCapabilities,
  root_dir = nvim_lsp.util.root_pattern('.git'),
  on_attach = function(client, bufnr)
    client.server_capabilities.document_formatting = false
  end,
  settings = {
    separate_diagnostic_server = true,
    publish_diagnostic_on = "insert_leave",
  }
})

-- require("lspconfig").tsserver.setup({
--   capabilities = cmpCapabilities,
--   root_dir = nvim_lsp.util.root_pattern('.git'),
--   on_attach = function(client)
--     client.server_capabilities.document_formatting = false
--   end,
-- })

require("lspconfig").graphql.setup({})
require("lspconfig").prismals.setup({})
require("lspconfig").gopls.setup({})
require("lspconfig").lua_ls.setup({})
require("lspconfig").tailwindcss.setup({
  root_dir = nvim_lsp.util.root_pattern('.git'),
  on_attach = function(client, bufnr)
    -- require("tailwindcss-colors").buf_attach(bufnr)
  end,
})
require("tw-values").setup({})
require("tailwindcss-colors").setup({})
require("renamer").setup({})
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<Tab>",
    clear_suggestion = "<C-c>"
  }
})


require('oil').setup({
  view_options = {
    show_hidden = true,
  }
})


local system_prompt =
'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
local helpful_prompt =
'You are a helpful assistant. What I have sent are my notes so far. You are very curt, yet helpful.'
local dingllm = require 'dingllm'

local function anthropic_help()
  dingllm.invoke_llm_and_stream_into_editor({
    url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-3-5-sonnet-20240620',
    api_key_name =
    'ANTHROPIC_API_KEY',
    system_prompt = helpful_prompt,
    replace = false,
  }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
end

local function anthropic_replace()
  dingllm.invoke_llm_and_stream_into_editor({
    url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-3-5-sonnet-20240620',
    api_key_name =
    'ANTHROPIC_API_KEY',
    system_prompt = system_prompt,
    replace = true,
  }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
end

vim.keymap.set({ 'n', 'v' }, '<leader>I', anthropic_help, { desc = 'llm anthropic_help' })
vim.keymap.set({ 'n', 'v' }, '<leader>i', anthropic_replace, { desc = 'llm anthropic' })

-- Create a new command called AnthropicHelp that calls the anthropic_help function
vim.api.nvim_create_user_command('AnthropicHelp', anthropic_help, {})

-- falls back to `vim.fn.stdpath 'data' .. '/lazy/kznllm/templates'` when the plugin is not locally installed
-- local root_dir = nvim_lsp.util.root_pattern('.git')
-- kznllm.TEMPLATE_DIRECTORY = root_dir .. '/templates/'


require('img-clip').setup({
  default = {
    embed_image_as_base64 = false,
    prompt_for_file_name = false,
    drag_and_drop = {
      insert_mode = true,
    },
  },
})

require('gp').setup({
  -- providers = {
  --   openai = {
  --     disable = true
  --   },
  --   anthropic = {
  --     disable = false,
  --     endpoint = "https://api.anthropic.com/v1/messages",
  --     secret = os.getenv("ANTHROPIC_API_KEY"),
  --   },
  -- }
})
