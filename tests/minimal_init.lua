-- Minimal init.lua for testing

-- プラグインのパスを追加
local plenary_dir = vim.fn.stdpath('data') .. '/site/pack/vendor/start/plenary.nvim'

-- plenary.nvimをインストール
if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth=1',
    'https://github.com/nvim-lua/plenary.nvim.git',
    plenary_dir,
  })
end

-- runtimepathに追加
vim.opt.runtimepath:append('.')
vim.opt.runtimepath:append(plenary_dir)

-- プラグインを読み込み
vim.cmd('runtime! plugin/**/*.lua')
vim.cmd('runtime! plugin/**/*.vim')

-- treesitterの設定
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/site/pack/vendor/start/nvim-treesitter')
