-- core/starnames.lua
-- Moteur de noms d'étoiles (chaîne de Markov d'ordre 2). Ne contient AUCUN mot :
-- tout le contenu vient des mods, via le registre. Lua 5.1 / LuaJIT (LÖVE).
--
-- Catégories lues dans le registre (voir mods/defaut/noms_etoiles.json) :
--   noms_corpus      { id, langue, mots = {...} }
--       Plusieurs entrées peuvent viser la même langue : leurs mots sont réunis.
--       Étendre une langue = nouvel id, même "langue".
--       Surcharger = redéfinir un id existant : la liste "mots" est REMPLACÉE
--       en entier (fusion superficielle du registre).
--   noms_blacklist   { id, motifs = {...} }
--       Union de toutes les entrées. Un mod ne peut pas retirer un motif d'un
--       autre mod, sauf en redéfinissant l'id de l'entrée qui le contient.
--   noms_repartition { id, repartition = { { langue = "...", poids = n }, ... } }
--       Tableau ORDONNÉ (l'ordre des clés d'un objet JSON ne serait pas garanti).
--
-- Usage (après mods.charger) :
--   local StarNames = require "core.starnames"
--   local gen  = StarNames.new(seed)               -- RNG dédié : la galaxie reste reproductible
--   local used = {}
--   noms[n] = gen:generate("gaulois", used)        -- langue imposée (secteur, faction)
--   noms[n] = gen:generateMixed(used, "standard")  -- langue tirée selon la répartition
--
-- Les mots sont normalisés : accents repliés (é -> e, œ -> oe), "*" (forme
-- reconstruite) retiré, minuscules, a-z uniquement, 3 lettres minimum. Les
-- entrées rejetées sont signalées par le journal (print par défaut).

local M = {}

local ORDER = 2                -- 3 = plus fidèle au corpus, demande un gros corpus
local MIN_LEN, MAX_LEN = 5, 12
local MIN_MOTS_CORPUS = 30     -- en dessous : avertissement "corpus pauvre"
local TENTATIVES = 200

local CAT_CORPUS      = "noms_corpus"
local CAT_BLACKLIST   = "noms_blacklist"
local CAT_REPARTITION = "noms_repartition"

------------------------------------------------------------------ Normalisation
local PLIAGE = {
  ["à"]="a", ["â"]="a", ["ä"]="a", ["æ"]="ae", ["ç"]="c",
  ["é"]="e", ["è"]="e", ["ê"]="e", ["ë"]="e",
  ["î"]="i", ["ï"]="i", ["ô"]="o", ["ö"]="o", ["œ"]="oe",
  ["ù"]="u", ["û"]="u", ["ü"]="u", ["ÿ"]="y",
  ["À"]="a", ["Â"]="a", ["Ç"]="c", ["É"]="e", ["È"]="e", ["Ê"]="e",
  ["Î"]="i", ["Ô"]="o", ["Œ"]="oe", ["Ù"]="u", ["Û"]="u",
}

local function normaliser(mot)
  if type(mot) ~= "string" then return nil end
  mot = mot:gsub("[\194-\244][\128-\191]*", function(c) return PLIAGE[c] or c end)
  mot = mot:gsub("%*", ""):lower()
  if #mot < 3 or not mot:find("^[a-z]+$") then return nil end
  return mot
end

local function origine(cat, def)
  return ("%s '%s' (mod %s)"):format(cat, tostring(def.id), tostring(def.source))
end

