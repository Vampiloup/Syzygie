-- ui.panneaux.economie

local events  = require("core.events")
local panneau = require("ui.widgets.panneau")

local ID = "economie"

local P = panneau.new({
  id = ID, w = 1280, h = 768, ancrage = "haut_droite",
  draw    = function(p) love.graphics.print("Panneau Economie", p.x + 16, p.y + 16) end,
  onclick = function(x, y, b) if b == 1 then print("Clic dans le panneau Economie") end end,
})

-- events.on("hud_bouton", function(id) if id == ID then P.toggle() end end)

events.on("hud_bouton", function(id)   if id == ID then P.toggle() end end)

return P
