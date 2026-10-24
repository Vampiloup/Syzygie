-- ui.widgets.fermer.lua

local M = {}

local TAILLE, MARGE = 32, 8

-- rectangle du bouton, calculé à chaque appel à partir de la géométrie du panneau
local function rect(panel)
  return panel.x + panel.w - TAILLE - MARGE, panel.y + MARGE, TAILLE, TAILLE
end

-- panel  : table {x, y, w, h}, passée par référence (le bouton suit ses changements)
-- action : fonction appelée quand le clic est validé
function M.new(panel, action)
  local b = { survol = false, enfonce = false }

  function b.contient(x, y)
    local bx, by, bw, bh = rect(panel)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
  end

  function b.draw()
    local bx, by, bw, bh = rect(panel)
    local c = b.enfonce and 0.6 or b.survol and 0.5 or 0.4
    love.graphics.setColor(c, 0.15, 0.15)
    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("x", bx + 12, by + 8)
  end

  -- true si le bouton a consommé l'événement
  function b.press(x, y, button)
    if button == 1 and b.contient(x, y) then
      b.enfonce = true
      return true
    end
    return false
  end

  function b.release(x, y, button)
    if button ~= 1 or not b.enfonce then return false end
    b.enfonce = false
    if b.contient(x, y) then action() end   -- relâché hors du bouton : annulation
    return true
  end

  function b.move(x, y) b.survol = b.contient(x, y) end

  function b.leave()
    b.survol = false
    b.enfonce = false
  end

  return b
end

return M
