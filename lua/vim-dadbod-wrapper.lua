-- main module file
local connection_manager = require("vim-dadbod-wrapper.connection-manager")

---@class VimDadbodWrapper
local M = {}

M.setup = function(_)
  -- TODO: Add support for custom prefix
  connection_manager.load_from_env("DADBOD_")

  vim.api.nvim_create_user_command("DBLoadSecret", function(opts)
    connection_manager.load_from_keychain(opts.fargs[1])
  end, {
    nargs = 1,
    desc = "Load DB connections from keychain",
  })

  vim.api.nvim_create_user_command("DBExec", function(opts)
    ---@type QueryRange|nil
    local range = nil
    if opts.range > 0 then
      range = { start_line = opts.line1, end_line = opts.line2 }
    end

    connection_manager.exec(opts.fargs[1], vim.api.nvim_get_current_buf(), range)
  end, {
    nargs = 1,
    range = true,
    desc = "Execute query for DB connection",
    complete = function()
      return connection_manager.list()
    end,
  })
end

return M
