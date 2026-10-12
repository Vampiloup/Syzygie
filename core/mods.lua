local registre = require "core.registre"

local M = {}
local API_VERSION = 1  -- version du contrat actuellement supportée par le jeu

local REFERENCES = {
  { "galaxy_defaults", "map_form",    "galaxy_form"    },
  { "galaxy_defaults", "map_size",    "galaxy_size"    },
  { "galaxy_defaults", "map_density", "galaxy_density" },
}

local function charger_mod(id)
  if not id:match("^[a-z0-9_]+$") then error("id de mod invalide : " .. id) end
  local base = "mods/" .. id .. "/"

  -- 1. Manifeste

  local chemin_man = base .. "manifeste.lua"
  local chunk_man, err_man = love.filesystem.load(chemin_man)
  if not chunk_man then error("Manifeste illisible pour " .. id .. " : " .. err_man) end
  setfenv(chunk_man, {})  -- aucun accès aux globales
  local ok_man, manifeste = pcall(chunk_man)
  if not ok_man then error("Erreur d'exécution dans " .. chemin_man .. " : " .. tostring(manifeste)) end
  if type(manifeste) ~= "table" then
    error(chemin_man .. " doit retourner une table")
  end
  if manifeste.id ~= id then
    error(chemin_man .. " : id '" .. tostring(manifeste.id) .. "' différent du dossier '" .. id .. "'")
  end
  if manifeste.api_version ~= API_VERSION then
    error(chemin_man .. " : api_version " .. tostring(manifeste.api_version) .. " non supportée (attendu : " .. API_VERSION .. ")")
  end
  if type(manifeste.donnees) ~= "table" then
    error(chemin_man .. " : 'donnees' doit être une liste de fichiers")
  end
  for i, f in ipairs(manifeste.donnees) do
    if type(f) ~= "string" then
      error(chemin_man .. " : donnees[" .. i .. "] doit être un nom de fichier (chaîne)")
    end
  end
  manifeste.requiert = manifeste.requiert or {}   -- valeur par défaut

  -- 2. Fichiers de données, dans l'ordre du manifeste
  for _, fichier in ipairs(manifeste.donnees) do
    local chemin = base .. fichier

    local chunk_d, err_d = love.filesystem.load(chemin)
    if not chunk_d then error("Erreur de syntaxe dans " .. chemin .. " : " .. err_d) end

    setfenv(chunk_d, {})  -- aucun accès aux globales
    local ok, donnees = pcall(chunk_d)
    if not ok then error("Erreur d'exécution dans " .. chemin .. " : " .. tostring(donnees)) end
    if type(donnees) ~= "table" then
      error(chemin .. " doit retourner une table")
    end

    for categorie, liste in pairs(donnees) do
      if type(liste) ~= "table" then
        error(chemin .. " : la catégorie '" .. tostring(categorie) .. "' doit être une liste")
      end
      for i, def in ipairs(liste) do
        if type(def) ~= "table" or type(def.id) ~= "string" then
          error(chemin .. " : " .. categorie .. "[" .. i .. "] n'a pas d'id valide")
        end
        registre.add(categorie, id .. ":" .. def.id, def)
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
