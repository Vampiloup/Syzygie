-- sim.creation_partie.graine.lua

local bit =                       require("bit")


-- Dérivation pure : f(graine, etape, id) -> entier 32 bits.
-- Multiplicateurs < 2^17 pour que h*m reste exact en double (< 2^53).
local function sous_graine(graine, etape, id)
  local h = bit.tobit(graine)
  for _, x in ipairs({ etape, id or 0 }) do
    h = bit.bxor(h, bit.tobit(x))
    h = bit.tobit(h * 65599)       -- tobit réduit à 32 bits signés
    h = bit.bxor(h, bit.rshift(h, 15))
  end
  return h % 4294967296            -- ramené dans [0, 2^32)
end

local function rng(graine, etape, id)
  return love.math.newRandomGenerator(sous_graine(graine, etape, id))
end


return { sous_graine = sous_graine, rng = rng }
