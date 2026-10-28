-- ui.hud.lua
--
-- ÉTAPE 2 : les boutons ne sont plus écrits en dur dans ce fichier,
-- ils sont lus dans le registre (catégories "hud_groupe" et "hud_bouton").
--
-- CE QUI A CHANGÉ PAR RAPPORT À L'ÉTAPE 1 (repéré par "MODIF") :
--   MODIF A : le module renvoie maintenant une table M, avec une fonction M.init().
--   MODIF B : la table "groupes" n'est plus écrite à la main : init() la remplit.
--   MODIF C : init() VALIDE les données avant de les utiliser.
--   MODIF D : init() place les boutons elle-même à la fin.
--   Inchangés : le calcul de placement (place), les callbacks de la couche,
--   et le fait que chaque bouton est un widget bouton.lua.

local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local registre  = require("core.registre")       -- MODIF B : pour lire les données
local screen    = require("affichage.ecran")      -- MODIF D : pour le placement initial
local bouton    = require("ui.widgets.bouton")

-- MODIF E : même vocabulaire que hud_panneau (ancrage_x / ancrage_y), au lieu
-- d'une ancre combinée ("bas-gauche"). Chaque mot est traduit en nombre :
-- 0 = gauche/haut, 0.5 = centre, 1 = droite/bas (les "ax" et "ay" de place()).
local ANCRAGE_X = { gauche = 0, centre = 0.5, droite = 1 }
local ANCRAGE_Y = { haut   = 0, centre = 0.5, bas    = 1 }
local DIRS = {
  droite = {1, 0}, gauche = {-1, 0}, bas = {0, 1}, haut = {0, -1},
}

-- MODIF A : table du module. C'est ce que "require('ui.hud')" renverra,
-- ce qui permet à main.lua d'écrire hud.init().
local M = {}

-- MODIF B : ces deux tables sont créées VIDES ici et remplies plus tard par init().
-- Important : on ne les remplace jamais par une nouvelle table (pas de "groupes = {...}"
-- dans init), on les remplit. Ainsi la couche et place(), définies plus bas,
-- voient automatiquement le contenu une fois init() passée.
local groupes = {}   -- { {id=, ancre=, dir=, boutons={...}}, ... }
local tous    = {}   -- liste à plat des boutons pour le survol, le clic et le dessin

local initialise = false


-- placement : inchangé par rapport à l'étape 1.
-- Défini AVANT init() car init() l'appelle (en Lua, une "local function"
-- doit être déclarée avant l'endroit où on l'utilise).
local function place(left, top, right, bottom)
  local W, H = right - left, bottom - top

  for _, g in ipairs(groupes) do
    local ax, ay, mx, my, es = g.ax, g.ay, g.mx, g.my, g.es          -- MODIF E : déjà convertis en nombres par init()
    local dx, dy = unpack(DIRS[g.dir])
    local liste  = g.boutons

    local gw, gh = 0, 0
    for i, b in ipairs(liste) do
      local esp = (i > 1) and es or 0
      if dx ~= 0 then gw = gw + b.w + esp; gh = math.max(gh, b.h)
      else            gh = gh + b.h + esp; gw = math.max(gw, b.w) end
    end

    local x = math.floor(left + mx + (W - 2 * mx - gw) * ax)
    local y = math.floor(top  + my + (H - 2 * my - gh) * ay)

    local debut, fin, pas = 1, #liste, 1
    if dx < 0 or dy < 0 then debut, fin, pas = #liste, 1, -1 end

    for i = debut, fin, pas do
      local b = liste[i]
      if dx ~= 0 then
        b.rect.x = x
        b.rect.y = y + (gh - b.h) * ay  -- Alignement perpendiculaire.
        x = x + b.w + es
      else
        b.rect.y = y
        b.rect.x = x + (gw - b.w) * ax
        y = y + b.h + es
      end
    end
  end
end
events.on("resize", place)


