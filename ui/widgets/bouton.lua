-- ui.widgets.bouton.lua
-- Bouton générique, même interface que ui.widgets.fermer :
-- contient / draw / press / release / move / leave
--
-- CE QUI A CHANGÉ PAR RAPPORT À L'ANCIENNE VERSION (repéré par "MODIF") :
--   MODIF 1 : l'état du bouton est calculé à un seul endroit (etat()).
--   MODIF 2 : le dessin est sorti dans une fonction "style" remplaçable.
--   Tout le reste (placement, press/release/move/leave) est inchangé.

local screen = require("affichage.ecran")
local i18n   = require("core.i18n")

local M = {}

-- (ax, ay) : 0 = gauche/haut, 1 = droite/bas (mêmes noms que le HUD)
local ANCRES = {
  ["haut-gauche"] = {0, 0}, ["haut-droite"] = {1, 0},
  ["bas-gauche"]  = {0, 1}, ["bas-droite"]  = {1, 1},
  ["centre"]      = {0.5, 0.5},
}

-- MODIF 2 : table des couleurs, indexée par l'état.
-- Avant, ces nombres (0.15, 0.25, 0.35...) étaient noyés dans draw().
-- Les mettre ici les rend faciles à retrouver et à changer.
-- Chaque entrée : { niveau de gris, opacité du fond, opacité du texte }
local COULEURS = {
  normal  = { 0.15, 0.9, 1.0 },
  survol  = { 0.25, 0.9, 1.0 },
  enfonce = { 0.35, 0.9, 1.0 },
  inactif = { 0.10, 0.5, 0.4 },
}

-- MODIF 2 : le "style" = la seule fonction qui sait COMMENT dessiner.
-- Elle reçoit tout ce qu'il lui faut en paramètres et ne connaît rien
-- de la logique du bouton (clics, survol...). C'est ça, la séparation
-- comportement / rendu.
-- Plus tard, un style "sprite" aura exactement la même signature :
--   function(x, y, w, h, etat, texte)
-- mais appellera love.graphics.draw(...) au lieu de rectangle(...).
function M.style_defaut(x, y, w, h, etat, texte)
  local niveau, alpha_fond, alpha_texte = unpack(COULEURS[etat])

  love.graphics.setColor(niveau, niveau, niveau + 0.05, alpha_fond)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)

  local font = love.graphics.getFont()
  love.graphics.setColor(1, 1, 1, alpha_texte)
  love.graphics.printf(texte, x, y + (h - font:getHeight()) / 2, w, "center")

  love.graphics.setColor(1, 1, 1)   -- on remet la couleur par défaut pour ne pas "polluer" le dessin suivant
end

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
--   style  = function(x, y, w, h, etat, texte) (optionnel) ; MODIF 2 : dessin personnalisé,
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

  -- MODIF 1 : l'état est décidé ici, UNE fois, dans un ordre de priorité clair
  -- (inactif l'emporte sur tout, puis enfoncé, puis survol).
  -- Avant, cette logique était écrite en une ligne compacte dans draw().
  -- Maintenant, draw() ne fait que lire le résultat.
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

  -- MODIF 1 + 2 : draw() ne dessine plus rien lui-même.
  -- Il rassemble les informations (position, état, texte) et les confie au style.
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
