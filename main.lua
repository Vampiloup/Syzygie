-- main.lua
love.math.setRandomSeed(os.time())

-- Librairies
local textureAtlas =          require("libs.TA")                         -- Librairie atlas
local json =                  require("libs.dkjson.dkjson")              -- Librairie json
local registre =              require("core.registre")                   -- Création du registre
local mods =                  require("core.mods")                       -- Chargement des mods
local i18n =                  require("core.i18n")                       -- Chargement des langues
local screen =                require("affichage.ecran")                 -- Chargement du module de gestion de la résolution.
local entrees =               require("ui.entrees")                      -- Chargement du module d'interception des entrées (souris, clavier)
local events =                require("core.events")                     -- Chargement du module de gestion des évènements
local couches =               require("core.couches")                    -- Chargement du système de couches/layers/pile pour les évents sur éléments visuels.

local hello =                 require("ui.panneaux.hello")               -- Chargement du panneau "Hello"
local fond =                  require("ui.fond")                         -- s'enregistre dans couches
local etoiles =               require("ui.etoiles")                      -- Chargement des étoiles
local hud =                   require("ui.hud")                          -- Chargement du HUD

local panneau_empire =        require("ui.panneaux.empire")
local panneau_diplomatie =    require("ui.panneaux.diplomatie")
local panneau_science =       require("ui.panneaux.science")





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

  print (registre.get_field("galaxy_density", "defaut:clairseme", "density"))


end

function love.update(dt)
  events.emit("update", dt)
end


function love.draw()
  screen.begin()
  couches.draw()
  screen.finish()
end

function love.resize(w, h)
  screen.resize(w, h)
  events.emit("resize", screen.bounds())
end

events.on("keypressed", function(key)
  if key == "h" then
    if hello.is_open() then hello.close() else hello.open() end
  end
end)
