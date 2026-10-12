local M = {}
local textes = {}                               -- textes["fr"]["galaxy_form.defaut:square"] = "Carrée"
local langue = "en"
local REPLI  = "en"

function M.ajouter(lang, tbl, source)           -- fusionne (appelé par le chargeur de mods)
  textes[lang] = textes[lang] or {}
  for k, v in pairs(tbl) do
    if textes[lang][k] ~= nil then
      print("[i18n] clé écrasée (" .. lang .. ") : " .. k .. " <- " .. tostring(source))
    end
    textes[lang][k] = v
  end
end

function M.definir(lang)
  if not textes[lang] then error("Langue inconnue : " .. tostring(lang)) end
  langue = lang
end

function M.t(cle)                                  -- langue courante, puis anglais, puis la clé brute
  local t = textes[langue]
  return (t and t[cle]) or (textes[REPLI] and textes[REPLI][cle]) or cle
end

function M.tc(categorie, id_complet)
  return M.t(categorie .. "." .. id_complet)
end

function M.manquantes(categories)                   -- à appeler en debug
  local registre = require "core.registre"
  for lang, t in pairs(textes) do
    for _, cat in ipairs(categories) do
      for _, def in ipairs(registre.list(cat)) do
        local cle = cat .. "." .. def.id_complet
        if not t[cle] then print("[i18n] " .. lang .. " : manque " .. cle) end
      end
    end
  end
end

return M
