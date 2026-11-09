-- ui.panneaux.planete.lua

local events  =                require("core.events")
local panneau =                require("ui.widgets.panneau")
local i18n =                   require("core.i18n")
local registre  =              require("core.registre")
local polices =                require("core.polices")
local bouton    =              require("ui.widgets.bouton")


local ID = "panneau_etoile"

events.on("planete_cliquee", function(k) print("planète", k.etoile, k.orbite) end)


local PL = panneau.new({

    id = ID, preset = "planete",
    draw       = function(p)
        love.graphics.print(" Planète : " .. tostring(etoile_id), p.x + 16, p.y + 64)

    end

})

events.on("panneau_etoile", function(id)
    etoile_id = id
    PL.open()
end)

return PL
