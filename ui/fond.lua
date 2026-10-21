-- ui.fond.lua
local cam = require("core.camera_monde")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")

couches.add({
  z = couches_z.FOND,
  contient = function() return true end,
  onwheel = function(dx, dy, vx, vy)
    cam:zoomAt(vx, vy, 1.1 ^ dy)
  end,
  onmove = function(vx, vy, ddx, ddy)
    if love.mouse.isDown(2) then            -- pan au bouton droit, par exemple
      cam.x = cam.x - ddx / cam.scale
      cam.y = cam.y - ddy / cam.scale
    end
  end,
})
