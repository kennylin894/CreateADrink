-- ServerScript inside NPC model
local npc = script.Parent
local humanoid = npc:FindFirstChild("Humanoid")
local head = npc:FindFirstChild("Head")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Crop Shop ServerScript started!")

-- Wait for existing crop system
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")

-- Check if RemoteEvent already exists, if not create it
local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
if not shopRemote then
	shopRemote = Instance.new("RemoteEvent")
	shopRemote.Name = "ShopRemote"
	shopRemote.Parent = ReplicatedStorage
	print("Created new ShopRemote")
else
	print("Found existing ShopRemote")
end

-- PROXIMITY PROMPT ONLY (NO CLICKDETECTOR)
if not head then
    warn("No head found on NPC! Looking for other parts...")
    -- Try to find any part to attach to
    for _, part in pairs(npc:GetChildren()) do
        if part:IsA("BasePart") then
            head = part
            print("Using", part.Name, "for ProximityPrompt")
            break
        end
    end
end

if head then
    print("=== SETTING UP PROXIMITY PROMPT FOR SHOP ===")
    
    -- DESTROY ANY EXISTING CLICKDETECTORS OR PROXIMITY PROMPTS
    for _, child in pairs(head:GetChildren()) do
        if child:IsA("ClickDetector") then
            print("DESTROYING SHOP CLICKDETECTOR!")
            child:Destroy()
        end
        if child:IsA("ProximityPrompt") then
            print("DESTROYING OLD SHOP PROXIMITY PROMPT!")
            child:Destroy()
        end
    end
    
    wait(0.1) -- Small delay
    
    -- Create ProximityPrompt
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.ActionText = "Open Shop"
    proximityPrompt.ObjectText = "Seed Shop"
    proximityPrompt.HoldDuration = 0
    proximityPrompt.MaxActivationDistance = 20
    proximityPrompt.RequiresLineOfSight = false
    proximityPrompt.Enabled = true
    proximityPrompt.Parent = head
    
    print("=== SHOP PROXIMITY PROMPT CREATED ===")
    
    -- Handle ProximityPrompt trigger
    proximityPrompt.Triggered:Connect(function(player)
        print("=== SHOP PROXIMITY PROMPT TRIGGERED BY", player.Name, "===")
        print("Sending shop data to client...")
        shopRemote:FireClient(player, "openShop", shopItems)
    end)
    
else
    warn("Could not find any part to attach ProximityPrompt to!")
    return
end

-- Crop shop items data - PROGRESSIVE PRICING SYSTEM
local shopItems = {
	{
		name = "Strawberry Seeds",
		price = 50,  -- Basic starter item
		description = "Sweet berries perfect for smoothies",
		id = "strawberry_seeds",
		toolType = "strawberry_seeds",
		count = 1
	},
	{
		name = "Carrot Seeds",
		price = 200,  -- Second tier
		description = "Healthy veggies for nutritious drinks",
		id = "carrot_seeds",
		toolType = "carrot_seeds",
		count = 1
	},
	{
		name = "Apple Seeds",
		price = 500,  -- Third tier
		description = "Classic fruit for cider and juice",
		id = "apple_seeds",
		toolType = "apple_seeds",
		count = 1
	},
	{
		name = "Orange Seeds",
		price = 1000,  -- Fourth tier
		description = "Citrus fruits for fresh juice",
		id = "orange_seeds",
		toolType = "orange_seeds",
		count = 1
	},
	{
		name = "Cucumber Seeds",
		price = 2000,  -- Fifth tier
		description = "Cool veggies for spa waters",
		id = "cucumber_seeds",
		toolType = "cucumber_seeds",
		count = 1
	},
	{
		name = "Lemon Seeds",
		price = 4000,  -- Sixth tier
		description = "Sour citrus for lemonades",
		id = "lemon_seeds",
		toolType = "lemon_seeds",
		count = 1
	},
	{
		name = "Blueberry Seeds",
		price = 8000,  -- Seventh tier
		description = "Antioxidant-rich berries for health drinks",
		id = "blueberry_seeds",
		toolType = "blueberry_seeds",
		count = 1
	},
	{
		name = "Mint Seeds",
		price = 15000,  -- Eighth tier
		description = "Fresh herbs for mojitos and teas",
		id = "mint_seeds",
		toolType = "mint_seeds",
		count = 1
	},
	{
		name = "Grape Seeds",
		price = 30000,  -- Ninth tier
		description = "Perfect for grape juice and wine",
		id = "grape_seeds",
		toolType = "grape_seeds",
		count = 1
	},
	{
		name = "Watermelon Seeds",
		price = 60000,  -- Top tier
		description = "Juicy melons for refreshing drinks",
		id = "watermelon_seeds",
		toolType = "watermelon_seeds",
		count = 1
	}
}

