-- core/camera.lua
local Camera = {}
Camera.__index = Camera

function Camera.new() return setmetatable({x = 0, y = 0, scale = 1}, Camera) end

function Camera:attach()
  love.graphics.push()
  love.graphics.scale(self.scale)
  love.graphics.translate(-self.x, -self.y)
end
function Camera:detach() love.graphics.pop() end

function Camera:toWorld(sx, sy)
  return sx / self.scale + self.x, sy / self.scale + self.y
end

-- zoom centré sur le curseur (le point monde sous la souris reste fixe)
function Camera:zoomAt(sx, sy, factor)
  local wx, wy = self:toWorld(sx, sy)
  self.scale = math.max(0.05, math.min(20, self.scale * factor))
  self.x = wx - sx / self.scale
  self.y = wy - sy / self.scale
end

-- Zoom inverse (Affiche en taille constante dans un module zoomable)
function Camera:toScreen(wx, wy)
  return (wx - self.x) * self.scale, (wy - self.y) * self.scale
end

function Camera:visibleRect(l, t, r, b)
  local x1, y1 = self:toWorld(l, t)
  local x2, y2 = self:toWorld(r, b)
  return x1, y1, x2, y2
end

return Camera
