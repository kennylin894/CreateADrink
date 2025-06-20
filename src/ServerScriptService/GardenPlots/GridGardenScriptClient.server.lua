-- UPDATED GARDEN SCRIPT WITH GRID - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for systems
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")
local cropRemote = plotEvents:WaitForChild("CropSystem")

-- Create remote for grid visibility IMMEDIATELY when script starts
local gridRemote = Instance.new("RemoteEvent")
gridRemote.Name = "GridVisibility"
gridRemote.Parent = plotEvents

print("✅ Created GridVisibility remote")

local plotOwners = {}
local gardenGrids = {}
local plantedCrops = {}

-- Create grid when plot claimed
local plotClaimedBindable = ReplicatedStorage:WaitForChild("PlotClaimed")
plotClaimedBindable.Event:Connect(function(plotNumber, userId, playerName)
	plotOwners[plotNumber] = userId
	
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
	
	-- Grid dimensions based on garden size and plot orientation
	local spotsX, spotsZ
	if plotNumber == 1 or plotNumber == 2 then
		-- Plots 1&2: Vertical orientation (50 wide x 100 deep)
		spotsX = 10  -- 10 spots across 50 studs (5 studs per spot)
		spotsZ = 20  -- 20 spots across 100 studs (5 studs per spot)
	else
		-- Plots 3-6: Horizontal orientation (100 wide x 50 deep)
		spotsX = 20  -- 20 spots across 100 studs (5 studs per spot)
		spotsZ = 10  -- 10 spots across 50 studs (5 studs per spot)
	end
	
	for x = 1, spotsX do
		for z = 1, spotsZ do
			local spot = Instance.new("Part")
			spot.Name = "Spot_" .. x .. "_" .. z
			spot.Size = Vector3.new(4.5, 0.1, 4.5)  -- Slightly smaller than 5x5 for visual gaps
			spot.Material = Enum.Material.Grass
			spot.Color = Color3.fromRGB(85, 170, 85)
			spot.Anchored = true
			spot.CanCollide = false
			spot.Transparency = 1
			
			-- Calculate position to properly fill the garden space
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
						-- Try to plant using crop system
						cropRemote:FireServer("plant", plotNumber, cropType, spot.Position + Vector3.new(0, 2, 0))
					else
						notificationRemote:FireClient(player, "error", "❌ No Seeds", "Equip seeds first!")
					end
				end
			end)
		end
	end
	
	gardenGrids[plotNumber] = spotsFolder
	
	-- Tell client about grid and show it immediately
	local player = Players:GetPlayerByUserId(userId)
	if player then
		gridRemote:FireClient(player, "grid_created", plotNumber)
		-- Show grid immediately when plot is claimed (with low transparency)
		gridRemote:FireClient(player, "update_grid", plotNumber, false) -- Start hidden
	end
	
	print("✅ Created " .. spotsX .. "x" .. spotsZ .. " grid for Plot " .. plotNumber)
end)

-- Handle tool equip/unequip events
local function onToolChange(player)
	print("🔧 Tool change detected for " .. player.Name)
	
	-- Check what plot this player owns
	for plotNumber, userId in pairs(plotOwners) do
		if userId == player.UserId then
			print("🏡 Player owns plot " .. plotNumber)
			
			-- Check if they have seeds equipped
			local hasSeed = false
			local seedType = "none"
			if player.Character then
				for _, tool in pairs(player.Character:GetChildren()) do
					if tool:IsA("Tool") and tool:GetAttribute("SeedType") then
						hasSeed = true
						seedType = tool:GetAttribute("SeedType")
						print("🌱 Found equipped seeds: " .. seedType)
						break
					end
				end
			end
			
			if not hasSeed then
				print("❌ No seeds equipped")
			end
			
			-- Tell client to show/hide their grid
			print("📡 Sending grid update: plot=" .. plotNumber .. ", show=" .. tostring(hasSeed))
			gridRemote:FireClient(player, "update_grid", plotNumber, hasSeed)
			break
		end
	end
end

-- Monitor tool changes
Players.PlayerAdded:Connect(function(player)
	print("👤 Player added: " .. player.Name)
	
	player.CharacterAdded:Connect(function(character)
		print("🧍 Character added for " .. player.Name)
		
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				print("🔧 Tool equipped: " .. child.Name)
				wait(0.1)
				onToolChange(player)
			end
		end)
		
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				print("🔧 Tool unequipped: " .. child.Name)
				wait(0.1)
				onToolChange(player)
			end
		end)
		
		-- Also check when character spawns
		wait(1)
		print("🔄 Initial tool check for " .. player.Name)
		onToolChange(player)
	end)
end)

-- For existing players
for _, player in pairs(Players:GetPlayers()) do
	print("🔄 Setting up existing player: " .. player.Name)
	if player.Character then
		spawn(function()
			wait(1)
			onToolChange(player)
		end)
	end
end

print("🌱 Garden system with grid ready!")