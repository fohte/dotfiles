local function remove_dup_lines()
  if vim.fn.line('$') <= 1 then
    return
  end

  local cursor_pos = vim.fn.getpos('.')

  while vim.fn.getline(1) == '' do
    vim.cmd('1delete_')
  end

  while vim.fn.getline('$') == '' do
    vim.cmd('$delete_')
  end

  vim.fn.setpos('.', cursor_pos)
end

vim.api.nvim_create_user_command('RemoveDupLines', remove_dup_lines, {})

vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'MyAutoCmd',
  callback = remove_dup_lines,
})

vim.api.nvim_create_autocmd('VimResized', {
  group = 'MyAutoCmd',
  callback = function()
    vim.cmd('wincmd =')
  end,
})

vim.api.nvim_create_user_command('VimShowHlGroup', function()
  local hl_group = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.synID(vim.fn.line('.'), vim.fn.col('.'), 1)), 'name')

  print(hl_group)
end, {})

require('core.commands.git_remote')
