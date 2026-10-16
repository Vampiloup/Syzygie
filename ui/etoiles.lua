-- ui/etoiles.lua
local couches   = require("core.couches")
local couches_z = require("core.couches_z")

local etoiles = {
  { id = 1, x = 500,  y = 300, r = 8 },
  { id = 2, x = 900,  y = 600, r = 12 },
  { id = 3, x = 1500, y = 300, r = 150 },
  -- ... des milliers d'autres
}

-- renvoie l'étoile touchée (la plus au-dessus), ou nil
local function trouver(px, py)
  for i = #etoiles, 1, -1 do          -- de la dernière dessinée à la première
    local s = etoiles[i]
    local dx, dy = px - s.x, py - s.y
    if dx*dx + dy*dy <= s.r * s.r then return s end
  end
  return nil
end

couches.add({
  z = couches_z.ETOILES,

  contient = function(px, py)
    return trouver(px, py) ~= nil
  end,

  draw = function()
    love.graphics.setColor(1, 0.9, 0.3)
    for _, s in ipairs(etoiles) do
      love.graphics.circle("fill", s.x, s.y, s.r)
    end
    love.graphics.setColor(1, 1, 1)
  end,

  onpress = function(x, y, button)
    local s = trouver(x, y)
    if s then print("étoile cliquée", s.id, s.x, s.y) end
  end,
})
