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
    local donnees = chunk_d()

    for categorie, liste in pairs(donnees) do
      for _, def in ipairs(liste) do
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
