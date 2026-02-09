--- Secret manager functions
-- @module secret_manager
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

--- Loads secrets from keychain and parses them from CSV format into a table.
--- Expected format in Keychain:
--- user_one,password1
--- user_two,password2
--- @param keychain_label string
--- @return table<string, string>|nil secrets A table of user=password pairs or nil on error.
M.load = function(keychain_label)
  local cmd = string.format('security find-generic-password -s "%s" -g 2>&1', keychain_label)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil
  end

  local raw_secret = parse_keychain_output(result)
  if not raw_secret or raw_secret == "" then
    return nil
  end

  local secrets = {}
  -- %f[^\n]%s* matches lines while ignoring leading/trailing whitespace
  for line in raw_secret:gmatch("[^\r\n]+") do
    -- Split by the first comma found
    local key, value = line:match("([^,]+),(.+)")

    if key and value then
      -- Clean up any accidental whitespace around the values
      secrets[key:gsub("%s+", "")] = value:gsub("%s+", "")
    end
  end

  if next(secrets) == nil then
    return nil
  end

  return secrets
end

return M
