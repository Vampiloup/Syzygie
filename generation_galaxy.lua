
-- Did you feed the bunnies ?
love.math.setRandomSeed(os.time())

-- Creation of the Galaxy

local Galaxy = {
    number_of_systems = 0,
    size_X = 0,
    size_Y = 0,
    star_system = {
        nom = {},                           -- Name of the system
        type = {},
        position_x = {},                    -- Position by X
        position_y = {},                    -- Position by X
        orbital = {                         -- Orbits around the "central" star, (planets or asteroids, essentially)
            phase = {}                      -- starting angle of orbitals
        },
        name = "",                          -- Name of the galaxy
        NbOrbits = 5                        -- Number of orbits by system
    },
    distmini = 80,                          -- distance mini between Systems
    name = "Name of the galaxy"             -- Name of the galaxy (the save name, basically)
}

function Galaxy.load()

	-- default map characteristics
    local map_X         = game_prep.map_size[game_prep.default.map_size]["map_X"]                        -- take the size of the galaxy, horizontaly
    local map_Y         = game_prep.map_size[game_prep.default.map_size]["map_Y"]                        -- take the size of the galaxy, Verticaly
    local map_density   = game_prep.map_density[game_prep.default.map_density]["density"]                -- take the density of the galaxy
    local map_form      = game_prep.default.map_form
    Galaxy.number_of_systems    =   math.ceil(((map_X * map_Y) / 4000000) * 100 * map_density)

    -- Size of the World
	if map_form == 1 then
		Galaxy.size_X = map_X
		Galaxy.size_Y = map_Y
	elseif map_form > 1 or map_form < 8 then
		Galaxy.size_X = (((map_X + map_Y)/2)/math.sqrt(math.pi))*2
		Galaxy.size_Y = (((map_X + map_Y)/2)/math.sqrt(math.pi))*2
	end

	local RealStarsNumber = 0
    for i = 1, Galaxy.number_of_systems do

        local Essayer2 = 0
        -- Coordinates of the new system
        repeat
            Essayer = ""
            Essayer2 = Essayer2 + 1
            local x1 = 0
            local y1 = 0
            if map_form == 1 then
                x1 = love.math.random(0, map_X)
                y1 = love.math.random(0, map_Y)
            elseif map_form == 2 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * love.math.random()
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            elseif map_form == 3 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * math.sqrt(love.math.random())
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            elseif map_form == 4 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * math.sqrt(love.math.random(2000,10000) / 10000)
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            elseif map_form == 5 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * math.sqrt(love.math.random(4000,10000) / 10000)
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            elseif map_form == 6 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * math.sqrt(love.math.random(6000,10000) / 10000)
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            elseif map_form == 7 then
                theta = 2 * math.pi * love.math.random()
                r = ((Galaxy.size_X)/2) * math.sqrt(love.math.random(8000,10000) / 10000)
                x1 = r * math.cos(theta) + Galaxy.size_X / 2
                y1 = r * math.sin(theta) + Galaxy.size_X / 2
            end
            local distance = true
            Galaxy.star_system.position_x[i] = x1
            Galaxy.star_system.position_y[i] = y1
            if i > 1 then
                for j = 1, i-1 do
                    ecart = math.sqrt((Galaxy.star_system.position_x[j] - x1)^2 + (Galaxy.star_system.position_y[j] - y1)^2)
                    if ecart < Galaxy.distmini then
                        distance = false
                        break
                    end
                end
            end

            -- Type of central star :
            	-- Stars types

           Galaxy.star_system.type[i] = love.math.random(1, #game_prep.starfield.type_etoile_lointain)
            if Essayer2 > 1000 then
                Essayer = "GAME GENERATION FUMBLE : GALAXIE SCRIPT - CAN'T FIND FREE PLACE FOR STAR SYSTEM ! - Planète " .. i
                break
            end
            RealStarsNumber = i
        until (distance == true)

        if Essayer ~= "" then
            break
        end

      Galaxy.star_system.orbital.phase[i] = {}
      for j = 1, galaxy.star_system.NbOrbits do
        Galaxy.star_system.orbital.phase[i][j] = 2 * math.pi * love.math.random()
        end
            Essayer = "Aucune erreur generation"


    end
	if RealStarsNumber < Galaxy.number_of_systems then
		print("Only ".. RealStarsNumber .. " stars on " .. Galaxy.number_of_systems .. " could be generated")
		Galaxy.number_of_systems = RealStarsNumber - 1
    else
        print ( Galaxy.number_of_systems .. " generated")
	end

	print (Essayer)


    print("Galaxie initialisée")




end

function Galaxy.update(dt)



end

function Galaxy.draw()

end

return Galaxy
