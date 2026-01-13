love.math.setRandomSeed(os.time())

-- Librairies
inspect = require("libs.inspect.inspect")
colors = require "libs.ansicolors.ansicolors"
textureAtlas = require("libs.TA")

-- print(colors(inspect(myTable, { newline = "\n", indent = "  " })))

game_prep = require "game_prep"
game_ref = require "game_ref"
galaxy = require "generation_galaxy"

local isDragging = false
local dragStartX, dragStartY = 0, 0     -- position souris quand on clique
local camStartX, camStartY = 0, 0       -- position caméra au moment du clic


-- Clicks
local click = {
	x = 0,      -- screen x
	y = 0,      -- screen y
	wx = 0,     -- world x
	wy = 0,      -- world y
	object_galaxy       = false,    -- Is an object on the map clicked ?
	object_type         = "",       -- type of clicked object (star, orbital...)
	object_id           = 0,        -- ID of the object
	object_X            = 0,        -- X coordinate of object origin
	object_Y            = 0         -- Y coordinate of object origin
}

-- Panel
local panel = {
	level_1 = 0
}

-- Double clicks
local clickCount = 0
local clickTime = 0

local png_files = nil
local starsBatch = nil
local orbitsBatch = nil


-- fonts
local normalFont = love.graphics.newFont(16)
local starLabelFont = love.graphics.newFont("/assets/syzygie/fonts/Roboto/Roboto-Bold.ttf", 12)


function love.load()

	-- Default Font used
	love.graphics.setFont(normalFont)

	love.window.setMode(1920, 1080, {resizable=true, fullscreen = false, vsync = true})
	game_ref.load(game_prep)
	galaxy.load(game_ref)

	game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)

		-- Loading objets : Galaxy Starfield
	atlas_galaxy = textureAtlas.newDynamicSize()
	atlas_galaxy:setFilter("nearest")

	local png_files = getFilesWithExtension("assets/" .. game_ref.path.default .. "/images/galaxy", ".png")
	print("Nombre de PNG trouvés : " .. #png_files)   -- debug
	for _, filename in ipairs(png_files) do
		local path = "assets/" .. game_ref.path.default .. "/images/galaxy/" .. filename
		local success, image = pcall(love.graphics.newImage, path)
		if success then
			local id = filename:gsub("%.png$", "")
			atlas_galaxy:add(love.graphics.newImage(path), id)

		else
			print("Échec chargement : " .. path .. " → " .. tostring(image))  -- Error is in "image"
		end
	end
	atlas_galaxy:hardBake("height")
	collectgarbage("collect")

	-- Starbatch : Galaxy starfield
	starsBatch_proche = love.graphics.newSpriteBatch(atlas_galaxy.image, galaxy.number_of_systems, "stream")
	for i = 1, galaxy.number_of_systems do          -- stars near (zoom in)
		local x = galaxy.star_system.position_X[i]  -- Position X du système i
		local y = galaxy.star_system.position_Y[i]  -- Position Y du système i
		local type_etoile = game_prep.starfield.type_etoile_proche[galaxy.star_system.type[i]]
		local vx, vy, vw, vh = atlas_galaxy:getViewport(type_etoile)
		local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_galaxy.image:getDimensions())
		starsBatch_proche:add(quad, x, y, 0, (0.25 * game_ref.current_global_scale), sx, vw/2, vh/2)

	end
	starsBatch_lointain = love.graphics.newSpriteBatch(atlas_galaxy.image, galaxy.number_of_systems, "stream")
	for i = 1, galaxy.number_of_systems do          -- stars far (zoom out)
		local x = galaxy.star_system.position_X[i]  -- Position X du système i
		local y = galaxy.star_system.position_Y[i]  -- Position Y du système i
		local type_etoile = game_prep.starfield.type_etoile_lointain[galaxy.star_system.type[i]]
		local vx, vy, vw, vh = atlas_galaxy:getViewport(type_etoile)
		local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_galaxy.image:getDimensions())
		starsBatch_lointain:add(quad, x, y, 0, 1, sx, vw/2, vh/2)
	end

	orbitalsBatch = love.graphics.newSpriteBatch(atlas_galaxy.image, totalOrbits, "stream")
	refill_batch_orbits()


	labelStarsBatch = love.graphics.newText(starLabelFont)
	-- height = font:getHeight( )
	for i = 1, galaxy.number_of_systems do
		labelStarsBatch:add( {{1,1,1}, galaxy.star_system.nom[i]}, galaxy.star_system.position_X[i] - 24, galaxy.star_system.position_Y[i] + 16)
	--	labelStarsBatch:add(galaxy.star_system.nom[i], galaxy.star_system.position_X[i],  galaxy.star_system.position_Y[i] + 10, 0, 1, sx)
	end




	-- guiGameBatch :  Gui standard in the game
	atlas_guiGame = textureAtlas.newDynamicSize()
	atlas_guiGame:setFilter("nearest")
	local png_files = getFilesWithExtension("assets/" .. game_ref.path.default .. "/GUI/gui_1920_1080", ".png")
	print("Nombre de PNG trouvés : " .. #png_files)   -- debug
	for _, filename in ipairs(png_files) do
		local path = "assets/" .. game_ref.path.default .. "/GUI/gui_1920_1080/" .. filename
		local success, image = pcall(love.graphics.newImage, path)
		if success then
			local id = filename:gsub("%.png$", "")
			atlas_guiGame:add(love.graphics.newImage(path), id)
		else
			print("Échec chargement : " .. path .. " → " .. tostring(image))  -- Error is in "image"
		end
	end
	atlas_guiGame:hardBake("height")
	collectgarbage("collect")

	guiGameBatch = love.graphics.newSpriteBatch(atlas_guiGame.image, game_ref.ui.gui_systeme_nb, "stream")

	for i in pairs(game_ref.ui.gui_systeme) do
		local x = game_ref.ui.gui_systeme[i][1]
		local y = game_ref.ui.gui_systeme[i][2]
		local vx, vy, vw, vh = atlas_guiGame:getViewport(i)
		local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_guiGame.image:getDimensions())
		guiGameBatch:add(quad, x, y, 0, 1, sx, vw, vh)
	end







