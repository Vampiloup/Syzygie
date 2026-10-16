local M = {}
local items = {}
local nextId = 0

-- item = {
--   z               = number,                 -- plus grand = au-dessus
--   contient        = function(x, y) -> bool, -- le point est-il sur l'élément ?
--   modal           = bool (optionnel),       -- bloque tout ce qui est dessous
--   onpress         = function(x, y, button), -- optionnel
--   onrelease       = function(x, y, button), -- optionnel
--   onmove          = function(x, y, dx, dy), -- optionnel
--   onwheel         = function(dx, dy),       -- optionnel
-- }
function M.add(item)
  nextId = nextId + 1
  item._id = nextId           -- départage les z égaux (le plus récent gagne)
  item.z = item.z or 0
  table.insert(items, item)
  M.sort()
  return item
end

function M.remove(item)
  for i, it in ipairs(items) do
    if it == item then table.remove(items, i) return end
  end
end

function M.sort()
  table.sort(items, function(a, b)
    if a.z ~= b.z then return a.z > b.z end   -- z décroissant
    return a._id > b._id
  end)
end

-- Renvoie l'élément le plus haut sous (x, y), ou nil
function M.pick(x, y)
  for _, it in ipairs(items) do
    if it.contient(x, y) then return it end
    if it.modal then return it end      -- un modal avale tout
  end
  return nil
end

-- Amène un élément au premier plan
function M.raise(item)
  local top = 0
  for _, it in ipairs(items) do top = math.max(top, it.z) end
  item.z = top + 1
  M.sort()
end

return M
