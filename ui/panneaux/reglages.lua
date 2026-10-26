-- ui.panneaux.science

local events  =                 require("core.events")
local panneau =                 require("ui.widgets.panneau")
local i18n =                    require("core.i18n")

local ID = "reglages"
local CLE = "hud_"..ID

local P = panneau.new({
  id = ID, w = 512, h = 768, ancrage_x = "centre", ancrage_y = "centre",
  draw    = function(p)
    local texte =i18n.t( CLE..".titre")
    love.graphics.print(texte, p.x + 16, p.y + 16)
  end,
  onclick = function(x, y, b) if b == 1 then print("Clic dans le panneau Réglages") end end,
})

events.on("hud_bouton", function(id) if id == ID then P.toggle() end end)

return P
