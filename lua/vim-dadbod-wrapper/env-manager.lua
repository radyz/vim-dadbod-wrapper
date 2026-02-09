--- Env manager functions
-- @module env_manager
local M = {}

--- Scans environment variables and returns a map of connections.
--- @param prefix string|nil (Optional) The prefix to search for. Defaults to "DADBOD_".
--- @return table<string, string> connections A table of connections and their corresponding values.
M.load = function(prefix)
  local opts = {
    prefix = prefix or "DADBOD_",
  }

  local connections = {}

  for key, value in pairs(vim.fn.environ()) do
    if key:find("^" .. opts.prefix) then
      local clean_name = key:sub(#opts.prefix + 1)

      connections[clean_name] = value
    end
  end

  return connections
end

return M
