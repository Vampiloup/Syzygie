-- core.registre.lua

local M = {}

local store, ordre = {}, {}   -- store["star_type"]["red_dwarf"] = { ... }
-- [MODIF] Les id ne sont plus préfixés par le mod ("red_dwarf" et non "red_dwarf").

function M.add(category, id, definition)    -- Ajoute une ligne dans une table.
  store[category] = store[category] or {}
  ordre[category] = ordre[category] or {}
  if store[category][id] then error("Doublon : " .. category .. " " .. id) end
  store[category][id] = definition
  ordre[category][#ordre[category] + 1] = id
end

-- [MODIF] NOUVEAU. Crée l'entrée si elle n'existe pas, sinon fusionne champ par champ.
--   - fusion SUPERFICIELLE : un champ qui est lui-même une table est remplacé en entier.
--   - 'source' mémorise le dernier mod ayant touché l'entrée (utile au débogage).
--   - une entrée surchargée garde sa position d'origine dans l'ordre (list()).
function M.merge(category, id, definition, source)
  store[category] = store[category] or {}
  ordre[category] = ordre[category] or {}
  local existant = store[category][id]
  if existant then
    for champ, valeur in pairs(definition) do existant[champ] = valeur end
    existant.source = source
  else
    definition.source = source
    store[category][id] = definition
    ordre[category][#ordre[category] + 1] = id
  end
end

function M.list(category)                   -- renvoie les définitions dans l'ordre d'enregistrement
  local res = {}
  for i, id in ipairs(ordre[category] or {}) do res[i] = store[category][id] end
  return res
end

function M.get(category, id)                -- renvoie une ligne
  local def = store[category] and store[category][id]
  if not def then
    error("Inconnu : " .. tostring(category) .. " " .. tostring(id), 2)
  end
  return def
end

function M.get_field(category, id, field)
    local def = store[category] and store[category][id]
    if not def then
        error("Inconnu : " .. tostring(category) .. " " .. tostring(id), 2)
    end
    local def2 = store[category][id][field]
    if def2 == nil then
        error("Inconnu : " .. tostring(category) .. " " .. tostring(id) .. " " .. tostring(field), 2)
    end
    return def2
end

function M.table(category)                   -- renvoie la liste des tables / catégories
  return store[category] or {}
end

function M.has(category, id)                -- Indique via boléen si une catégorie est présente ou non.
  return store[category] ~= nil and store[category][id] ~= nil
end

function M.dump()                           -- renvoie un dump du registre.
  print ("fonction dump appelée")
  for categorie, ids in pairs(ordre) do
    print("[" .. categorie .. "]")
    for _, id in ipairs(ids) do
      print("  " .. id)
    end
  end
end

function M.clear(category)                                      -- Efface une catégorie
  store[category], ordre[category] = nil, nil
end

return M

-- local registre = require "core.registre"
--
-- local defauts = registre.get("galaxy_defaults", "standard")
-- local forme   = registre.get("galaxy_form",    map_form)
-- local taille  = registre.get("galaxy_size",    map_size)
-- local densite = registre.get("galaxy_density", map_density)
--
-- registre.get_field("panneau_hub", "empire", "touche")   -- "f1"
