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
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.rectangle("fill", p.x , p.y , 1200, 160, 6, 6)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", p.x,        p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", p.x + 263,  p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(0, 0, 1)
        love.graphics.rectangle("fill", p.x + 526,  p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", p.x + 789,  p.y + 160 + 8 ,  255, 776, 6, 6)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", p.x + 1052, p.y + 160 + 8 ,  255, 776, 6, 6)

        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.rectangle("fill", p.x + 1315, p.y + 160 + 8 ,  255, 776, 6, 6)

    end,
})

events.on("etoile_changee", function() PL.close() end)

events.on("etoile_fermee", function() PL.close() end)

events.on("panneau_etoile", function(d)
    etoile_id, orbite = d.etoile, d.orbite
    PL.open()
end)


return PL
