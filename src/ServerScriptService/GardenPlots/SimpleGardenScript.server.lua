-- -- UPDATED GARDEN SCRIPT WITH GRID - Put in ServerScriptService
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- -- Wait for systems
-- local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
-- local notificationRemote = plotEvents:WaitForChild("ShowNotification")
-- local cropRemote = plotEvents:WaitForChild("CropSystem")

-- -- Create remote for grid visibility IMMEDIATELY when script starts
-- local gridRemote = Instance.new("RemoteEvent")
-- gridRemote.Name = "GridVisibility"
-- gridRemote.Parent = plotEvents

-- print("✅ Created GridVisibility remote")

-- local plotOwners = {}
-- local gardenGrids = {}
-- local plantedCrops = {}  -- [plotNumber][plantId] = cropData

-- -- UPDATED: All crop definitions with growth times
-- local CROPS = {
-- 	strawberry = { growthTime = 30, harvestCount = 3 },
-- 	orange = { growthTime = 45, harvestCount = 2 },
-- 	apple = { growthTime = 25, harvestCount = 4 },
-- 	carrot = { growthTime = 20, harvestCount = 5 },
-- 	blueberry = { growthTime = 40, harvestCount = 6 },
-- 	mint = { growthTime = 50, harvestCount = 2 },
-- 	watermelon = { growthTime = 60, harvestCount = 1 },
-- 	lemon = { growthTime = 35, harvestCount = 3 },
-- 	grape = { growthTime = 55, harvestCount = 4 },
-- 	cucumber = { growthTime = 25, harvestCount = 6 }
-- }

-- -- Create grid when plot claimed
-- local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
-- plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
-- 	plotOwners[plotNumber] = userId
	
-- 	-- Find garden part
-- 	local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
-- 	if not plotFolder then return end
	
-- 	local gardenPart = plotFolder:FindFirstChild("Plot" .. plotNumber .. "_Garden")
-- 	if not gardenPart then return end
	
-- 	-- Delete any existing grids
-- 	local existing = plotFolder:FindFirstChild("PlantingSpots")
-- 	if existing then existing:Destroy() end
	
-- 	-- Create simple grid with correct orientation
-- 	local spotsFolder = Instance.new("Folder")
-- 	spotsFolder.Name = "PlantingSpots"
-- 	spotsFolder.Parent = plotFolder
	
-- 	-- Set grid dimensions based on plot orientation
-- 	local spotsX, spotsZ
-- 	if plotNumber == 1 or plotNumber == 2 then
-- 		-- Plots 1&2: Vertical orientation (10 wide x 20 deep)
-- 		spotsX = 10
-- 		spotsZ = 20
-- 	else
-- 		-- Plots 3-6: Horizontal orientation (20 wide x 10 deep)  
-- 		spotsX = 20
-- 		spotsZ = 10
-- 	end
	
-- 	-- Initialize planted crops for this plot
-- 	if not plantedCrops[plotNumber] then
-- 		plantedCrops[plotNumber] = {}
-- 	end
	
-- 	for x = 1, spotsX do
-- 		for z = 1, spotsZ do
-- 			local spot = Instance.new("Part")
-- 			spot.Name = "Spot_" .. x .. "_" .. z
-- 			spot.Size = Vector3.new(4.5, 0.1, 4.5)
-- 			spot.Material = Enum.Material.Grass
-- 			spot.Color = Color3.fromRGB(85, 170, 85)
-- 			spot.Anchored = true
-- 			spot.CanCollide = false
-- 			spot.Transparency = 1  -- Always invisible on server
			
-- 			local offsetX = (x - spotsX/2 - 0.5) * 5
-- 			local offsetZ = (z - spotsZ/2 - 0.5) * 5
-- 			spot.Position = gardenPart.Position + Vector3.new(offsetX, 0.5, offsetZ)
-- 			spot.Parent = spotsFolder
			
