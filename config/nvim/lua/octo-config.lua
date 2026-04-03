vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function()
require("octo").setup({
  picker = "snacks",
  enable_builtin = true,
  mappings_disable_default = true,
  reviews = {
    auto_show_threads = true,
    focus = "right",
  },
  mappings = {
    issue = {
      close_issue       = { lhs = "<leader>gc", desc = "close issue" },
      reopen_issue      = { lhs = "<leader>go", desc = "reopen issue" },
      list_issues       = { lhs = "<leader>gi", desc = "list open issues on same repo" },
      reload            = { lhs = "<C-r>",      desc = "reload issue" },
      open_in_browser   = { lhs = "<C-b>",      desc = "open issue in browser" },
      copy_url          = { lhs = "<C-y>",      desc = "copy url to system clipboard" },
      add_assignee      = { lhs = "<leader>gaa", desc = "add assignee" },
      remove_assignee   = { lhs = "<leader>gad", desc = "remove assignee" },
      add_label         = { lhs = "<leader>gla", desc = "add label" },
      remove_label      = { lhs = "<leader>gld", desc = "remove label" },
      create_label      = { lhs = "<leader>glc", desc = "create label" },
      goto_issue        = { lhs = "<leader>gj",  desc = "navigate to a local repo issue" },
      add_comment       = { lhs = "<leader>ga",  desc = "add comment" },
      add_reply         = { lhs = "<leader>gr",  desc = "add reply" },
      delete_comment    = { lhs = "<leader>gd",  desc = "delete comment" },
      next_comment      = { lhs = "<leader>gn",  desc = "go to next comment" },
      prev_comment      = { lhs = "<leader>gN",  desc = "go to previous comment" },
      react_hooray      = { lhs = "<leader>g1",  desc = "add/remove 🎉 reaction" },
      react_heart       = { lhs = "<leader>g2",  desc = "add/remove ❤️ reaction" },
      react_eyes        = { lhs = "<leader>g3",  desc = "add/remove 👀 reaction" },
      react_thumbs_up   = { lhs = "<leader>g+",  desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<leader>g-",  desc = "add/remove 👎 reaction" },
      react_rocket      = { lhs = "<leader>g4",  desc = "add/remove 🚀 reaction" },
      react_laugh       = { lhs = "<leader>g5",  desc = "add/remove 😄 reaction" },
      react_confused    = { lhs = "<leader>g6",  desc = "add/remove 😕 reaction" },
      issue_options     = { lhs = "<CR>",         desc = "show issue options" },
    },
    pull_request = {
      pr_options              = { lhs = "<CR>",         desc = "show PR options" },
      checkout_pr             = { lhs = "<leader>gk",   desc = "checkout PR" },
      merge_pr                = { lhs = "<leader>gm",   desc = "merge PR" },
      squash_and_merge_pr     = { lhs = "<leader>gMs",  desc = "squash and merge PR" },
      rebase_and_merge_pr     = { lhs = "<leader>gMr",  desc = "rebase and merge PR" },
      list_commits            = { lhs = "<leader>gpc",  desc = "list PR commits" },
      list_changed_files      = { lhs = "<leader>gpf",  desc = "list PR changed files" },
      show_pr_diff            = { lhs = "<leader>gpd",  desc = "show PR diff" },
      add_reviewer            = { lhs = "<leader>gva",  desc = "add reviewer" },
      remove_reviewer         = { lhs = "<leader>gvd",  desc = "remove reviewer request" },
      close_issue             = { lhs = "<leader>gc",   desc = "close PR" },
      reopen_issue            = { lhs = "<leader>go",   desc = "reopen PR" },
      list_issues             = { lhs = "<leader>gi",   desc = "list open issues on same repo" },
      reload                  = { lhs = "<C-r>",        desc = "reload PR" },
      open_in_browser         = { lhs = "<C-b>",        desc = "open PR in browser" },
      copy_url                = { lhs = "<C-y>",        desc = "copy url to system clipboard" },
      goto_file               = { lhs = "<leader>gf",   desc = "go to file" },
      add_assignee            = { lhs = "<leader>gaa",  desc = "add assignee" },
      remove_assignee         = { lhs = "<leader>gad",  desc = "remove assignee" },
      add_label               = { lhs = "<leader>gla",  desc = "add label" },
      remove_label            = { lhs = "<leader>gld",  desc = "remove label" },
      create_label            = { lhs = "<leader>glc",  desc = "create label" },
      goto_issue              = { lhs = "<leader>gj",   desc = "navigate to a local repo issue" },
      add_comment             = { lhs = "<leader>ga",   desc = "add comment" },
      add_reply               = { lhs = "<leader>gr",   desc = "add reply" },
      delete_comment          = { lhs = "<leader>gd",   desc = "delete comment" },
      next_comment            = { lhs = "<leader>gn",   desc = "go to next comment" },
      prev_comment            = { lhs = "<leader>gN",   desc = "go to previous comment" },
      react_hooray            = { lhs = "<leader>g1",   desc = "add/remove 🎉 reaction" },
      react_heart             = { lhs = "<leader>g2",   desc = "add/remove ❤️ reaction" },
      react_eyes              = { lhs = "<leader>g3",   desc = "add/remove 👀 reaction" },
      react_thumbs_up         = { lhs = "<leader>g+",   desc = "add/remove 👍 reaction" },
      react_thumbs_down       = { lhs = "<leader>g-",   desc = "add/remove 👎 reaction" },
      react_rocket            = { lhs = "<leader>g4",   desc = "add/remove 🚀 reaction" },
      react_laugh             = { lhs = "<leader>g5",   desc = "add/remove 😄 reaction" },
      react_confused          = { lhs = "<leader>g6",   desc = "add/remove 😕 reaction" },
      review_start            = { lhs = "<leader>gs",   desc = "start or resume review for the current PR" },
      resolve_thread          = { lhs = "<leader>gt",   desc = "resolve PR thread" },
      unresolve_thread        = { lhs = "<leader>gT",   desc = "unresolve PR thread" },
    },
    review_thread = {
      goto_issue              = { lhs = "<leader>gj",   desc = "navigate to a local repo issue" },
      add_comment             = { lhs = "<leader>ga",   desc = "add comment" },
      add_reply               = { lhs = "<leader>gr",   desc = "add reply" },
      add_suggestion          = { lhs = "<leader>gv",   desc = "add suggestion" },
      delete_comment          = { lhs = "<leader>gd",   desc = "delete comment" },
      next_comment            = { lhs = "<leader>gn",   desc = "go to next comment" },
      prev_comment            = { lhs = "<leader>gN",   desc = "go to previous comment" },
      select_next_entry       = { lhs = "]q",           desc = "move to next changed file" },
      select_prev_entry       = { lhs = "[q",           desc = "move to previous changed file" },
      select_first_entry      = { lhs = "[Q",           desc = "move to first changed file" },
      select_last_entry       = { lhs = "]Q",           desc = "move to last changed file" },
      close_review_tab        = { lhs = "<leader>gq",   desc = "close review tab" },
      react_hooray            = { lhs = "<leader>g1",   desc = "add/remove 🎉 reaction" },
      react_heart             = { lhs = "<leader>g2",   desc = "add/remove ❤️ reaction" },
      react_eyes              = { lhs = "<leader>g3",   desc = "add/remove 👀 reaction" },
      react_thumbs_up         = { lhs = "<leader>g+",   desc = "add/remove 👍 reaction" },
      react_thumbs_down       = { lhs = "<leader>g-",   desc = "add/remove 👎 reaction" },
      react_rocket            = { lhs = "<leader>g4",   desc = "add/remove 🚀 reaction" },
      react_laugh             = { lhs = "<leader>g5",   desc = "add/remove 😄 reaction" },
      react_confused          = { lhs = "<leader>g6",   desc = "add/remove 😕 reaction" },
      resolve_thread          = { lhs = "<leader>gt",   desc = "resolve PR thread" },
      unresolve_thread        = { lhs = "<leader>gT",   desc = "unresolve PR thread" },
    },
    submit_win = {
      approve_review          = { lhs = "<C-a>",        desc = "approve review", mode = { "n", "i" } },
      comment_review          = { lhs = "<C-m>",        desc = "comment review", mode = { "n", "i" } },
      request_changes         = { lhs = "<C-r>",        desc = "request changes review", mode = { "n", "i" } },
      close_review_tab        = { lhs = "<C-c>",        desc = "close review tab", mode = { "n", "i" } },
    },
    review_diff = {
      submit_review           = { lhs = "<leader>gS",   desc = "submit review" },
      discard_review          = { lhs = "<leader>gD",   desc = "discard review" },
      add_review_comment      = { lhs = "<leader>ga",   desc = "add a new review comment", mode = { "n", "x" } },
      add_review_suggestion   = { lhs = "<leader>gv",   desc = "add a new review suggestion", mode = { "n", "x" } },
      focus_files             = { lhs = "<leader>ge",   desc = "move focus to changed file panel" },
      toggle_files            = { lhs = "<leader>gb",   desc = "hide/show changed files panel" },
      next_thread             = { lhs = "]t",           desc = "move to next thread" },
      prev_thread             = { lhs = "[t",           desc = "move to previous thread" },
      select_next_entry       = { lhs = "]q",           desc = "move to next changed file" },
      select_prev_entry       = { lhs = "[q",           desc = "move to previous changed file" },
      select_first_entry      = { lhs = "[Q",           desc = "move to first changed file" },
      select_last_entry       = { lhs = "]Q",           desc = "move to last changed file" },
      close_review_tab        = { lhs = "<leader>gq",   desc = "close review tab" },
      toggle_viewed           = { lhs = "<leader>g<space>", desc = "toggle viewer viewed state" },
      goto_file               = { lhs = "<leader>gf",   desc = "go to file" },
    },
    file_panel = {
      submit_review           = { lhs = "<leader>gS",   desc = "submit review" },
      discard_review          = { lhs = "<leader>gD",   desc = "discard review" },
      next_entry              = { lhs = "j",             desc = "move to next changed file" },
      prev_entry              = { lhs = "k",             desc = "move to previous changed file" },
      select_entry            = { lhs = "<cr>",          desc = "show selected changed file diffs" },
      refresh_files           = { lhs = "R",             desc = "refresh changed files panel" },
      focus_files             = { lhs = "<leader>ge",    desc = "move focus to changed file panel" },
      toggle_files            = { lhs = "<leader>gb",    desc = "hide/show changed files panel" },
      select_next_entry       = { lhs = "]q",            desc = "move to next changed file" },
      select_prev_entry       = { lhs = "[q",            desc = "move to previous changed file" },
      select_first_entry      = { lhs = "[Q",            desc = "move to first changed file" },
      select_last_entry       = { lhs = "]Q",            desc = "move to last changed file" },
      close_review_tab        = { lhs = "<leader>gq",    desc = "close review tab" },
      toggle_viewed           = { lhs = "<leader>g<space>", desc = "toggle viewer viewed state" },
    },
  },
})


local orig_apply = require("octo.utils").apply_mappings
require("octo.utils").apply_mappings = function(kind, bufnr)
  orig_apply(kind, bufnr)
  if kind == "submit_win" then
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = bufnr,
      callback = function()
        local reviews = require("octo.reviews")
        local current_review = reviews.get_current_review()
        if current_review then
          current_review:submit("COMMENT")
        end
      end,
    })
  end
  if kind == "review_thread" then
    vim.keymap.set("c", "<CR>", function()
      local cmd = vim.fn.getcmdline()
      if cmd:match("^q!?$") or cmd:match("^wq!?$") then
        local has_w = cmd:match("^w")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u><Esc>", true, false, true), "n", false)
        vim.schedule(function()
          if has_w then
            vim.cmd("w")
          end
          local key = vim.api.nvim_replace_termcodes("q", true, false, true)
          vim.api.nvim_feedkeys(key, "m", false)
        end)
        return ""
      end
      return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
    end, { buffer = bufnr, expr = true })
  end
