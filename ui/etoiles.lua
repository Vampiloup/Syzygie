
-- ui/etoiles.lua
local events = require("core.events")
local screen = require("affichage.ecran")
local couches    = require("core.couches")

print ("étoile chargée")

local star = { x = 1500, y = 300, r = 150 }

events.on("draw_world", function()
  love.graphics.setColor(1, 0.9, 0.3)
  love.graphics.circle("fill", star.x, star.y, star.r)
  love.graphics.setColor(1, 1, 1)
end)

couches.add({
  z = 0,
  contient = function(px, py)
    local dx, dy = px - star.x, py - star.y
    return dx*dx + dy*dy <= star.r * star.r
  end,
  onpress = function() print("étoile cliquée") end,
})
