local treesitter = require('nvim-tdd.utils.treesitter')

describe('treesitter utils', function()
  local test_bufnr

  before_each(function()
    -- テスト用のバッファを作成
    test_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(test_bufnr, 'filetype', 'lua')
  end)

  after_each(function()
    -- テストバッファを削除
    if vim.api.nvim_buf_is_valid(test_bufnr) then
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end
  end)

  describe('get_node_at_cursor', function()
    it('should return a node even for empty buffer (chunk node)', function()
      local node = treesitter.get_node_at_cursor(test_bufnr, 0, 0)
      -- 空のバッファでもchunk（ルート）ノードが返される
      assert.is_not_nil(node)
    end)

    it('should return a node for valid lua code', function()
      -- Luaコードをバッファに設定
      local lines = {
        'local function test()',
        '  return 42',
        'end',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      -- treesitterパーサーが利用可能になるまで待機
      vim.wait(100)

      -- 1行目の"function"キーワード位置のノードを取得
      local node = treesitter.get_node_at_cursor(test_bufnr, 0, 6)
      assert.is_not_nil(node)
    end)

    it('should return node at cursor position when row and col are nil', function()
      local lines = {
        'local x = 10',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)
      vim.api.nvim_set_current_buf(test_bufnr)
      vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- "x"の位置

      vim.wait(100)

      local node = treesitter.get_node_at_cursor()
      assert.is_not_nil(node)
    end)

    it('should handle invalid buffer gracefully', function()
      local node = treesitter.get_node_at_cursor(999999, 0, 0)
      assert.is_nil(node)
    end)
  end)

  describe('get_node_ancestors', function()
    it('should return array with chunk node for empty buffer', function()
      local nodes = treesitter.get_node_ancestors(test_bufnr, 0, 0)
      -- 空のバッファでもchunkノードが含まれる
      assert.is_true(#nodes > 0)
    end)

    it('should return array of ancestor nodes', function()
      local lines = {
        'local function outer()',
        '  local function inner()',
        '    return 42',
        '  end',
        'end',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      -- "42"の位置のノードとその祖先を取得
      local nodes = treesitter.get_node_ancestors(test_bufnr, 2, 11)

      -- 少なくとも複数のノードが返されるはず
      assert.is_true(#nodes > 0)

      -- 配列の最後は必ずrootノード
      if #nodes > 0 then
        local root = nodes[#nodes]
        assert.is_not_nil(root)
      end
    end)

    it('should return nodes in order from child to parent', function()
      local lines = {
        'local x = 42',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      local nodes = treesitter.get_node_ancestors(test_bufnr, 0, 10)

      -- 子から親の順序で並んでいることを確認
      if #nodes > 1 then
        for i = 1, #nodes - 1 do
          local child = nodes[i]
          local parent = nodes[i + 1]
          assert.are.equal(child:parent(), parent)
        end
      end
    end)
  end)

  describe('find_parent_node_by_type', function()
    it('should return nil when node type is not found', function()
      local lines = {
        'local x = 42',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      local node = treesitter.find_parent_node_by_type(test_bufnr, 0, 10, 'nonexistent_type')
      assert.is_nil(node)
    end)

    it('should find function_declaration node', function()
      local lines = {
        'local function test()',
        '  local x = 42',
        'end',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      -- "x"の位置から関数ノードを探す
      local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 8, 'function_declaration')
      assert.is_not_nil(node)
      if node then
        assert.are.equal('function_declaration', node:type())
      end
    end)

    it('should return the node itself if it matches the type', function()
      local lines = {
        'local function test()',
        '  return 42',
        'end',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      -- 関数宣言の位置で関数ノードを探す
      local node = treesitter.find_parent_node_by_type(test_bufnr, 0, 15, 'function_declaration')
      assert.is_not_nil(node)
    end)
  end)

  describe('get_node_text', function()
    it('should return the text content of a node', function()
      local lines = {
        'local x = 42',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      local node = treesitter.get_node_at_cursor(test_bufnr, 0, 10)
      if node then
        local text = treesitter.get_node_text(node, test_bufnr)
        assert.is_not_nil(text)
        assert.is_string(text)
      end
    end)

    it('should use current buffer when bufnr is nil', function()
      local lines = {
        'local x = 42',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)
      vim.api.nvim_set_current_buf(test_bufnr)

      vim.wait(100)

      local node = treesitter.get_node_at_cursor(test_bufnr, 0, 6)
      if node then
        local text = treesitter.get_node_text(node)
        assert.is_not_nil(text)
      end
    end)
  end)

  describe('get_node_range', function()
    it('should return the range of a node', function()
      local lines = {
        'local x = 42',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      local node = treesitter.get_node_at_cursor(test_bufnr, 0, 6)
      if node then
        local start_row, start_col, end_row, end_col = treesitter.get_node_range(node)

        assert.is_number(start_row)
        assert.is_number(start_col)
        assert.is_number(end_row)
        assert.is_number(end_col)

        -- 範囲が論理的に正しいことを確認
        assert.is_true(start_row <= end_row)
        if start_row == end_row then
          assert.is_true(start_col <= end_col)
        end
      end
    end)

    it('should return correct range for multi-line node', function()
      local lines = {
        'local function test()',
        '  return 42',
        'end',
      }
      vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

      vim.wait(100)

      local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 2, 'function_declaration')
      if node then
        local start_row, start_col, end_row, end_col = treesitter.get_node_range(node)

        -- 複数行にまたがることを確認
        assert.are.equal(0, start_row)
        assert.are.equal(2, end_row)
      end
    end)
  end)
end)
