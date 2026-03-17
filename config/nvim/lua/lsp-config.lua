require("lsp-file-operations").setup()

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

local sql_formatter = formatters.shell({
  cmd = { "sql-formatter", "-l", "tsql", "%" },
  expand_executable = false
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
    html = formatters.prettierd,
    ejs = formatters.prettierd,
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
    -- sql = sql_formatter,
    -- yaml = formatters.prettierd,
    typescript = biome_formatter,
    typescriptreact = biome_formatter,
    javascript = biome_formatter,
    javascriptreact = biome_formatter,
  },
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

-- tsgo for TypeScript/JavaScript (TypeScript native preview)
vim.lsp.config.tsgo = {
  cmd = { 'tsgo', '--lsp', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json', '.git' },
  capabilities = cmpCapabilities,
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
  end,
}
vim.lsp.enable('tsgo')

local ts_code_action_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local function apply_code_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end

  local command = action.command
  if command then
    local command_to_run = type(command) == 'table' and command or action
    client:exec_cmd(command_to_run, ctx)
  end
end

local function on_code_action_choice(choice)
  if not choice then
    return
  end

  local client = assert(vim.lsp.get_client_by_id(choice.ctx.client_id))
  local action = choice.action
  local bufnr = assert(choice.ctx.bufnr, 'Must have buffer number')

  if type(action.title) == 'string' and type(action.command) == 'string' then
    apply_code_action(action, client, choice.ctx)
    return
  end

  if action.disabled then
    vim.notify(action.disabled.reason, vim.log.levels.ERROR)
    return
  end

  if not (action.edit and action.command) and client:supports_method('codeAction/resolve') then
    client:request('codeAction/resolve', action, function(err, resolved_action)
      if err then
        if action.edit or action.command then
          apply_code_action(action, client, choice.ctx)
        else
          vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
        end
      else
        apply_code_action(resolved_action, client, choice.ctx)
      end
    end, bufnr)
  else
    apply_code_action(action, client, choice.ctx)
  end
end

local function make_code_action_params(client)
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params(win, client.offset_encoding)
  local ns_push = vim.lsp.diagnostic.get_namespace(client.id, false)
  local ns_pull = vim.lsp.diagnostic.get_namespace(client.id, true)
  local diagnostics = {}
  local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1

  vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = lnum }))
  vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = lnum }))

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
    diagnostics = vim.tbl_map(function(d)
      return d.user_data.lsp
    end, diagnostics),
  }

  return params
end

local function preferred_code_action_client(bufnr)
  if not ts_code_action_filetypes[vim.bo[bufnr].filetype] then
    return nil
  end

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeAction' })) do
    if client.name == 'tsgo' then
      return client
    end
  end

  return nil
end

_G.smart_code_action = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = preferred_code_action_client(bufnr)
  if not client then
    vim.lsp.buf.code_action()
    return
  end

  client:request('textDocument/codeAction', make_code_action_params(client), function(err, result, ctx)
    if err then
      vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
      return
    end

    local actions = {}
    for _, action in pairs(result or {}) do
      table.insert(actions, {
        action = action,
        ctx = ctx,
      })
    end

    if #actions == 0 then
      vim.notify('No code actions available', vim.log.levels.INFO)
      return
    end

    vim.ui.select(actions, {
      prompt = 'Code actions:',
      kind = 'codeaction',
      format_item = function(item)
        local title = item.action.title:gsub('\r\n', '\\r\\n'):gsub('\n', '\\n')
        if item.action.disabled then
          return title .. ' (disabled)'
        end
        return title
      end,
    }, on_code_action_choice)
  end, bufnr)
end