-- MODIF B + C : lecture et validation des données, puis création des widgets.
-- À appeler UNE fois, depuis love.load(), APRÈS mods.charger()
-- (avant, le registre est vide).
function M.init()
  if initialise then error("hud.init() ne doit être appelée qu'une seule fois") end
  initialise = true

  -- Valeurs par défaut des boutons (entrée "general", comme dans hud_panneau).
  local defauts = registre.get("hud_bouton", "general")
  for _, champ in ipairs({ "w", "h" }) do
    if type(defauts[champ]) ~= "number" then
      error("hud_bouton 'general' : le champ '" .. champ .. "' est manquant ou n'est pas un nombre")
    end
  end

  -- 1. Les groupes. registre.list() les renvoie dans l'ordre d'enregistrement.
  -- par_id sert à retrouver un groupe à partir de son nom (utilisé à l'étape 2).
  local par_id = {}
  for _, def in ipairs(registre.list("hud_groupe")) do
    -- MODIF E : les deux champs sont obligatoires (pas de valeur par défaut).
    -- Lire ANCRAGE_X[nil] ne plante pas en Lua, ça renvoie nil : le test fonctionne
    -- donc aussi quand le champ est absent.
    local ax, ay, mx, my, es = ANCRAGE_X[def.ancrage_x], ANCRAGE_Y[def.ancrage_y], def.margin_x, def.margin_y, def.espace
    if not ax then
      error("hud_groupe '" .. def.id .. "' : ancrage_x inconnu : " .. tostring(def.ancrage_x))
    end
    if not ay then
      error("hud_groupe '" .. def.id .. "' : ancrage_y inconnu : " .. tostring(def.ancrage_y))
    end
    if not mx then
      error("hud_groupe '" .. def.id .. "' : margin_x inconnu : " .. tostring(def.margin_x))
    end
    if not my then
      error("hud_groupe '" .. def.id .. "' : margin_y inconnu : " .. tostring(def.margin_y))
    end
    if not es then
      error("hud_groupe '" .. def.id .. "' : espace inconnu : " .. tostring(def.espace))
    end
    if not DIRS[def.dir] then
      error("hud_groupe '" .. def.id .. "' : direction inconnue : " .. tostring(def.dir))
    end
    local g = { id = def.id, ax = ax, ay = ay, mx = mx, my = my, es = es, dir = def.dir, boutons = {} }
    groupes[#groupes + 1] = g
    par_id[def.id] = g
  end

  -- 2. Les boutons : on les range dans leur groupe, en vérifiant tout.
  local ordres = {}   -- ordres[groupe][numero] = id du bouton qui occupe ce numéro
  for _, def in ipairs(registre.list("hud_bouton")) do
    if def.id ~= "general" then          -- "general" = valeurs par défaut, pas un vrai bouton
      local g = par_id[def.groupe]
      if not g then
        error("hud_bouton '" .. def.id .. "' : groupe inconnu : " .. tostring(def.groupe))
      end
      if type(def.ordre) ~= "number" then
        error("hud_bouton '" .. def.id .. "' : le champ 'ordre' est manquant ou n'est pas un nombre")
      end

      -- Deux boutons du même groupe avec le même ordre : erreur claire,
      -- plutôt que de laisser le hasard décider lequel passe en premier.
      ordres[g] = ordres[g] or {}
      local deja = ordres[g][def.ordre]
      if deja then
        error("hud_bouton '" .. def.id .. "' : l'ordre " .. def.ordre ..
              " du groupe '" .. g.id .. "' est déjà pris par '" .. deja .. "'")
      end
      ordres[g][def.ordre] = def.id

      -- "a or b" : prend a s'il existe, sinon b. Donne ici la valeur propre au bouton
      -- si elle est présente, sinon la valeur par défaut de "general".
      local w, h = def.w or defauts.w, def.h or defauts.h
      if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then
        error("hud_bouton '" .. def.id .. "' : w et h doivent être des nombres positifs")
      end

      g.boutons[#g.boutons + 1] = { id = def.id, ordre = def.ordre, w = w, h = h }
    end
  end

  -- 3. Tri par 'ordre', puis création des widgets (même code qu'à l'étape 1).
  for _, g in ipairs(groupes) do
    table.sort(g.boutons, function(a, b) return a.ordre < b.ordre end)
    for _, b in ipairs(g.boutons) do
      tous[#tous + 1] = b
      b.rect = { x = 0, y = 0, w = b.w, h = b.h }
      b.widget = bouton.new(b.rect, {
        id  = b.id,
        w   = b.w,
        h   = b.h,
        cle = "hud_general." .. b.id,   -- clé i18n : toujours construite à partir de l'id
        action = function(id) events.emit("hud_bouton", id) end,
      })
    end
  end

  -- MODIF D : on place tout de suite. Avant, il fallait compter sur l'événement
  -- "resize" émis par main.lua APRÈS init(). Maintenant l'ordre des deux appels
  -- dans love.load() n'a plus d'importance pour le HUD.
  place(screen.bounds())
end


-- La couche est toujours créée au chargement du module (comme avant).
-- Au début, "tous" est vide : rien à dessiner, rien à cliquer. Après init(), il est rempli.
couches.add({
  z = couches_z.HUD,

  -- uniquement sur les boutons, pas sur toute la barre
  contient = function(px, py)
    for _, b in ipairs(tous) do
      if b.widget.contient(px, py) then return true end
    end
    return false
  end,

  draw = function()
    for _, b in ipairs(tous) do b.widget.draw() end
  end,

  onpress = function(x, y, button)
    for _, b in ipairs(tous) do
      if b.widget.press(x, y, button) then return end
    end
  end,

  onrelease = function(x, y, button)
    for _, b in ipairs(tous) do
      if b.widget.release(x, y, button) then return end
    end
  end,

  -- Pas de "return" anticipé : tous les boutons mettent leur survol à jour.
  onmove = function(x, y)
    for _, b in ipairs(tous) do b.widget.move(x, y) end
  end,

  onleave = function()
    for _, b in ipairs(tous) do b.widget.leave() end
  end,
})

return M   -- MODIF A
