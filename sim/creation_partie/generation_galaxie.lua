-- sim.creation_partie.generation_galaxie.lua

local registre =                            require("core.registre")

local map_X = 2500                                                      -- Taille de la carte (ici moyenne)
local map_Y = 2500
local distance_mini = 80                                                -- distance mini between Systems (in coordinates).
local densite = 1
local map_form = 1                                                      -- ou 2..

-- Les données précédentes seront amenées soit par le joueur, soit par une table pré-créée par un autre module. Elle sont ici juste le temps de la construction de cette génération et des tests.

love.math.setRandomSeed(os.time())

local function generer_etoiles(map_X, map_Y, nombre_cible, dist_mini, map_form)
    local xs, ys = {}, {}
    local n = 0
    local d2 = dist_mini * dist_mini
    local MAX_ESSAIS = 1000

    -- Taille de la galaxie (déclarées AVANT le if pour rester visibles)
    local galaxy_size_X, galaxy_size_Y
    if map_form == 1 then
        galaxy_size_X, galaxy_size_Y = map_X, map_Y
    else
        local d = math.floor(((map_X + map_Y) / 2) / math.sqrt(math.pi) * 2)
        galaxy_size_X, galaxy_size_Y = d, d
    end

    while n < nombre_cible do
        local place = false
        for _ = 1, MAX_ESSAIS do
            local x, y   -- déclarés ici, visibles dans tout le tour de boucle

            if map_form == 1 then
                x = love.math.random(0, map_X)
                y = love.math.random(0, map_Y)
            elseif map_form == 2 then
                local R = galaxy_size_X / 2
                local theta = 2 * math.pi * love.math.random()
                local r = R * math.sqrt(love.math.random())
                x = math.floor(R + r * math.cos(theta) + 0.5)
                y = math.floor(R + r * math.sin(theta) + 0.5)
            end

            if x then   -- garde-fou : forme non gérée => pas de crash
                local ok = true
                for j = 1, n do
                    local dx, dy = xs[j] - x, ys[j] - y
                    if dx*dx + dy*dy < d2 then ok = false; break end
                end
                if ok then
                    n = n + 1
                    xs[n], ys[n] = x, y
                    place = true
                    break
                end
            end
        end

        if not place then
            print(("Seulement %d étoiles sur %d générées (espace saturé ou forme non gérée)"):format(n, nombre_cible))
            break
        end
    end
    return xs, ys, n
end

local nombre_etoiles = math.ceil((map_X * map_Y) / 4000000 * 100 * densite)
local star_position_X, star_position_Y
star_position_X, star_position_Y, nombre_etoiles = generer_etoiles(map_X, map_Y, nombre_etoiles, distance_mini, map_form)

registre.add("jeu_galaxie_details", "principal", { nombre_etoiles = nombre_etoiles })
for i = 1, nombre_etoiles do
    registre.add("jeu_galaxie_etoiles", tostring(i), {
        id    = tostring(i),
        pos_x = star_position_X[i],
        pos_y = star_position_Y[i],
  })
end
