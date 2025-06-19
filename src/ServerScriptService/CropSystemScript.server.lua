-- CROP SYSTEM SCRIPT - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for plot events to be created
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")

-- Create crop-specific remotes
local cropRemote = Instance.new("RemoteEvent")
cropRemote.Name = "CropSystem"
cropRemote.Parent = plotEvents

-- Crop definitions
local CROPS = {
	strawberry = {
		name = "Strawberry",
		seedName = "Strawberry Seeds",
		growthTime = 10,  -- 10 seconds
		harvestCount = 3,
		sellPrice = 10,
		seedCost = 5
	}
}

-- Function to create strawberry seeds tool with count
local function createStrawberrySeedsTool(count)
	local tool = Instance.new("Tool")
	tool.Name = "Strawberry Seeds (" .. count .. ")"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	
	-- Store the count as an attribute
	tool:SetAttribute("SeedCount", count)
	tool:SetAttribute("SeedType", "strawberry_seeds")
	
	-- Create handle (the part you see in your hand)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(34, 139, 34)  -- Green
	handle.Shape = Enum.PartType.Ball
	handle.CanCollide = false
	handle.Parent = tool
	
	-- Add a mesh for better appearance
	local specialMesh = Instance.new("SpecialMesh")
	specialMesh.MeshType = Enum.MeshType.Sphere
	specialMesh.Scale = Vector3.new(0.5, 0.5, 0.5)
	specialMesh.Parent = handle
	
	-- Add sparkles
	local sparkles = Instance.new("Sparkles")
	sparkles.Color = Color3.fromRGB(0, 255, 0)
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

-- Function to create strawberry tool with count
local function createStrawberryTool(count)
	local tool = Instance.new("Tool")
	tool.Name = "Strawberry (" .. count .. ")"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	
	-- Store the count as an attribute
	tool:SetAttribute("ItemCount", count)
	tool:SetAttribute("ItemType", "strawberry")
	
	-- Create handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 0.6, 0.8)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(220, 20, 60)  -- Red
	handle.Shape = Enum.PartType.Ball
	handle.CanCollide = false
	handle.Parent = tool
	
	-- Add sparkles
	local sparkles = Instance.new("Sparkles")
	sparkles.Color = Color3.fromRGB(255, 0, 0)
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
	if toolType == "strawberry_seeds" then
		tool = createStrawberrySeedsTool(newCount)
	elseif toolType == "strawberry" then
		tool = createStrawberryTool(newCount)
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
		if toolType == "strawberry_seeds" then
			newTool = createStrawberrySeedsTool(newCount)
		elseif toolType == "strawberry" then
			newTool = createStrawberryTool(newCount)
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
		local seedCount = countPlayerTools(player, "strawberry_seeds")
		local strawberryCount = countPlayerTools(player, "strawberry")
		
		local message = "Your Inventory:\n"
		if seedCount > 0 then
			message = message .. "🌱 Strawberry Seeds: " .. seedCount .. "\n"
		end
		if strawberryCount > 0 then
			message = message .. "🍓 Strawberries: " .. strawberryCount .. "\n"
		end
		
		if seedCount == 0 and strawberryCount == 0 then
			message = "Your inventory is empty!\nClaim a plot to get starter seeds!"
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

print("🌾 Crop system initialized!")