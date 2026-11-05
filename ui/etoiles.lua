-- ui/etoiles.lua
local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local ecran     = require("affichage.ecran")
local cam       = require("core.camera_monde")   -- une instance partagée
local registre  = require("core.registre")
local polices   = require("core.polices")

local TOLERANCE_PX = 6   -- rayon minimal cliquable, en pixels virtuels
local RAYON_ETOILE = 8
local etoiles, etoiles_type

local function charger()
    etoiles  = registre.list("jeu_galaxie_etoiles")
    etoiles_type = registre.table("etoiles_type")                       -- indexé par id : etoiles_type["rouge"] = {R=,G=,B=}
    for _, s in ipairs(etoiles) do                                      -- vérification unique, au lieu d'une par frame
        assert(etoiles_type[s.type], "type d'étoile inconnu : " .. tostring(s.type))
    end
end

local function assurer()
    if not etoiles then charger() end
end

local function invalider() etoiles, etoiles_type = nil, nil end
events.on("galaxie_generee", invalider)

-- renvoie l'étoile touchée (la plus au-dessus), ou nil
local function trouver(px, py)
    assurer()
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
        assurer()

        local x1, y1, x2, y2 = cam:visibleRect(ecran.bounds())
        local rayon = math.max(RAYON_ETOILE, 2 / cam.scale)
        local font   = love.graphics.getFont()
        for _, s in ipairs(etoiles) do
            if s.pos_x + rayon >= x1 and s.pos_x - rayon <= x2 and s.pos_y + rayon >= y1 and s.pos_y - rayon <= y2 then
                local c = etoiles_type[s.type]
                local nom    = s.nom
                local textW  = font:getWidth(nom)
                local textH  = font:getHeight()
                local padX, padY = 6, 2
                local boxW   = textW + padX * 2
                local boxH   = textH + padY * 2
                local boxX   = math.floor((s.pos_x - boxW / 2) + 0.5)                                             -- centré sur le disque
                local boxY   = s.pos_y + rayon + 4                                            -- sous le disque (4 px d'écart)
                love.graphics.setFont(polices.f["standard_panneau"])
                love.graphics.setColor(c.R, c.G, c.B)
                love.graphics.circle("fill", s.pos_x, s.pos_y, rayon)
                if cam.scale > 0.5 then
                    love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
                    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4, 4)
                    love.graphics.setColor(0.45, 0.45, 0.45)                                      -- liseré fin
                    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4, 4)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(nom, boxX + padX, boxY + padY)
                end
                love.graphics.setColor(1, 1, 1)
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