------------------------------------------------------------------ Markov
local function construire_modele(mots)
  local trans = {}
  local blob = {}
  for _, mot in ipairs(mots) do          -- mots déjà triés : ordre déterministe
    blob[#blob + 1] = mot
    local s = string.rep("^", ORDER) .. mot .. "$"
    for i = 1, #s - ORDER do
      local ctx = s:sub(i, i + ORDER - 1)
      local suivant = s:sub(i + ORDER, i + ORDER)
      local t = trans[ctx]
      if not t then t = {}; trans[ctx] = t end
      t[#t + 1] = suivant                -- les répétitions servent de poids
    end
  end
  -- blob : sert à rejeter une sortie qui est une copie OU un fragment d'un mot du corpus
  return { trans = trans, blob = "|" .. table.concat(blob, "|") .. "|", n = #mots }
end

------------------------------------------------------------------ Lecture du registre
local function construire(reg, journal)
  -- 1. Corpus, réuni par langue
  local par_langue = {}
  for _, def in ipairs(reg.list(CAT_CORPUS)) do
    if type(def.langue) ~= "string" or not def.langue:find("^[a-z0-9_]+$") then
      error(origine(CAT_CORPUS, def) .. " : 'langue' manquant ou invalide")
    end
    if type(def.mots) ~= "table" then
      error(origine(CAT_CORPUS, def) .. " : 'mots' doit être une liste")
    end
    local ens = par_langue[def.langue]
    if not ens then ens = {}; par_langue[def.langue] = ens end
    local rejets = {}
    for _, brut in ipairs(def.mots) do
      local mot = normaliser(brut)
      if mot then ens[mot] = true else rejets[#rejets + 1] = tostring(brut) end
    end
    if #rejets > 0 then
      journal(("[noms] %s : %d mot(s) rejeté(s) : %s%s"):format(
        origine(CAT_CORPUS, def), #rejets,
        table.concat(rejets, ", ", 1, math.min(#rejets, 5)),
        #rejets > 5 and ", ..." or ""))
    end
  end

  local langues, modeles = {}, {}
  for langue in pairs(par_langue) do langues[#langues + 1] = langue end
  table.sort(langues)
  for _, langue in ipairs(langues) do
    local mots = {}
    for mot in pairs(par_langue[langue]) do mots[#mots + 1] = mot end
    table.sort(mots)                     -- l'ordre de chargement des mods n'influe plus
    if #mots < MIN_MOTS_CORPUS then
      journal(("[noms] langue '%s' : corpus pauvre (%d mots, %d conseillés), noms peu variés"):format(
        langue, #mots, MIN_MOTS_CORPUS))
    end
    modeles[langue] = construire_modele(mots)
  end

  -- 2. Liste noire (union)
  local vus, blacklist = {}, {}
  for _, def in ipairs(reg.list(CAT_BLACKLIST)) do
    if type(def.motifs) ~= "table" then
      error(origine(CAT_BLACKLIST, def) .. " : 'motifs' doit être une liste")
    end
    for _, motif in ipairs(def.motifs) do
      if type(motif) ~= "string" or motif == "" then
        error(origine(CAT_BLACKLIST, def) .. " : motif invalide (chaîne non vide attendue)")
      end
      local m = motif:lower()
      if not vus[m] then vus[m] = true; blacklist[#blacklist + 1] = m end
    end
  end

  -- 3. Répartitions
  local repartitions = {}
  for _, def in ipairs(reg.list(CAT_REPARTITION)) do
    if type(def.repartition) ~= "table" or #def.repartition == 0 then
      error(origine(CAT_REPARTITION, def) .. " : 'repartition' doit être une liste non vide")
    end
    local items, total = {}, 0
    for i, e in ipairs(def.repartition) do
      if type(e) ~= "table" or type(e.langue) ~= "string"
         or type(e.poids) ~= "number" or e.poids <= 0 then
        error(origine(CAT_REPARTITION, def) .. " : repartition[" .. i .. "] doit être { langue = chaîne, poids = nombre > 0 }")
      end
      if not modeles[e.langue] then
        error(origine(CAT_REPARTITION, def) .. " : langue '" .. e.langue .. "' sans corpus")
      end
      items[i] = e
      total = total + e.poids
    end
    repartitions[def.id] = { items = items, total = total }
  end

  return { modeles = modeles, langues_ = langues, blacklist = blacklist, repartitions = repartitions }
end

------------------------------------------------------------------ RNG
local function creer_rng(seed)
  seed = seed or os.time()
  local love = rawget(_G, "love")
  if love and love.math then return love.math.newRandomGenerator(seed) end
  -- Hors LÖVE (tests) : Park-Miller, identique quelle que soit la version de Lua.
  local etat = (math.floor(math.abs(seed)) % 2147483646) + 1
  local rng = {}
  function rng:random(a, b)
    etat = (etat * 16807) % 2147483647
    local u = (etat - 1) / 2147483646            -- [0, 1[
    if a == nil then return u end
    if b == nil then a, b = 1, a end
    return a + math.floor(u * (b - a + 1))
  end
  return rng
end

------------------------------------------------------------------ API
local Gen = {}
Gen.__index = Gen

-- opts (facultatif) : registre = table registre ; journal = function(texte)
function M.new(seed, opts)
  opts = opts or {}
  local reg = opts.registre or require "core.registre"
  local self = setmetatable(construire(reg, opts.journal or print), Gen)
  self.rng = creer_rng(seed)
  return self
end

-- Contrôle sans créer de générateur (ex. à appeler en fin de mods.charger).
function M.verifier(reg, journal)
  construire(reg or require "core.registre", journal or print)
end

function Gen:langues()                       -- copie triée des langues disponibles
  local res = {}
  for i, l in ipairs(self.langues_) do res[i] = l end
  return res
end

local function est_propre(nom, blacklist)
  for _, mauvais in ipairs(blacklist) do
    if nom:find(mauvais, 1, true) then return false end
  end
  -- pas de 4 consonnes de suite (y compte comme voyelle), pas de lettre triplée
  if nom:find("[^aeiouy][^aeiouy][^aeiouy][^aeiouy]") then return false end
  if nom:find("(.)%1%1") then return false end
  return nom:find("[aeiouy]") ~= nil
end

function Gen:_brut(modele)
  local ctx, out = string.rep("^", ORDER), {}
  while true do
    local t = modele.trans[ctx]
    if not t then return nil end
    local c = t[self.rng:random(1, #t)]
    if c == "$" then break end
    out[#out + 1] = c
    if #out > MAX_LEN then return nil end
    ctx = (ctx .. c):sub(-ORDER)
  end
  local nom = table.concat(out)
  if #nom < MIN_LEN then return nil end
  if modele.blob:find(nom, 1, true) then return nil end   -- copie/fragment du corpus
  if not est_propre(nom, self.blacklist) then return nil end
  return nom
end

local function chiffres_romains(n)
  local map = { {10,"X"}, {9,"IX"}, {5,"V"}, {4,"IV"}, {1,"I"} }
  local out = ""
  for _, p in ipairs(map) do
    while n >= p[1] do out = out .. p[2]; n = n - p[1] end
  end
  return out
end

local function capitale(s) return s:sub(1, 1):upper() .. s:sub(2) end

function Gen:generate(langue, used)
  local modele = self.modeles[langue]
  if not modele then
    error("langue inconnue : '" .. tostring(langue) .. "' (disponibles : " ..
          table.concat(self.langues_, ", ") .. ")", 2)
  end
  for _ = 1, TENTATIVES do
    local nom = self:_brut(modele)
    if nom then
      nom = capitale(nom)
      if not used[nom] then used[nom] = true; return nom end
    end
  end
  -- Repli : suffixe en chiffres romains (Vesta II) si l'espace de noms est saturé.
  local base
  for _ = 1, TENTATIVES do
    base = self:_brut(modele)
    if base then break end
  end
  if not base then
    error("langue '" .. langue .. "' : corpus trop pauvre (" .. modele.n ..
          " mots), aucun nom valide n'a pu être généré", 2)
  end
  base = capitale(base)
  local n = 2
  while used[base .. " " .. chiffres_romains(n)] do n = n + 1 end
  local nom = base .. " " .. chiffres_romains(n)
  used[nom] = true
  return nom
end

function Gen:generateMixed(used, id_repartition)
  id_repartition = id_repartition or "standard"
  local rep = self.repartitions[id_repartition]
  if not rep then error("répartition inconnue : '" .. tostring(id_repartition) .. "'", 2) end
  local r = self.rng:random() * rep.total
  local choix = rep.items[#rep.items]
  for _, e in ipairs(rep.items) do
    r = r - e.poids
    if r < 0 then choix = e; break end
  end
  return self:generate(choix.langue, used)
end

return M
