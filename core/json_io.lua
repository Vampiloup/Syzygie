-- core.json_io.lua

local json = require("libs.dkjson.dkjson")              -- Librairie json

local M = {}

function M.lire(chemin)
  local info = love.filesystem.getInfo(chemin)
  if not info then error("Fichier introuvable : " .. chemin, 0) end
  if info.type ~= "file" then error(chemin .. " n'est pas un fichier (type : " .. info.type .. ").", 0) end

  local src, err = love.filesystem.read(chemin)
  if not src then error("Lecture impossible de " .. chemin .. " : " .. tostring(err), 0) end

  if src:sub(1, 3) == "\239\187\191" then src = src:sub(4) end   -- BOM UTF-8

  local tbl, pos, jerr = json.decode(src, 1, nil)
  if jerr then error("JSON invalide dans " .. chemin .. " (position " .. tostring(pos) .. ") : " .. jerr, 0) end
  return tbl
end

return M
