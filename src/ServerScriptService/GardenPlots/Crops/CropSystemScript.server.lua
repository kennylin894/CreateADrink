-- UPDATED CROP SYSTEM SCRIPT - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for plot events to be created
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")

-- Create crop-specific remotes
local cropRemote = Instance.new("RemoteEvent")
cropRemote.Name = "CropSystem"
cropRemote.Parent = plotEvents

-- UPDATED: All crop definitions from your shop
local CROPS = {
	strawberry = {
		name = "Strawberry",
		seedName = "Strawberry Seeds",
		growthTime = 30,  -- 30 seconds
		harvestCount = 3,
		sellPrice = 15,
		seedCost = 25
	},
	orange = {
		name = "Orange",
		seedName = "Orange Seeds",
		growthTime = 45,  -- 45 seconds
		harvestCount = 2,
		sellPrice = 20,
		seedCost = 30
	},
	apple = {
		name = "Apple",
		seedName = "Apple Seeds",
		growthTime = 25,  -- 25 seconds
		harvestCount = 4,
		sellPrice = 12,
		seedCost = 20
	},
	carrot = {
		name = "Carrot",
		seedName = "Carrot Seeds",
		growthTime = 20,  -- 20 seconds
		harvestCount = 5,
		sellPrice = 8,
		seedCost = 15
	},
	blueberry = {
		name = "Blueberry",
		seedName = "Blueberry Seeds",
		growthTime = 40,  -- 40 seconds
		harvestCount = 6,
		sellPrice = 25,
		seedCost = 35
	},
	mint = {
		name = "Mint",
		seedName = "Mint Seeds",
		growthTime = 50,  -- 50 seconds
		harvestCount = 2,
		sellPrice = 30,
		seedCost = 40
	},
	watermelon = {
		name = "Watermelon",
		seedName = "Watermelon Seeds",
		growthTime = 60,  -- 60 seconds (longest)
		harvestCount = 1,
		sellPrice = 35,
		seedCost = 50
	},
	lemon = {
		name = "Lemon",
		seedName = "Lemon Seeds",
		growthTime = 35,  -- 35 seconds
		harvestCount = 3,
		sellPrice = 18,
		seedCost = 28
	},
	grape = {
		name = "Grape",
		seedName = "Grape Seeds",
		growthTime = 55,  -- 55 seconds
		harvestCount = 4,
		sellPrice = 28,
		seedCost = 45
	},
	cucumber = {
		name = "Cucumber",
		seedName = "Cucumber Seeds",
		growthTime = 25,  -- 25 seconds
		harvestCount = 6,
		sellPrice = 10,
		seedCost = 18
	}
}

-- Function to create seed tools with count (matches your existing system)
local function createSeedsTool(seedType, count)
	local tool = Instance.new("Tool")
	tool.Name = seedType:gsub("_", " "):gsub("(%a)(%a*)", function(a,b) return string.upper(a)..b end) .. " (" .. count .. ")"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	
	-- Store the count as an attribute
	tool:SetAttribute("SeedCount", count)
	tool:SetAttribute("SeedType", seedType)
	
	-- Create handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Material = Enum.Material.Neon
	handle.Shape = Enum.PartType.Ball
	handle.CanCollide = false
	handle.Parent = tool
	
	-- Color based on crop type
	if seedType == "strawberry_seeds" then
		handle.Color = Color3.fromRGB(34, 139, 34)  -- Green
	elseif seedType == "orange_seeds" then
		handle.Color = Color3.fromRGB(255, 140, 0)  -- Orange
	elseif seedType == "apple_seeds" then
		handle.Color = Color3.fromRGB(50, 205, 50)  -- Light green
	elseif seedType == "carrot_seeds" then
		handle.Color = Color3.fromRGB(255, 165, 0)  -- Orange
	elseif seedType == "blueberry_seeds" then
		handle.Color = Color3.fromRGB(70, 130, 180)  -- Steel blue
	elseif seedType == "mint_seeds" then
		handle.Color = Color3.fromRGB(152, 251, 152)  -- Pale green
	elseif seedType == "watermelon_seeds" then
		handle.Color = Color3.fromRGB(34, 139, 34)  -- Dark green
	elseif seedType == "lemon_seeds" then
		handle.Color = Color3.fromRGB(255, 255, 0)  -- Yellow
	elseif seedType == "grape_seeds" then
		handle.Color = Color3.fromRGB(128, 0, 128)  -- Purple
	elseif seedType == "cucumber_seeds" then
		handle.Color = Color3.fromRGB(144, 238, 144)  -- Light green
	else
		handle.Color = Color3.fromRGB(34, 139, 34)  -- Default green
	end
	
	-- Add a mesh for better appearance
	local specialMesh = Instance.new("SpecialMesh")
	specialMesh.MeshType = Enum.MeshType.Sphere
	specialMesh.Scale = Vector3.new(0.5, 0.5, 0.5)
	specialMesh.Parent = handle
	
	-- Add sparkles
	local sparkles = Instance.new("Sparkles")
	sparkles.Color = handle.Color
	sparkles.Parent = handle
	
	-- Add count display
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 50, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.Parent = handle
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 1, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = tostring(count)
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextStrokeTransparency = 0
	countLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	countLabel.Parent = billboard
	
	return tool
