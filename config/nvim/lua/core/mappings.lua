local M = {}

vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<S-h>', '^', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<S-l>', '$', { noremap = true })

vim.keymap.set('n', 'x', '"_x', { noremap = true })

vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })

-- <ESC> key handling using User autocmd pattern
-- This approach allows multiple plugins/configs to register their own <ESC> handlers
-- without mapping conflicts, regardless of load order (e.g., lazy-loaded plugins).

-- Register a handler for the <ESC> key in normal mode
-- This uses the User autocmd pattern 'EscPressed' to allow multiple handlers
-- without mapping conflicts. Handlers are executed when <ESC> is pressed.
--
---@param callback function: The function to call when <ESC> is pressed
---@param opts table: Optional configuration
--   - group string|number: augroup name or id (default: creates unique group)
--   - desc string: Description for the autocmd
function M.on_esc(callback, opts)
  opts = opts or {}
  local group = opts.group or vim.api.nvim_create_augroup('OnEsc_' .. vim.fn.rand(), { clear = true })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'EscPressed',
    callback = callback,
    desc = opts.desc,
  })
end

-- Trigger User EscPressed event
vim.keymap.set('n', '<ESC>', function()
  vim.api.nvim_exec_autocmds('User', { pattern = 'EscPressed' })
end, { noremap = true })

-- User autocmd handler for nohlsearch
-- Note: :nohlsearch doesn't work directly in autocmd because the highlighting state
-- is saved and restored when executing autocommands. We use vim.schedule() to execute
-- it after the autocmd completes, outside of the state save/restore mechanism.
M.on_esc(function()
  vim.schedule(function()
    vim.cmd('nohlsearch')
  end)
end, { desc = 'Clear search highlight' })

vim.keymap.set('n', '<C-z>', '<Nop>', { noremap = true })

vim.keymap.set('c', '<C-p>', '<Up>', { noremap = true })
vim.keymap.set('c', '<C-n>', '<Down>', { noremap = true })

vim.keymap.set('i', '<C-j>', '<Nop>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Nop>', { noremap = true })

vim.keymap.set({ 'n', 'v' }, 'Q', 'q', { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'q', '<Nop>', { noremap = true })

vim.keymap.set({ 'n', 'v' }, ';', ':', { noremap = true })
vim.keymap.set({ 'n', 'v' }, ':', ';', { noremap = true })

return M
