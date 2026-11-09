-- ui.widgets.zone.lua

-- Zone cliquable invisible : consomme le clic et émet events.emit(nom, donnee).
local screen = require("affichage.ecran")
local events = require("core.events")

local M = {}

local function val(v) if type(v) == "function" then return v() end return v end

-- parent : {x, y, w, h} passé par référence (nil = coordonnées absolues)
-- x, y   : décalage depuis le coin haut-gauche du parent
function M.new(parent, x, y, w, h, nom, donnee, actif)
    parent = parent or { x = 0, y = 0 }
    local z = { enfonce = false }

    function z.rect()
        return screen.snap(parent.x + val(x)), screen.snap(parent.y + val(y)), val(w), val(h)
    end

    function z.contient(px, py)
        local rx, ry, rw, rh = z.rect()
        return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
    end

    function z.press(px, py, button)
        if button ~= 1 or not z.contient(px, py) then return false end
        if actif and not actif() then return false end                              -- zone inactive : le clic passe
        z.enfonce = true
        return true                                                                 -- consomme
    end

    function z.release(px, py, button)
        if button ~= 1 or not z.enfonce then return false end
        z.enfonce = false
        if z.contient(px, py) then events.emit(nom, val(donnee)) end
        return true
    end

    function z.move() end
    function z.leave() z.enfonce = false end

        function z.draw()                                                           -- invisible ; le dessin reste à la charge du panneau
        if M.debug then
        local rx, ry, rw, rh = z.rect()
        love.graphics.setColor(1, 0, 0, 0.6)
        love.graphics.rectangle("line", rx, ry, rw, rh)
        love.graphics.setColor(1, 1, 1)
        end
    end

    function z.draw() end

    return z
end

return M


-- Exemples d'usage'

-- zone fixe
-- P.zone(20, 60, 100, 100, "ui_planete", "one")

-- zone dont l'emplacement dépend d'un état du panneau
-- P.zone(16, function() return 72 + 144 * ligne_courante end, 200, 32, "ui_ligne", nil)

-- liste : créée une fois pour le maximum d'éléments, avec une condition d'activité
-- for k = 1, N_MAX do
--  P.zone(16, 72 + 144 * k, 200, 32, "planete_cliquee", k, function() return existe(k) end)
-- end
