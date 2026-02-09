-- main module file
local secret_manager = require("vim-dadbod-wrapper.secret-manager")
local env_manager = require("vim-dadbod-wrapper.env-manager")

--- @type table<string, string>
local registered_connections = {}

---@class VimDadbodWrapper
local M = {}

M.setup = function(args)
  -- TODO: Add support for custom prefix
  local env_connections = env_manager.load()
  M.register_connections(env_connections)

  vim.api.nvim_create_user_command("DBLoadSecret", function(opts)
    local secret_connections = secret_manager.load(opts.fargs[1])

    if not secret_connections then
      vim.notify(string.format("Secrets unavailable at %s", opts.fargs[1]), vim.log.levels.WARN)
      return
    end

    M.register_connections(secret_connections)
  end, {
    nargs = 1,
    desc = "Load DB connections from keychain",
  })

  vim.api.nvim_create_user_command("DBExec", function(opts)
    local connection = registered_connections[opts.fargs[1]]

    if not connection then
      vim.notify("Usage: :DBExec conn_name", vim.log.levels.ERROR)
      return
    end

    local command = string.format(":DB %s < %%", connection)
    if opts.range > 0 then
      command = string.format(":'<,'>%%DB %s", connection)
    end

    vim.cmd(command)
  end, {
    nargs = 1,
    range = true,
    desc = "Execute query for DB connection",
    complete = function()
      return M.connections()
    end,
  })
end

--- Connections will overwrite existing entries with the same name.
--- @param connections table
M.register_connections = function(connections)
  for name, url in pairs(connections) do
    registered_connections[name:lower()] = url
  end
end

M.connections = function()
  local connections = {}

  if registered_connections then
    for key, _ in pairs(registered_connections) do
      table.insert(connections, key)
    end

    table.sort(connections)
  end

  return connections
end

return M
