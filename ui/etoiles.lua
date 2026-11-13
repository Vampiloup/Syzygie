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

-- Les orbitals.
local NB_ORBITS       = 5
local ORBIT_BASE      = 4
local ORBIT_STEP      = 6
local MAX_RADIUS      = NB_ORBITS * ORBIT_STEP + ORBIT_BASE   -- 34
local PLANET_R        = 1.5
local PLANET_MIN_SCALE = 0.5
local BASE_SPEED      = 0.5          -- rad/s, à régler
local RADIUS, OMEGA = {}, {}
for o = 1, NB_ORBITS do
    RADIUS[o] = o * ORBIT_STEP + ORBIT_BASE
    OMEGA[o]  = BASE_SPEED / o
end
local COULEUR_PLANETE = {            -- à remplacer par ton registre
    tellurique = {0.6, 0.45, 0.3},
    gazeuse    = {0.8, 0.7, 0.5},
}
local COULEUR_DEFAUT = {0.7, 0.7, 0.7}

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
    local rayon   = math.max(RAYON_ETOILE, 2 / cam.scale)
    local marge   = math.max(rayon, MAX_RADIUS + PLANET_R)                                          -- couvre étoile ET planètes
    local planetes = cam.scale >= PLANET_MIN_SCALE
    local etiquettes = cam.scale > 0.5
    local t = love.timer.getTime()                                                                  -- une fois par frame
    local font = polices.f["standard_panneau"]
    love.graphics.setFont(font)
    local hauteur = font:getHeight()
    local padX, padY = 6, 2

    for _, s in ipairs(etoiles) do
        local cx, cy = s.pos_x, s.pos_y
        if cx + marge >= x1 and cx - marge <= x2 and cy + marge >= y1 and cy - marge <= y2 then

            if planetes then                                                                        -- Orbites planetes
                local orbites, phases = s.orbites, s.phases
                for o = 1, NB_ORBITS do
                    local typ = orbites[o]
                    if typ ~= 0 then
                        local a = phases[o] + t * OMEGA[o]
                        local c = COULEUR_PLANETE[typ] or COULEUR_DEFAUT
                        love.graphics.setColor(c[1], c[2], c[3])
                        love.graphics.circle("fill",
                            cx + math.cos(a) * RADIUS[o],
                            cy + math.sin(a) * RADIUS[o],
                            PLANET_R, 16)
                    end
                end
            end

            local c = etoiles_type[s.type]
            love.graphics.setColor(c.R, c.G, c.B)
            love.graphics.circle("fill", cx, cy, rayon)

            if etiquettes then
                local boxW = font:getWidth(s.nom) + padX * 2
                local boxH = hauteur + padY * 2
                local boxX = math.floor(cx - boxW / 2 + 0.5)
                local boxY = math.floor(cy + rayon + 4 + 0.5)
                love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
                love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4, 4)
                love.graphics.setColor(0.45, 0.45, 0.45)
                love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 4, 4)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(s.nom, boxX + padX, boxY + padY)
            end
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