end

local function auto_submit_and_restart(review)
  local gh = require("octo.gh")
  local graphql = require("octo.gh.graphql")
  local utils = require("octo.utils")

  local review_id = review.id
  if review_id == -1 then return end

  local query = graphql("submit_pull_request_review_mutation", review_id, "COMMENT", "", { escape = false })
  gh.run {
    args = { "api", "graphql", "-f", string.format("query=%s", query) },
    cb = function(output, stderr)
      if stderr and not utils.is_blank(stderr) then
        utils.error(stderr)
        return
      end
      utils.info "Comment posted!"
      local create_query = graphql("start_review_mutation", review.pull_request.id)
      gh.run {
        args = { "api", "graphql", "-f", string.format("query=%s", create_query) },
        cb = function(create_output, create_stderr)
          if create_stderr and not utils.is_blank(create_stderr) then
            return
          end
          local resp = vim.json.decode(create_output)
          review.id = resp.data.addPullRequestReview.pullRequestReview.id
          local threads = resp.data.addPullRequestReview.pullRequestReview.pullRequest.reviewThreads.nodes
          review:update_threads(threads)
        end,
      }
    end,
  }
end

local OctoBuffer = require("octo.model.octo-buffer").OctoBuffer

local orig_do_add_new_thread = OctoBuffer.do_add_new_thread
OctoBuffer.do_add_new_thread = function(self, comment_metadata)
  local orig_cb_creator = require("octo.gh").create_callback
  local reviews = require("octo.reviews")

  local patched = false
  require("octo.gh").create_callback = function(opts)
    if not patched then
      patched = true
      local orig_success = opts.success
      opts.success = function(output)
        orig_success(output)
        vim.schedule(function()
          local current_review = reviews.get_current_review()
          if current_review and current_review.id ~= -1 then
            auto_submit_and_restart(current_review)
          end
        end)
      end
    end
    return orig_cb_creator(opts)
  end

  orig_do_add_new_thread(self, comment_metadata)
  require("octo.gh").create_callback = orig_cb_creator
