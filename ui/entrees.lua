local events = require("core.events")
local screen = require("affichage.ecran")


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
  events.emit("mousepressed", vx, vy, button)
end

function love.mousereleased(x, y, button)
  local vx, vy = screen.toVirtual(x, y)
  events.emit("mousereleased", vx, vy, button)
end

function love.mousemoved(x, y, dx, dy)
  local vx, vy = screen.toVirtual(x, y)
  events.emit("mousemoved", vx, vy, dx / screen.scale, dy / screen.scale)
end

function love.wheelmoved(dx, dy)
  events.emit("wheelmoved", dx, dy)
end

return {}   -- (le `M` vide ne servait à rien)
