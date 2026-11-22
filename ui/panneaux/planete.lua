-- ui.panneaux.planete.lua

local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")
local polices =                require("core.polices")
local bouton    =              require("ui.widgets.bouton")


local ID = "hud_planete"
local etoile_id, orbite, zone_couleur = nil, nil


local PL = panneau.new({
    id = ID, preset = ID, groupe = "panneaux_secondaires",
    draw = function(p)
        local reponse = registre.get("jeu_galaxie_etoiles", tostring(etoile_id))
        local reponse_zones = reponse.zones[orbite]
        -- local reponse = registre.get("jeu_galaxie_etoiles", tostring(etoile_id))
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.rectangle("fill", p.x , p.y , 1200, 160, 6, 6)
        for i = 1, 4 do
            zone_couleur = registre.get_field("base_orbitales_type", reponse_zones[i], "RGB")
            love.graphics.setColor(zone_couleur)
            love.graphics.rectangle("fill", p.x + ((i-1)*263),        p.y + 160 + 8 ,  255, 776, 6, 6)
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", p.x + 1052, p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x + 1315, p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(" Planète : " .. tostring(orbite) .. " de l'étoile " .. tostring(etoile_id), p.x + 16, p.y)
    end,
})

events.on("etoile_changee", function() PL.close() end)

events.on("etoile_fermee", function() PL.close() end)

events.on("panneau_etoile", function(d)
    etoile_id, orbite = d.etoile, d.orbite
    PL.open()
end)


return PL
