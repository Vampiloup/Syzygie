-- ui.widgets.bouton.lua
-- Bouton générique, même interface que ui.widgets.fermer :
-- contient / draw / press / release / move / leave

local screen = require("affichage.ecran")
local i18n   = require("core.i18n")

local M = {}

-- (ax, ay) : 0 = gauche/haut, 1 = droite/bas (mêmes noms que le HUD)
local ANCRES = {
  ["haut-gauche"] = {0, 0}, ["haut-droite"] = {1, 0},
  ["bas-gauche"]  = {0, 1}, ["bas-droite"]  = {1, 1},
  ["centre"]      = {0.5, 0.5},
}

-- parent : table {x, y, w, h} passée par référence (le bouton suit ses changements).
--          nil = coordonnées absolues (virtuelles).
-- def    : {
--   id     = string (optionnel),
--   x, y   = décalage depuis l'ancre, vers l'intérieur du parent (défaut 0),
--   w, h   = taille,
--   ancre  = "haut-gauche" (défaut) | "haut-droite" | "bas-gauche" | "bas-droite" | "centre",
--   cle    = clé i18n (traduite à chaque dessin, donc compatible changement de langue à chaud),
--   texte  = texte brut si pas de clé,
--   action = function() appelée quand le clic est validé,
--   actif  = function() -> bool (optionnel) ; faux = grisé et inerte,
-- }
function M.new(parent, def)
  parent = parent or { x = 0, y = 0, w = 0, h = 0 }
  local a = assert(ANCRES[def.ancre or "haut-gauche"],
                   "ancre inconnue : " .. tostring(def.ancre))
  local ax, ay = a[1], a[2]
  local sx = (ax == 1) and -1 or 1      -- à droite / en bas, le décalage va vers l'intérieur
  local sy = (ay == 1) and -1 or 1
  local w, h = def.w, def.h

  local b = { id = def.id, survol = false, enfonce = false }

  -- calculé à chaque appel : suit le panneau après un resize
  local function rect()
    local x = parent.x + ax * (parent.w - w) + sx * (def.x or 0)
    local y = parent.y + ay * (parent.h - h) + sy * (def.y or 0)
    return screen.snap(x), screen.snap(y), w, h
  end

  local function actif()
    return def.actif == nil or def.actif()
  end

  function b.contient(x, y)
    local bx, by, bw, bh = rect()
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
  end

  function b.draw()
    local bx, by, bw, bh = rect()
    local ok = actif()
    local c = (not ok) and 0.1 or b.enfonce and 0.35 or b.survol and 0.25 or 0.15
    love.graphics.setColor(c, c, c + 0.05, ok and 0.9 or 0.5)
    love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)

    local texte = def.cle and i18n.t(def.cle) or def.texte or ""
    local font = love.graphics.getFont()
    love.graphics.setColor(1, 1, 1, ok and 1 or 0.4)
    love.graphics.printf(texte, bx, by + (bh - font:getHeight()) / 2, bw, "center")
    love.graphics.setColor(1, 1, 1)
  end

  -- true si le bouton a consommé l'événement (même désactivé : évite le clic "à travers")
  function b.press(x, y, button)
    if button ~= 1 or not b.contient(x, y) then return false end
    if actif() then b.enfonce = true end
    return true
  end

  function b.release(x, y, button)
    if button ~= 1 or not b.enfonce then return false end
    b.enfonce = false
    if b.contient(x, y) and actif() and def.action then def.action(def.id) end
    return true
  end

  function b.move(x, y) b.survol = b.contient(x, y) end

  function b.leave()
    b.survol = false
    b.enfonce = false
  end

  return b
end

return M


-- Utilisation (ne pas oublier ID, ici l'identifiant du bouton) :
--
--   boutons = {
--    { id = "test", x = 16, y = 16, w = 160, h = 40,
--    ancre = "bas-gauche", cle = "hud_empire.test",
--    action = function(id) events.emit("bouton_reglage", id) end },
--  },

-- local bouton_test   -- en début de module (définir cette fonction AVANT panneau.new)
--
--   boutons = {
--    { id = "test", x = 16, y = 16, w = 160, h = 40,
--    ancre = "bas-gauche", cle = "hud_empire.test",
-- action = function(id) bouton_test(id) end
-- ... plus bas :
-- bouton_test = function(id) ... end
--

