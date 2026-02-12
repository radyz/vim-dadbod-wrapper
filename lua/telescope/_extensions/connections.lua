local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local connections = require("vim-dadbod-wrapper.connection-manager")
local parser = require("vim-dadbod-wrapper.utils.parser")

return function(opts)
  opts = opts or {}

  local range = nil
  local current_bufnr = vim.api.nvim_get_current_buf()

  -- If we are in visual mode, exit it to sync the '< and '> marks
  local mode = vim.api.nvim_get_mode().mode
  if mode:find("[vV\22]") then
    -- This sends <Esc> and waits for the editor to process it
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    -- At this point it's safe to grab the start and end positions of the selection.
    range = {
      start_line = vim.api.nvim_buf_get_mark(current_bufnr, "<")[1],
      end_line = vim.api.nvim_buf_get_mark(current_bufnr, ">")[1],
    }
  end

  pickers
    .new(opts, {
      prompt_title = "dadbod connections",
      finder = finders.new_table({
        results = connections.list(),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = action_state.get_selected_entry()[1]
          if not selection or selection == "" then
            return
          end

          local can_execute = 1

          local effectful_statements = parser.list_effectful_statements(current_bufnr, range)

          if #effectful_statements > 0 then
            local message = string.format(
              "Database state modifications detected:\n%s\n\nProceed?",
              table.concat(effectful_statements, "\n")
            )
            can_execute = vim.fn.confirm(message, "&Yes\n&No")
          end

          if can_execute == 1 then
            connections.exec(selection, current_bufnr, range)
          end
        end)

        return true
      end,
    })
    :find()
end