-- Function to create seed tools with count (similar to your crop system)
local function createSeedTool(seedType, count)
	local tool = Instance.new("Tool")
	tool.Name = seedType:gsub("_", " "):gsub("(%a)(%a*)", function(a,b) return string.upper(a)..b end) .. " (" .. count .. ")"
	tool.RequiresHandle = false
	tool.CanBeDropped = false

	-- Store the count as an attribute (matches your crop system)
	tool:SetAttribute("SeedCount", count)
	tool:SetAttribute("SeedType", seedType)

	-- Create handle (the part you see in your hand)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Material = Enum.Material.Neon
	handle.Shape = Enum.PartType.Ball
	handle.CanCollide = false
	handle.Parent = tool

	-- Color the seeds based on type (similar to your strawberry system)
	if string.find(seedType, "strawberry") then
		handle.Color = Color3.fromRGB(34, 139, 34)  -- Green like your strawberry seeds
	elseif string.find(seedType, "orange") then
		handle.Color = Color3.fromRGB(255, 140, 0)
	elseif string.find(seedType, "apple") then
		handle.Color = Color3.fromRGB(50, 205, 50)
	elseif string.find(seedType, "carrot") then
		handle.Color = Color3.fromRGB(255, 165, 0)
	elseif string.find(seedType, "blueberry") then
		handle.Color = Color3.fromRGB(70, 130, 180)
	elseif string.find(seedType, "mint") then
		handle.Color = Color3.fromRGB(152, 251, 152)
	elseif string.find(seedType, "watermelon") then
		handle.Color = Color3.fromRGB(34, 139, 34)
	elseif string.find(seedType, "lemon") then
		handle.Color = Color3.fromRGB(255, 255, 0)
	elseif string.find(seedType, "grape") then
		handle.Color = Color3.fromRGB(128, 0, 128)
	elseif string.find(seedType, "cucumber") then
		handle.Color = Color3.fromRGB(144, 238, 144)
	else
		handle.Color = Color3.fromRGB(34, 139, 34)
	end

	-- Add a mesh for better appearance
	local specialMesh = Instance.new("SpecialMesh")
	specialMesh.MeshType = Enum.MeshType.Sphere
	specialMesh.Scale = Vector3.new(0.5, 0.5, 0.5)
	specialMesh.Parent = handle

	-- Add sparkles (like your crop system)
	local sparkles = Instance.new("Sparkles")
	sparkles.Color = handle.Color
	sparkles.Parent = handle

	-- Add count display (matches your crop system exactly)
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

-- Function to give player tools with count (matches your crop system exactly)
local function givePlayerTool(player, toolType, amount)
	if not player.Backpack then return end

	-- Check if player already has this type of tool
	local existingTool = nil
	local currentCount = 0

	-- Check backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolSeedType = tool:GetAttribute("SeedType")
			if toolSeedType == toolType then
				existingTool = tool
				currentCount = tool:GetAttribute("SeedCount") or 0
				break
			end
		end
	end

	-- Check if holding the tool
	if not existingTool and player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolSeedType = tool:GetAttribute("SeedType")
				if toolSeedType == toolType then
					existingTool = tool
					currentCount = tool:GetAttribute("SeedCount") or 0
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
	local tool = createSeedTool(toolType, newCount)
	if tool then
		tool.Parent = player.Backpack
	end

	print("📦 Gave " .. player.Name .. " " .. amount .. " " .. toolType .. " (Total: " .. newCount .. ")")
end

-- DEBOUNCE TABLE TO PREVENT DOUBLE PURCHASING
local purchaseDebounce = {}

-- Handle purchase - FIXED: Added debounce to prevent double buying
local function handlePurchase(player, item)
	print("Handling purchase for", player.Name, "item:", item.name)

	-- DEBOUNCE CHECK - Prevent double buying
	local playerId = player.UserId
	local itemKey = playerId .. "_" .. item.id
	
	if purchaseDebounce[itemKey] then
		print("Purchase blocked - too fast!")
		return
	end
	
	-- Set debounce for 1 second
	purchaseDebounce[itemKey] = true
	spawn(function()
		wait(1)
		purchaseDebounce[itemKey] = nil
	end)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		print("No leaderstats found for", player.Name)
		notificationRemote:FireClient(player, "error", "❌ No Currency System", "Currency system not found!")
		return 
	end

	local sippies = leaderstats:FindFirstChild("Sippies")
	if not sippies then 
		print("No sippies found in leaderstats for", player.Name)
		notificationRemote:FireClient(player, "error", "❌ No Sippies", "Sippies not found!")
		return 
	end

	print(player.Name, "has", sippies.Value, "sippies, item costs", item.price)

	if sippies.Value >= item.price then
		sippies.Value = sippies.Value - item.price
		print("Purchase successful!")

		-- Give seeds using the crop system approach
		givePlayerTool(player, item.toolType, item.count)

		-- Use ONLY your notification system
		notificationRemote:FireClient(player, "success", "🌱 Seeds Purchased!", 
			"You bought " .. item.count .. " " .. item.name .. "! Check your inventory!")

	else
		print("Not enough sippies!")
		-- Use ONLY your notification system
		notificationRemote:FireClient(player, "error", "❌ Not Enough Sippies", 
			"You need " .. item.price .. " sippies but only have " .. sippies.Value .. "!")
	end
end

-- Handle server events - FIXED: Added extra safety
shopRemote.OnServerEvent:Connect(function(player, action, data)
	print("Server received event:", action, "from", player.Name)
	if action == "buyItem" and data then
		handlePurchase(player, data)
	end
end)

print("Crop Shop ServerScript ready with ProximityPrompt and no double buying!")