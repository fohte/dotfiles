local M = {}

-- Merges two tables together, overwriting the first table with the second.
-- e.g. mergeTables({a = 1, b = 2}, {b = 3, c = 4}) -> {a = 1, b = 3, c = 4}
function M.mergeTables(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == 'table' then
      if type(t1[k] or false) == 'table' then
        mergeTables(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

return M
