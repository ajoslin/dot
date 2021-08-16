local nvim_lsp = require("lspconfig")
local util = require 'lspconfig/util'

-- enable null-ls integration (optional)
require("null-ls").config {}
require("lspconfig")["null-ls"].setup {}

nvim_lsp.tsserver.setup {
    on_attach = function(client, bufnr)
        -- disable tsserver formatting if you plan on formatting via null-ls
        client.resolved_capabilities.document_formatting = false
        -- define an alias
        vim.cmd("command! -buffer Formatting lua vim.lsp.buf.formatting()")

        -- format on save
        vim.cmd("autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()")

        local ts_utils = require("nvim-lsp-ts-utils")

        -- defaults
        ts_utils.setup {
            debug = false,
            disable_commands = false,
            enable_import_on_completion = false,

            -- import all
            import_all_timeout = 5000, -- ms
            import_all_priorities = {
                buffers = 4, -- loaded buffer names
                buffer_content = 3, -- loaded buffer content
                local_files = 2, -- git files or files with relative path markers
                same_file = 1, -- add to existing import statement
            },
            import_all_scan_buffers = 100,
            import_all_select_source = false,

            -- eslint
            eslint_enable_code_actions = true,
            eslint_enable_disable_comments = true,
            eslint_bin = "eslint_d",
            eslint_config_fallback = nil,
            eslint_enable_diagnostics = false,
            eslint_show_rule_id = false,

            -- formatting
            enable_formatting = true,
            formatter = "prettierd",
            formatter_config_fallback = nil,

            -- update imports on file move
            update_imports_on_move = true,
            require_confirmation_on_move = false,
            watch_dir = nil,
        }

        -- required to fix code action ranges
        ts_utils.setup_client(client)

        -- no default maps, so you may want to define some here
        local opts = {silent = true}
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gs", ":TSLspOrganize<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "qq", ":TSLspFixCurrent<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", ":TSLspRenameFile<CR>", opts)
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", ":TSLspImportAll<CR>", opts)
    end
}

-- use .ts snippets in .tsx files
vim.g.vsnip_filetypes = {
    typescriptreact = {"typescript"}
}
require"compe".setup {
    preselect = "always",
    source = {
        path = true,
        buffer = false,
        vsnip = false,
        nvim_lsp = true,
        nvim_lua = true
    }
}
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end
_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return vim.fn["compe#confirm"]()
    elseif vim.fn.call("vsnip#available", {1}) == 1 then
        return t("<Plug>(vsnip-expand-or-jump)")
    else
        return t("<Tab>")
    end
end
vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<C-Space>", "compe#complete()",
                        {expr = true, silent = true})
vim.api.nvim_set_keymap("i", "<CR>", [[compe#confirm("<CR>")]],
                        {expr = true, silent = true})
vim.api.nvim_set_keymap("i", "<C-e>", [[compe#close("<C-e>")]],
                        {expr = true, silent = true})


                    -- require('trouble').setup()
require('lspsaga').init_lsp_saga({
        border_style='single';
        code_action_prompt = {
            enable = false 
        }
    })

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    signs = {
      severity_limit = 'Warning',
    },
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 2,
      severity_limit = 'Warning',
    },
  }
)

require('lspkind').init({
        preset = 'codicons'
    })

-- require('lspconfig').tailwindcss.setup { 
--   default_config = {
--     cmd = 'tailwindcss-language-server';
--     filetypes = {'html','svelte','typescriptreact'};
--     root_dir = util.root_pattern("tailwind.config.js", "package.json", ".git");
--   };
-- }