end

local orig_do_add_thread_comment = OctoBuffer.do_add_thread_comment
OctoBuffer.do_add_thread_comment = function(self, comment_metadata)
  local gh = require("octo.gh")
  local reviews = require("octo.reviews")
  local orig_run = gh.run

  gh.run = function(opts)
    local orig_cb = opts.cb
    opts.cb = function(output, stderr)
      orig_cb(output, stderr)
      if not stderr or require("octo.utils").is_blank(stderr) then
        vim.schedule(function()
          local current_review = reviews.get_current_review()
          if current_review and current_review.id ~= -1 then
            auto_submit_and_restart(current_review)
          end
        end)
      end
    end
    return orig_run(opts)
  end

  orig_do_add_thread_comment(self, comment_metadata)
  gh.run = orig_run
end

local mappings = require("octo.mappings")

local function with_confirm(msg, fn)
  return function()
    vim.ui.select({ "Yes", "No" }, { prompt = msg }, function(choice)
      if choice == "Yes" then fn() end
    end)
  end
end

local function with_loading(msg, fn)
  return function()
    vim.notify(msg, vim.log.levels.INFO, { title = "Octo" })
    fn()
  end
end

local function with_confirm_and_loading(confirm_msg, loading_msg, fn)
  return function()
    vim.ui.select({ "Yes", "No" }, { prompt = confirm_msg }, function(choice)
      if choice == "Yes" then
        vim.notify(loading_msg, vim.log.levels.INFO, { title = "Octo" })
        fn()
      end
    end)
  end
