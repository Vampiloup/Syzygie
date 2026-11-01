-- ui.panneaux.etoile
local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")


local ID = "carte_etoile"
local RAYON_ETOILE = 24

local etoile_id = nil

local P = panneau.new({
  id = ID, preset = "etoile",
  draw       = function(p)
    local texte = i18n.t("hud_star.titre")
    love.graphics.print(texte.." : " .. tostring(etoile_id), p.x + 72, p.y + 16)

    local reponse = registre.get_field("jeu_galaxie_etoiles", tostring(etoile_id) , "type")
    love.graphics.print(texte.." : " .. reponse, p.x + 16, p.y + 64)
    local etoile = registre.get("etoiles_type", tostring(reponse))
    love.graphics.setColor(etoile.R, etoile.G, etoile.B)
    love.graphics.circle("fill", p.x + 24, p.y + 32, RAYON_ETOILE)

   -- etoiles_type

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
