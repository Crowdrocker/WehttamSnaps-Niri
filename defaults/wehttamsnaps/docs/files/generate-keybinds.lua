-- generate-keybinds.lua
-- Generates a Markdown cheatsheet of current Neovim keymaps and writes it to:
--   ~/.config/nvim/niri-keybinds-cheatsheet.md  (adjust path if needed)

local output_path = vim.fn.stdpath('config') .. '/niri-keybinds-cheatsheet.md'
local modes = {
  n = 'Normal',
  i = 'Insert',
  v = 'Visual',
  x = 'Visual (x)',
  s = 'Select',
  o = 'Operator-pending',
  c = 'Command',
  t = 'Terminal',
}

local function escape_pipe(str)
  if not str then return '' end
  return str:gsub('|', '\\|'):gsub('\n', '\\n')
end

local lines = {}
table.insert(lines, '# Keybind cheatsheet')
table.insert(lines, '')
table.insert(lines, '*Generated: ' .. os.date('%Y-%m-%d %H:%M:%S') .. '*')
table.insert(lines, '')

for mode, pretty in pairs(modes) do
  local maps = vim.api.nvim_get_keymap(mode)
  if #maps > 0 then
    table.insert(lines, '## ' .. pretty .. ' (' .. mode .. ')')
    table.insert(lines, '')
    table.insert(lines, '| LHS | RHS | Desc | Buffer | Expr | Silent | Script |')
    table.insert(lines, '|-----|-----|------|--------|------|--------|--------|')
    for _, m in ipairs(maps) do
      local lhs = '`' .. escape_pipe(m.lhs) .. '`'
      local rhs = '`' .. escape_pipe(m.rhs) .. '`'
      local desc = m.desc or ''
      local buffer = tostring(m.buffer ~= nil and m.buffer or false)
      local expr = tostring(m.expr and true or false)
      local silent = tostring(m.silent and true or false)
      local script = tostring(m.script and true or false)
      table.insert(lines, string.format('| %s | %s | %s | %s | %s | %s | %s |',
        lhs, rhs, desc, buffer, expr, silent, script))
    end
    table.insert(lines, '')
  end
end

-- Write file
vim.fn.writefile(lines, output_path)
print('Keybind cheatsheet written to: ' .. output_path)