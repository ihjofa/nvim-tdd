local M = {}

---カーソル位置のTreesitterノードを取得する
---@param bufnr number|nil バッファ番号 (nilの場合は現在のバッファ)
---@param row number|nil 行番号 (0-indexed, nilの場合は現在のカーソル行)
---@param col number|nil 列番号 (0-indexed, nilの場合は現在のカーソル列)
---@return TSNode|nil node カーソル位置のノード
function M.get_node_at_cursor(bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- バッファが有効かチェック
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  -- カーソル位置を取得
  if not row or not col then
    local cursor = vim.api.nvim_win_get_cursor(0)
    row = row or (cursor[1] - 1) -- 1-indexed to 0-indexed
    col = col or cursor[2]
  end

  -- treesitterのパーサーを取得
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil
  end

  -- 構文木を取得
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil
  end

  local tree = trees[1]
  if not tree then
    return nil
  end

  local root = tree:root()

  -- カーソル位置のノードを取得
  return root:named_descendant_for_range(row, col, row, col)
end

---カーソル位置のノードとその親ノードをすべて取得する
---@param bufnr number|nil バッファ番号 (nilの場合は現在のバッファ)
---@param row number|nil 行番号 (0-indexed, nilの場合は現在のカーソル行)
---@param col number|nil 列番号 (0-indexed, nilの場合は現在のカーソル列)
---@return TSNode[] nodes ノードの配列 (子から親の順)
function M.get_node_ancestors(bufnr, row, col)
  local node = M.get_node_at_cursor(bufnr, row, col)
  if not node then
    return {}
  end

  local nodes = {}
  while node do
    table.insert(nodes, node)
    node = node:parent()
  end

  return nodes
end

---指定した型のノードを親方向に検索する
---@param bufnr number|nil バッファ番号
---@param row number|nil 行番号 (0-indexed)
---@param col number|nil 列番号 (0-indexed)
---@param node_type string ノードタイプ (例: "function_declaration", "class_declaration")
---@return TSNode|nil node 見つかったノード
function M.find_parent_node_by_type(bufnr, row, col, node_type)
  local nodes = M.get_node_ancestors(bufnr, row, col)

  for _, node in ipairs(nodes) do
    if node:type() == node_type then
      return node
    end
  end

  return nil
end

---ノードのテキストを取得する
---@param node TSNode ノード
---@param bufnr number|nil バッファ番号 (nilの場合は現在のバッファ)
---@return string text ノードのテキスト
function M.get_node_text(node, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.treesitter.get_node_text(node, bufnr)
end

---ノードの範囲を取得する
---@param node TSNode ノード
---@return number start_row 開始行 (0-indexed)
---@return number start_col 開始列 (0-indexed)
---@return number end_row 終了行 (0-indexed)
---@return number end_col 終了列 (0-indexed)
function M.get_node_range(node)
  return node:range()
end

---ノードが実装済みかどうかを確認する
---@param node TSNode|nil ノード
---@param bufnr number|nil バッファ番号 (nilの場合は現在のバッファ)
---@return boolean is_implemented 実装済みの場合true
function M.is_node_implemented(node, bufnr)
  if not node then
    return false
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- ノードのテキストを取得
  local text = M.get_node_text(node, bufnr)

  -- テキストを行ごとに分割
  local lines = vim.split(text, '\n', { plain = true })

  -- コメントと空白以外の行があるかチェック
  for _, line in ipairs(lines) do
    -- 空白を除去
    local trimmed = line:match('^%s*(.-)%s*$')

    -- 空でない、かつコメントでない行があれば実装済み
    if trimmed ~= '' and not trimmed:match('^%-%-') and not trimmed:match('^local%s+function') and not trimmed:match('^function') and not trimmed:match('^end$') then
      return true
    end
  end

  return false
end

return M
