-- SELL NPC ServerScript - Place inside your Sell NPC model
local npc = script.Parent
local humanoid = npc:FindFirstChild("Humanoid")
local head = npc:FindFirstChild("Head")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Sell NPC ServerScript started!")

-- Create leaderstats for players when they join
local function onPlayerAdded(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local sippies = Instance.new("IntValue")
    sippies.Name = "Sippies"
    sippies.Value = 0
    sippies.Parent = leaderstats
    
    print("Created leaderstats for", player.Name)
end

-- Connect to existing players and new players
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in pairs(Players:GetPlayers()) do
    if not player:FindFirstChild("leaderstats") then
        onPlayerAdded(player)
    end
end

-- Wait for existing crop system (with error handling)
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents", 10)
local notificationRemote
if plotEvents then
    notificationRemote = plotEvents:WaitForChild("ShowNotification", 10)
    if not notificationRemote then
        warn("Could not find ShowNotification RemoteEvent!")
    end
else
    warn("Could not find PlotEvents folder!")
end

-- Create RemoteEvent for sell system
local sellRemote = ReplicatedStorage:FindFirstChild("SellRemote")
if not sellRemote then
    sellRemote = Instance.new("RemoteEvent")
    sellRemote.Name = "SellRemote"
    sellRemote.Parent = ReplicatedStorage
    print("Created SellRemote")
else
    print("Found existing SellRemote")
end

-- Create ClickDetector (make sure head exists)
if not head then
    warn("No head found on NPC! Looking for other parts...")
    -- Try to find any part to attach the ClickDetector to
    for _, part in pairs(npc:GetChildren()) do
        if part:IsA("BasePart") then
            head = part
            print("Using", part.Name, "for ClickDetector")
            break
        end
    end
end

if head then
    local clickDetector = head:FindFirstChild("ClickDetector")
    if not clickDetector then
        clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 10
        clickDetector.Parent = head
        print("Created ClickDetector on", head.Name)
    end
else
    warn("Could not find any part to attach ClickDetector to!")
    return
end

-- Crop sell prices (PROGRESSIVE PRICING - what you get for selling harvested crops)
local CROP_SELL_PRICES = {
	strawberry = 25,    -- Basic: 50% of seed cost (50 → 25)
	carrot = 100,       -- Tier 2: 50% of seed cost (200 → 100)
	apple = 250,        -- Tier 3: 50% of seed cost (500 → 250)
	orange = 500,       -- Tier 4: 50% of seed cost (1000 → 500)
	cucumber = 1000,    -- Tier 5: 50% of seed cost (2000 → 1000)
	lemon = 2000,       -- Tier 6: 50% of seed cost (4000 → 2000)
	blueberry = 4000,   -- Tier 7: 50% of seed cost (8000 → 4000)
	mint = 7500,        -- Tier 8: 50% of seed cost (15000 → 7500)
	grape = 15000,      -- Tier 9: 50% of seed cost (30000 → 15000)
	watermelon = 30000  -- Tier 10: 50% of seed cost (60000 → 30000)
}

-- Function to send notification (with fallback)
local function sendNotification(player, notificationType, title, message)
    if notificationRemote then
        notificationRemote:FireClient(player, notificationType, title, message)
    else
        -- Fallback: print to console if notification system isn't available
        print("Notification for", player.Name, ":", title, "-", message)
    end
end

-- Function to count player's harvested crops (FIXED VERSION)
local function countPlayerCrops(player, cropType)
	if not player.Backpack then return 0 end

	-- Only check backpack for crops (ignore equipped tools)
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("ItemType")
			if toolItemType == cropType then
				return tool:GetAttribute("ItemCount") or 0
			end
		end
	end

	-- REMOVED character checking - crops should stay in backpack
	return 0
end

-- Function to remove crops from player inventory (FIXED VERSION)
local function removePlayerCrops(player, cropType, amount)
	if not player.Backpack then return false end

	-- Find the tool in backpack only
	local targetTool = nil
	local currentCount = 0

	-- Only check backpack for crops
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("ItemType")
			if toolItemType == cropType then
				targetTool = tool
				currentCount = tool:GetAttribute("ItemCount") or 0
				break
			end
		end
	end

	-- REMOVED character checking - crops should stay in backpack

	if not targetTool or currentCount < amount then
		return false
	end

	local newCount = currentCount - amount

	-- Remove the old tool
	targetTool:Destroy()

	return true
end

-- Function to get player's inventory (FIXED VERSION)
local function getPlayerInventory(player)
	local inventory = {}

	if not player.Backpack then return inventory end

	-- Only check backpack for harvested crops (ignore equipped tools)
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local itemType = tool:GetAttribute("ItemType")
			if itemType and CROP_SELL_PRICES[itemType] then
				local count = tool:GetAttribute("ItemCount") or 0
				if count > 0 then
					table.insert(inventory, {
						name = itemType:gsub("^%l", string.upper), -- Capitalize first letter
						itemType = itemType,
						count = count,
						sellPrice = CROP_SELL_PRICES[itemType],
						totalValue = count * CROP_SELL_PRICES[itemType]
					})
				end
			end
		end
	end

	-- REMOVED the character checking part that was causing the issue
	-- The crops should stay in backpack, so we don't need to check character

	return inventory
end

-- Handle selling items
local function handleSell(player, itemType, amount)
	print("Handling sell for", player.Name, "item:", itemType, "amount:", amount)

	-- Check if player has enough of this item
	local currentCount = countPlayerCrops(player, itemType)
	if currentCount < amount then
		sendNotification(player, "error", "❌ Not Enough Items", 
			"You only have " .. currentCount .. " " .. itemType .. "(s)!")
		return
	end

	-- Check if this item can be sold
	if not CROP_SELL_PRICES[itemType] then
		sendNotification(player, "error", "❌ Cannot Sell", 
			"This item cannot be sold!")
		return
	end

	-- Calculate payment
	local pricePerItem = CROP_SELL_PRICES[itemType]
	local totalPayment = pricePerItem * amount

	-- Remove items from inventory
	if removePlayerCrops(player, itemType, amount) then
		-- Add sippies to player
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local sippies = leaderstats:FindFirstChild("Sippies")
			if sippies then
				sippies.Value = sippies.Value + totalPayment

				sendNotification(player, "success", "💰 Items Sold!", 
					"Sold " .. amount .. " " .. itemType .. "(s) for " .. totalPayment .. " sippies!")

				-- Send updated inventory to client
				local updatedInventory = getPlayerInventory(player)
				sellRemote:FireClient(player, "updateInventory", updatedInventory)
			else
				sendNotification(player, "error", "❌ Error", "Could not find sippies!")
			end
		else
			sendNotification(player, "error", "❌ Error", "Could not find leaderstats!")
		end
	else
		sendNotification(player, "error", "❌ Sell Failed", 
			"Could not remove items from inventory!")
	end
end

-- Handle NPC click
local clickDetector = head:FindFirstChild("ClickDetector")
if clickDetector then
    clickDetector.MouseClick:Connect(function(player)
        print("Sell NPC clicked by", player.Name)

        -- Get player's inventory
        local inventory = getPlayerInventory(player)

        -- Always open the sell shop, even if inventory is empty
        print("Sending inventory to client:", #inventory, "items")
        
        -- Use pcall to catch any errors when firing to client
        local success, error = pcall(function()
            sellRemote:FireClient(player, "openSellShop", inventory)
        end)
        
        if not success then
            warn("Error firing to client:", error)
        end
    end)
    print("ClickDetector connected successfully!")
else
    warn("Could not find ClickDetector!")
end

-- Handle sell requests
sellRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "sellItem" then
		local itemType, amount = ...
		handleSell(player, itemType, amount)
	elseif action == "sellAll" then
		local itemType = ...
		local currentCount = countPlayerCrops(player, itemType)
		if currentCount > 0 then
			handleSell(player, itemType, currentCount)
		end
	end
end)

print("Sell NPC system ready!")