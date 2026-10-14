love.math.setRandomSeed(os.time())

-- Librairies
local textureAtlas =      require("libs.TA")                         -- Librairie atlas
local json =              require("libs.dkjson.dkjson")              -- Librairie json
local registre =          require("core.registre")                   -- Création du registre
local mods =              require("core.mods")                       -- Chargement des mods
local i18n =              require("core.i18n")                       -- Chargement des langues
local entrees =           require("ui.entrees")                      -- Chargement du module d'interception des entrées (souris, clavier)
local events =            require("core.events")                     -- Chargement du module de gestion des évènements
local screen =            require("affichage.ecran")                 -- Chargement du module de gestion de la résolution.

local hello =             require("ui.panneaux.hello")               -- Chargement du panneau "Hello"



function love.load()

  mods.charger_defaut()                                              -- découvre, trie, exécute, remplit le registre
  mods.verifier_references()
  i18n.definir("fr")                                                 -- une fois, au démarrage
  screen.load()
  events.emit("resize", screen.bounds())                             -- placement initial des panneaux


  local defauts = registre.get("galaxy_defaults", "defaut:standard")


  local forme   = registre.get("galaxy_form",    defauts.map_form)
  local taille  = registre.get("galaxy_size",    defauts.map_size)
  local densite = registre.get("galaxy_density", defauts.map_density)

  -- print(i18n.t("ui.defaut:forme"))                                -- Disc with uniform density
  print(taille.map_X, taille.map_Y)                                  -- 2500  2500
  print(densite.density)                                             -- 1

  local reponse = i18n.tc("galaxy_form", "defaut:disque_uniforme")
  print (reponse)
end

function love.update(dt)
  events.emit("update", dt)
end


function love.draw()
  screen.begin()
  love.graphics.setColor(0.2, 0.3, 0.2)
  love.graphics.rectangle("fill", 0, 0, screen.W, screen.H)
  love.graphics.setColor(1, 1, 1)
  events.emit("draw_world")   -- plus tard : la carte, avec sa caméra
  events.emit("draw_ui")      -- les panneaux, dans le repère 1920x1080
  screen.finish()
end

function love.resize(w, h)
  screen.resize(w, h)
  events.emit("resize", screen.bounds())
end
