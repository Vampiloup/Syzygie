-- ui.widgets.bouton.lua
-- Bouton générique, même interface que ui.widgets.fermer :
-- contient / draw / press / release / move / leave
--
-- HISTORIQUE (repéré par "MODIF" dans le code) :
--   MODIF 1 : l'état du bouton est calculé à un seul endroit (etat()).
--   MODIF 2 : le dessin est sorti dans une fonction "style" remplaçable.
--   MODIF G : l'ancrage utilise ancrage_x / ancrage_y (comme hud_panneau et hud_groupe)
--             au lieu de l'ancre combinée "bas-gauche".

local screen = require("affichage.ecran")
local i18n   = require("core.i18n")

local M = {}

-- MODIF G : 0 = gauche/haut, 0.5 = centre, 1 = droite/bas (même vocabulaire que le HUD)
local ANCRAGE_X = { gauche = 0, centre = 0.5, droite = 1 }
local ANCRAGE_Y = { haut   = 0, centre = 0.5, bas    = 1 }

-- Couleurs par état : { niveau de gris, opacité du fond, opacité du texte }
local COULEURS = {
  normal  = { 0.15, 0.9, 1.0 },
  survol  = { 0.25, 0.9, 1.0 },
  enfonce = { 0.35, 0.9, 1.0 },
  inactif = { 0.10, 0.5, 0.4 },
}

-- Le "style" = la seule fonction qui sait COMMENT dessiner.
-- Un futur style sprite aura la même signature : function(x, y, w, h, etat, texte)
function M.style_defaut(x, y, w, h, etat, texte)
  local niveau, alpha_fond, alpha_texte = unpack(COULEURS[etat])

  love.graphics.setColor(niveau, niveau, niveau + 0.05, alpha_fond)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)

  local font = love.graphics.getFont()
  love.graphics.setColor(1, 1, 1, alpha_texte)
  love.graphics.printf(texte, x, y + (h - font:getHeight()) / 2, w, "center")

  love.graphics.setColor(1, 1, 1)
end

-- parent : table {x, y, w, h} passée par référence (le bouton suit ses changements).
--          nil = coordonnées absolues (virtuelles).
-- def    : {
--   id        = string (optionnel),
--   x, y      = décalage depuis l'ancrage, vers l'intérieur du parent (défaut 0),
--   w, h      = taille,
--   ancrage_x = "gauche" (défaut) | "centre" | "droite",      -- MODIF G
--   ancrage_y = "haut" (défaut)   | "centre" | "bas",         -- MODIF G
--   cle       = clé i18n (traduite à chaque dessin, donc compatible changement de langue à chaud),
--   texte     = texte brut si pas de clé,
--   action    = function(id) appelée quand le clic est validé,
--   actif     = function() -> bool (optionnel) ; faux = grisé et inerte,
--   style     = function(x, y, w, h, etat, texte) (optionnel) ; dessin personnalisé,
-- }
function M.new(parent, def)
  parent = parent or { x = 0, y = 0, w = 0, h = 0 }

  -- MODIF G : l'ancien champ 'ancre' n'existe plus. Si un fichier l'utilise encore,
  -- on le dit tout de suite avec un message clair, plutôt que de l'ignorer
  -- silencieusement (le bouton se retrouverait en haut à gauche sans explication).
  if def.ancre ~= nil then
    error("bouton '" .. tostring(def.id) .. "' : le champ 'ancre' n'est plus supporté, " ..
          "utiliser ancrage_x et ancrage_y", 2)
  end

  local ax = ANCRAGE_X[def.ancrage_x or "gauche"]
  local ay = ANCRAGE_Y[def.ancrage_y or "haut"]
  if not ax then
    error("bouton '" .. tostring(def.id) .. "' : ancrage_x inconnu : " .. tostring(def.ancrage_x), 2)
  end
  if not ay then
    error("bouton '" .. tostring(def.id) .. "' : ancrage_y inconnu : " .. tostring(def.ancrage_y), 2)
  end

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

  -- L'état est décidé ici, UNE fois, dans un ordre de priorité clair.
  local function etat()
    if not actif()  then return "inactif" end
    if b.enfonce    then return "enfonce" end
    if b.survol     then return "survol"  end
    return "normal"
  end

  function b.contient(x, y)
    local bx, by, bw, bh = rect()
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
  end

  function b.draw()
    local bx, by, bw, bh = rect()
    local texte = def.cle and i18n.t(def.cle) or def.texte or ""
    local style = def.style or M.style_defaut
    style(bx, by, bw, bh, etat(), texte)
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


-- Utilisation :
--   * Boutons du HUD   : créés par ui.hud (lus dans hud_bouton / hud_groupe).
--   * Boutons de panneau : créés par ui.widgets.panneau (lus dans hud_bouton_panneau).
--   * Ailleurs : bouton.new(parent, { id = "...", w = 160, h = 40,
--       ancrage_x = "centre", ancrage_y = "bas", cle = "...", action = function(id) ... end })