--[[
	-- Centrage sur système :
	-- camX = galaxy.star_system.position_x[start_sys]
	-- camY = galaxy.star_system.position_y[start_sys]
	-- game_ref.zoom.state = 4

	zoom_state()
	]]

end


function love.update(dt)

	-- move camera with keys
	local camSpeed     = 300 * dt / math.max(game_ref.current_global_scale, 0.05)
	if love.keyboard.isDown("up") then game_ref.camera.Y = game_ref.camera.Y - camSpeed end
	if love.keyboard.isDown("down") then game_ref.camera.Y = game_ref.camera.Y + camSpeed end
	if love.keyboard.isDown("left") then game_ref.camera.X = game_ref.camera.X - camSpeed end
	if love.keyboard.isDown("right") then game_ref.camera.X = game_ref.camera.X + camSpeed end
--   print (" zoom : " .. game_ref.zoom.state .. " " )

	-- clicking simple or double-click
	if clickCount > 0 then
		clickTime = clickTime + dt
		if clickTime > game_ref.ui.doubleClickThreshold then
			if clickCount == 1 then
		--       print("Simple click")
			else
		--       print("Double click")
			end
			clickCount = 0
			clickTime = 0
		end
	end

end

function love.draw()

	game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)

love.graphics.push()
		love.graphics.translate(                                                                    -- moving camera at screen center
			love.graphics.getWidth()  / 2,
			love.graphics.getHeight() / 2
		)
		love.graphics.scale(game_ref.current_global_scale, game_ref.current_global_scale)           -- zoom scale
		love.graphics.translate(-game_ref.camera.X, -game_ref.camera.Y)                             -- Moving camera

		-- debug (line around galaxy)
		local half = galaxy.size_X / 2
		love.graphics.rectangle("line", -half, -half, galaxy.size_X, galaxy.size_Y)
		-- love.graphics.print("Camera world pos: " .. string.format("%.0f", game_ref.camera.X) .. ", " .. string.format("%.0f", game_ref.camera.Y), -love.graphics.getWidth()/2 + 20, -love.graphics.getHeight()/2 + 20)

		-- Draw stars, orbitals
		zoom_state()



		if click.object_galaxy then
			love.graphics.push()                      -- Niveau 2 : effet local
				love.graphics.translate(click.object_X, click.object_Y)
				love.graphics.rotate(love.timer.getTime())   -- rotation animée
				love.graphics.setColor(1, 1, 0, 1)
				love.graphics.setLineWidth(16)
				love.graphics.circle("line", 0, 0, 64, 16)
			love.graphics.pop()
		end


		-- Graphic cursor
		local mx, my = love.mouse.getPosition()
		local wx, wy = game_ref:screenToWorld(mx, my)
		love.graphics.setColor(1, 0, 0, 0.6)
		love.graphics.circle("fill", wx, wy, 10 / game_ref.current_global_scale)
		love.graphics.setColor(1,1,1)

	love.graphics.pop()

	---------------
	-- HUD
	---------------

	love.graphics.print("Zoom state: " .. game_ref.zoom.state, 10, 10)
	love.graphics.print("Scale: " .. string.format("%.3f", game_ref.current_global_scale), 10, 30)
	love.graphics.print("Camera: " .. math.floor(game_ref.camera.X) .. ", " .. math.floor(game_ref.camera.Y), 10, 50)

	-- Calling Star Panel

	if click.object_galaxy and click.object_type == "star" then
		GUI_Star_Bar()
		panel.level_1 = 1
	else
		panel.level_1 = 0
	end



