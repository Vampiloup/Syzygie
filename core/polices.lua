    local registre =              require("core.registre")
    local M = { f = {} }

function M.charger()

    local polices  = registre.list("polices")
    for _, s in ipairs(polices) do
       M.f[s.id] = love.graphics.newFont("mods/"..s.police..".ttf", s.taille)
    end

end
return M
