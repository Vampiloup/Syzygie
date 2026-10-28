-- ui.hud.lua
--
-- CE QUI A CHANGÉ PAR RAPPORT À L'ANCIENNE VERSION (repéré par "MODIF") :
--   MODIF 1 : chaque bouton du HUD devient un vrai widget bouton.lua.
--   MODIF 2 : place() écrit dans un rectangle (b.rect) que le widget lit.
--   MODIF 3 : les callbacks de la couche se contentent de transmettre aux widgets.
--   MODIF 4 : disparition de trouver(), survol, enfonce et du dessin maison.
--   Le calcul des files de boutons (groupes, ancres, directions) est INCHANGÉ :
--   c'est la vraie spécificité du HUD, elle reste ici.

local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local bouton    = require("ui.widgets.bouton")   -- MODIF 1 : remplace i18n et screen,
                                                  -- dont le HUD n'a plus besoin directement

local MARGIN = 12
local ESPACE = 12


-- ancre = coin de départ ; dir = sens de la file
local groupes = {
  { ancre = "bas-gauche", dir = "droite", boutons = {
      { id = "empire",           w = 120, h = 40 },
      { id = "science",          w = 120, h = 40 },
      { id = "diplomatie",       w = 120, h = 40 },
      { id = "economie",         w = 120, h = 40 },
  }},
  { ancre = "haut-droite", dir = "gauche", boutons = {
      { id = "reglages",         w = 120, h = 40 },
  }},
  { ancre = "bas-droite", dir = "gauche", boutons = {
      { id = "appel_tour",       w = 160, h = 48 },
  }},
--    { ancre = "centre", dir = "bas", boutons = {
--    { id = "nouvelle_partie",  w = 240, h = 48 },
--    { id = "options",          w = 240, h = 48 },
--    { id = "quitter",          w = 240, h = 48 },
--  }},
}

-- (ax, ay) : 0 = gauche/haut, 1 = droite/bas
local ANCRES = {
  ["haut-gauche"] = {0, 0}, ["haut-droite"] = {1, 0},
  ["bas-gauche"]  = {0, 1}, ["bas-droite"]  = {1, 1},
  ["centre"] = {0.5, 0.5},
}
local DIRS = {
  droite = {1, 0}, gauche = {-1, 0}, bas = {0, 1}, haut = {0, -1},
}

-- liste à plat pour le survol, le clic et le dessin
local tous = {}
for _, g in ipairs(groupes) do
  assert(ANCRES[g.ancre], "ancre inconnue : " .. tostring(g.ancre))
  assert(DIRS[g.dir],     "direction inconnue : " .. tostring(g.dir))
  for _, b in ipairs(g.boutons) do
    tous[#tous + 1] = b

    -- MODIF 1 : on crée le widget de chaque bouton ici, une seule fois, au chargement.
    -- b.rect est le "parent" du widget : un rectangle {x, y, w, h}.
    -- bouton.lua lit ce rectangle à chaque dessin/clic (il est passé par
    -- référence), donc quand place() le modifie, le widget suit tout seul.
    -- x et y valent 0 pour l'instant : place() les remplira au premier "resize".
    b.rect = { x = 0, y = 0, w = b.w, h = b.h }

    b.widget = bouton.new(b.rect, {
      id  = b.id,
      w   = b.w,
      h   = b.h,
      cle = "hud_general." .. b.id,   -- même clé i18n qu'avant (ex-b.cle)
      -- Quand le clic est validé, le widget appelle cette fonction avec son id.
      -- C'est elle qui émet l'événement : les autres modules n'ont rien à changer.
      action = function(id) events.emit("hud_bouton", id) end,
    })
    -- Pas d'ancre ni de décalage donnés : valeurs par défaut de bouton.lua
    -- ("haut-gauche", décalage 0), donc le widget se place exactement sur b.rect.
  end
end



-- placement : ancré en bas à gauche, dans les bornes réelles de la fenêtre
local function place(left, top, right, bottom)
  local W, H = right - left, bottom - top

  for _, g in ipairs(groupes) do
    local ax, ay = unpack(ANCRES[g.ancre])
    local dx, dy = unpack(DIRS[g.dir])
    local liste  = g.boutons

    local gw, gh = 0, 0
    for i, b in ipairs(liste) do
      local esp = (i > 1) and ESPACE or 0
      if dx ~= 0 then gw = gw + b.w + esp; gh = math.max(gh, b.h)
      else            gh = gh + b.h + esp; gw = math.max(gw, b.w) end
    end

    local x = math.floor(left + MARGIN + (W - 2 * MARGIN - gw) * ax)
    local y = math.floor(top  + MARGIN + (H - 2 * MARGIN - gh) * ay)

    local debut, fin, pas = 1, #liste, 1
    if dx < 0 or dy < 0 then debut, fin, pas = #liste, 1, -1 end

    for i = debut, fin, pas do
      local b = liste[i]
      -- MODIF 2 : on écrit dans b.rect au lieu de b.x / b.y.
      -- Le screen.snap() a disparu d'ici : bouton.lua l'applique déjà lui-même
      -- à chaque lecture, inutile de le faire deux fois.
      if dx ~= 0 then
        b.rect.x = x
        b.rect.y = y + (gh - b.h) * ay  -- Alignement perpendiculaire.
        x = x + b.w + ESPACE
      else
        b.rect.y = y
        b.rect.x = x + (gw - b.w) * ax
        y = y + b.h + ESPACE
      end
    end
  end
end
events.on("resize", place)

-- MODIF 4 : trouver(), survol et enfonce ont disparu. Chaque widget connaît
-- maintenant son propre état (b.survol / b.enfonce dans bouton.lua).

couches.add({
  z = couches_z.HUD,

  -- uniquement sur les boutons, pas sur toute la barre
  -- MODIF 3 : on demande à chaque widget s'il contient le point.
  contient = function(px, py)
    for _, b in ipairs(tous) do
      if b.widget.contient(px, py) then return true end
    end
    return false
  end,

  -- MODIF 4 : plus de dessin maison (rectangle, couleurs, texte) : le widget s'en charge.
  draw = function()
    for _, b in ipairs(tous) do b.widget.draw() end
  end,

  -- MODIF 3 : press/release/move/leave sont transmis aux widgets.
  -- press() renvoie true si le widget a consommé l'événement : on s'arrête alors
  -- (un seul bouton peut être enfoncé à la fois).
  onpress = function(x, y, button)
    for _, b in ipairs(tous) do
      if b.widget.press(x, y, button) then return end
    end
  end,

  -- La règle "press et release sur le même bouton" est maintenant dans bouton.lua :
  -- release() ne déclenche l'action que si le widget était enfoncé ET que
  -- la souris est encore dessus. Le widget non enfoncé renvoie false : on continue.
  onrelease = function(x, y, button)
    for _, b in ipairs(tous) do
      if b.widget.release(x, y, button) then return end
    end
  end,

  -- Ici PAS de "return" anticipé : tous les boutons doivent mettre leur survol à jour
  -- (celui qu'on quitte doit s'éteindre, celui qu'on entre doit s'allumer).
  onmove = function(x, y)
    for _, b in ipairs(tous) do b.widget.move(x, y) end
  end,

  -- Remet survol ET enfoncé à zéro (avant, seul le survol l'était : petit oubli corrigé).
  onleave = function()
    for _, b in ipairs(tous) do b.widget.leave() end
  end,
})
