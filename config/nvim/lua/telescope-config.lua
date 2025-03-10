local action_state = require("telescope.actions.state")

local custom_actions = {}
local actions = require("telescope.actions")

function custom_actions.fzf_multi_select(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local num_selections = table.getn(picker:get_multi_selection())

    if num_selections > 1 then
        actions.send_selected_to_qflist(prompt_bufnr)
        actions.open_qflist()
    else
        actions.file_edit(prompt_bufnr)
    end
end

local mappings = {
    i = {
        ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
        ["<s-cr>"] = custom_actions.fzf_multi_select,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = false,
        ["<C-p>"] = false,
        ["<esc>"] = actions.close,
    },
    n = {
        ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
        ["<cr>"] = custom_actions.fzf_multi_select,
    },
}
require("telescope").setup({
    pickers = {
        -- live_grep = {
        --     on_input_filter_cb = function(prompt)
        --         -- AND operator for live_grep like how fzf handles spaces with wildcards in rg
        --         return { prompt = prompt:gsub("%s", ".*") }
        --     end,
        -- },
        find_files = {
            hidden = true,
        }
    },
    dynamic_preview_title = true,
    defaults = {
        mappings = mappings,
    },
})

local ymap = require("yanky.telescope.mapping")
require("yanky").setup({
    picker = {
        select = {
            -- action = nil, -- nil to use default put action
        },
        telescope = {
            use_default_mappings = false,
            -- mappings = nil, -- nil to use default mappings
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
require("telescope").load_extension("yank_history")

vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
