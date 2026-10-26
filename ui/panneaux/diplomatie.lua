-- ui.panneaux.diplomatie

local events  = require("core.events")
local panneau = require("ui.widgets.panneau")
local i18n =                   require("core.i18n")

local ID = "diplomatie"
local CLE = "hud_"..ID

local P = panneau.new({
  id = ID, w = 1280, h = 768, ancrage_x = "droite", ancrage_y = "haut",
  draw    = function(p)
    local texte =i18n.t( CLE..".titre")
    love.graphics.print(texte, p.x + 16, p.y + 16)
  end,
  onclick = function(x, y, b) if b == 1 then print("Clic dans le panneau Diplomatie") end end,
})

events.on("hud_bouton", function(id) if id == ID then P.toggle() end end)

return P
