-- core.mods.lua
--
-- Le chargement se fait désormais en 3 phases :
--   1. LECTURE      : chaque mod est lu et validé, SANS toucher au registre (lire_mod)
--   2. FUSION       : les mods sont appliqués dans l'ordre de la liste (appliquer_mod)
--   3. VÉRIFICATION : les références croisées sont contrôlées une seule fois,
--                     sur le registre final (verifier_references)
-- Conséquence : un mod chargé plus tard écrase les champs du précédent,
-- et un mod peut référencer une entrée définie par un autre mod.

local registre = require "core.registre"
local i18n = require "core.i18n"
local json_io = require "core.json_io"

local M = {}
local API_VERSION = 1  -- version du contrat actuellement supportée par le jeu

local REFERENCES = {
  { "galaxy_defaults", "map_form",    "galaxy_form"    },
  { "galaxy_defaults", "map_size",    "galaxy_size"    },
  { "galaxy_defaults", "map_density", "galaxy_density" },
}

local function tries(dossier)
  local items = love.filesystem.getDirectoryItems(dossier)
  table.sort(items)                          -- ordre déterministe
  return items
end

-- ============================================================
-- PHASE 1 : lecture et validation d'un mod (aucun effet sur le registre)

-- Renvoie { manifeste, base, entrees = { {categorie=, def=}, ... } }
-- ============================================================
local function lire_mod(id)
  if not id:match("^[a-z0-9_]+$") then error("id de mod invalide : " .. id) end
  local base = "mods/" .. id .. "/"

  -- 1. Manifeste (validation inchangée, sauf 'requiert' désormais vérifié)

  local chemin_man = base .. "manifeste.json"
  local manifeste = json_io.lire(chemin_man)
  if type(manifeste) ~= "table"  or manifeste[1] ~= nil then error(chemin_man .. " doit contenir un objet JSON") end
  if manifeste.id ~= id then error(chemin_man .. " : id '" .. tostring(manifeste.id) .. "' différent du dossier '" .. id .. "'") end
  if manifeste.api_version ~= API_VERSION then error(chemin_man .. " : api_version " .. tostring(manifeste.api_version) .. " non supportée (attendu : " .. API_VERSION .. ")") end
  if type(manifeste.donnees) ~= "table" then error(chemin_man .. " : 'donnees' doit être une liste de fichiers") end
  for i, f in ipairs(manifeste.donnees) do
    if type(f) ~= "string" then error(chemin_man .. " : donnees[" .. i .. "] doit être un nom de fichier (chaîne)") end
  end
  manifeste.requiert = manifeste.requiert or {}   -- valeur par défaut
  if type(manifeste.requiert) ~= "table" then error(chemin_man .. " : 'requiert' doit être une liste d'id de mods") end
  for i, r in ipairs(manifeste.requiert) do
    if type(r) ~= "string" then error(chemin_man .. " : requiert[" .. i .. "] doit être un id de mod (chaîne)") end
  end

  -- 2. Fichiers de données, dans l'ordre du manifeste
  local entrees = {}
  local vus = {}   -- [étecte un doublon DANS un même mod.

  for _, fichier in ipairs(manifeste.donnees) do
    local chemin = base .. fichier
    local donnees = json_io.lire(chemin)
    if type(donnees) ~= "table" then error(chemin .. " doit contenir un objet JSON") end

    -- Les catégories sont triées avant parcours : pairs() n'a pas d'ordre garanti,
    -- ce qui rendait l'ordre d'enregistrement non déterministe.
    local noms = {}
    for categorie in pairs(donnees) do
      if type(categorie) ~= "string" then error(chemin .. " : le niveau supérieur doit être un objet (clés nommées), pas un tableau") end
      noms[#noms + 1] = categorie
    end
    table.sort(noms)

    for _, categorie in ipairs(noms) do
      local liste = donnees[categorie]
      if type(liste) ~= "table" then error(chemin .. " : la catégorie '" .. categorie .. "' doit être une liste") end
      for i, def in ipairs(liste) do
        if type(def) ~= "table" or type(def.id) ~= "string" then error(chemin .. " : " .. categorie .. "[" .. i .. "] n'a pas d'id valide") end
        local cle = categorie .. "\0" .. def.id
        if vus[cle] then error(chemin .. " : doublon " .. categorie .. " '" .. def.id .. "' dans le mod '" .. id .. "'") end
        vus[cle] = true
        entrees[#entrees + 1] = { categorie = categorie, def = def }
      end
    end
  end

  return { manifeste = manifeste, base = base, entrees = entrees }
end

-- ============================================================
-- PHASE 2 : application d'un mod lu sur le registre

-- ============================================================
local function appliquer_mod(mod)
  for _, e in ipairs(mod.entrees) do
    registre.merge(e.categorie, e.def.id, e.def, mod.manifeste.id)
  end

  -- 3. Textes : mods/<id>/langues/<lang>/*.json

  local dossier = mod.base .. "langues/"
  for _, lang in ipairs(tries(dossier)) do
    local dlang = dossier .. lang .. "/"
    if love.filesystem.getInfo(dlang, "directory") then
      for _, f in ipairs(tries(dlang)) do
        local chemin = dlang .. f
        if f:match("%.json$") then
          i18n.declarer(lang, chemin)
        elseif love.filesystem.getInfo(chemin, "directory") then
          for _, g in ipairs(tries(chemin)) do
            if g:match("%.json$") then i18n.declarer(lang, chemin .. "/" .. g, f) end
          end
        end
      end
    end
  end
end

-- PHASE 3 : vérification des références (inchangée)
-- Appelée une seule fois, par M.charger, après toutes les fusions.
function M.verifier_references()
  for _, r in ipairs(REFERENCES) do                      -- 1. pour chaque règle de la table
    local categorie, champ, cible = r[1], r[2], r[3]
    for _, def in ipairs(registre.list(categorie)) do    -- 2. pour chaque entrée de cette catégorie
      local ref = def[champ]                             --    ex. def.map_form = "disque_uniforme"
      if type(ref) ~= "string" then                      -- 3a. le champ est-il bien un texte ?
        error(categorie .. " '" .. def.id .. "' : le champ '" .. champ .. "' est manquant ou n'est pas une chaîne")
      end
      if not registre.has(cible, ref) then               -- 3b. cette clé existe-t-elle dans la cible ?
        error(categorie .. " '" .. def.id .. "' : '" .. champ .. "' référence '" .. ref .. "', introuvable dans " .. cible)
      end
    end
  end
end

-- ============================================================
-- Point d'entrée
-- Charge une liste ordonnée d'id de mods.
-- Le dernier de la liste a la priorité.
-- ============================================================
function M.charger(liste_ids)
  -- Phase 1 : tout lire et valider avant de modifier le registre
  local mods, position = {}, {}
  for i, id in ipairs(liste_ids) do
    if position[id] then error("mod présent deux fois dans la liste : " .. id) end
    mods[i] = lire_mod(id)
    position[id] = i
  end

  -- Dépendances : un mod requis doit être présent ET placé avant celui qui le requiert.
  -- (Pas de tri automatique pour l'instant : l'ordre de la liste fait foi.)
  for i, mod in ipairs(mods) do
    for _, req in ipairs(mod.manifeste.requiert) do
      if not position[req] then
        error("mod '" .. mod.manifeste.id .. "' requiert '" .. req .. "', qui n'est pas chargé")
      end
      if position[req] > i then
        error("mod '" .. mod.manifeste.id .. "' doit être chargé après '" .. req .. "'")
      end
    end
  end

  -- Phase 2 : fusion dans l'ordre
  for _, mod in ipairs(mods) do appliquer_mod(mod) end

  -- Phase 3 : vérification sur le résultat final
  M.verifier_references()

  M.actifs = {}
  for i, mod in ipairs(mods) do M.actifs[i] = mod.manifeste end
end

-- Plus tard : M.charger({ "defaut", "mod_du_joueur", ... })
function M.charger_defaut()
  M.charger({ "defaut" })
end

return M
