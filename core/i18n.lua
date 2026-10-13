local json = require("libs.dkjson.dkjson")              -- Librairie json

local M = {}

local REPLI    = "en"      -- mettre nil pour désactiver le repli
local sources  = {}        -- sources[lang] = { { chemin = ..., domaine = nil|"event" }, ... }
local courante = nil       -- langue chargée
local repli    = nil       -- langue de repli, chargée seulement au premier besoin

local function lire_table(chemin)
  local info = love.filesystem.getInfo(chemin)
  if not info then error("[i18n] Fichier introuvable : " .. chemin, 0) end
  if info.type ~= "file" then error("[i18n] " .. chemin .. " n'est pas un fichier (type : " .. info.type .. ").", 0) end
  local src, err = love.filesystem.read(chemin)
  if not src then error("[i18n] Lecture impossible de " .. chemin .. " : " .. tostring(err), 0) end
  if src:sub(1, 3) == "\239\187\191" then src = src:sub(4) end    -- Certains éditeurs (Notepad…) ajoutent un BOM UTF-8 que dkjson refuse
  local tbl, pos, jerr = json.decode(src, 1, nil)
  if jerr then error("[i18n] JSON invalide dans " .. chemin .. " (position " .. tostring(pos) .. ") : " .. jerr, 0) end
  if type(tbl) ~= "table" then error("[i18n] " .. chemin .. " doit contenir un objet JSON.", 0) end

  for k, v in pairs(tbl) do
    if type(k) ~= "string" then error("[i18n] " .. chemin .. " : La clé " .. tostring(k) .. " doit être une chaîne.",0) end
    if type(v) ~= "string" and type(v) ~= "table" then error("[i18n] " .. chemin .. " : Valeur invalide '" .. tostring(k) .. "' : La valeur doit être une chaîne ou une table.",0) end
    if v == "" then
      print ("[i18n] " .. chemin .. " : '" .. tostring(k) .. "' : valeur vide ignorée.")
      tbl[k] = nil
    elseif type(v) == "table"  then
      if next(v) == nil then error("[i18n] " .. chemin .. " : valeur invalide '" .. tostring(k) .. "' : La table ne doit pas être vide.",0) end
      local vide = false
      for k2, v2 in pairs(v) do
        if type(k2) ~= "string" then error("[i18n] " .. chemin .. " : Valeur invalide '" .. tostring(k) .. "' >> '" .. tostring(k2) .."' : La clef doit être une chaîne.",0) end
        if type(v2) ~= "string" then error("[i18n] " .. chemin .. " : Valeur invalide '" .. tostring(k) .. "' >> '" .. tostring(k2) .."' : La valeur doit être une chaîne.",0) end
        if v2 == "" then vide = true end
      end
      if vide then
        print("[i18n] " .. chemin .. " : '" .. tostring(k) .. "' : une forme est vide, entrée ignorée.")
        tbl[k] = nil                       -- une table à moitié remplie est pire que pas de table
      end
    end
  end
  return tbl
end
-- Bonne pratique :  ignorer au chargement toute clé commençant par _ (par exemple "_todo.galaxy_form.carre": "square" pour mettre en attente).

local function nouvelle(lang)             -- charge les fichiers "immédiats" de cette langue
  local l = { lang = lang, eager = {}, lazy = {} }
  for _, s in ipairs(sources[lang] or {}) do
    if s.domaine == nil then
      for k, v in pairs(lire_table(s.chemin)) do l.eager[k] = v end
    end
  end
  return l
end

local function domaine_de(l, domaine)     -- charge un domaine paresseux au besoin
  if l.lazy[domaine] then return l.lazy[domaine] end
  local tbl, trouve = {}, false
  for _, s in ipairs(sources[l.lang] or {}) do
    if s.domaine == domaine then
      trouve = true
      for k, v in pairs(lire_table(s.chemin)) do tbl[k] = v end
    end
  end
  if not trouve then return nil end
  l.lazy[domaine] = tbl
  return tbl
end

local function chercher(l, cle)
  local v = l.eager[cle]
  if v then return v end
  local d = cle:match("^([^.]+)%.")
  local p = d and domaine_de(l, d)
  return p and p[cle]
end

function M.declarer(lang, chemin, domaine)   -- appelé par mods.lua : aucune lecture ici
  sources[lang] = sources[lang] or {}
  table.insert(sources[lang], { chemin = chemin, domaine = domaine })
end

function M.langues()                         -- pour un menu de choix de langue
  local res = {}
  for lang in pairs(sources) do res[#res + 1] = lang end
  table.sort(res)
  return res
end

function M.definir(lang)
  if not sources[lang] then error("Langue inconnue : " .. tostring(lang)) end
  courante = nouvelle(lang)
  repli = nil
  collectgarbage()                           -- libère l'ancienne langue
end

function M.t(cle)
  local v = chercher(courante, cle)
  if v then return v end
  if REPLI and courante.lang ~= REPLI and sources[REPLI] then
    repli = repli or nouvelle(REPLI)         -- chargé seulement au premier texte manquant
    v = chercher(repli, cle)
    if v then return v end
  end
  return cle
end

function M.tc(categorie, id_complet)
  return M.t(categorie .. "." .. id_complet)
end

return M
