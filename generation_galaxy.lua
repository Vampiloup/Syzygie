
-- Did you feed the bunnies ?
love.math.setRandomSeed(os.time())

-- Creation of the Galaxy

local Galaxy = {
    number_of_systems = 0,
    size_X = 0,
    size_Y = 0,
    nbOrbits = 5,                           -- Number of orbits by system
    star_system = {
        nom = {},                           -- Name of the system
        type = {},
        position_X = {},                    -- Position by X
        position_Y = {},                    -- Position by X
        orbital = {                         -- Orbits around the "central" star, (planets or asteroids, essentially)
            phase = {},                     -- starting angle of orbitals
            type = {}                       -- Type of orbital (rock planet, gaz giant, asteroids, etc.)
        },
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
            Galaxy.star_system.position_X[i] = x1
            Galaxy.star_system.position_Y[i] = y1
            if i > 1 then
                for j = 1, i-1 do
                    ecart = math.sqrt((Galaxy.star_system.position_X[j] - x1)^2 + (Galaxy.star_system.position_Y[j] - y1)^2)
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
        Galaxy.star_system.orbital.type[i] = {}
        for j = 1, galaxy.nbOrbits do
            Galaxy.star_system.orbital.phase[i][j] = 2 * math.pi * love.math.random()
            Galaxy.star_system.orbital.type[i][j] = love.math.random(1, #game_prep.starfield.orbitals.chance)
        end


    -- Name creation
		local Premiere = {
			"a", "ab", "ac", "ad", "ae", "aes", "am", "an", "ante", "au", "be","car", "clau", "cen", "circum", "co", "con", "dan", "de", "den", "di", "dic", "dis", "do","duo", "e", "est", "ex", "fe", "fi", "foe", "gra", "in", "inter", "ma", "me", "men", "mi", "mit", "mo", "mon", "ni", "no", "non", "o", "ob", "pa", "pe", "per", "plu", "post", "prae", "pre", "pro", "pu", "qua", "quam", "quasi", "re", "rem", "res", "retro", "ro", "sa", "san", "sax", "si", "su", "sub", "super", "tan","ter", "tol", "tra", "trans", "tri", "ui", "ver","vi", "vo"
		}
		local Medium = {
			"a", "an", "ant", "at", "bi", "bus", "ci", "di", "cer", "clu", "de", "e", "el", "en", "ent", "er", "ere", "es", "et", "fa", "fe", "in", "is", "it", "iu", "la", "le", "li", "ma", "mi", "mit", "mo", "mu", "na", "ne", "ni", "nt", "ob", "phan", "qu", "que", "qui", "ra", "re", "ri", "rum", "per", "ta", "te", "ter", "ti", "tin", "tu", "tur", "um", "us", "vi", "zen"
		}
		local Derniere = {
			"a", "ae", "am", "an", "as", "ate", "ble", "bus", "ca", "ce", "cus", "cris", "ctae", "cto", "cus", "cut", "des", "do", "dos", "dus", "e", "ent", "er", "est", "hil", "git", "go", "gno", "ia", "io", "ion", "ior", "is", "it", "ius", "la", "le", "lo", "lus", "ma", "ment", "mnes", "mu", "mus", "na", "ne", "no", "num", "nus", "o", "ory", "ous", "que", "quis", "ra", "re", "rem", "ro", "ros", "sa", "sis","sit", "sor", "sti", "sto", "stris", "strum", "sul", "sum", "tae", "tem", "to", "ter", "tes", "tius", "to", "tor", "tur", "tus", "ty", "um" ,"us", "va"
		}
		local nom_choisi = ""
		repeat
			local nom_disponible = true
			nom_choisi = StartNameGeneration (Premiere, Medium, Derniere)
			-- check if the newly created name is already taken by another star
			if i > 1 then
				for j = 1, i-1 do
					nomJ = Galaxy.star_system.nom[j]
					if nomJ == nom_choisi then
						nom_disponible = false
					end
				end
			end
		until (nom_disponible == true)
		Galaxy.star_system.nom[i] = nom_choisi

    Essayer = "Aucune erreur generation"

    end

	if RealStarsNumber < Galaxy.number_of_systems then
		print("Only ".. RealStarsNumber .. " stars on " .. Galaxy.number_of_systems .. " could be generated")
		Galaxy.number_of_systems = RealStarsNumber - 1
    else
        print ( Galaxy.number_of_systems .. " generated")
	end

    -- moving the coordinates 0 to the center of the galaxy
    local center_X = Galaxy.size_X / 2
    local center_Y = Galaxy.size_Y / 2
	for i = 1, Galaxy.number_of_systems do
        Galaxy.star_system.position_X[i] = Galaxy.star_system.position_X[i] - center_X
        Galaxy.star_system.position_Y[i] = Galaxy.star_system.position_Y[i] - center_Y
    end

	print (Essayer)


    print("Galaxie initialisée")




end

function Galaxy.update(dt)



end

function Galaxy.draw()

end

function StartNameGeneration (Premiere, Medium, Derniere)
	local number2 = Premiere[math.random(1,#Premiere)]

	-- choose number of middle syllages (can be 0 to 2)
	local number = math.random(0,2)
	-- Choose "number" middle syllabes
	for i = 1, number do
		number2 = number2 .. Medium[math.random(1,#Medium)]
	end

	-- Choose last syllabe
	number2 = number2 .. Derniere[math.random(1,#Derniere)]
	return number2
end

return Galaxy
