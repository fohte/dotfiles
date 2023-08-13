vim.keymap.set({'n', 'i', 'v'}, 'j', 'gj', { noremap = true })
vim.keymap.set({'n', 'i', 'v'}, 'k', 'gk', { noremap = true })
vim.keymap.set({'n', 'i', 'v'}, '<S-h>', '^', { noremap = true })
vim.keymap.set({'n', 'i', 'v'}, '<S-l>', '$', { noremap = true })

vim.keymap.set('n', 'x', '"_x', { noremap = true })

vim.keymap.set('v', '>', '>gv', { noremap = true })
vim.keymap.set('v', '<', '<gv', { noremap = true })

vim.keymap.set('n', '<ESC>', ':nohlsearch<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-z>', '<Nop>', { noremap = true })

vim.keymap.set('c', '<C-p>', '<Up>', { noremap = true })
vim.keymap.set('c', '<C-n>', '<Down>', { noremap = true })

vim.keymap.set('i', '<C-j>', '<Nop>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Nop>', { noremap = true })

vim.keymap.set({'n', 'i', 'v'}, 'Q', 'q', { noremap = true })
