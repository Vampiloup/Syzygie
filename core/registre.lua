local M = {}

local store, ordre = {}, {}   -- store["star_type"]["base:red_dwarf"] = { ... }

function M.add(category, id, definition)    -- Ajoute une ligne dans une table.
  store[category] = store[category] or {}
  ordre[category] = ordre[category] or {}
  if store[category][id] then error("Doublon : " .. category .. " " .. id) end
  store[category][id] = definition
  ordre[category][#ordre[category] + 1] = id
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

function M.list(category)                   -- renvoie la liste des tables / catégories
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

return M


-- local registre = require "core.registre"
--
-- registre.add("galaxy_form",    "defaut:square",
--             { nom = "Square" })
--
-- registre.add("galaxy_size",    "defaut:minuscule",
--             { nom = "minuscule", map_X = 1250, map_Y = 1250 })
--
-- registre.add("galaxy_density", "defaut:epars",
--             { nom = "épars", density = 0.5 })

-- local defauts = registre.get("galaxy_defaults", "defaut:standard")
-- local forme   = registre.get("galaxy_form",    defauts.map_form)
-- local taille  = registre.get("galaxy_size",    defauts.map_size)
-- local densite = registre.get("galaxy_density", defauts.map_density)
-- print(forme.nom)                -- Disc with uniform density
-- print(taille.map_X, taille.map_Y)  -- 2500  2500
-- print(densite.density)

-- registre.get(...).champ

-- local reponse = registre.get_field("galaxy_form", "defaut:disc_uniform", "nom")
-- print (reponse)
