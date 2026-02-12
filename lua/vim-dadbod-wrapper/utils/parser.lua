local _, ts = pcall(require, "vim.treesitter")
local _, ts_utils = pcall(require, "nvim-treesitter.ts_utils")

--- SQL parser module.
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
--- @param range QueryRange|nil (Optional) Query range to parse.
--- @return table<number, string> statements Statements with side effects.
M.list_effectful_statements = function(bufnr, range)
  if not ts or not ts_utils then
    return {}
  end

  local parser = ts.get_parser(bufnr, "sql")
  local root = parser:parse()[1]:root()

  local result = {}
  local query = vim.treesitter.query.parse("sql", effectful_statements_query)

  local start_row = range and (range.start_line - 1) or 0
  local end_row = range and range.end_line or -1

  for id, node in query:iter_captures(root, bufnr, start_row, end_row) do
    local capture_name = query.captures[id]:upper()
    local row = ts_utils.get_vim_range({ node:range() }, bufnr)

    table.insert(result, string.format("- %s on L%d", capture_name, row))
  end

  return result
end

return M
