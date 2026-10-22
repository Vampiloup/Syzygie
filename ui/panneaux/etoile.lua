-- ui.panneaux.etoile

local events       = require("core.events")
local exclusif     = require("core.exclusif")
local screen       = require("affichage.ecran")
local couches      = require("core.couches")
local couches_z    = require("core.couches_z")
local registre     = require("core.registre")

local M = {}
local MARGIN = 24
-- local panel = { w = 1280, h = 768 }
local panel = { w = 1876, h = 768 }
local GROUPE = "panneaux_jeu"
local ouvert = false
local item
local close                             -- déclaration anticipée : onKey en a besoin avant sa définition.
local touche_open = nil                 -- touche d'accès à ce panneau.
local ID = "carte_etoile"               -- ID de ce panneau (utilisé pour les events, les mods...).
local etoile_id = nil     -- l'étoile actuellement affichée

  print ("etoile ouverte")

local function place(left, top, right, bottom)
  panel.x = right - panel.w - MARGIN
  panel.y = top + MARGIN
end

local function inside(x, y)
  return x >= panel.x and x <= panel.x + panel.w
     and y >= panel.y and y <= panel.y + panel.h
end

local function onDraw()
  love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
  love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 12, 12)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Étoile n° " .. tostring(etoile_id), panel.x + 16, panel.y + 16)
end

local function onClick(x, y, button)
  if button == 1 then print("Clic dans le panneau Etoile") end
  -- inutile de retester inside() : pick l'a déjà fait
end

local function onKey(key, scancode, isrepeat)
  if key == "x" then close() end      -- close sera assignée plus bas
end

local function open()
  if ouvert then return end
  exclusif.prendre(GROUPE, close)   -- ferme l'occupant du groupe, s'inscrit
  ouvert = true
  place(screen.bounds())
  events.on("keypressed", onKey)
  events.on("resize", place)

  item = couches.add({
    z = couches_z.PANNEAUX,
    contient = inside,
    onpress = onClick,
    draw = onDraw,                  -- remplace events.on("draw_ui", onDraw)
  })

end

function close()
  if not ouvert then return end
  ouvert = false
  etoile_id = nil                      -- pas de donnée périmée à la prochaine ouverture
  exclusif.liberer(GROUPE, close)
  events.off("keypressed", onKey)
  events.off("resize", place)
  couches.remove(item)
  item = nil
end

M.open = open
M.close = close
M.is_open = function() return ouvert end


-- l'argument est une donnée (numéro d'étoile), pas une adresse : pas de filtre sur ID
local function onCarteEtoile(id)
  etoile_id = id       -- ouvert ou non, on change l'étoile affichée
  open()               -- sans effet si déjà ouvert (le "if ouvert" de open)
end
events.on("carte_etoile", onCarteEtoile)

local function onToucheGlobale(key)
  touche_open = touche_open or registre.get_field("panneau_hub", ID, "touche")
  if key ~= touche_open then return end
  if ouvert then
    close()
  else
    etoile_id = etoile_id or 1   -- étoile par défaut si aucune n'est choisie
    open()
  end
end
events.on("keypressed", onToucheGlobale)

return M
