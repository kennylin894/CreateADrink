-- GridGardenScript.server.lua
-- GARDEN SCRIPT WITH REALISTIC CROPS - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for systems
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")
local cropRemote = plotEvents:WaitForChild("CropSystem")

-- Create remotes
local gridRemote = Instance.new("RemoteEvent")
gridRemote.Name = "GridVisibility"
gridRemote.Parent = plotEvents

local gridClickRemote = Instance.new("RemoteEvent")
gridClickRemote.Name = "GridClick"
gridClickRemote.Parent = plotEvents

-- Function to remove seed from player's inventory
local function removeSeedFromInventory(player, seedType)
	if not player.Backpack then return false end
	
	-- Check backpack first
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("SeedType") == seedType then
			local currentCount = tool:GetAttribute("SeedCount") or 1
			if currentCount > 1 then
				-- Update count and tool name
				tool:SetAttribute("SeedCount", currentCount - 1)
				tool.Name = seedType:gsub("_", " "):gsub("(%a)(%a*)", function(a,b) return string.upper(a)..b end) .. " (" .. (currentCount - 1) .. ")"
			else
				-- Remove tool completely
				tool:Destroy()
			end
			return true
		end
	end
	
	-- Check if holding the tool
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("SeedType") == seedType then
				local currentCount = tool:GetAttribute("SeedCount") or 1
				if currentCount > 1 then
					-- Update count and tool name
					tool:SetAttribute("SeedCount", currentCount - 1)
					tool.Name = seedType:gsub("_", " "):gsub("(%a)(%a*)", function(a,b) return string.upper(a)..b end) .. " (" .. (currentCount - 1) .. ")"
				else
					-- Remove tool completely
					tool:Destroy()
				end
				return true
			end
		end
	end
	
	return false
end

local plotOwners = {}
local gardenGrids = {}
local plantedCrops = {}
local function giveCropsToPlayer(player, cropType, amount)
	if not player.Backpack then return end
	
	-- Check if player already has this crop type
	local existingTool = nil
	local currentCount = 0
	
	-- Check backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("ItemType") == cropType then
			existingTool = tool
			currentCount = tool:GetAttribute("ItemCount") or 0
			break
		end
	end
	
	-- Check if holding the tool
	if not existingTool and player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("ItemType") == cropType then
				existingTool = tool
				currentCount = tool:GetAttribute("ItemCount") or 0
				break
			end
		end
	end
	
	local newCount = currentCount + amount
	
	if existingTool then
		-- Update existing tool
		existingTool:SetAttribute("ItemCount", newCount)
		existingTool.Name = cropType:gsub("^%l", string.upper) .. " (" .. newCount .. ")"
	else
		-- Create new crop tool
		local tool = Instance.new("Tool")
		tool.Name = cropType:gsub("^%l", string.upper) .. " (" .. newCount .. ")"
		tool.RequiresHandle = false
		tool.CanBeDropped = false
		tool:SetAttribute("ItemCount", newCount)
		tool:SetAttribute("ItemType", cropType)
		
		-- Create simple handle
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.8, 0.6, 0.8)
		handle.Material = Enum.Material.Neon
		handle.Color = Color3.fromRGB(220, 20, 60) -- Red for strawberry
		handle.Shape = Enum.PartType.Ball
		handle.CanCollide = false
		handle.Parent = tool
		
		tool.Parent = player.Backpack
	end
end

-- Crop definitions with your custom model IDs
local CROPS = {
	strawberry = {
		name = "Strawberry",
		growthTime = 15,
		harvestCount = 3,
		seedModelId = 84042288644312, -- Your seedling model
		youngModelId = 97551869960130, -- Your NEW 2nd stage model
		matureModelId = 80476146564750, -- Your final model
		size = Vector3.new(3, 3, 3)
	},
}

