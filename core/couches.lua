-- core.couches.lua

local couches_z    = require("core.couches_z")

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

local function appliquerCamera(item)
  local cam = item.camera
  if not cam then return end

  local contient, onpress, onrelease, onmove, draw =
    item.contient, item.onpress, item.onrelease, item.onmove, item.draw

  if contient then
    item.contient = function(x, y)
      return contient(cam:toWorld(x, y))
    end
  end

  if onpress then
    item.onpress = function(x, y, b)
      local wx, wy = cam:toWorld(x, y)
      return onpress(wx, wy, b)
    end
  end

  if onrelease then
    item.onrelease = function(x, y, b)
      local wx, wy = cam:toWorld(x, y)
      return onrelease(wx, wy, b)
    end
  end

  -- molette : zoom par défaut
  if not item.onwheel then
    item.onwheel = function(dx, dy, vx, vy)
      cam:zoomAt(vx, vy, 1.1 ^ dy)
    end
  end

  -- onmove : pan au bouton droit, puis comportement propre à l'item
  item.onmove = function(x, y, dx, dy)
    if love.mouse.isDown(2) then
      cam.x = cam.x - dx / cam.scale
      cam.y = cam.y - dy / cam.scale
    end
    if onmove then
      local wx, wy = cam:toWorld(x, y)
      return onmove(wx, wy, dx / cam.scale, dy / cam.scale)
    end
  end

  if draw then
    item.draw = function()
      cam:attach()
      draw()
      cam:detach()
    end
  end
end


function M.add(item)
  nextId = nextId + 1
  item._id = nextId           -- départage les z égaux (le plus récent gagne)
  item.z = item.z or 0
  appliquerCamera(item)
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
    if it.contient and it.contient(x, y) then return it end
    if it.modal then return it end
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

function M.draw()
  for i = #items, 1, -1 do        -- items est trié z décroissant : on parcourt à l'envers
    local it = items[i]
    if it.draw then it.draw() end
  end
end

return M