end

-- Function to create harvested crop tools (NEW: supports all crop types)
local function createCropTool(cropType, count)
	local tool = Instance.new("Tool")
	tool.Name = cropType:gsub("^%l", string.upper) .. " (" .. count .. ")"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	
	-- Store the count as an attribute
	tool:SetAttribute("ItemCount", count)
	tool:SetAttribute("ItemType", cropType)
	
	-- Create handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.6, 0.8)
	handle.Material = Enum.Material.Neon
	handle.Shape = Enum.PartType.Ball
	handle.CanCollide = false
	handle.Parent = tool
	
	-- Color based on crop type
	if cropType == "strawberry" then
		handle.Color = Color3.fromRGB(220, 20, 60)  -- Red
	elseif cropType == "orange" then
		handle.Color = Color3.fromRGB(255, 140, 0)  -- Orange
	elseif cropType == "apple" then
		handle.Color = Color3.fromRGB(255, 0, 0)  -- Red
	elseif cropType == "carrot" then
		handle.Color = Color3.fromRGB(255, 140, 0)  -- Orange
	elseif cropType == "blueberry" then
		handle.Color = Color3.fromRGB(70, 130, 180)  -- Blue
	elseif cropType == "mint" then
		handle.Color = Color3.fromRGB(152, 251, 152)  -- Light green
	elseif cropType == "watermelon" then
		handle.Color = Color3.fromRGB(255, 20, 147)  -- Pink
	elseif cropType == "lemon" then
		handle.Color = Color3.fromRGB(255, 255, 0)  -- Yellow
	elseif cropType == "grape" then
		handle.Color = Color3.fromRGB(128, 0, 128)  -- Purple
	elseif cropType == "cucumber" then
		handle.Color = Color3.fromRGB(50, 205, 50)  -- Green
	else
		handle.Color = Color3.fromRGB(220, 20, 60)  -- Default red
	end
	
	-- Add sparkles
	local sparkles = Instance.new("Sparkles")
	sparkles.Color = handle.Color
	sparkles.Parent = handle
	
	-- Add count display
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 50, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.Parent = handle
	
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 1, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = tostring(count)
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextStrokeTransparency = 0
	countLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	countLabel.Parent = billboard
	
	return tool
end

-- Function to give player tools with count
local function givePlayerTool(player, toolType, amount)
	if not player.Backpack then return end
	
	-- Check if player already has this type of tool
	local existingTool = nil
	local currentCount = 0
	
	-- Check backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
			if toolItemType == toolType then
				existingTool = tool
				currentCount = tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
				break
			end
		end
	end
	
	-- Check if holding the tool
	if not existingTool and player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
				if toolItemType == toolType then
					existingTool = tool
					currentCount = tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
					break
				end
			end
		end
	end
	
	local newCount = currentCount + amount
	
	if existingTool then
		-- Update existing tool
		existingTool:Destroy()
	end
	
	-- Create new tool with updated count
	local tool
	if string.find(toolType, "_seeds") then
		tool = createSeedsTool(toolType, newCount)
	else
		tool = createCropTool(toolType, newCount)
	end
	
	if tool then
		tool.Parent = player.Backpack
	end
	
	print("📦 Gave " .. player.Name .. " " .. amount .. " " .. toolType .. " (Total: " .. newCount .. ")")
end

-- Function to count tools with count system
local function countPlayerTools(player, toolType)
	if not player.Backpack then return 0 end
	
	-- Check backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
			if toolItemType == toolType then
				return tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
			end
		end
	end
	
	-- Check if holding the tool
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
				if toolItemType == toolType then
					return tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
				end
			end
		end
	end
	
	return 0
end