-- Function to create crop models from Roblox catalog
local function createCropModel(modelId, position, scale)
	if not modelId then
		return nil
	end
	
	local success, model = pcall(function()
		return game:GetService("InsertService"):LoadAsset(modelId)
	end)
	
	if success and model then
		local actualModel = model:GetChildren()[1]
		if actualModel then
			actualModel.Parent = workspace
			model:Destroy()
			
			-- Scale and position the model
			if actualModel:IsA("Model") then
				local primaryPart = actualModel.PrimaryPart
				if not primaryPart then
					for _, child in pairs(actualModel:GetChildren()) do
						if child:IsA("BasePart") then
							primaryPart = child
							actualModel.PrimaryPart = primaryPart
							break
						end
					end
				end
				
				if primaryPart then
					actualModel:SetPrimaryPartCFrame(CFrame.new(position))
					
					-- Scale all parts in the model
					for _, part in pairs(actualModel:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Size = part.Size * scale
							part.Anchored = true
							part.CanCollide = false
						end
					end
				end
			else
				actualModel.Position = position
				actualModel.Size = actualModel.Size * scale
				actualModel.Anchored = true
				actualModel.CanCollide = false
			end
			
			return actualModel
		end
	end
	
	return nil
end

-- Function to create crop visual with growth stages
local function createCropVisual(cropType, position, plotNumber, spotName)
	local crop = CROPS[cropType]
	if not crop then return nil end
	
	-- Create container for the crop
	local cropContainer = Instance.new("Model")
	cropContainer.Name = cropType .. "_Plant_" .. spotName
	cropContainer.Parent = workspace
	
	-- Start with seedling
	local currentModel = createCropModel(crop.seedModelId, position, 0.8)
	if currentModel then
		currentModel.Parent = cropContainer
	end
	
	-- Store crop data
	local cropData = {
		container = cropContainer,
		currentModel = currentModel,
		cropType = cropType,
		plotNumber = plotNumber,
		spotName = spotName,
		stage = "seedling",
		isHarvestable = false
	}
	
	-- Growth animation with stages
	spawn(function()
		wait(1)
		
		-- Stage 1: Young plant
		wait(crop.growthTime * 0.3)
		if currentModel then currentModel:Destroy() end
		currentModel = createCropModel(crop.youngModelId, position, 0.9)
		if currentModel then
			currentModel.Parent = cropContainer
			cropData.currentModel = currentModel
			cropData.stage = "young"
		end
		
		-- Stage 2: Growing plant - use your second model
		wait(crop.growthTime * 0.3)
		if currentModel then currentModel:Destroy() end
		currentModel = createCropModel(crop.youngModelId, position, 1.0) -- Use second model
		if currentModel then
			currentModel.Parent = cropContainer
			cropData.currentModel = currentModel
			cropData.stage = "growing"
		end
		
		-- Stage 3: Mature plant - use your third model at full size
		wait(crop.growthTime * 0.4)
		if currentModel then currentModel:Destroy() end
		currentModel = createCropModel(crop.matureModelId, position, 1.0) -- Full size mature
		if currentModel then
			currentModel.Parent = cropContainer
			cropData.currentModel = currentModel
			cropData.stage = "mature"
			cropData.isHarvestable = true
			
			-- Add ProximityPrompt for harvesting instead of text GUI
			local proximityPrompt = Instance.new("ProximityPrompt")
			proximityPrompt.ActionText = "Harvest " .. crop.name
			proximityPrompt.ObjectText = "Crop"
			proximityPrompt.HoldDuration = 1 -- Hold for 1 second
			proximityPrompt.MaxActivationDistance = 8
			proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
			proximityPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			proximityPrompt.Parent = currentModel
			
			-- Handle harvest interaction
			proximityPrompt.Triggered:Connect(function(player)
				if plotOwners[plotNumber] == player.UserId then
					-- Give player 3 strawberries directly
					giveCropsToPlayer(player, cropData.cropType, CROPS[cropData.cropType].harvestCount)
					
					-- Remove visual
					cropData.container:Destroy()
					plantedCrops[plotNumber][spotName] = nil
					
					notificationRemote:FireClient(player, "success", "🍓 Harvested!", "You harvested " .. CROPS[cropData.cropType].harvestCount .. " " .. CROPS[cropData.cropType].name .. "s!")
				else
					notificationRemote:FireClient(player, "error", "❌ Not Your Plot", "You can only harvest from your own plot!")
				end
			end)
		end
	end)
	
	return cropData
end

-- Create grid when plot claimed
local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
	plotOwners[plotNumber] = userId
	plantedCrops[plotNumber] = {}
	
	local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
	if not plotFolder then return end
	
	local gardenPart = plotFolder:FindFirstChild("Plot" .. plotNumber .. "_Garden")
	if not gardenPart then return end
	
	-- Delete any existing grids
	local existing = plotFolder:FindFirstChild("PlantingSpots")
	if existing then existing:Destroy() end
	
	-- Create grid
	local spotsFolder = Instance.new("Folder")
	spotsFolder.Name = "PlantingSpots"
	spotsFolder.Parent = plotFolder
	
	-- Grid dimensions
	local spotsX, spotsZ
	if plotNumber == 1 or plotNumber == 2 then
		spotsX = 10
		spotsZ = 20
	else
		spotsX = 20
		spotsZ = 10
	end
	
	for x = 1, spotsX do
		for z = 1, spotsZ do
			local spot = Instance.new("Part")
			spot.Name = "Spot_" .. x .. "_" .. z
			spot.Size = Vector3.new(4.5, 0.1, 4.5)
			spot.Material = Enum.Material.Grass
			spot.Color = Color3.fromRGB(85, 170, 85)
			spot.Anchored = true
			spot.CanCollide = false
			spot.Transparency = 1
			
			local offsetX = (x - spotsX/2 - 0.5) * 5
			local offsetZ = (z - spotsZ/2 - 0.5) * 5
			spot.Position = gardenPart.Position + Vector3.new(offsetX, 0.5, offsetZ)
			spot.Parent = spotsFolder
			
			-- Store spot data for remote clicking
			spot:SetAttribute("PlotNumber", plotNumber)
			spot:SetAttribute("SpotName", spot.Name)
		end
	end
	
	gardenGrids[plotNumber] = spotsFolder
	
	-- Tell client about grid
	local player = Players:GetPlayerByUserId(userId)
	if player then
		gridRemote:FireClient(player, "grid_created", plotNumber)
		gridRemote:FireClient(player, "update_grid", plotNumber, false)
	end
end)

