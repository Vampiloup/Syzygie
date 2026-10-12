love.math.setRandomSeed(os.time())

-- Librairies
-- local textureAtlas = require("libs.TA")
local mods = require "core.mods"
local registre = require "core.registre"

function love.load()

    mods.charger_defaut()     -- découvre, trie, exécute, remplit le registre

local defauts = registre.get("galaxy_defaults", "defaut:standard")

local forme   = registre.get("galaxy_form",    defauts.map_form)
local taille  = registre.get("galaxy_size",    defauts.map_size)
local densite = registre.get("galaxy_density", defauts.map_density)

print(forme.nom)                -- Disc with uniform density
print(taille.map_X, taille.map_Y)  -- 2500  2500
print(densite.density)


local reponse = registre.get_field("galaxy_form", "defaut:disc_uniform", "nom")
print (reponse)
end

