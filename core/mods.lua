local registre = require "core.registre"

local M = {}

local function charger_mod(id)
  local base = "mods/" .. id .. "/"

  -- 1. Manifeste
  local chunk, err = love.filesystem.load(base .. "manifeste.lua")
  if not chunk then error("Manifeste illisible pour " .. id .. " : " .. err) end
  local manifeste = chunk()

  -- 2. Fichiers de données, dans l'ordre du manifeste
  for _, fichier in ipairs(manifeste.donnees) do
    local chunk_d, err_d = love.filesystem.load(base .. fichier)
    if not chunk_d then error("Erreur dans " .. base .. fichier .. " : " .. err_d) end

    setfenv(chunk_d, {})            -- le fichier de données n'a accès à aucune fonction globale
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

function M.charger_defaut()
  M.actifs = { charger_mod("defaut") }
end

return M
