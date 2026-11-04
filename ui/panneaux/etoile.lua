-- ui.panneaux.etoile
local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")
local polices =                require("core.polices")


local ID = "carte_etoile"
local RAYON_ETOILE = 24

local etoile_id = nil

local P = panneau.new({

  id = ID, preset = "etoile",
  draw       = function(p)
    -- for k, v in pairs(polices.f) do print("police chargée : [" .. k .. "]", v) end
    local texte = i18n.t("hud_star.numero")
    local reponse = registre.get("jeu_galaxie_etoiles", tostring(etoile_id))
    love.graphics.setFont(polices.f["titre_panneau"])
    -- love.graphics.setFont(assert(polices.f["titre_panneau"], "police 'titre_panneau' introuvable"))
    love.graphics.setColor(1, 0.9, 0.4)
    love.graphics.print(reponse.nom, p.x + 72, p.y + 16)
    love.graphics.setFont(polices.f["standard_panneau"])
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(texte.." : " .. tostring(etoile_id), p.x + 16, p.y + 64)
    local etoile = registre.get("etoiles_type", tostring(reponse.type))
    love.graphics.setColor(etoile.R, etoile.G, etoile.B)
    love.graphics.circle("fill", p.x + 24, p.y + 32, RAYON_ETOILE)
    love.graphics.setFont(polices.f["standard_panneau"])

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(polices.f["standard_panneau"])

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
