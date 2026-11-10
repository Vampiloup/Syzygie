-- ui.panneaux.etoile
local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")
local polices =                require("core.polices")
local bouton    =              require("ui.widgets.bouton")


local ID = "carte_etoile"
local RAYON_ETOILE = 24
local NB_ORBITES = 5

local etoile_id = nil

-- Position RELATIVE au panneau de la ligne k : source unique pour le texte et la zone
local function ligne_y(k) return 72 + 144 * k end

local LIGNE_X, LIGNE_W, LIGNE_H = 16, 200, 32   -- à ajuster à la taille réelle du texte
local MARGE = 4



local P = panneau.new({

    id = ID, preset = "etoile",  groupe = "panneaux_jeu",
    draw       = function(p)
        -- for k, v in pairs(polices.f) do print("police chargée : [" .. k .. "]", v) end
        local texte = i18n.t("hud_star.numero")
        local reponse = registre.get("jeu_galaxie_etoiles", tostring(etoile_id))
        local etoile = registre.get("etoiles_type", tostring(reponse.type))
        love.graphics.setFont(polices.f["titre_panneau"])
        -- love.graphics.setFont(assert(polices.f["titre_panneau"], "police 'titre_panneau' introuvable"))
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print(reponse.nom, p.x + 72, p.y + 16)
        love.graphics.setFont(polices.f["standard_panneau"])
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(texte.." : " .. tostring(etoile_id), p.x + 16, p.y + 64)

        love.graphics.setColor(etoile.R, etoile.G, etoile.B)
        love.graphics.circle("fill", p.x + 24, p.y + 32, RAYON_ETOILE)
        love.graphics.setFont(polices.f["standard_panneau"])

        love.graphics.setFont(polices.f["standard_panneau"])
        love.graphics.setColor(1, 1, 1)
        for k = 1, NB_ORBITES do
            if reponse.orbites[k] ~= 0 then
                love.graphics.print(k .. " : Planète " .. reponse.orbites[k], p.x + LIGNE_X, p.y + ligne_y(k))
            end
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(polices.f["standard_panneau"])
    end,
    pre_touche = function() etoile_id = etoile_id or 1 end,
    on_close   = function()
        etoile_id = nil
        events.emit("etoile_fermee")
    end,

})

for k = 1, NB_ORBITES do
P.zone(LIGNE_X - MARGE, ligne_y(k) - MARGE, LIGNE_W + 2*MARGE, LIGNE_H + 2*MARGE,   "panneau_etoile", function() return { etoile = etoile_id, orbite = k } end,
         function()
           if not etoile_id then return false end
           local r = registre.get("jeu_galaxie_etoiles", tostring(etoile_id))
           return r.orbites[k] ~= 0
         end)
end

-- l'argument est une donnée (numéro d'étoile), pas une adresse
events.on("carte_etoile", function(id)
    if id ~= etoile_id then
        events.emit("etoile_changee", id)   -- avant la mise à jour
    end
    etoile_id = id
    P.open()
end)


return P
