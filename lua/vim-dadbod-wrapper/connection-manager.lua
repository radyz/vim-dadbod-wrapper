local keychain_access = require("vim-dadbod-wrapper.utils.keychain-access")

--- Connection manager
-- @module env_manager
local M = {}

--- @type table<string, string>
local connections = {}

---@class ConnectionStatistics
---@field usage number The number of times used.
---@field used_at number Timestamp of the last time it was used.

--- @type table<string, ConnectionStatistics>
local connections_statistics = {}

--- Loads connections from environment variables.
--- Expected format in environment variable:
--- <prefix>CONNECTION_NAME=CONNECTION_URL
--- @param prefix string|nil (Optional) The prefix to search for. Defaults to "DADBOD_".
M.load_from_env = function(prefix)
  local opts = {
    prefix = prefix or "DADBOD_",
  }

  for key, value in pairs(vim.fn.environ()) do
    if key:find("^" .. opts.prefix) then
      local clean_name = key:sub(#opts.prefix + 1)

      M.add(clean_name, value)
    end
  end
end

--- Loads secrets from keychain and parses them from CSV format into a table.
--- Expected format in Keychain:
--- connection_name,connection_url
--- @param keychain_label string
M.load_from_keychain = function(keychain_label)
  local raw_secret = keychain_access.find_generic_password(keychain_label)
  if not raw_secret then
    vim.notify("Secret from keychain access is unavailable", vim.log.levels.WARN)
    return
  end

  -- %f[^\n]%s* matches lines while ignoring leading/trailing whitespace
  for line in raw_secret:gmatch("[^\r\n]+") do
    -- Split by the first comma found
    local key, value = line:match("([^,]+),(.+)")

    if key and value then
      M.add(key, value)
    end
  end
end

--- Lists all connection names.
--- Connections are sorted from most relevant to least.
M.list = function()
  if next(connections_statistics) == nil then
    return {}
  end

  local statistics = {}
  local most_recently_used = 0
  local most_recently_used_connection = ""

  -- Flatten the statistics table to perform sorting on usage.
  for connection, stats in pairs(connections_statistics) do
    table.insert(statistics, {
      connection = connection,
      usage = stats.usage,
      used_at = stats.used_at,
    })

    if stats.used_at > most_recently_used then
      most_recently_used = stats.used_at
      most_recently_used_connection = connection
    end
  end

  table.sort(statistics, function(a, b)
    if a.usage ~= b.usage then
      return a.usage > b.usage
    end

    return a.connection < b.connection
  end)

  local result = {}
  table.insert(result, most_recently_used_connection)
  for _, stats in ipairs(statistics) do
    if stats.connection ~= most_recently_used_connection then
      table.insert(result, stats.connection)
    end
  end

  return result
end

---@alias QueryRange { start_line: number, end_line: number }

--- Gets a connection.
--- @param connection string
--- @param bufnr number Which buffer to run the connection on.
--- @param range QueryRange|nil (Optional) Query range to execute.
M.exec = function(connection, bufnr, range)
  local connection_url = connections[connection]
  if not connection_url or connection_url == "" then
    vim.notify("Connection is not registered", vim.log.levels.WARN)
    return
  end

  local stats = connections_statistics[connection]
  if stats then
    stats.usage = stats.usage + 1
    stats.used_at = os.time()
  end

  local command = string.format(":DB %s < %%", connection_url)
  if range then
    command = string.format(":%d,%dDB %s", range.start_line, range.end_line, connection_url)
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd(command)
  end)
end

--- Adds a new connection.
--- Connections with the same name will be overwritten.
--- @param connection string
--- @param url string
M.add = function(connection, url)
  if not connection or connection == "" or not url or url == "" then
    return
  end

  local connection_name = connection:lower()
  connections[connection_name] = url
  connections_statistics[connection_name] = {
    usage = 0,
    used_at = os.time(),
  }
end

return M
