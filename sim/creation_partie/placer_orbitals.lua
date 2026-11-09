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

local function genererNombrePlanetes(couleur)                         -- Génère le nombre de planètes dans le système
    local mu = registre.get_field("etoiles_type", couleur, "nbplanets_pic")
    local sigma = registre.get_field("etoiles_type", couleur, "nbplanets_disp")
    if not mu then
        error("etoiles_type unknown: " .. tostring(couleur))
    end

    local probs = calculerProbabilites(mu, sigma)

    -- Initialisation du générateur aléatoire (si ce n'est pas déjà fait globalement)
    local jet = math.random() -- Retourne un nombre décimal entre 0.0 et 1.0
    local cumul = 0.0

    for x = 1, 5 do
        cumul = cumul + probs[x]
        if jet <= cumul then
            return x
        end
    end

    return 5
end

local function generer_orbites(X)
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
    for i = 1, X do
        orbits[indices[i]] = 1
    end

    return orbits
end



return {
    genererNombrePlanetes = genererNombrePlanetes,
    generer_orbites = generer_orbites
}
