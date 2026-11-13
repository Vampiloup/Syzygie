-- sim.creation_partie.generation_galaxie.lua
--
-- Usage (depuis main.lua, après le chargement des modules qui remplissent le registre) :
--   local generation_galaxie = require("sim.creation_partie.generation_galaxie")
--   generation_galaxie.generer({ map_X = 5000, map_Y = 5000, map_form = 12 })
--
-- Paramètres de generer(params) :
--   map_X, map_Y   (obligatoires) dimensions du "carré plein" de référence ; A = map_X * map_Y
--   map_form       (obligatoire)  id de la forme, trouvé dans galaxy_form (type_galaxies.json par défaut)
--   densite        (défaut 1)     multiplicateur du nombre d'étoiles
--   distance_mini  (défaut 80)    distance minimale entre deux étoiles
--   graine         (défaut os.time())  graine aléatoire, mémorisée dans le registre

local registre =                  require("core.registre")
local events =                    require("core.events")
local StarNames =                 require("sim.creation_partie.noms_etoiles")
local orbitals =                  require("sim.creation_partie.placer_orbitals")
local Graine  =                   require("sim.creation_partie.graine")

local PI2 = 2 * math.pi
local ETAPE = { POS = 1, TYPE = 2, NOM = 3, NB_PLANETES = 4, PLANETES = 5 }



-- noms[n] = gen:generate("gaulois", used)          -- langue imposée (secteur, faction)
-- noms[n] = gen:generateMixed({latin=3, grec=1}, used)  -- tirage pondéré, une langue par nom
-- gen:addWords("gaulois", { ...mots du dictionnaire... })


----------------------------------------------------------------------
-- FORMES
-- Chaque constructeur reçoit (A, map_X, map_Y), où A = map_X * map_Y est l'aire
-- PEUPLABLE visée, et renvoie : tirer, largeur_hors_tout, hauteur_hors_tout.
-- tirer() renvoie un point (x, y) RELATIF au centre de la forme, tiré uniformément
-- dans la zone peuplable (sauf forme 2, volontairement non uniforme).
----------------------------------------------------------------------

-- 1 : carré plein
local function forme_carre(A, mX, mY)
    return function(g)
        return (g:random() - 0.5) * mX, (g:random() - 0.5) * mY
    end, mX, mY
end

-- 2 : disque à densité décroissante (même aire que le carré, densité en 1/r)
local function forme_disque_decroissant(A)
    local R = math.sqrt(A / math.pi)
    return function(g)
        local t = PI2 * g:random()
        local r = R * g:random()
        return r * math.cos(t), r * math.sin(t)
    end, 2 * R, 2 * R
end

-- 3 à 7 : disque (a = 0) ou anneau.
-- a = fraction de r² retirée au centre ; le rayon externe grandit pour garder l'aire A.
local function forme_anneau(a)
    return function(A)
        local R = math.sqrt(A / (math.pi * (1 - a)))
        return function(g)
            local t = PI2 * g:random()
            local r = R * math.sqrt(a + (1 - a) * g:random())
            return r * math.cos(t), r * math.sin(t)
        end, 2 * R, 2 * R
    end
end

-- 8 à 11 : ellipse pleine d'aire A, de rapport d'axes k^2 (demi-axes R0*k et R0/k)
local function forme_ellipse(k)
    return function(A)
        local R0 = math.sqrt(A / math.pi)
        local a, b = R0 * k, R0 / k
        return function(g)
            local t = PI2 * g:random()
            local r = math.sqrt(g:random())
            return r * a * math.cos(t), r * b * math.sin(t)
        end, 2 * a, 2 * b
    end
end

-- 12 : double anneau. Bandes en r²/R² dans [0.3, 0.5] et [0.7, 0.9] (aire totale = 0.4*pi*R²).
-- Les deux bandes ont la même aire : tirage 50/50.
local function forme_double_anneau(A)
    local R = math.sqrt(A / (math.pi * 0.4))
    return function(g)
        local lo, hi = 0.7, 0.9
        if g:random() < 0.5 then lo, hi = 0.3, 0.5 end
        local t = PI2 * g:random()
        local r = R * math.sqrt(lo + (hi - lo) * g:random())
        return r * math.cos(t), r * math.sin(t)
    end, 2 * R * math.sqrt(0.9), 2 * R * math.sqrt(0.9)
end

-- 13 : croix, bras de largeur w = 0.2*L, aire = 0.36*L² (centre compté une seule fois)
local function forme_croix(A)
    local L = math.sqrt(A) / 0.6
    local w = 0.2 * L
    local p_horiz = L / (2 * L - w)            -- part d'aire de la barre horizontale
    return function(g)
        if g:random() < p_horiz then
            return (g:random() - 0.5) * L, (g:random() - 0.5) * w
        end
                -- barre verticale SANS le carré central (déjà dans la barre horizontale)
        local u = g:random() * (L - w)
        local y = u - L / 2
        if u >= (L - w) / 2 then y = y + w end
        return (g:random() - 0.5) * w, y
    end, L, L
end


local GENERATEURS = {
    forme_carre              = forme_carre,
    forme_disque_decroissant = forme_disque_decroissant,
    forme_anneau             = forme_anneau,
    forme_ellipse            = forme_ellipse,
    forme_double_anneau      = forme_double_anneau,
    forme_croix              = forme_croix,
}

local unpack = table.unpack or unpack   -- LuaJIT (LÖVE) : unpack

