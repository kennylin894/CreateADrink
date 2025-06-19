-- SIMPLE GARDEN SCRIPT - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for systems
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")
local cropRemote = plotEvents:WaitForChild("CropSystem")

-- Garden data
local gardenAreas = {}
local plotOwners = {}
local plantedCrops = {}  -- [plotNumber][plantId] = cropData

-- Function to check if player owns plot
local function playerOwnsPlot(player, plotNumber)
	return plotOwners[plotNumber] == player.UserId
end

-- Create interactive garden area
local function createInteractiveGarden(plotNumber)
	local playerPlotsFolder = workspace:FindFirstChild("PlayerPlots")
	if not playerPlotsFolder then return end
	
	local plotFolder = playerPlotsFolder:FindFirstChild("Plot" .. plotNumber)
	if not plotFolder then return end
	
	local gardenPart = plotFolder:FindFirstChild("Plot" .. plotNumber .. "_Garden")
	if not gardenPart then return end
	
	-- Create invisible interaction part
	local interactionPart = Instance.new("Part")
	interactionPart.Name = "GardenInteraction"
	interactionPart.Size = gardenPart.Size + Vector3.new(0, 5, 0)
	interactionPart.Position = gardenPart.Position + Vector3.new(0, 2.5, 0)
	interactionPart.Anchored = true
	interactionPart.CanCollide = false
	interactionPart.Transparency = 1
	interactionPart.Parent = plotFolder
	
	-- Create click detector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = interactionPart
	
	-- Handle clicks
	clickDetector.MouseClick:Connect(function(player)
		if not playerOwnsPlot(player, plotNumber) then
			notificationRemote:FireClient(player, "error", "❌ Access Denied", "You don't own this garden!")
			return
		end
		
		-- Calculate planting position
		local gardenCenter = gardenPart.Position
		local gardenSize = gardenPart.Size
		local offsetX = math.random(-gardenSize.X/2 + 5, gardenSize.X/2 - 5)
		local offsetZ = math.random(-gardenSize.Z/2 + 5, gardenSize.Z/2 - 5)
		
		local plantPosition = Vector3.new(
			gardenCenter.X + offsetX,
			gardenCenter.Y + gardenSize.Y/2 + 1,
			gardenCenter.Z + offsetZ
		)
		
		-- Check spacing
		local tooClose = false
		if plantedCrops[plotNumber] then
			for _, cropData in pairs(plantedCrops[plotNumber]) do
				if cropData.position then
					local distance = (plantPosition - cropData.position).Magnitude
					if distance < 8 then
						tooClose = true
						break
					end
				end
			end
		end
		
		if tooClose then
			notificationRemote:FireClient(player, "error", "❌ Too Close", "Space your plants out more!")
			return
		end
		
		-- Try to plant (communicate with crop system)
		cropRemote:FireServer("plant", plotNumber, "strawberry", plantPosition)
		
		-- Create the actual plant
		plantCrop(plotNumber, "strawberry", plantPosition, player)
	end)
	
	-- Store garden data
	gardenAreas[plotNumber] = {
		interactionPart = interactionPart,
		gardenPart = gardenPart,
		plotFolder = plotFolder
	}
	
	-- Initialize planted crops for this plot
	if not plantedCrops[plotNumber] then
		plantedCrops[plotNumber] = {}
	end
	
	print("✅ Created interactive garden for Plot " .. plotNumber)
end

