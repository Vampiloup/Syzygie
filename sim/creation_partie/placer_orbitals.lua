-- sim.creation_partie.placer_orbitals.lua

local registre =                  require("core.registre")


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

local function genererTypePlanete(couleur)
    local proba = registre.get_field("etoiles_type", couleur, "planet_gas_prob")

    if proba == nil then
        error("etoiles_type unknown: " .. tostring(couleur))
    end
    if math.random() < proba then
        return "gazeuse"
    else
        return "tellurique"
    end
end

local function generer_orbites(x, couleur)
    -- Table de 5 positions, toutes à 0 au départ
    local orbits = {0, 0, 0, 0, 0}

    -- On crée une liste des indices disponibles
    local indices = {1, 2, 3, 4, 5}

    -- On mélange les indices (Fisher-Yates)
    for i = 5, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- On met à 1 les X premières positions tirées au hasard
    for i = 1, x do
        orbits[indices[i]] = genererTypePlanete(couleur)
    end

    return orbits
end



local function placer_orbitals(couleur)
    local mu = registre.get_field("etoiles_type", couleur, "nbplanets_pic")
    local sigma = registre.get_field("etoiles_type", couleur, "nbplanets_disp")
    if not mu or not sigma then error("etoiles_type unknown: " .. tostring(couleur)) end
    if sigma <= 0 then error("nbplanets_disp invalide pour: " .. tostring(couleur)) end

    local probs = calculerProbabilites(mu, sigma)
    local jet = math.random()
    local cumul = 0.0
    local choix = 5  -- repli en cas d'arrondi

    for x = 1, 5 do
        cumul = cumul + probs[x]
        if jet <= cumul then
            choix = x
            break
        end
    end

    return generer_orbites(choix, couleur)
end



return {
    placer_orbitals = placer_orbitals
}