-- Custom code action function that sorts vtsls/TypeScript actions first, biome last
_G.sorted_code_action = function()
  local params = vim.lsp.util.make_range_params(nil, nil, 0)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  params.context = { diagnostics = diagnostics }
  
  vim.lsp.buf_request_all(0, 'textDocument/codeAction', params, function(results)
    if not results or vim.tbl_isempty(results) then
      print("No code actions available")
      return
    end
    
    local actions = {}
    for client_id, result in pairs(results) do
      local client = vim.lsp.get_client_by_id(client_id)
      if result and result.result then
        for _, action in pairs(result.result) do
          action.client_name = client.name
          table.insert(actions, action)
        end
      end
    end
    
    -- Sort: tsgo first, then others, biome last
    table.sort(actions, function(a, b)
      local a_is_ts = a.client_name == "tsgo" or a.client_name == "ts_ls"
      local b_is_ts = b.client_name == "tsgo" or b.client_name == "ts_ls"
      local a_is_biome = a.client_name == "biome"
      local b_is_biome = b.client_name == "biome"
      
      if a_is_ts and not b_is_ts then return true end
      if b_is_ts and not a_is_ts then return false end
      if a_is_biome and not b_is_biome then return false end
      if b_is_biome and not a_is_biome then return true end
      
      return false
    end)
    
    if #actions == 0 then
      print("No code actions available")
      return
    end
    
    -- Present sorted actions to user
    vim.ui.select(actions, {
      prompt = "Code actions:",
      format_item = function(action)
        return (action.title or "") .. " [" .. action.client_name .. "]"
      end,
    }, function(selected)
      if selected then
        local action = selected
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
        end
        if action.command then
          local command = type(action.command) == "table" and action.command or action
          local fn = vim.lsp.commands[command.command]
          if fn then
            fn(command, { bufnr = 0, client_id = vim.lsp.get_client_by_id(action.client_id) })
          else
            vim.lsp.buf.execute_command(command)
          end
        end
      end
    end)
  end)
end

vim.lsp.config.graphql = {
  cmd = { 'graphql-lsp', 'server', '-m', 'stream' },
  filetypes = { 'graphql', 'typescriptreact', 'javascriptreact' },
  root_markers = { '.git', '.graphqlrc*', '.graphql.config.*', 'graphql.config.*' },
}
vim.lsp.enable('graphql')

vim.lsp.config.prismals = {
  cmd = { 'prisma-language-server', '--stdio' },
  filetypes = { 'prisma' },
  root_markers = { '.git', 'package.json' },
  settings = {
    prisma = {
      prismaFmtBinPath = '',
    },
  },
}
vim.lsp.enable('prismals')

vim.lsp.config.gopls = {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
}
vim.lsp.enable('gopls')

vim.lsp.config.lua_ls = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
}
vim.lsp.enable('lua_ls')

vim.lsp.config.jsonls = {
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc' },
  root_markers = { '.git' },
  capabilities = cmpCapabilities,
  settings = {
    json = {
      validate = { enable = true },
    },
  },
}
vim.lsp.enable('jsonls')

vim.lsp.config.tailwindcss = {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  filetypes = { 'aspnetcorerazor', 'astro', 'astro-markdown', 'blade', 'clojure', 'django-html', 'htmldjango', 'edge', 'eelixir', 'elixir', 'ejs', 'erb', 'eruby', 'gohtml', 'gohtmltmpl', 'haml', 'handlebars', 'hbs', 'html', 'htmlangular', 'html-eex', 'heex', 'jade', 'leaf', 'liquid', 'markdown', 'mdx', 'mustache', 'njk', 'nunjucks', 'php', 'razor', 'slim', 'twig', 'css', 'less', 'postcss', 'sass', 'scss', 'stylus', 'sugarss', 'javascript', 'javascriptreact', 'reason', 'rescript', 'typescript', 'typescriptreact', 'vue', 'svelte', 'templ' },
  root_markers = { 'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts', 'postcss.config.js', 'postcss.config.cjs', 'postcss.config.mjs', 'postcss.config.ts', '.git' },
  on_attach = function(client, bufnr)
    -- require("tailwindcss-colors").buf_attach(bufnr)
  end,
}
vim.lsp.enable('tailwindcss')
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
require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "tailwindcss", "jsonls" },
  handlers = {
    -- Default handler for auto-setup (keeps existing behavior)
    function(server_name)
      -- Skip TypeScript language servers managed elsewhere in this config.
      if server_name == "vtsls" or server_name == "ts_ls" then
        return
      end
      -- Auto-setup everything else
      require("lspconfig")[server_name].setup({})
    end,
  }
})

-- require('avante').setup({
--   provider = 'claude',
--   claude = {
--     endpoint = "https://api.anthropic.com",
--     model = "claude-sonnet-4-20250514",
--     temperature = 0,
--     max_tokens = 4096,
--   },
--   keys = {
--     {
--       "<leader>a+",
--       function()
--         local tree_ext = require("avante.extensions.nvim_tree")
--         tree_ext.add_file()
--       end,
--       desc = "Select file in NvimTree",
--       ft = "NvimTree",
--     },
--     {
--       "<leader>a-",
--       function()
--         local tree_ext = require("avante.extensions.nvim_tree")
--         tree_ext.remove_file()
--       end,
--       desc = "Deselect file in NvimTree",
--       ft = "NvimTree",
--     },
--   },
-- })

-- require("claude-code").setup({
-- })

require('pretty-ts-errors').setup({
  auto_open = false
})