-- 			-- Click to plant
-- 			local click = Instance.new("ClickDetector")
-- 			click.MaxActivationDistance = 20
-- 			click.Parent = spot
			
-- 			click.MouseClick:Connect(function(player)
-- 				if plotOwners[plotNumber] == player.UserId then
-- 					-- Check for seeds and get crop type
-- 					local cropType = nil
-- 					if player.Character then
-- 						for _, tool in pairs(player.Character:GetChildren()) do
-- 							if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
-- 								local seedType = tool:GetAttribute("SeedType")
-- 								cropType = seedType:gsub("_seeds", "") -- Convert "strawberry_seeds" to "strawberry"
-- 								break
-- 							end
-- 						end
-- 					end
					
-- 					if cropType and CROPS[cropType] then
-- 						-- Check if spot is already occupied
-- 						local spotKey = x .. "_" .. z
-- 						if plantedCrops[plotNumber][spotKey] then
-- 							notificationRemote:FireClient(player, "error", "❌ Spot Occupied", "There's already a plant here!")
-- 							return
-- 						end
						
-- 						-- Try to plant (communicate with crop system)
-- 						cropRemote:FireServer("plant", plotNumber, cropType, spot.Position + Vector3.new(0, 2, 0))
						
-- 						-- Create the actual plant and mark spot as occupied
-- 						plantCrop(plotNumber, cropType, spot.Position + Vector3.new(0, 2, 0), player, spotKey)
						
-- 						-- Hide this specific spot after planting
-- 						spot.Transparency = 1
-- 					else
-- 						notificationRemote:FireClient(player, "error", "❌ No Seeds", "Equip seeds first!")
-- 					end
-- 				else
-- 					notificationRemote:FireClient(player, "error", "❌ Not Your Plot", "You don't own this garden!")
-- 				end
-- 			end)
-- 		end
-- 	end
	
-- 	gardenGrids[plotNumber] = spotsFolder
	
-- 	-- Tell the owner about their new grid
-- 	local player = Players:GetPlayerByUserId(userId)
-- 	if player then
-- 		gridRemote:FireClient(player, "grid_created", plotNumber)
-- 	end
-- end)

-- -- Plant a crop
-- function plantCrop(plotNumber, cropType, position, player, spotKey)
-- 	if not plantedCrops[plotNumber] then
-- 		plantedCrops[plotNumber] = {}
-- 	end
	
-- 	-- Create growing plant model
-- 	local plantModel = createPlantModel(position, "growing", plotNumber, spotKey, cropType)
-- 	local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
-- 	if plotFolder then
-- 		plantModel.Parent = plotFolder
-- 	end
	
-- 	-- Store crop data using spot key
-- 	plantedCrops[plotNumber][spotKey] = {
-- 		cropType = cropType,
-- 		position = position,
-- 		plantedAt = tick(),
-- 		model = plantModel,
-- 		stage = "growing",
-- 		owner = player.UserId
-- 	}
	
-- 	-- Start growth timer (use crop-specific growth time)
-- 	local growthTime = CROPS[cropType].growthTime
-- 	spawn(function()
-- 		wait(growthTime)
		
-- 		-- Check if plant still exists
-- 		if plantedCrops[plotNumber][spotKey] then
-- 			-- Replace with grown version
-- 			local oldModel = plantedCrops[plotNumber][spotKey].model
-- 			local newModel = createPlantModel(position, "grown", plotNumber, spotKey, cropType)
-- 			if plotFolder then
-- 				newModel.Parent = plotFolder
-- 			end
-- 			if oldModel then
-- 				oldModel:Destroy()
-- 			end
			
-- 			plantedCrops[plotNumber][spotKey].model = newModel
-- 			plantedCrops[plotNumber][spotKey].stage = "grown"
			
-- 			-- Notify owner
-- 			local owner = Players:GetPlayerByUserId(plantedCrops[plotNumber][spotKey].owner)
-- 			if owner then
-- 				notificationRemote:FireClient(owner, "success", "🌱 Ready to Harvest!", "Your " .. cropType .. " is ready!")
-- 			end
-- 		end
-- 	end)
-- end