end

-- What's changing at zoom state X ?
function zoom_state()
	if game_ref.zoom.state <= game_ref.zoom.proche then
		refill_batch_orbits()
		love.graphics.draw(orbitalsBatch)
		love.graphics.draw(starsBatch_proche)
	else
	--	love.graphics.draw(orbitalsBatch)
		love.graphics.draw(starsBatch_lointain)
	end
	if game_ref.zoom.state <= game_ref.zoom.show_label then
		love.graphics.draw(labelStarsBatch)
	end
end


function love.wheelmoved(x, y)

	local old_state = game_ref.zoom.state
	if y > 0 then       -- molette haut → zoom in → state diminue
		game_ref.zoom.state = math.max(game_ref.zoom.min, game_ref.zoom.state - 1)
	elseif y < 0 then   -- molette bas → zoom out → state augmente
		game_ref.zoom.state = math.min(game_ref.zoom.max, game_ref.zoom.state + 1)
	end

end


function love.keypressed(key, scancode, isrepeat)

end

function love.mousepressed(x, y, button)

	if button == 3 then -- middle click
			isDragging = true
			dragStartX, dragStartY = x, y
			camStartX, camStartY = game_ref.camera.X, game_ref.camera.Y
	end

	if button == 1 then  -- Bouton gauche de la souris
		clickCount = clickCount + 1
		clickTime = 0  -- Réinitialise le minuteur
		click.x = x
		click.y = y
		local wx, wy = game_ref:screenToWorld(x, y)
	--   print(string.format("Clic world : %.1f , %.1f", wx, wy))
		a, b = findSystemNear(wx, wy, 16)
		if a ~= nil then
			click.object_galaxy       = true
			click.object_type         = "star"
			click.object_id           = a
			click.object_X            = galaxy.star_system.position_X[a]
			click.object_Y            = galaxy.star_system.position_Y[a]
		else
			click.object_galaxy       = false
		end
	end

