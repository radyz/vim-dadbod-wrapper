-- main module file
local connection_manager = require("vim-dadbod-wrapper.connection-manager")

---@class VimDadbodWrapper
local M = {}

---@class VimDadbodWrapperOptions
---@field env_prefix string Environment prefix to load connections.

--- Sets up plugin.
--- @param opts VimDadbodWrapperOptions|nil (Optional) Plugin opts.
M.setup = function(opts)
  opts = opts or {}

  connection_manager.load_from_env(opts.env_prefix)
end

return M
