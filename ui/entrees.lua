-- ui.entrees.lua
local events = require("core.events")
local screen = require("affichage.ecran")
local couches    = require("core.couches")

local pressed = {}   -- bouton -> élément qui a reçu le press


function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
    return
  end
  if key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen())
    return
  end

  events.emit("keypressed", key, scancode, isrepeat)
end


function love.mousepressed(x, y, button)
  local vx, vy = screen.toVirtual(x, y)
  local target = couches.pick(vx, vy)
  pressed[button] = target          -- on mémorise pour le release/drag
  if target and target.onpress then
    target.onpress(vx, vy, button)
  end
end

function love.mousereleased(x, y, button)
  local vx, vy = screen.toVirtual(x, y)
  local target = pressed[button]    -- le release va à celui qui a reçu le press
  pressed[button] = nil
  if target and target.onrelease then
    target.onrelease(vx, vy, button)
  end
end

function love.mousemoved(x, y, dx, dy)
  local vx, vy = screen.toVirtual(x, y)
  local ddx, ddy = dx / screen.scale, dy / screen.scale

  -- pendant un drag, l'élément "capturé" reçoit tout, même hors de ses bords
  local captured = pressed[1]
  if captured then
    if captured.onmove then captured.onmove(vx, vy, ddx, ddy) end
  else
    local target = couches.pick(vx, vy)   -- survol
    if target and target.onmove then target.onmove(vx, vy, ddx, ddy) end
  end
end

function love.wheelmoved(dx, dy)
  local mx, my = love.mouse.getPosition()
  local vx, vy = screen.toVirtual(mx, my)
  local target = couches.pick(vx, vy)
  if target and target.onwheel then target.onwheel(dx, dy) end
end

return {}


-- tx, ty = love.mouse.getPosition( )
-- dx, dy = screen.toVirtual(tx, ty)