end

function love.mousereleased(x, y, button)
	if button == 3 then
		isDragging = false
	end
end

function love.mousemoved(x, y, dx, dy)
	if isDragging then
		-- inverse the move
		local divisor = math.max(game_ref.current_global_scale, 0.05)
		game_ref.camera.X = camStartX - (x - dragStartX) / divisor
		game_ref.camera.Y = camStartY - (y - dragStartY) / divisor
	end
end


function game_ref:screenToWorld(sx, sy)

	local wx = (sx - love.graphics.getWidth()/2) / game_ref.current_global_scale + game_ref.camera.X
	local wy = (sy - love.graphics.getHeight()/2) / game_ref.current_global_scale + game_ref.camera.Y

	return wx, wy
end

function worldToScreen(wx, wy)
	local halfW = love.graphics.getWidth()  / 2
	local halfH = love.graphics.getHeight() / 2
	local scale = game_ref.current_global_scale

	local sx = (wx - game_ref.camera.X) * scale + halfW
	local sy = (wy - game_ref.camera.Y) * scale + halfH

	return sx, sy
end


function findSystemNear(tx, ty, max_distance)
	max_distance = max_distance or 32       -- Pixels or units.
	local sys = galaxy.star_system
	local best_index = nil
	local best_dist_sq = max_distance * max_distance

	for i = 1, galaxy.number_of_systems do
		local dx = sys.position_X[i] - tx
		local dy = sys.position_Y[i] - ty
		local dist_sq = dx*dx + dy*dy

		if dist_sq < best_dist_sq then
			best_dist_sq = dist_sq
			best_index = i
		end
	end

	if best_index then
		return best_index, galaxy.star_system.nom[best_index]
	end
	return nil, nil
end


function getFilesWithExtension(path, extension)
	local files = {}
	-- Récupère tous les éléments du dossier
	local items = love.filesystem.getDirectoryItems(path or "")

	-- Filtre sur l'extension voulue
	for _, filename in ipairs(items) do
		-- Vérifie que c'est bien un fichier (pas un dossier)d
		local info = love.filesystem.getInfo((path or "") .. "/" .. filename)
		if info and info.type == "file" then
			-- take the file extension
			local ext = filename:sub(-#extension):lower()

			if ext == extension:lower() then
				table.insert(files, filename)
			end
		end
	end
	return files
end






function refill_batch_orbits()

	orbitalsBatch:clear()
	for sys = 1, galaxy.number_of_systems do
		local centerX = galaxy.star_system.position_X[sys]
		local centerY = galaxy.star_system.position_Y[sys]
		local size = game_ref.current_global_scale * 0.01
		for orbit = 1, galaxy.nbOrbits do
			local radius = (orbit * 6 + 4)
			local angularSpeed = 0.8 / orbit
			local angle = galaxy.star_system.orbital.phase[sys][orbit] + (love.timer.getTime() * angularSpeed)
			local px = centerX + math.cos(angle) * radius
			local py = centerY + math.sin(angle) * radius
			local type_orbital = galaxy.star_system.orbital.type[sys][orbit]
			if type_orbital > 1 then
				local type_orbital2 = game_prep.starfield.orbitals.type[type_orbital]
			--	print (type_orbital .. " " ..type_orbital2)
				local vx, vy, vw, vh = atlas_galaxy:getViewport(type_orbital2)
				local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_galaxy.image:getDimensions())
				orbitalsBatch:add(quad, px, py, 0, size, size, vw/2, vh/2)
			end
		end
	end

end


function GUI_Star_Bar()
	love.graphics.push()
	atlas_guiGame:draw("systeme_barre", game_ref.ui.gui_systeme.systeme_barre[1], game_ref.ui.gui_systeme.systeme_barre[2], game_ref.ui.gui_systeme.systeme_barre[3], game_ref.ui.gui_systeme.systeme_barre[4])
	love.graphics.pop()
end