end

local orig_merge = mappings.merge_pr
mappings.merge_pr = with_confirm_and_loading("Merge this PR?", "Merging...", orig_merge)

local orig_squash = mappings.squash_and_merge_pr
mappings.squash_and_merge_pr = with_confirm_and_loading("Squash and merge this PR?", "Squash merging...", orig_squash)

local orig_rebase = mappings.rebase_and_merge_pr
mappings.rebase_and_merge_pr = with_confirm_and_loading("Rebase and merge this PR?", "Rebase merging...", orig_rebase)

local orig_close = mappings.close_issue
mappings.close_issue = with_confirm("Close this?", orig_close)

local orig_delete_comment = mappings.delete_comment
mappings.delete_comment = with_confirm("Delete this comment?", orig_delete_comment)

local orig_discard = mappings.discard_review
mappings.discard_review = with_confirm("Discard this review?", orig_discard)

local reviews = require("octo.reviews")
mappings.review_start = with_loading("Starting review...", function()
  reviews.start_or_resume_review()
end)

local orig_checkout = mappings.checkout_pr
mappings.checkout_pr = with_loading("Checking out PR...", orig_checkout)

end })

vim.keymap.set("n", "<leader>gp", "<cmd>Octo pr list<cr>", { desc = "Octo: list PRs" })
vim.keymap.set("n", "<leader>gi", "<cmd>Octo issue list<cr>", { desc = "Octo: list issues" })
vim.keymap.set("n", "<leader>gx", "<cmd>Octo search<cr>", { desc = "Octo: search" })
vim.keymap.set("n", "<leader>gw", "<cmd>Octo actions<cr>", { desc = "Octo: all actions" })