-- -- Create plant model (UPDATED: handles all crop types)
-- function createPlantModel(position, stage, plotNumber, spotKey, cropType)
-- 	local model = Instance.new("Model")
-- 	model.Name = cropType .. "Plant_" .. spotKey
	
-- 	-- Stem
-- 	local stem = Instance.new("Part")
-- 	stem.Name = "Stem"
-- 	stem.Size = Vector3.new(0.5, 2, 0.5)
-- 	stem.Material = Enum.Material.Wood
-- 	stem.Color = Color3.fromRGB(34, 139, 34)
-- 	stem.Anchored = true
-- 	stem.CanCollide = false
-- 	stem.Position = position
-- 	stem.Parent = model
	
-- 	-- Leaves (different amounts for different crops)
-- 	local leafCount = 3
-- 	if cropType == "watermelon" then leafCount = 5
-- 	elseif cropType == "mint" then leafCount = 6
-- 	elseif cropType == "grape" then leafCount = 4
-- 	end
	
-- 	for i = 1, leafCount do
-- 		local leaf = Instance.new("Part")
-- 		leaf.Name = "Leaf" .. i
-- 		leaf.Size = Vector3.new(1, 0.1, 1.5)
-- 		leaf.Material = Enum.Material.Leaf
-- 		leaf.Color = Color3.fromRGB(50, 205, 50)
-- 		leaf.Anchored = true
-- 		leaf.CanCollide = false
-- 		leaf.Position = position + Vector3.new(math.random(-1, 1), i * 0.3, math.random(-1, 1))
-- 		leaf.Rotation = Vector3.new(0, math.random(0, 360), 0)
-- 		leaf.Parent = model
-- 	end
	
-- 	-- Add crop-specific features if grown
-- 	if stage == "grown" then
-- 		local harvestCount = CROPS[cropType].harvestCount
		
-- 		for i = 1, harvestCount do
-- 			local crop = Instance.new("Part")
-- 			crop.Name = cropType:gsub("^%l", string.upper) .. i
-- 			crop.Anchored = true
-- 			crop.CanCollide = false
-- 			crop.Parent = model
			
-- 			-- Crop-specific appearance
-- 			if cropType == "strawberry" then
-- 				crop.Size = Vector3.new(0.8, 0.6, 0.8)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(220, 20, 60)
-- 			elseif cropType == "orange" then
-- 				crop.Size = Vector3.new(1, 1, 1)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(255, 140, 0)
-- 			elseif cropType == "apple" then
-- 				crop.Size = Vector3.new(0.9, 0.9, 0.9)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(255, 0, 0)
-- 			elseif cropType == "carrot" then
-- 				crop.Size = Vector3.new(0.4, 1.2, 0.4)
-- 				crop.Shape = Enum.PartType.Cylinder
-- 				crop.Color = Color3.fromRGB(255, 140, 0)
-- 			elseif cropType == "blueberry" then
-- 				crop.Size = Vector3.new(0.4, 0.4, 0.4)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(70, 130, 180)
-- 			elseif cropType == "mint" then
-- 				crop.Size = Vector3.new(0.6, 0.2, 1.2)
-- 				crop.Shape = Enum.PartType.Block
-- 				crop.Color = Color3.fromRGB(152, 251, 152)
-- 			elseif cropType == "watermelon" then
-- 				crop.Size = Vector3.new(2, 1.5, 2)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(34, 139, 34)
-- 			elseif cropType == "lemon" then
-- 				crop.Size = Vector3.new(0.7, 0.9, 0.7)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(255, 255, 0)
-- 			elseif cropType == "grape" then
-- 				crop.Size = Vector3.new(0.3, 0.3, 0.3)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(128, 0, 128)
-- 			elseif cropType == "cucumber" then
-- 				crop.Size = Vector3.new(0.5, 1.5, 0.5)
-- 				crop.Shape = Enum.PartType.Cylinder
-- 				crop.Color = Color3.fromRGB(50, 205, 50)
-- 			else
-- 				-- Default appearance
-- 				crop.Size = Vector3.new(0.8, 0.6, 0.8)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(220, 20, 60)
-- 			end
			