-- Handle tool changes
local function onToolChange(player)
	for plotNumber, userId in pairs(plotOwners) do
		if userId == player.UserId then
			local hasSeed = false
			if player.Character then
				for _, tool in pairs(player.Character:GetChildren()) do
					if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
						hasSeed = true
						break
					end
				end
			end
			gridRemote:FireClient(player, "update_grid", plotNumber, hasSeed)
			break
		end
	end
end

-- Monitor tool changes
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				wait(0.1)
				onToolChange(player)
			end
		end)
		
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				wait(0.1)
				onToolChange(player)
			end
		end)
		
		wait(1)
		onToolChange(player)
	end)
end)

-- Handle grid clicks from client
gridClickRemote.OnServerEvent:Connect(function(player, plotNumber, spotName)
	local success, errorMsg = pcall(function()
		if plotOwners[plotNumber] == player.UserId then
			-- Check if spot already has crop
			if plantedCrops[plotNumber] and plantedCrops[plotNumber][spotName] then
				notificationRemote:FireClient(player, "error", "❌ Spot Occupied", "There's already a crop growing here!")
				return
			end
			
			-- Get equipped crop type
			local cropType = nil
			if player.Character then
				for _, tool in pairs(player.Character:GetChildren()) do
					if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
						local seedType = tool:GetAttribute("SeedType")
						cropType = seedType:gsub("_seeds", "")
						break
					end
				end
			end
			
			if cropType then
				-- Find the spot
				local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
				local spotsFolder = plotFolder and plotFolder:FindFirstChild("PlantingSpots")
				local spot = spotsFolder and spotsFolder:FindFirstChild(spotName)
				
				if spot then
					-- Create crop visual at ground level
					local cropPosition = spot.Position + Vector3.new(0, 1, 0)
					local cropData = createCropVisual(cropType, cropPosition, plotNumber, spotName)
					
					if cropData then
						-- Remove 1 seed from inventory
						local seedType = cropType .. "_seeds"
						if removeSeedFromInventory(player, seedType) then
							-- Track planted crop
							if not plantedCrops[plotNumber] then
								plantedCrops[plotNumber] = {}
							end
							plantedCrops[plotNumber][spotName] = cropData
							
							notificationRemote:FireClient(player, "success", "🌱 Planted!", cropType:gsub("^%l", string.upper) .. " planted successfully!")
						else
							-- Failed to remove seed - destroy the crop visual
							if cropData.container then
								cropData.container:Destroy()
							end
							notificationRemote:FireClient(player, "error", "❌ No Seeds", "Failed to use seed!")
						end
					end
				end
			else
				notificationRemote:FireClient(player, "error", "❌ No Seeds", "Equip seeds first!")
			end
		end
	end)
end)

-- ProximityPrompt handles harvesting now - no need for E-key remote system

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	for plotNumber, userId in pairs(plotOwners) do
		if userId == player.UserId then
			if plantedCrops[plotNumber] then
				for spotName, cropData in pairs(plantedCrops[plotNumber]) do
					if cropData.container and cropData.container.Parent then
						cropData.container:Destroy()
					end
				end
				plantedCrops[plotNumber] = nil
			end
			break
		end
	end
end)