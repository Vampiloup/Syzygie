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
local panneau_economie =      require("ui.panneaux.economie")
local carte_etoile =          require("ui.panneaux.etoile")

# local appel_tour =            require("core.appel_tour")                 -- Module demandant et recevant l'event de tour.




function love.load()

  -- mods.charger_defaut()                                                   -- lit, fusionne, vérifie les références, remplit le registre
  -- mods.charger({ "defaut", "test" })
  mods.charger({ "defaut" })
  i18n.definir("fr")                                                         -- une fois, au démarrage
  screen.load()
  events.emit("resize", screen.bounds())                                     -- placement initial des panneaux



-- local reponse = i18n.tc("table", "id")
-- => Renvoit le nom à afficher de l'entrée "id" de la catégorie "table"

 -- local reponse = registre.get("table", "entree")
-- => Renvoit une table constituée des champs de l'entrée "id" = "entree" de la catégorie "table"

-- local reponse = registre.get_field("table", "id", "champs")
-- => renvoit la valeur du champs "champs", de l'entrée "id", de la catégorie "table".

-- Utilisation :

local reponse = i18n.tc("galaxy_form", "disque_uniforme")
print (reponse)

local r = registre.get("galaxy_defaults", "standard")
 print(r.map_size, r.map_form, r.source)

local preset  = registre.get("galaxy_defaults", "standard")
local densite = registre.get_field("galaxy_density", preset.map_density, "density")
print(densite)   -- 1 (ou la valeur imposée par un mod)

local preset  = registre.get("galaxy_defaults", "standard")
local taille  = registre.get("galaxy_size",    preset.map_size)
print(taille.map_X, taille.map_Y)

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
