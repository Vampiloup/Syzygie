-- ui.hud.lua
--
-- Les boutons du HUD sont lus dans le registre (catégories "hud_groupe" et "hud_bouton").
--
-- HISTORIQUE DES MODIFICATIONS (repérées par "MODIF" dans le code) :
--   MODIF A : le module renvoie une table M, avec une fonction M.init().
--   MODIF B : les tables "groupes" et "tous" sont remplies par init().
--   MODIF C : init() VALIDE les données avant de les utiliser.
--   MODIF D : init() place les boutons elle-même à la fin.
--   MODIF E : ancrage_x / ancrage_y, comme hud_panneau.
--   MODIF F : margin_x, margin_y et espace viennent du registre, avec une entrée
--             "general" de hud_groupe pour les valeurs par défaut.

local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local registre  = require("core.registre")
local screen    = require("affichage.ecran")
local bouton    = require("ui.widgets.bouton")

-- 0 = gauche/haut, 0.5 = centre, 1 = droite/bas (les "ax" et "ay" de place()).
local ANCRAGE_X = { gauche = 0, centre = 0.5, droite = 1 }
local ANCRAGE_Y = { haut   = 0, centre = 0.5, bas    = 1 }
local DIRS = {
  droite = {1, 0}, gauche = {-1, 0}, bas = {0, 1}, haut = {0, -1},
}

-- MODIF F : les trois champs numériques d'un groupe, listés une seule fois.
-- Utilisés pour valider "general" ET chaque groupe avec la même boucle.
local CHAMPS_GROUPE = { "margin_x", "margin_y", "espace" }

-- MODIF F : un nombre valide ici = un nombre supérieur ou égal à 0
-- (0 est accepté : pas de marge, ou pas d'espace entre les boutons).
local function nombre_valide(v)
  return type(v) == "number" and v >= 0
end

local M = {}

-- Créées VIDES ici et remplies par init() (on ne les remplace jamais par une
-- nouvelle table : la couche et place() voient ainsi le contenu une fois init() passée).
local groupes = {}   -- { {id=, ax=, ay=, mx=, my=, es=, dir=, boutons={...}}, ... }
local tous    = {}   -- liste à plat des boutons pour le survol, le clic et le dessin

local initialise = false


-- placement : défini AVANT init() car init() l'appelle (en Lua, une "local function"
-- doit être déclarée avant l'endroit où on l'utilise).
local function place(left, top, right, bottom)
  local W, H = right - left, bottom - top

  for _, g in ipairs(groupes) do
    -- MODIF F : marges et espacement propres à chaque groupe (convertis/validés par init()).
    local ax, ay, mx, my, es = g.ax, g.ay, g.mx, g.my, g.es
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


-- Lecture et validation des données, puis création des widgets.
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

  -- MODIF F : valeurs par défaut des groupes (entrée "general" de hud_groupe).
  -- On vérifie d'abord qu'elles sont elles-mêmes valides : sinon un groupe qui
  -- s'en sert hériterait d'une valeur fausse.
  local defauts_g = registre.get("hud_groupe", "general")
  for _, champ in ipairs(CHAMPS_GROUPE) do
    if not nombre_valide(defauts_g[champ]) then
      error("hud_groupe 'general' : '" .. champ ..
            "' est manquant ou n'est pas un nombre positif ou nul")
    end
  end

  -- 1. Les groupes. registre.list() les renvoie dans l'ordre d'enregistrement.
  -- par_id sert à retrouver un groupe à partir de son nom (utilisé à l'étape 2).
  local par_id = {}
  for _, def in ipairs(registre.list("hud_groupe")) do
    if def.id ~= "general" then          -- MODIF F : "general" = valeurs par défaut, pas un vrai groupe

      -- Ancrage et direction : obligatoires (pas de valeur par défaut).
      -- Lire ANCRAGE_X[nil] ne plante pas en Lua, ça renvoie nil : le test fonctionne
      -- donc aussi quand le champ est absent.
      local ax, ay = ANCRAGE_X[def.ancrage_x], ANCRAGE_Y[def.ancrage_y]
      if not ax then
        error("hud_groupe '" .. def.id .. "' : ancrage_x inconnu : " .. tostring(def.ancrage_x))
      end
      if not ay then
        error("hud_groupe '" .. def.id .. "' : ancrage_y inconnu : " .. tostring(def.ancrage_y))
      end
      if not DIRS[def.dir] then
        error("hud_groupe '" .. def.id .. "' : direction inconnue : " .. tostring(def.dir))
      end

      -- MODIF F : marges et espace. Valeur propre au groupe si elle existe, sinon celle
      -- de "general". On teste "== nil" (et non "or") pour que le code reste correct
      -- même si on veut un jour distinguer "absent" de "égal à zéro".
      local valeurs = {}
      for _, champ in ipairs(CHAMPS_GROUPE) do
        local v = def[champ]
        if v == nil then v = defauts_g[champ] end
        if not nombre_valide(v) then
          error("hud_groupe '" .. def.id .. "' : '" .. champ ..
                "' doit être un nombre positif ou nul")
        end
        valeurs[champ] = v
      end

      local g = {
        id = def.id, ax = ax, ay = ay, dir = def.dir,
        mx = valeurs.margin_x, my = valeurs.margin_y, es = valeurs.espace,
        boutons = {},
      }
      groupes[#groupes + 1] = g
      par_id[def.id] = g
    end
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

  -- 3. Tri par 'ordre', puis création des widgets.
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

  -- On place tout de suite : l'ordre des appels dans love.load() n'a ainsi
  -- plus d'importance pour le HUD.
  place(screen.bounds())
end


-- La couche est créée au chargement du module. Au début, "tous" est vide :
-- rien à dessiner, rien à cliquer. Après init(), il est rempli.
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

return M
