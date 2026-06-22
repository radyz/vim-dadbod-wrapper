--- SQL parser module modernized for Neovim 0.12+
-- @module parser

local M = {}

local effectful_statements_query = [[
  (keyword_insert) @insert
  (keyword_update) @update
  (keyword_delete) @delete
  (keyword_drop) @drop
  (keyword_create) @create
  (keyword_alter) @alter
  (keyword_truncate) @truncate
]]

--- Gets effectful query statements.
--- @param bufnr number
--- @param range table|nil (Optional) Query range to parse containing start_line and end_line.
--- @return table<number, string> statements Statements with side effects.
M.list_effectful_statements = function(bufnr, range)
  -- 1. Use the core native vim.treesitter API directly
  if not vim.treesitter then
    return {}
  end

  -- 2. Wrap parser generation in a pcall to gracefully handle missing parsers
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "sql")
  if not ok or not parser then
    return {}
  end

  -- 3. Modern way to safely fetch the root node of the syntax tree
  local tree = parser:parse()[1]
  if not tree then
    return {}
  end
  local root = tree:root()

  local result = {}
  local query = vim.treesitter.query.parse("sql", effectful_statements_query)

  -- Convert 1-indexed editor lines to 0-indexed API rows
  local start_row = range and (range.start_line - 1) or 0
  local end_row = range and range.end_line or -1

  for id, node in query:iter_captures(root, bufnr, start_row, end_row) do
    local capture_name = query.captures[id]:upper()

    -- 4. Native replacement for ts_utils.get_vim_range
    -- node:range() returns: start_row, start_col, end_row, end_col (all 0-indexed)
    local start_line = node:range()
    local vim_row = start_line + 1 -- Convert back to 1-indexed line for the editor UI

    table.insert(result, string.format("- %s on L%d", capture_name, vim_row))
  end

  return result
end

return M
