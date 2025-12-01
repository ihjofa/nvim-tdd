local treesitter = require('nvim-tdd.utils.treesitter')

describe('is_node_implemented', function()
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

  it('should return false for nil node', function()
    local is_implemented = treesitter.is_node_implemented(nil, test_bufnr)
    assert.is_false(is_implemented)
  end)

  it('should return true for implemented function', function()
    local lines = {
      'local function test()',
      '  return 42',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_true(is_implemented)
  end)

  it('should return false for empty function', function()
    local lines = {
      'local function test()',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 0, 15, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_false(is_implemented)
  end)

  it('should return false for function with only whitespace', function()
    local lines = {
      'local function test()',
      '  ',
      '  ',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_false(is_implemented)
  end)

  it('should return false for function with only comments', function()
    local lines = {
      'local function test()',
      '  -- TODO: implement this',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_false(is_implemented)
  end)

  it('should return true for function with code and comments', function()
    local lines = {
      'local function test()',
      '  -- calculate result',
      '  return 42',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 2, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_true(is_implemented)
  end)

  it('should return true for multi-line implementation', function()
    local lines = {
      'local function test()',
      '  local x = 10',
      '  local y = 20',
      '  return x + y',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 2, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node, test_bufnr)
    assert.is_true(is_implemented)
  end)

  it('should use current buffer when bufnr is nil', function()
    local lines = {
      'local function test()',
      '  return 42',
      'end',
    }
    vim.api.nvim_buf_set_lines(test_bufnr, 0, -1, false, lines)
    vim.api.nvim_set_current_buf(test_bufnr)

    vim.wait(100)

    local node = treesitter.find_parent_node_by_type(test_bufnr, 1, 2, 'function_declaration')
    assert.is_not_nil(node)

    local is_implemented = treesitter.is_node_implemented(node)
    assert.is_true(is_implemented)
  end)
end)
