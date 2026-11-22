-- sim.creation_partie.placer_orbitals.lua

local registre =                  require("core.registre")

local TAU = 2 * math.pi
local NB_ZONES = 4

local CFG = {         -- Données pour calcul température orbite.
    pas      = 0.8,   -- niveaux de température gagnés par orbite (orbite 1 → 5 : 3.2 niveaux)
    gain     = 0.75,   -- décalage par unité de ln(luminosité) : l'effet "couleur d'étoile"
    sigma    = 0.75,  -- dispersion autour de la moyenne
}

local function generer_taille(g)
    local taille = {}
    for k = 1, 5 do
        taille[k] = g:random(1, 5)
    end
    return taille
end

local function generer_humidite(g)
    local eau = {}
    for k = 1, 5 do
        eau[k] = g:random(1, 5)
    end
    return eau
end

local function gauss(g)                     -- Box-Muller, 2 tirages par appel (flux stable)
    local u1, u2 = 1 - g:random(), g:random()   -- 1 - u1 évite log(0)
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

local function temperature_moyenne(lum, k)  -- sans clamp : le clamp final suffit
    return 3 - CFG.pas * (k - 3) + CFG.gain * math.log(lum)
end

local function generer_temperatures(couleur, g)
    local lum = registre.get_field("etoiles_type", couleur, "luminosite")
    if not lum or lum <= 0 then error("luminosite invalide pour: " .. tostring(couleur)) end
    local temps = {}
    for k = 1, 5 do                         -- 5 tirages, orbites vides comprises
        local x = temperature_moyenne(lum, k) + CFG.sigma * gauss(g)
        temps[k] = math.max(1, math.min(5, math.floor(x + 0.5)))
    end
    table.sort(temps, function(a, b) return a > b end)
    return temps
end


local function generer_phases(ph)
    local phases = {}
    for o = 1, 5 do                       -- 5 tirages, orbites vides comprises
        phases[o] = ph:random() * TAU
    end
    return phases
end


local function calculerProbabilites(mu, sigma)                  -- Calcul probabilité du nombre de planètes.
    local poids = {}
    local sommePoids = 0

    for x = 1, 5 do
        local w = math.exp(-((x - mu)^2) / (2 * (sigma^2)))
        poids[x] = w
        sommePoids = sommePoids + w
    end

    local probabilites = {}
    for x = 1, 5 do
        probabilites[x] = poids[x] / sommePoids
    end

    return probabilites
end

local function genererTypePlanete(couleur, g)
    local proba = registre.get_field("etoiles_type", couleur, "planet_gas_prob")
    if proba == nil then
        error("etoiles_type unknown: " .. tostring(couleur))
    end
    -- [MODIF] math.random() -> g:random()  (méthode : deux-points, pas de point)
    if g:random() < proba then
        return "gazeuse"
    else
        return "tellurique"
    end
end

local function generer_orbites(x, couleur, g)
    -- Table de 5 positions, toutes à 0 au départ
    local orbits = {0, 0, 0, 0, 0}

    -- On crée une liste des indices disponibles
    local indices = {1, 2, 3, 4, 5}

    -- On mélange les indices (Fisher-Yates)
    for i = 5, 2, -1 do
        local j = g:random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- On met le type voulu dans les X premières positions tirées au hasard
    for i = 1, x do
        orbits[indices[i]] = genererTypePlanete(couleur, g)
    end

    return orbits
end

local function generer_zones(orbits, humidite, g)
    local zones = {}
    for i = 1, #orbits do
        -- Mélange fait pour toutes les orbites : nombre de tirages constant
        local indices = {1, 2, 3, 4}
        for k = NB_ZONES, 2, -1 do
            local j = g:random(k)
            indices[k], indices[j] = indices[j], indices[k]
        end

        if orbits[i] == "tellurique" then
            local z = {"terre", "terre", "terre", "terre"}
            for k = 1, humidite[i] - 1 do
                z[indices[k]] = "ocean"
            end
            zones[i] = z
        else
            zones[i] = 0
        end
    end
    return zones
end


local function placer_orbitals(couleur, rng_nb, rng_types, rng_ph, rng_temp, rng_eau, rng_taille, rng_zones)
    local mu = registre.get_field("etoiles_type", couleur, "nbplanets_pic")
    local sigma = registre.get_field("etoiles_type", couleur, "nbplanets_disp")
    if not mu or not sigma then error("etoiles_type unknown: " .. tostring(couleur)) end
    if sigma <= 0 then error("nbplanets_disp invalide pour: " .. tostring(couleur)) end

    local probs = calculerProbabilites(mu, sigma)
    local jet = rng_nb:random()
    local cumul = 0.0
    local choix = 5  -- repli en cas d'arrondi

    for x = 1, 5 do
        cumul = cumul + probs[x]
        if jet <= cumul then
            choix = x
            break
        end
    end
    local orbites       = generer_orbites(choix, couleur, rng_types)
    local phases        = generer_phases(rng_ph)
    local temperatures  = generer_temperatures(couleur, rng_temp)
    local humidite      = generer_humidite(rng_eau)
    local taille        = generer_taille(rng_taille)
    local zones         = generer_zones(orbites, humidite, rng_zones)

    return orbites, phases, temperatures, humidite, taille, zones
end



return {
    placer_orbitals = placer_orbitals
}
