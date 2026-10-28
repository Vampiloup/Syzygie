-- ui/etoiles.lua
local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local ecran     = require("affichage.ecran")
local cam       = require("core.camera_monde")   -- une instance partagée

local TOLERANCE_PX = 6   -- rayon minimal cliquable, en pixels virtuels

local etoiles = {
  { id = 1, x = 500,  y = 300, r = 8, rgb_1 = 1, rgb_2 = 0.9, rgb_3 = 0.3 },
  { id = 2, x = 900,  y = 600, r = 12, rgb_1 = 1, rgb_2 = 0.1, rgb_3 = 0.1 },
  { id = 3, x = 1500, y = 300, r = 150, rgb_1 = 0, rgb_2 = 1, rgb_3 = 1 },
  -- ... des milliers d'autres
}

-- renvoie l'étoile touchée (la plus au-dessus), ou nil
local function trouver(px, py)
  local tol = TOLERANCE_PX / cam.scale
  local meilleure, meilleureDist = nil, math.huge
  for i = #etoiles, 1, -1 do
    local s = etoiles[i]
    local r = math.max(s.r, tol)
    local dx, dy = px - s.x, py - s.y
    local d2 = dx*dx + dy*dy
    if d2 <= r * r and d2 < meilleureDist then
      meilleure, meilleureDist = s, d2
    end
  end
  return meilleure
end

couches.add({
  z = couches_z.ETOILES,
  camera = cam,

  contient = function(px, py)
    return trouver(px, py) ~= nil
  end,

  draw = function()
    local x1, y1, x2, y2 = cam:visibleRect(ecran.bounds())
    local plancher = 2 / cam.scale
    for _, s in ipairs(etoiles) do
      love.graphics.setColor(s.rgb_1, s.rgb_2, s.rgb_3)
      local rayon = math.max(s.r, plancher)
      if s.x + rayon >= x1 and s.x - rayon <= x2 and s.y + rayon >= y1 and s.y - rayon <= y2 then
        love.graphics.circle("fill", s.x, s.y, rayon)
      end
    end
    love.graphics.setColor(1, 1, 1)
end,

  onpress = function(x, y, button)
    if button ~= 1 then return end
    local s = trouver(x, y)
    if s then
      print("étoile cliquée", s.id, s.x, s.y)
      events.emit("carte_etoile", s.id)
      end
  end,
})
