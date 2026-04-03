local M = {}

local last_picker = nil
local last_fff_snapshot = nil

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

local function get_fff_picker_ui()
    local ok, picker_ui = pcall(require, "fff.picker_ui")
    if not ok or picker_ui.state == nil or not picker_ui.state.active then
        return nil
    end

    return picker_ui
end

local function clamp(value, min_value, max_value)
    return math.max(min_value, math.min(value, max_value))
end

local function snapshot_fff_state()
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return nil
    end

    local state = picker_ui.state
    local picker_opts = {}
    if last_picker ~= nil and last_picker.backend == "fff" then
        picker_opts = copy_opts(last_picker.opts)
    end

    last_fff_snapshot = {
        method = last_picker and last_picker.method or "find_files",
        opts = picker_opts,
        query = state.query,
        cursor = state.cursor,
        mode = state.mode,
        renderer = state.renderer,
        grep_mode = state.grep_mode,
        grep_config = copy_opts(state.grep_config),
        location = copy_opts(state.location),
        items = vim.deepcopy(state.items),
        filtered_items = vim.deepcopy(state.filtered_items),
        selected_files = vim.deepcopy(state.selected_files),
        selected_items = vim.deepcopy(state.selected_items),
        suggestion_items = vim.deepcopy(state.suggestion_items),
        suggestion_source = state.suggestion_source,
    }

    return last_fff_snapshot
end

local function restore_fff_state(snapshot)
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil or snapshot == nil then
        return
    end

    local state = picker_ui.state

    state.query = snapshot.query or ""
    state.mode = snapshot.mode
    state.renderer = snapshot.renderer
    state.grep_mode = snapshot.grep_mode or state.grep_mode
    state.grep_config = copy_opts(snapshot.grep_config)
    state.location = copy_opts(snapshot.location)
    state.items = vim.deepcopy(snapshot.items) or state.items
    state.filtered_items = vim.deepcopy(snapshot.filtered_items) or state.filtered_items
    state.selected_files = vim.deepcopy(snapshot.selected_files) or {}
    state.selected_items = vim.deepcopy(snapshot.selected_items) or {}
    state.suggestion_items = vim.deepcopy(snapshot.suggestion_items)
    state.suggestion_source = snapshot.suggestion_source

    local item_count = #state.filtered_items
    state.cursor = item_count == 0 and 1 or clamp(snapshot.cursor or 1, 1, item_count)

    if state.input_buf ~= nil and vim.api.nvim_buf_is_valid(state.input_buf) then
        vim.api.nvim_set_option_value("modifiable", true, { buf = state.input_buf })
        vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { state.config.prompt .. state.query })
    end

    picker_ui.render_list()
    picker_ui.update_preview()
    picker_ui.update_status()

    if state.input_win ~= nil and vim.api.nvim_win_is_valid(state.input_win) then
        vim.api.nvim_set_current_win(state.input_win)
        vim.api.nvim_win_set_cursor(state.input_win, { 1, #state.config.prompt + #state.query })
        vim.cmd("startinsert!")
    end
end

local function refresh_fff_picker(picker_ui)
    local state = picker_ui.state

    picker_ui.render_list()
    if state.mode == "grep" or state.suggestion_source == "grep" then
        picker_ui.update_preview_smart()
    else
        picker_ui.update_preview()
    end
    picker_ui.update_status()
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
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    snapshot_fff_state()

    if selected_item_count(picker_ui.state) > 0 then
        picker_ui.send_to_quickfix()
    else
        picker_ui.select()
    end
end

function M.fff_close()
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    snapshot_fff_state()
    picker_ui.close()
end

function M.fff_select(action)
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    snapshot_fff_state()
    picker_ui.select(action)
end

function M.fff_send_to_quickfix()
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    snapshot_fff_state()
    picker_ui.send_to_quickfix()
end

function M.fff_move_up_wrap()
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    local state = picker_ui.state
    local item_count = #state.filtered_items
    if item_count == 0 then
        return
    end

    if state.cursor <= 1 then
        state.cursor = item_count
        refresh_fff_picker(picker_ui)
        return
    end

    picker_ui.move_up()
end

function M.fff_move_down_wrap()
    local picker_ui = get_fff_picker_ui()
    if picker_ui == nil then
        return
    end

    local state = picker_ui.state
    local item_count = #state.filtered_items
    if item_count == 0 then
        return
    end

    if state.cursor >= item_count then
        state.cursor = 1
        refresh_fff_picker(picker_ui)
        return
    end

    picker_ui.move_down()
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
            vim.keymap.set({ "i", "n" }, "<C-k>", M.fff_move_up_wrap, opts)
            vim.keymap.set({ "i", "n" }, "<Up>", M.fff_move_up_wrap, opts)
            vim.keymap.set({ "i", "n" }, "<C-j>", M.fff_move_down_wrap, opts)
            vim.keymap.set({ "i", "n" }, "<Down>", M.fff_move_down_wrap, opts)
            vim.keymap.set({ "i", "n" }, "<Esc>", M.fff_close, opts)
            vim.keymap.set("n", "q", M.fff_close, opts)
            vim.keymap.set({ "i", "n" }, "<C-q>", M.fff_send_to_quickfix, opts)
            vim.keymap.set({ "i", "n" }, "<C-s>", function()
                M.fff_select("split")
            end, opts)
            vim.keymap.set({ "i", "n" }, "<C-v>", function()
                M.fff_select("vsplit")
            end, opts)
            vim.keymap.set({ "i", "n" }, "<C-t>", function()
                M.fff_select("tab")
            end, opts)

            vim.api.nvim_create_autocmd("WinLeave", {
                buffer = event.buf,
                callback = function()
                    snapshot_fff_state()
                end,
            })
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
        },
        preview = {
            enabled = false,
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
            timer = 100,
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
        local snapshot = vim.deepcopy(last_fff_snapshot)
        local method = snapshot and snapshot.method or last_picker.method
        local opts = snapshot and copy_opts(snapshot.opts) or copy_opts(last_picker.opts)

        if snapshot ~= nil and snapshot.query ~= nil then
            opts.query = snapshot.query
        end

        call_fff(method, opts)
        restore_fff_state(snapshot)
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
