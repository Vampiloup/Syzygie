-- ui.panneaux.etoile
local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")

local ID = "carte_etoile"

local etoile_id = nil

local P = panneau.new({
  id = ID, w = 320, h = 990,  ancrage_x = "gauche", ancrage_y = "haut",
  draw       = function(p)
    local texte = i18n.t("hud_star.titre")
    love.graphics.print(texte.." : " .. tostring(etoile_id), p.x + 16, p.y + 16)
  end,
  pre_touche = function() etoile_id = etoile_id or 1 end,
  on_close   = function() etoile_id = nil end,
})

-- l'argument est une donnée (numéro d'étoile), pas une adresse
events.on("carte_etoile", function(id)
  etoile_id = id
  P.open()
end)

return P
