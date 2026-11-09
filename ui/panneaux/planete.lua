-- ui.panneaux.planete.lua

local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")
local polices =                require("core.polices")
local bouton    =              require("ui.widgets.bouton")


local ID = "planete"
local etoile_id, orbite = nil, nil


local PL = panneau.new({
    id = ID, preset = ID, groupe = "panneaux_secondaires",
    draw = function(p)
        love.graphics.print(" Planète : " .. tostring(orbite) .. " de l'étoile " .. tostring(etoile_id), p.x + 16, p.y + 64)
    end,
})

events.on("etoile_changee", function() PL.close() end)

events.on("etoile_fermee", function() PL.close() end)

events.on("panneau_etoile", function(d)
    etoile_id, orbite = d.etoile, d.orbite
    PL.open()
end)


return PL
