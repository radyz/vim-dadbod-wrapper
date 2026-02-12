local connection_manager = require("vim-dadbod-wrapper.connection-manager")
local parser = require("vim-dadbod-wrapper.utils.parser")

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

  local can_execute = 1
  local bufnr = vim.api.nvim_get_current_buf()

  local effectful_statements = parser.list_effectful_statements(bufnr, range)

  if #effectful_statements > 0 then
    local message =
      string.format("Database state modifications detected:\n%s\n\nProceed?", table.concat(effectful_statements, "\n"))
    can_execute = vim.fn.confirm(message, "&Yes\n&No")
  end

  if can_execute == 1 then
    connection_manager.exec(opts.fargs[1], vim.api.nvim_get_current_buf(), range)
  end
end, {
  nargs = 1,
  range = true,
  desc = "Execute query for DB connection",
  complete = function()
    return connection_manager.list()
  end,
})
