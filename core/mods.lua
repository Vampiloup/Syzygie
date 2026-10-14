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

local function charger_mod(id)
  if not id:match("^[a-z0-9_]+$") then error("id de mod invalide : " .. id) end
  local base = "mods/" .. id .. "/"

  -- 1. Manifeste

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

  -- 2. Fichiers de données, dans l'ordre du manifeste
  for _, fichier in ipairs(manifeste.donnees) do
    local chemin = base .. fichier
    local donnees = json_io.lire(chemin)
    if type(donnees) ~= "table" then error(chemin .. " doit contenir un objet JSON") end
    for categorie, liste in pairs(donnees) do
      if type(categorie) ~= "string" then error(chemin .. " : le niveau supérieur doit être un objet (clés nommées), pas un tableau") end
      if type(liste) ~= "table" then error(chemin .. " : la catégorie '" .. categorie .. "' doit être une liste") end
      for i, def in ipairs(liste) do
        if type(def) ~= "table" or type(def.id) ~= "string" then error(chemin .. " : " .. categorie .. "[" .. i .. "] n'a pas d'id valide") end
        def.id_complet = id .. ":" .. def.id
        registre.add(categorie, def.id_complet, def)
      end
    end
  end

    -- 3. Textes : mods/<id>/langues/<lang>/*.lua

  local dossier = base .. "langues/"
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
  return manifeste
end


function M.verifier_references()
  for _, r in ipairs(REFERENCES) do                      -- 1. pour chaque règle de la table
    local categorie, champ, cible = r[1], r[2], r[3]
    for _, def in ipairs(registre.list(categorie)) do    -- 2. pour chaque entrée de cette catégorie
      local ref = def[champ]                             --    ex. def.map_form = "defaut:disc_uniform"
      if type(ref) ~= "string" then                      -- 3a. le champ est-il bien un texte ?
        error(categorie .. " '" .. def.id .. "' : le champ '" .. champ .. "' est manquant ou n'est pas une chaîne")
      end
      if not registre.has(cible, ref) then               -- 3b. cette clé existe-t-elle dans la cible ?
        error(categorie .. " '" .. def.id .. "' : '" .. champ .. "' référence '" .. ref .. "', introuvable dans " .. cible)
      end
    end
  end
end


function M.charger_defaut()
  M.actifs = { charger_mod("defaut") }
end

return M