local function resoudre_constructeur(id)
    local def = registre.get("galaxy_form", id)   -- erreur claire si l'id est inconnu
    local f = GENERATEURS[def.generation]
    if not f then
        error("generation inconnue dans galaxy_form : " .. tostring(def.generation))
    end
    if def.args then
        return f(unpack(def.args))   -- fabrique (anneau, ellipse)
    end
    return f                         -- constructeur direct
end

----------------------------------------------------------------------
-- GÉNÉRATION DES POSITIONS
-- Renvoie : xs, ys, n, boite  (boite = boîte englobante de la forme)
----------------------------------------------------------------------
local function generer_etoiles(map_X, map_Y, nombre_cible, dist_mini, map_form, graine)
    local NB_ETOILES = registre.nombre("etoiles_type")

    -- Un seul générateur pour les noms, créé UNE fois avant la boucle.
    -- sous_graine() donne un entier ; StarNames.new l'accepte comme graine (creer_rng).

    local gen  = StarNames.new(Graine.sous_graine(graine, ETAPE.NOM))
    local used = {}

    -- Un seul générateur pour toutes les positions : le placement par rejet
    -- est séquentiel (chaque étoile dépend des précédentes), donc un flux unique.
    local rng_pos = Graine.rng(graine, ETAPE.POS)

    local constructeur = resoudre_constructeur(map_form)
    if not constructeur then
        print(("Forme %s non gérée : aucune étoile générée"):format(tostring(map_form)))
        return {}, {}, 0, nil, {}, {}
    end

    local A = map_X * map_Y
    local tirer, largeur, hauteur = constructeur(A, map_X, map_Y)
    local cx, cy = map_X / 2, map_Y / 2

    local boite = {
        min_x = cx - largeur / 2, max_x = cx + largeur / 2,
        min_y = cy - hauteur / 2, max_y = cy + hauteur / 2,
        largeur = largeur, hauteur = hauteur,
    }

    local xs, ys, etoiles_type = {}, {}, {}
    local noms, nb_orbitals, orbites = {}, {}, {}
    local n = 0
    local d2 = dist_mini * dist_mini
    local MAX_ESSAIS = 1000

    while n < nombre_cible do
        local place = false
        for _ = 1, MAX_ESSAIS do
            local dx0, dy0 = tirer(rng_pos)      -- on passe le générateur
            local x = math.floor(cx + dx0 + 0.5)
            local y = math.floor(cy + dy0 + 0.5)

            local ok = true
            for j = 1, n do
                local dx, dy = xs[j] - x, ys[j] - y
                if dx * dx + dy * dy < d2 then ok = false; break end
            end
            if ok then
                n = n + 1
                xs[n], ys[n] = x, y
                place = true
                break
            end
        end

        if not place then
            print(("Seulement %d étoiles sur %d générées (espace saturé)"):format(n, nombre_cible))
            break
        end

        -- Couleur (type étoile)
        local rng_type = Graine.rng(graine, ETAPE.TYPE, n)
        local a = rng_type:random(1, NB_ETOILES)
        local def = registre.list("etoiles_type")[a]
        etoiles_type[n] = def.id

        -- Nom
        -- noms[n] = gen:generate("egyptien", used)
        noms[n] = gen:generateMixed(used, "standard")

        -- Générer les orbitals (planètes, essentiellement)
        local rng_nb = Graine.rng(graine, ETAPE.NB_PLANETES, n)                     -- générateur nombre de planètes
        local rng_pl = Graine.rng(graine, ETAPE.PLANETES, n)                        -- emplacement et type
        orbites[n] = orbitals.placer_orbitals(etoiles_type[n], rng_nb, rng_pl)

    end
    return xs, ys, n, boite, etoiles_type, noms, nb_orbitals, orbites
end

----------------------------------------------------------------------
-- POINT D'ENTRÉE
----------------------------------------------------------------------
local M = {}

function M.generer(params)
    assert(params, "generer(params) : params manquant")
    assert(params.map_X and params.map_Y, "generer : map_X et map_Y sont obligatoires")
    assert(registre.has("galaxy_form", params.map_form), "generer : map_form inconnu : " .. tostring(params.map_form))

    local map_X         = params.map_X
    local map_Y         = params.map_Y
    local map_form      = params.map_form
    local densite       = params.densite or 1
    local distance_mini = params.distance_mini or 80

    local graine = params.graine or os.time()

    -- Repartir d'un registre vide : évite l'erreur « Doublon » en cas de régénération
    registre.clear("jeu_galaxie_details")
    registre.clear("jeu_galaxie_etoiles")

    local nombre_cible = math.ceil((map_X * map_Y) / 4000000 * 100 * densite)
    local xs, ys, nombre_etoiles, boite, etoiles_type, noms, nb_orbitals, orbites =
        generer_etoiles(map_X, map_Y, nombre_cible, distance_mini, map_form, graine)

    registre.add("jeu_galaxie_details", "principal", {
        nombre_etoiles   = nombre_etoiles,      -- nombre réellement placé
        nombre_cible     = nombre_cible,        -- nombre demandé
        boite_englobante = boite,               -- {min_x, max_x, min_y, max_y, largeur, hauteur}
        graine           = graine,              -- pour rejouer la même galaxie
        map_form         = map_form,
    })
    for i = 1, nombre_etoiles do
        registre.add("jeu_galaxie_etoiles", tostring(i), {
            id              = tostring(i),
            pos_x           = xs[i],
            pos_y           = ys[i],
            type            = etoiles_type[i],
            nom             = noms[i],
            nb_orbitals     = nb_orbitals[i],
            orbites         = orbites[i]
        })
    end
    events.emit("galaxie_generee")
end

return M
