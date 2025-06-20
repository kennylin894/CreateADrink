-- SELL NPC ServerScript - Place inside your Sell NPC model
local npc = script.Parent
local humanoid = npc:FindFirstChild("Humanoid")
local head = npc:FindFirstChild("Head")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("Sell NPC ServerScript started!")

-- Wait for existing crop system
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")

-- Create RemoteEvent for sell system
local sellRemote = Instance.new("RemoteEvent")
sellRemote.Name = "SellRemote"
sellRemote.Parent = ReplicatedStorage

-- Create ClickDetector
local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = 10
clickDetector.Parent = head

print("Sell NPC ClickDetector created")

-- Crop sell prices (what you get for selling harvested crops)
local CROP_SELL_PRICES = {
	strawberry = 15,
	orange = 20,
	apple = 12,
	carrot = 8,
	blueberry = 25,
	mint = 30,
	watermelon = 35,
	lemon = 18,
	grape = 28,
	cucumber = 10
}

-- Function to count player's harvested crops (matches your crop system)
local function countPlayerCrops(player, cropType)
	if not player.Backpack then return 0 end

	-- Check backpack
	for _, tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local toolItemType = tool:GetAttribute("ItemType")
			if toolItemType == cropType then
				return tool:GetAttribute("ItemCount") or 0
			end
		end
	end

	-- Check if holding the tool
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolItemType = tool:GetAttribute("ItemType")
				if toolItemType == cropType then
					return tool:GetAttribute("ItemCount") or 0
				end
			end
		end
	end

	return 0
end

-- Function to remove crops from player inventory (matches your crop system)
local function removePlayerCrops(player, cropType, amount)
	if not player.Backpack then return false end

	-- Find the tool
	local targetTool = nil
	local currentCount = 0

	-- Check backpack first
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

	-- Check if holding the tool
	if not targetTool and player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local toolItemType = tool:GetAttribute("ItemType")
				if toolItemType == cropType then
					targetTool = tool
					currentCount = tool:GetAttribute("ItemCount") or 0
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

	-- If any crops left, we don't need to recreate the tool for selling
	-- The crop system will handle recreation if needed

	return true
end

-- Function to get player's inventory
local function getPlayerInventory(player)
	local inventory = {}

	if not player.Backpack then return inventory end

	-- Check backpack for harvested crops
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

	-- Check if holding any crops
	if player.Character then
		for _, tool in pairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				local itemType = tool:GetAttribute("ItemType")
				if itemType and CROP_SELL_PRICES[itemType] then
					local count = tool:GetAttribute("ItemCount") or 0
					if count > 0 then
						-- Check if we already found this item type in backpack
						local found = false
						for _, item in pairs(inventory) do
							if item.itemType == itemType then
								found = true
								break
							end
						end

						if not found then
							table.insert(inventory, {
								name = itemType:gsub("^%l", string.upper),
								itemType = itemType,
								count = count,
								sellPrice = CROP_SELL_PRICES[itemType],
								totalValue = count * CROP_SELL_PRICES[itemType]
							})
						end
					end
				end
			end
		end
	end

	return inventory
end

-- Handle selling items
local function handleSell(player, itemType, amount)
	print("Handling sell for", player.Name, "item:", itemType, "amount:", amount)

	-- Check if player has enough of this item
	local currentCount = countPlayerCrops(player, itemType)
	if currentCount < amount then
		notificationRemote:FireClient(player, "error", "❌ Not Enough Items", 
			"You only have " .. currentCount .. " " .. itemType .. "(s)!")
		return
	end

	-- Check if this item can be sold
	if not CROP_SELL_PRICES[itemType] then
		notificationRemote:FireClient(player, "error", "❌ Cannot Sell", 
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

				notificationRemote:FireClient(player, "success", "💰 Items Sold!", 
					"Sold " .. amount .. " " .. itemType .. "(s) for " .. totalPayment .. " sippies!")

				-- Send updated inventory to client
				local updatedInventory = getPlayerInventory(player)
				sellRemote:FireClient(player, "updateInventory", updatedInventory)
			else
				notificationRemote:FireClient(player, "error", "❌ Error", "Could not find sippies!")
			end
		else
			notificationRemote:FireClient(player, "error", "❌ Error", "Could not find leaderstats!")
		end
	else
		notificationRemote:FireClient(player, "error", "❌ Sell Failed", 
			"Could not remove items from inventory!")
	end
end

-- Handle NPC click
clickDetector.MouseClick:Connect(function(player)
	print("Sell NPC clicked by", player.Name)

	-- Get player's inventory
	local inventory = getPlayerInventory(player)

	-- Always open the sell shop, even if inventory is empty
	print("Sending inventory to client:", #inventory, "items")
	sellRemote:FireClient(player, "openSellShop", inventory)
end)

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