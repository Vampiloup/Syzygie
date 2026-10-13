love.math.setRandomSeed(os.time())

-- Librairies
local textureAtlas = require("libs.TA")         -- Librairie atlas
local registre = require "core.registre"        -- Création du registre
local mods = require "core.mods"                -- Chargement des mods
local i18n = require("core.i18n")               -- Chargement des langues

function love.load()

  mods.charger_defaut()                       -- découvre, trie, exécute, remplit le registre
  mods.verifier_references()
  i18n.definir("fr")                                 -- une fois, au démarrage



  local defauts = registre.get("galaxy_defaults", "defaut:standard")


  local forme   = registre.get("galaxy_form",    defauts.map_form)
  local taille  = registre.get("galaxy_size",    defauts.map_size)
  local densite = registre.get("galaxy_density", defauts.map_density)

  -- print(i18n.t("ui.defaut:forme"))                                -- Disc with uniform density
  print(taille.map_X, taille.map_Y)               -- 2500  2500
  print(densite.density)                          -- 1

  local reponse = i18n.tc("galaxy_form", "defaut:disque_uniforme")
  print (reponse)
  end