vim.keymap.set("n", "<leader>gP", function()
  local reviews = require("octo.reviews")
  local current_review = reviews.get_current_review()
  if current_review and current_review.pull_request then
    local pr = current_review.pull_request
    local repo = pr.owner .. "/" .. pr.name
    vim.cmd("Octo pr edit " .. repo .. " " .. pr.number)
  else
    vim.cmd("Octo pr list")
  end
end, { desc = "Octo: open current PR summary" })

vim.keymap.set("n", "<leader>g?", function()
  local sections = {
    { title = "GLOBAL", items = {
      { "SPC g?", "this help" },
      { "SPC gp", "list PRs" },
      { "SPC gP", "current PR summary" },
      { "SPC gi", "list issues" },
      { "SPC gx", "search" },
      { "SPC gw", "all actions" },
      { "SPC gl", "open in GitHub" },
    }},
    { title = "COMMENTS (:wq posts)", items = {
      { "SPC ga", "add comment" },
      { "SPC gr", "reply" },
      { "SPC gv", "add suggestion" },
      { "SPC gd", "delete comment" },
      { "SPC gn", "next comment" },
      { "SPC gN", "prev comment" },
    }},
    { title = "REVIEW", items = {
      { "SPC gs", "start/resume review" },
      { "SPC gS", "submit (batch)" },
      { "SPC gD", "discard review" },
      { "SPC gt", "resolve thread" },
      { "SPC gT", "unresolve thread" },
    }},
    { title = "PR / ISSUE", items = {
      { "SPC gc", "close" },
      { "SPC go", "reopen" },
      { "SPC gk", "checkout PR" },
      { "SPC gm", "merge PR" },
      { "SPC gMs", "squash merge" },
      { "SPC gMr", "rebase merge" },
      { "SPC gf", "goto file" },
      { "SPC gj", "goto issue" },
    }},
    { title = "NAVIGATION", items = {
      { "SPC ge", "focus file panel" },
      { "SPC gb", "toggle file panel" },
      { "SPC gq", "close review tab" },
      { "SPC g ", "toggle viewed" },
      { "]q/[q", "next/prev file" },
      { "]t/[t", "next/prev thread" },
    }},
    { title = "META", items = {
      { "SPC gaa", "add assignee" },
      { "SPC gad", "rm assignee" },
      { "SPC gla", "add label" },
      { "SPC gld", "rm label" },
      { "SPC gva", "add reviewer" },
      { "SPC gvd", "rm reviewer" },
      { "SPC gpd", "show PR diff" },
      { "SPC gpc", "list PR commits" },
      { "SPC gpf", "list PR files" },
    }},
    { title = "REACTIONS", items = {
      { "SPC g+", "thumbs up" },
      { "SPC g-", "thumbs down" },
      { "SPC g1", "hooray" },
      { "SPC g2", "heart" },
      { "SPC g3", "eyes" },
      { "SPC g4", "rocket" },
    }},
    { title = "SUBMIT WINDOW", items = {
      { "C-a", "approve" },
      { "C-m", "comment" },
      { "C-r", "request changes" },
      { "C-c", "close" },
      { "C-b", "open in browser" },
      { "C-y", "copy url" },
    }},
  }

  local col_width = 28
  local avail_width = math.floor(vim.o.columns * 0.85)
  local num_cols = math.max(2, math.floor(avail_width / col_width))
  local actual_col_w = math.floor(avail_width / num_cols)

  local columns = {}
  for i = 1, num_cols do columns[i] = {} end

  local col_heights = {}
  for i = 1, num_cols do col_heights[i] = 0 end

  for _, sec in ipairs(sections) do
    local sec_height = 1 + #sec.items + 1

    local shortest_col = 1
    for i = 2, num_cols do
      if col_heights[i] < col_heights[shortest_col] then shortest_col = i end
    end

    table.insert(columns[shortest_col], sec)
    col_heights[shortest_col] = col_heights[shortest_col] + sec_height
  end

  local max_height = 0
  for i = 1, num_cols do
    if col_heights[i] > max_height then max_height = col_heights[i] end
  end

  local col_lines = {}
  local col_hls = {}
  for c = 1, num_cols do
    col_lines[c] = {}
    col_hls[c] = {}
    for _, sec in ipairs(columns[c]) do
      table.insert(col_lines[c], { text = " " .. sec.title, hl = "Title" })
      for _, item in ipairs(sec.items) do
        table.insert(col_lines[c], { text = string.format("  %-9s %s", item[1], item[2]) })
      end
      table.insert(col_lines[c], { text = "" })
    end
  end

  local content = {}
  local highlights = {}
  local total_width = actual_col_w * num_cols
  local sep = " \u{2502} "

  for row = 1, max_height do
    local parts = {}
    for c = 1, num_cols do
      local entry = col_lines[c][row]
      local text = entry and entry.text or ""
      local padded = text .. string.rep(" ", actual_col_w - #text - (#sep - 1))
      if #padded > actual_col_w - (#sep - 1) then
        padded = padded:sub(1, actual_col_w - (#sep - 1))
      end
      parts[c] = padded
    end
    local line = table.concat(parts, sep)
    table.insert(content, line)

    local offset = 0
    for c = 1, num_cols do
      local entry = col_lines[c][row]
      if entry and entry.hl then
        table.insert(highlights, { line = #content - 1, col_start = offset, col_end = offset + actual_col_w, group = entry.hl })
      end
      offset = offset + actual_col_w + #sep
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = total_width
  local height = math.min(max_height, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Octo (SPC g) ",
    title_pos = "center",
  })

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl.group, hl.line, hl.col_start, hl.col_end)
  end

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<leader>g?", "<cmd>close<cr>", { buffer = buf })
end, { desc = "Octo: show keybinding help" })