-- Plant a crop
function plantCrop(plotNumber, cropType, position, player)
	if not plantedCrops[plotNumber] then
		plantedCrops[plotNumber] = {}
	end
	
	local plantId = #plantedCrops[plotNumber] + 1
	
	-- Create growing plant model
	local plantModel = createPlantModel(position, "growing", plotNumber, plantId, cropType)
	plantModel.Parent = gardenAreas[plotNumber].plotFolder
	
	-- Store crop data
	plantedCrops[plotNumber][plantId] = {
		cropType = cropType,
		position = position,
		plantedAt = tick(),
		model = plantModel,
		stage = "growing",
		owner = player.UserId
	}
	
	-- Start growth timer
	spawn(function()
		wait(30) -- 30 seconds growth time
		
		-- Check if plant still exists
		if plantedCrops[plotNumber][plantId] then
			-- Replace with grown version
			local oldModel = plantedCrops[plotNumber][plantId].model
			local newModel = createPlantModel(position, "grown", plotNumber, plantId, cropType)
			newModel.Parent = gardenAreas[plotNumber].plotFolder
			oldModel:Destroy()
			
			plantedCrops[plotNumber][plantId].model = newModel
			plantedCrops[plotNumber][plantId].stage = "grown"
			
			-- Notify owner
			local owner = Players:GetPlayerByUserId(plantedCrops[plotNumber][plantId].owner)
			if owner then
				notificationRemote:FireClient(owner, "success", "🌱 Ready to Harvest!", "Your strawberry is ready!")
			end
		end
	end)
end

-- Create plant model
function createPlantModel(position, stage, plotNumber, plantId, cropType)
	local model = Instance.new("Model")
	model.Name = cropType .. "Plant_" .. plantId
	
	-- Stem
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.5, 2, 0.5)
	stem.Material = Enum.Material.Wood
	stem.Color = Color3.fromRGB(34, 139, 34)
	stem.Anchored = true
	stem.CanCollide = false
	stem.Position = position
	stem.Parent = model
	
	-- Leaves
	for i = 1, 3 do
		local leaf = Instance.new("Part")
		leaf.Name = "Leaf" .. i
		leaf.Size = Vector3.new(1, 0.1, 1.5)
		leaf.Material = Enum.Material.Leaf
		leaf.Color = Color3.fromRGB(50, 205, 50)
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Position = position + Vector3.new(math.random(-1, 1), i * 0.5, math.random(-1, 1))
		leaf.Rotation = Vector3.new(0, math.random(0, 360), 0)
		leaf.Parent = model
	end
	
	-- Add fruit if grown
	if stage == "grown" then
		for i = 1, 3 do
			local berry = Instance.new("Part")
			berry.Name = "Berry" .. i
			berry.Size = Vector3.new(0.8, 0.6, 0.8)
			berry.Shape = Enum.PartType.Ball
			berry.Material = Enum.Material.Neon
			berry.Color = Color3.fromRGB(220, 20, 60)
			berry.Anchored = true
			berry.CanCollide = false
			berry.Position = position + Vector3.new(math.random(-1, 1), math.random(0, 1), math.random(-1, 1))
			berry.Parent = model
		end
		
		-- Sparkles
		local sparkles = Instance.new("Sparkles")
		sparkles.Color = Color3.fromRGB(255, 255, 0)
		sparkles.Parent = stem
		
		-- Harvest click detector
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 15
		clickDetector.Parent = stem
		
		clickDetector.MouseClick:Connect(function(player)
			if playerOwnsPlot(player, plotNumber) then
				-- Remove plant
				if plantedCrops[plotNumber][plantId] then
					plantedCrops[plotNumber][plantId] = nil
					model:Destroy()
					
					-- Tell crop system about harvest
					cropRemote:FireServer("harvest", plotNumber, plantId, cropType)
				end
			else
				notificationRemote:FireClient(player, "error", "❌ Not Yours", "You can only harvest your own crops!")
			end
		end)
	end
	
	return model
end

-- Listen for plot claims
local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
	plotOwners[plotNumber] = userId
	print("🏡 Garden: Plot " .. plotNumber .. " claimed by " .. playerName)
	createInteractiveGarden(plotNumber)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	for plotNumber, ownerId in pairs(plotOwners) do
		if ownerId == player.UserId then
			plotOwners[plotNumber] = nil
			if gardenAreas[plotNumber] then
				gardenAreas[plotNumber].interactionPart:Destroy()
				gardenAreas[plotNumber] = nil
			end
			if plantedCrops[plotNumber] then
				for _, cropData in pairs(plantedCrops[plotNumber]) do
					if cropData.model then
						cropData.model:Destroy()
					end
				end
				plantedCrops[plotNumber] = nil
			end
		end
	end
end)

print("🌱 Garden system ready!")