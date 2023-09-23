vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { noremap = true })
vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<S-h>', '^', { noremap = true })
vim.keymap.set({ 'n', 'v' }, '<S-l>', '$', { noremap = true })

vim.keymap.set('n', 'x', '"_x', { noremap = true })

vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })

vim.keymap.set('n', '<ESC>', ':nohlsearch<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-z>', '<Nop>', { noremap = true })

vim.keymap.set('c', '<C-p>', '<Up>', { noremap = true })
vim.keymap.set('c', '<C-n>', '<Down>', { noremap = true })

vim.keymap.set('i', '<C-j>', '<Nop>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Nop>', { noremap = true })

vim.keymap.set({ 'n', 'v' }, 'Q', 'q', { noremap = true })

vim.keymap.set({ 'n', 'v' }, ';', ':', { noremap = true })
vim.keymap.set({ 'n', 'v' }, ':', ';', { noremap = true })

vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true })

-- LSP
vim.keymap.set('n', 'gd', function()
  vim.lsp.buf.definition()
end, { noremap = true, silent = true })

vim.keymap.set('n', 'gy', function()
  vim.lsp.buf.type_definition()
end, { noremap = true, silent = true })

vim.keymap.set('n', 'gi', function()
  vim.lsp.buf.implementation()
end, { noremap = true, silent = true })

vim.keymap.set('n', 'gr', function()
  vim.lsp.buf.references()
end, { noremap = true, silent = true })

vim.keymap.set('n', '<F9>', function()
  vim.lsp.buf.rename()
end, { noremap = true, silent = true })

vim.keymap.set('n', 'K', function()
  vim.lsp.buf.hover()
end, { noremap = true, silent = true })