-- 			crop.Material = Enum.Material.Neon
-- 			crop.Position = position + Vector3.new(math.random(-1, 1), math.random(0, 1), math.random(-1, 1))
-- 		end
		
-- 		-- Sparkles
-- 		local sparkles = Instance.new("Sparkles")
-- 		sparkles.Color = Color3.fromRGB(255, 255, 0)
-- 		sparkles.Parent = stem
		
-- 		-- Harvest click detector
-- 		local clickDetector = Instance.new("ClickDetector")
-- 		clickDetector.MaxActivationDistance = 15
-- 		clickDetector.Parent = stem
		
-- 		clickDetector.MouseClick:Connect(function(player)
-- 			if plotOwners[plotNumber] == player.UserId then
-- 				-- Remove plant and free up the spot
-- 				if plantedCrops[plotNumber][spotKey] then
-- 					plantedCrops[plotNumber][spotKey] = nil
-- 					model:Destroy()
					
-- 					-- Tell crop system about harvest
-- 					cropRemote:FireServer("harvest", plotNumber, spotKey, cropType)
-- 				end
-- 			else
-- 				notificationRemote:FireClient(player, "error", "❌ Not Yours", "You can only harvest your own crops!")
-- 			end
-- 		end)
-- 	end
	
-- 	return model
-- end

-- -- Handle tool equip/unequip events
-- local function onToolChange(player)
-- 	-- Check what plot this player owns
-- 	for plotNumber, userId in pairs(plotOwners) do
-- 		if userId == player.UserId then
-- 			-- Check if they have seeds equipped
-- 			local hasSeed = false
-- 			if player.Character then
-- 				for _, tool in pairs(player.Character:GetChildren()) do
-- 					if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
-- 						hasSeed = true
-- 						break
-- 					end
-- 				end
-- 			end
			
-- 			-- Tell client to show/hide their grid
-- 			gridRemote:FireClient(player, "update_grid", plotNumber, hasSeed)
-- 			break
-- 		end
-- 	end
-- end

-- -- Monitor tool changes
-- Players.PlayerAdded:Connect(function(player)
-- 	player.CharacterAdded:Connect(function(character)
-- 		character.ChildAdded:Connect(function(child)
-- 			if child:IsA("Tool") then
-- 				wait(0.1)
-- 				onToolChange(player)
-- 			end
-- 		end)
-- 		character.ChildRemoved:Connect(function(child)
-- 			if child:IsA("Tool") then
-- 				wait(0.1)
-- 				onToolChange(player)
-- 			end
-- 		end)
		
-- 		-- Also check when character spawns
-- 		wait(1)
-- 		onToolChange(player)
-- 	end)
-- end)

-- -- For existing players
-- for _, player in pairs(Players:GetPlayers()) do
-- 	if player.Character then
-- 		spawn(function()
-- 			wait(1)
-- 			onToolChange(player)
-- 		end)
-- 	end
-- end

-- -- Clean up when player leaves
-- Players.PlayerRemoving:Connect(function(player)
-- 	for plotNumber, ownerId in pairs(plotOwners) do
-- 		if ownerId == player.UserId then
-- 			plotOwners[plotNumber] = nil
-- 			if gardenGrids[plotNumber] then
-- 				gardenGrids[plotNumber]:Destroy()
-- 				gardenGrids[plotNumber] = nil
-- 			end
-- 			if plantedCrops[plotNumber] then
-- 				for _, cropData in pairs(plantedCrops[plotNumber]) do
-- 					if cropData.model then
-- 						cropData.model:Destroy()
-- 					end
-- 				end
-- 				plantedCrops[plotNumber] = nil
-- 			end
-- 		end
-- 	end
-- end)

