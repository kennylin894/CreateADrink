-- MINIMAL GARDEN SCRIPT - Server Side Only
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")
local cropRemote = plotEvents:WaitForChild("CropSystem")

-- Create remote for grid visibility
local gridRemote = Instance.new("RemoteEvent")
gridRemote.Name = "GridVisibility"
gridRemote.Parent = plotEvents

local plotOwners = {}
local gardenGrids = {}

-- Create grid when plot claimed
local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
	plotOwners[plotNumber] = userId
	
	-- Find garden part
	local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
	if not plotFolder then return end
	
	local gardenPart = plotFolder:FindFirstChild("Plot" .. plotNumber .. "_Garden")
	if not gardenPart then return end
	
	-- Delete any existing grids
	local existing = plotFolder:FindFirstChild("PlantingSpots")
	if existing then existing:Destroy() end
	
	-- Create simple grid with correct orientation
	local spotsFolder = Instance.new("Folder")
	spotsFolder.Name = "PlantingSpots"
	spotsFolder.Parent = plotFolder
	
	-- Set grid dimensions based on plot orientation
	local spotsX, spotsZ
	if plotNumber == 1 or plotNumber == 2 then
		-- Plots 1&2: Vertical orientation (10 wide x 20 deep)
		spotsX = 10
		spotsZ = 20
	else
		-- Plots 3-6: Horizontal orientation (20 wide x 10 deep)  
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
			spot.Transparency = 1  -- Always invisible on server
			
			local offsetX = (x - spotsX/2 - 0.5) * 5
			local offsetZ = (z - spotsZ/2 - 0.5) * 5
			spot.Position = gardenPart.Position + Vector3.new(offsetX, 0.5, offsetZ)
			spot.Parent = spotsFolder
			
			-- Click to plant
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 20
			click.Parent = spot
			
			click.MouseClick:Connect(function(player)
				if plotOwners[plotNumber] == player.UserId then
					-- Check for seeds
					local hasSeed = false
					if player.Character then
						for _, tool in pairs(player.Character:GetChildren()) do
							if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
								hasSeed = true
								break
							end
						end
					end
					
					if hasSeed then
						cropRemote:FireServer("plant", plotNumber, "strawberry", spot.Position + Vector3.new(0, 2, 0))
						-- Hide spot for everyone after planting
						spot.Transparency = 1
					else
						notificationRemote:FireClient(player, "error", "No Seeds", "Equip seeds first!")
					end
				end
			end)
		end
	end
	
	gardenGrids[plotNumber] = spotsFolder
	
	-- Tell the owner about their new grid
	local player = Players:GetPlayerByUserId(userId)
	if player then
		gridRemote:FireClient(player, "grid_created", plotNumber)
	end
end)

-- Handle tool equip/unequip events
local function onToolChange(player)
	-- Check what plot this player owns
	for plotNumber, userId in pairs(plotOwners) do
		if userId == player.UserId then
			-- Check if they have seeds equipped
			local hasSeed = false
			if player.Character then
				for _, tool in pairs(player.Character:GetChildren()) do
					if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
						hasSeed = true
						break
					end
				end
			end
			
			-- Tell client to show/hide their grid
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
		
		-- Also check when character spawns
		wait(1)
		onToolChange(player)
	end)
end)

-- For existing players
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		spawn(function()
			wait(1)
			onToolChange(player)
		end)
	end
end