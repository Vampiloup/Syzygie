-- affichage.ecran.lua
local M = { W = 1920, H = 1080 }

function M.resize(w, h)
  M.scale = math.min(w / M.W, h / M.H)
  M.ox = math.floor((w - M.W * M.scale) / 2)
  M.oy = math.floor((h - M.H * M.scale) / 2)
end

function M.load()
  M.resize(love.graphics.getDimensions())
end

-- à appeler autour de tout le dessin
function M.begin()
  love.graphics.push()
  love.graphics.translate(M.ox, M.oy)
  love.graphics.scale(M.scale)
end

function M.finish()
  love.graphics.pop()
end

function M.toVirtual(x, y)
  return (x - M.ox) / M.scale, (y - M.oy) / M.scale
end

-- limites de la fenêtre réelle, en coordonnées virtuelles
function M.bounds()
  local w, h = love.graphics.getDimensions()
  return -M.ox / M.scale,          -- gauche
         -M.oy / M.scale,          -- haut
         (w - M.ox) / M.scale,     -- droite
         (h - M.oy) / M.scale      -- bas
end

function M.snap(v)
  return math.floor(v * M.scale + 0.5) / M.scale
end

M.load()
return M
