local M = {}

local last_picker = nil

local function copy_opts(opts)
    if opts == nil then
        return {}
    end

    return vim.deepcopy(opts)
end

local function remember_picker(backend, method, opts)
    last_picker = {
        backend = backend,
        method = method,
        opts = copy_opts(opts),
    }
end

local function notify_missing(plugin_name)
    vim.notify(plugin_name .. " is not available. Run :PlugInstall to sync plugins.", vim.log.levels.WARN)
end

local function call_fff(method, opts)
    local ok, fff = pcall(require, "fff")
    if not ok then
        notify_missing("fff.nvim")
        return
    end

    remember_picker("fff", method, opts)
    fff[method](copy_opts(opts))
end

local function call_telescope_builtin(method, opts)
    local ok, builtin = pcall(require, "telescope.builtin")
    if not ok then
        notify_missing("telescope.nvim")
        return
    end

    local picker = builtin[method]
    if type(picker) ~= "function" then
        vim.notify("Telescope picker not found: " .. method, vim.log.levels.WARN)
        return
    end

    remember_picker("telescope", method, opts)
    picker(copy_opts(opts))
end

local function call_telescope_extension(extension_name, method, opts)
    local ok, telescope = pcall(require, "telescope")
    if not ok then
        notify_missing("telescope.nvim")
        return
    end

    local extension = telescope.extensions[extension_name]
    if extension == nil then
        local loaded, load_err = pcall(telescope.load_extension, extension_name)
        if not loaded then
            vim.notify(load_err, vim.log.levels.WARN)
            return
        end
        extension = telescope.extensions[extension_name]
    end

    local picker = extension and extension[method]
    if type(picker) ~= "function" then
        vim.notify("Telescope extension picker not found: " .. extension_name .. "." .. method, vim.log.levels.WARN)
        return
    end

    remember_picker("telescope_extension", extension_name .. "." .. method, opts)
    picker(copy_opts(opts))
end

local function selected_item_count(state)
    local count = 0
    local selected = state.mode == "grep" and state.selected_items or state.selected_files

    for _ in pairs(selected or {}) do
        count = count + 1
    end

    return count
end

function M.fff_multi_select()
    local ok, picker_ui = pcall(require, "fff.picker_ui")
    if not ok or picker_ui.state == nil or not picker_ui.state.active then
        return
    end

    if selected_item_count(picker_ui.state) > 0 then
        picker_ui.send_to_quickfix()
    else
        picker_ui.select()
    end
end

local function setup_fff_picker_keymaps()
    local group = vim.api.nvim_create_augroup("andrew_fff_picker_keymaps", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "fff_input", "fff_list", "fff_preview" },
        callback = function(event)
            local opts = { buffer = event.buf, noremap = true, silent = true }

            vim.keymap.set("i", "<S-CR>", M.fff_multi_select, opts)
            vim.keymap.set("n", "<CR>", M.fff_multi_select, opts)
            vim.keymap.set("n", "<S-CR>", M.fff_multi_select, opts)
        end,
    })
end

local function setup_fff()
    local ok, fff = pcall(require, "fff")
    if not ok then
        return
    end

    fff.setup({
        prompt = "> ",
        title = "Files",
        lazy_sync = true,
        layout = {
            height = 0.85,
            width = 0.85,
            prompt_position = "top",
            preview_position = "right",
            preview_size = 0.5,
        },
        keymaps = {
            close = "<Esc>",
            select = "<CR>",
            select_split = "<C-s>",
            select_vsplit = "<C-v>",
            select_tab = "<C-t>",
            move_up = "<C-k>",
            move_down = "<C-j>",
            preview_scroll_up = "<C-u>",
            preview_scroll_down = "<C-d>",
            cycle_grep_modes = "<S-Tab>",
            cycle_previous_query = "<C-Up>",
            toggle_select = "<Tab>",
            send_to_quickfix = "<C-q>",
            focus_list = "<leader>l",
            focus_preview = "<leader>p",
        },
        file_picker = {
            current_file_label = "(current)",
        },
    })

    setup_fff_picker_keymaps()
end

local function setup_telescope_yanky()
    local ok, telescope = pcall(require, "telescope")
    if not ok then
        return
    end

    telescope.setup({
        defaults = {
            dynamic_preview_title = true,
        },
    })

    local actions = require("telescope.actions")
    local ymap = require("yanky.telescope.mapping")

    require("yanky").setup({
        picker = {
            select = {},
            telescope = {
                use_default_mappings = false,
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-n>"] = false,
                        ["<C-p>"] = false,
                        ["<esc>"] = actions.close,
                        ["<cr>"] = ymap.put("p"),
                        ["<C-l>"] = ymap.put("p"),
                        ["<C-h>"] = ymap.put("P"),
                    },
                },
            },
        },
        highlight = {
            on_put = true,
            on_yank = true,
            timer = 250,
        },
        preserve_cursor_position = {
            enabled = true,
        },
    })

    telescope.load_extension("yank_history")
end

function M.find_files()
    call_fff("find_files", { title = "Find Files" })
end

function M.live_grep()
    call_fff("live_grep", { title = "Live Grep" })
end

function M.grep_string()
    call_fff("live_grep", {
        title = "Live Grep",
        query = vim.fn.expand("<cword>"),
    })
end

function M.resume()
    if last_picker ~= nil and last_picker.backend == "fff" then
        call_fff(last_picker.method, last_picker.opts)
        return
    end

    local ok, builtin = pcall(require, "telescope.builtin")
    if ok and type(builtin.resume) == "function" then
        builtin.resume()
        return
    end

    vim.notify("No picker session to resume.", vim.log.levels.WARN)
end

function M.yank_history()
    call_telescope_extension("yank_history", "yank_history")
end

function M.lsp_definitions()
    call_telescope_builtin("lsp_definitions")
end

function M.lsp_references()
    call_telescope_builtin("lsp_references")
end

function M.lsp_implementations()
    call_telescope_builtin("lsp_implementations")
end

function M.lsp_dynamic_workspace_symbols()
    call_telescope_builtin("lsp_dynamic_workspace_symbols")
end

function M.lsp_document_symbols()
    call_telescope_builtin("lsp_document_symbols")
end

setup_fff()
setup_telescope_yanky()

vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

return M
