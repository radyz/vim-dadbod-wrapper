--- Keychain Access facade.
-- @module keychain-access
local M = {}

--- Extract password generically from security -g output
--- @param output string
--- @return string|nil
local function parse_keychain_output(output)
  -- 1. Use a pattern that finds 'password:' anywhere in the string.
  -- %s* matches any spaces.
  -- (0x%x*%s*)? optionally matches the hex blob.
  -- "(.-)" matches the shortest possible string inside quotes (non-greedy).
  local _, secret = output:match('password:%s*(0x%x*%s*)"(.-)"')

  -- Fallback if there is no hex blob and the match above failed
  if not secret then
    secret = output:match('password:%s*"(.-)"')
  end

  if not secret then
    return nil
  end

  -- 2. Convert octal escapes (\012 -> newline)
  -- This is critical because macOS encodes control chars in -g output.
  return secret:gsub("\\(%d%d%d)", function(octal)
    return string.char(tonumber(octal, 8))
  end)
end

--- Gets secret from keychain.
--- @param keychain_label string
--- @return string|nil secret
M.find_generic_password = function(keychain_label)
  local cmd = string.format('security find-generic-password -s "%s" -g 2>&1', keychain_label)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  local raw_secret = parse_keychain_output(result)
  if not raw_secret or raw_secret == "" then
    return nil
  end

  return raw_secret
end

return M
