-- ui/etoiles.lua
local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local ecran     = require("affichage.ecran")
local cam       = require("core.camera_monde")   -- une instance partagée
local registre  = require("core.registre")

local TOLERANCE_PX = 6   -- rayon minimal cliquable, en pixels virtuels
local RAYON_ETOILE = 8
local etoiles

-- renvoie l'étoile touchée (la plus au-dessus), ou nil
local function trouver(px, py)
    etoiles = etoiles or registre.list("jeu_galaxie_etoiles")
    local r = math.max(RAYON_ETOILE, TOLERANCE_PX / cam.scale)
    local r2 = r * r
    local meilleure, meilleureDist = nil, math.huge
    for i = #etoiles, 1, -1 do
        local s = etoiles[i]
        local dx, dy = px - s.pos_x, py - s.pos_y
        local d2 = dx*dx + dy*dy
        if d2 <= r2 and d2 < meilleureDist then
            meilleure, meilleureDist = s, d2
        end
    end
    return meilleure
end

couches.add({
    z = couches_z.ETOILES,
    camera = cam,

    contient = function(px, py)
        return trouver(px, py) ~= nil
    end,

    draw = function()
        etoiles = etoiles or registre.list("jeu_galaxie_etoiles")
        local x1, y1, x2, y2 = cam:visibleRect(ecran.bounds())
        local rayon = math.max(RAYON_ETOILE, 2 / cam.scale)
        love.graphics.setColor(1, 0.9, 0.3)
        for _, s in ipairs(etoiles) do
            if s.pos_x + rayon >= x1 and s.pos_x - rayon <= x2 and s.pos_y + rayon >= y1 and s.pos_y - rayon <= y2 then
                love.graphics.circle("fill", s.pos_x, s.pos_y, rayon)
            end
        end
        love.graphics.setColor(1, 1, 1)
    end,

    onpress = function(x, y, button)
        if button ~= 1 then return end
        local s = trouver(x, y)
        if s then
            print("étoile cliquée", s.id, s.pos_x, s.pos_y)
            events.emit("carte_etoile", s.id)
        end
    end,
})