-- Function to remove tools with count system
local function removePlayerTool(player, toolType, amount)
	if not player.Backpack then return false end
	
	-- Find the tool
	local targetTool = nil
	local currentCount = 0
	
	-- Check backpack first
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
			if toolItemType == toolType then
				targetTool = tool
				currentCount = tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
				break
			end
		end
	end
	
	-- Check if holding the tool
	if not targetTool and player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolItemType = tool:GetAttribute("SeedType") or tool:GetAttribute("ItemType")
				if toolItemType == toolType then
					targetTool = tool
					currentCount = tool:GetAttribute("SeedCount") or tool:GetAttribute("ItemCount") or 0
					break
				end
			end
		end
	end
	
	if not targetTool or currentCount < amount then
		return false
	end
	
	local newCount = currentCount - amount
	local wasInCharacter = targetTool.Parent == player.Character
	
	-- Remove the old tool
	targetTool:Destroy()
	
	-- Create new tool with updated count if any left
	if newCount > 0 then
		local newTool
		if string.find(toolType, "_seeds") then
			newTool = createSeedsTool(toolType, newCount)
		else
			newTool = createCropTool(toolType, newCount)
		end
		
		if newTool then
			if wasInCharacter then
				newTool.Parent = player.Character
			else
				newTool.Parent = player.Backpack
			end
		end
	end
	
	return true
end

-- Give starter pack when plot is claimed
local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		print("🎁 Giving starter pack to " .. playerName .. " for plot " .. plotNumber)
		
		-- Send plot claimed notification first
		notificationRemote:FireClient(player, "success", "🏡 Plot " .. plotNumber .. " Claimed!", "You successfully claimed your drink stand!")
		
		-- Wait for the plot claimed notification to finish
		spawn(function()
			wait(3.5)  -- Wait for notification to completely disappear
			
			-- Give 1 seed in backpack after notification is gone
			givePlayerTool(player, "strawberry_seeds", 1)
			
			-- Send starter pack notification
			notificationRemote:FireClient(player, "success", "🎁 Starter Pack!", "You received 1 Strawberry Seed! Check your inventory at the bottom!")
			
			print("✅ Starter pack given successfully to " .. playerName)
		end)
	else
		print("❌ Could not find player " .. playerName .. " (ID: " .. userId .. ")")
	end
end)

-- Handle crop system requests
cropRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "check_inventory" then
		-- Check all crop types
		local message = "Your Inventory:\n"
		local hasItems = false
		
		-- Check seeds
		for cropType, cropData in pairs(CROPS) do
			local seedType = cropType .. "_seeds"
			local seedCount = countPlayerTools(player, seedType)
			if seedCount > 0 then
				message = message .. "🌱 " .. cropData.seedName .. ": " .. seedCount .. "\n"
				hasItems = true
			end
		end
		
		-- Check harvested crops
		for cropType, cropData in pairs(CROPS) do
			local cropCount = countPlayerTools(player, cropType)
			if cropCount > 0 then
				message = message .. "🍓 " .. cropData.name .. "s: " .. cropCount .. "\n"
				hasItems = true
			end
		end
		
		if not hasItems then
			message = "Your inventory is empty!\nBuy seeds from the shop or claim a plot to get starter seeds!"
		end
		
		notificationRemote:FireClient(player, "success", "📦 Inventory", message)
		
	elseif action == "plant" then
		local plotNumber, cropType, position = ...
		
		-- Check if player has seeds
		local seedType = cropType .. "_seeds"
		if countPlayerTools(player, seedType) == 0 then
			notificationRemote:FireClient(player, "error", "❌ No Seeds", "You need " .. CROPS[cropType].seedName .. " to plant!")
			return
		end
		
		-- Remove seed from backpack
		if removePlayerTool(player, seedType, 1) then
			local seedsLeft = countPlayerTools(player, seedType)
			notificationRemote:FireClient(player, "success", "🌱 Planted!", CROPS[cropType].name .. " planted! (" .. seedsLeft .. " seeds left)")
		else
			notificationRemote:FireClient(player, "error", "❌ Error", "Failed to use seed!")
		end
		
	elseif action == "harvest" then
		local plotNumber, plantId, cropType = ...
		
		-- Give harvest items to backpack
		local crop = CROPS[cropType]
		if crop then
			givePlayerTool(player, cropType, crop.harvestCount)
			local total = countPlayerTools(player, cropType)
			notificationRemote:FireClient(player, "success", "🍓 Harvested!", "+" .. crop.harvestCount .. " " .. crop.name .. "s! Total: " .. total)
		end
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	-- No need to clean up backpack items - Roblox handles this automatically
end)

print("🌾 Updated crop system initialized with all crop types!")