-- print("🌱 Updated garden system ready with grid support!"))
-- 				-- Add watermelon stripes
-- 				local stripes = Instance.new("SurfaceGui")
-- 				stripes.Face = Enum.NormalId.Front
-- 				stripes.Parent = crop
-- 				local stripe = Instance.new("Frame")
-- 				stripe.Size = UDim2.new(0.1, 0, 1, 0)
-- 				stripe.Position = UDim2.new(0.3, 0, 0, 0)
-- 				stripe.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
-- 				stripe.BorderSizePixel = 0
-- 				stripe.Parent = stripes
-- 			elseif cropType == "lemon" then
-- 				crop.Size = Vector3.new(0.7, 0.9, 0.7)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(255, 255, 0)
-- 			elseif cropType == "grape" then
-- 				crop.Size = Vector3.new(0.3, 0.3, 0.3)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(128, 0, 128)
-- 			elseif cropType == "cucumber" then
-- 				crop.Size = Vector3.new(0.5, 1.5, 0.5)
-- 				crop.Shape = Enum.PartType.Cylinder
-- 				crop.Color = Color3.fromRGB(50, 205, 50)
-- 			else
-- 				-- Default appearance
-- 				crop.Size = Vector3.new(0.8, 0.6, 0.8)
-- 				crop.Shape = Enum.PartType.Ball
-- 				crop.Color = Color3.fromRGB(220, 20, 60)
-- 			end
			
-- 			crop.Material = Enum.Material.Neon
-- 			crop.Position = position + Vector3.new(math.random(-1, 1), math.random(0, 1), math.random(-1, 1))
-- 		end
		
-- 		-- Sparkles
-- 		local sparkles = Instance.new("Sparkles")
-- 		sparkles.Color = Color3.fromRGB(255, 255, 0)
-- 		sparkles.Parent = stem
		
-- 		-- Harvest click detector
-- 		local clickDetector = Instance.new("ClickDetector")
-- 		clickDetector.MaxActivationDistance = 15
-- 		clickDetector.Parent = stem
		
-- 		clickDetector.MouseClick:Connect(function(player)
-- 			if playerOwnsPlot(player, plotNumber) then
-- 				-- Remove plant
-- 				if plantedCrops[plotNumber][plantId] then
-- 					plantedCrops[plotNumber][plantId] = nil
-- 					model:Destroy()
					
-- 					-- Tell crop system about harvest
-- 					cropRemote:FireServer("harvest", plotNumber, plantId, cropType)
-- 				end
-- 			else
-- 				notificationRemote:FireClient(player, "error", "❌ Not Yours", "You can only harvest your own crops!")
-- 			end
-- 		end)
-- 	end
	
-- 	return model
-- end

-- -- Listen for plot claims
-- local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
-- plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
-- 	plotOwners[plotNumber] = userId
-- 	print("🏡 Garden: Plot " .. plotNumber .. " claimed by " .. playerName)
-- 	createInteractiveGarden(plotNumber)
-- end)

-- -- Clean up when player leaves
-- Players.PlayerRemoving:Connect(function(player)
-- 	for plotNumber, ownerId in pairs(plotOwners) do
-- 		if ownerId == player.UserId then
-- 			plotOwners[plotNumber] = nil
-- 			if gardenAreas[plotNumber] then
-- 				gardenAreas[plotNumber].interactionPart:Destroy()
-- 				gardenAreas[plotNumber] = nil
-- 			end
-- 			if plantedCrops[plotNumber] then
-- 				for _, cropData in pairs(plantedCrops[plotNumber]) do
-- 					if cropData.model then
-- 						cropData.model:Destroy()
-- 					end
-- 				end
-- 				plantedCrops[plotNumber] = nil
-- 			end
-- 		end
-- 	end
-- end)

-- print("🌱 Updated garden system ready with all crop types!")