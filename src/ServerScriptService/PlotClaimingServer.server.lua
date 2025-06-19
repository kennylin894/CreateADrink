-- PLOT SYSTEM SCRIPT - Put in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local claimedPlots = {}
local playerPlots = {}
local playerCooldowns = {}
local PLOTS_COUNT = 6
local PLOT_NUMBERS = {1, 2, 3, 4, 5, 6}
local ERROR_COOLDOWN = 3

-- Create RemoteEvents
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "PlotEvents"
remoteEvents.Parent = ReplicatedStorage

local claimPlotRemote = Instance.new("RemoteEvent")
claimPlotRemote.Name = "ClaimPlot"
claimPlotRemote.Parent = remoteEvents

local notificationRemote = Instance.new("RemoteEvent")
notificationRemote.Name = "ShowNotification"
notificationRemote.Parent = remoteEvents

-- 🌿 NEW: Create BindableEvent for garden system communication
local plotClaimedBindable = Instance.new("BindableEvent")
plotClaimedBindable.Name = "PlotClaimed"
plotClaimedBindable.Parent = ReplicatedStorage

-- Update plot appearance
local function updatePlotAppearance(plotNumber, isOwned, ownerName)
	local claimPart = workspace:FindFirstChild("ClaimPart" .. plotNumber)
	if not claimPart then return end

	local gui = claimPart:FindFirstChild("ClaimGui")
	if not gui then return end

	local claimButton = gui:FindFirstChild("ClaimButton")
	local ownerLabel = gui:FindFirstChild("OwnerLabel")

	if isOwned then
		claimButton.Visible = false
		ownerLabel.Visible = true
		ownerLabel.Text = "🥤 " .. ownerName .. "'s Drink Stand 🥤"
		claimPart.Transparency = 1
	else
		claimButton.Visible = true
		ownerLabel.Visible = false
		claimPart.Transparency = 1
	end

	spawn(function()
		wait(0.1)
	end)
end

-- Handle plot claiming
local function claimPlot(player, plotNumber)
	print("=== CLAIM ATTEMPT ===")
	print("Player: " .. player.Name)
	print("Plot: " .. plotNumber)

	if plotNumber < 1 or plotNumber > PLOTS_COUNT then
		return false, "Invalid plot number"
	end

	-- If player already owns this exact plot, do nothing (no error)
	if playerPlots[player.UserId] == plotNumber then
		return "silent", "You already own this plot"
	end

	-- If player tries to claim a different plot, show error with cooldown
	if playerPlots[player.UserId] then
		-- Check cooldown
		local currentTime = tick()
		local lastErrorTime = playerCooldowns[player.UserId] or 0
		
		if currentTime - lastErrorTime < ERROR_COOLDOWN then
			return "silent", "Please wait before trying again"
		end
		
		-- Set new cooldown
		playerCooldowns[player.UserId] = currentTime
		return false, "You already own drink stand " .. playerPlots[player.UserId] .. "!"
	end

	if claimedPlots[plotNumber] then
		local owner = Players:GetPlayerByUserId(claimedPlots[plotNumber])
		local ownerName = owner and owner.Name or "Unknown"
		
		-- Check cooldown for this error too
		local currentTime = tick()
		local lastErrorTime = playerCooldowns[player.UserId] or 0
		
		if currentTime - lastErrorTime < ERROR_COOLDOWN then
			return "silent", "Please wait before trying again"
		end
		
		playerCooldowns[player.UserId] = currentTime
		return false, "Drink stand " .. plotNumber .. " is already owned by " .. ownerName
	end

	claimedPlots[plotNumber] = player.UserId
	playerPlots[player.UserId] = plotNumber
	updatePlotAppearance(plotNumber, true, player.Name)
	
	-- 🌿 NEW: Notify garden system about plot claim
	plotClaimedBindable:Fire(plotNumber, player.UserId, player.Name)

	return true, "Successfully claimed plot " .. plotNumber .. "!"
end

-- Handle plot clicks
local function onPlotClicked(player, plotNumber)
	local success, message = claimPlot(player, plotNumber)

	if success == true then
		print("🎉 " .. player.Name .. " successfully claimed plot " .. plotNumber .. "!")
		notificationRemote:FireClient(player, "success", "🥤 Successfully claimed Drink Stand " .. plotNumber .. "! 🥤", "You now own this stand and can start serving drinks!")
	elseif success == false then
		print("❌ Claim failed: " .. message)
		notificationRemote:FireClient(player, "error", "❌ Cannot Claim Stand", message)
	elseif success == "silent" then
		print("🔇 Silent action: " .. message)
		-- No notification sent
	end
end

-- Find existing plots in workspace
local function findExistingPlots()
	local plots = {}
	local playerPlotsFolder = workspace:FindFirstChild("PlayerPlots")
	if not playerPlotsFolder then
		warn("PlayerPlots folder not found in workspace!")
		return plots
	end

	for i = 1, 6 do
		local plotFolder = playerPlotsFolder:FindFirstChild("Plot" .. i)
		if plotFolder then
			local gardenPart = plotFolder:FindFirstChild("Plot" .. i .. "_Garden")
			local storePart = plotFolder:FindFirstChild("Plot" .. i .. "_Store") 
			local claimPart = plotFolder:FindFirstChild("Plot" .. i .. "_Claim")

			if gardenPart and storePart and claimPart then
				plots[i] = claimPart
				print("Found complete Plot " .. i)
			else
				warn("Plot " .. i .. " missing some parts:")
				if not gardenPart then warn("  Missing _Garden") end
				if not storePart then warn("  Missing _Store") end
				if not claimPart then warn("  Missing _Claim") end
			end
		else
			warn("Plot" .. i .. " folder not found")
		end
	end

	return plots
end

-- Setup plot claiming system
local function setupPlotClaiming(plot, plotNumber)
	local claimPart = Instance.new("Part")
	claimPart.Name = "ClaimPart" .. plotNumber
	claimPart.Anchored = true
	claimPart.CanCollide = false
	claimPart.Transparency = 1
	
	-- Handle different orientations for plots 1&2 vs 3-6
	if plotNumber == 1 or plotNumber == 2 then
		claimPart.Size = Vector3.new(plot.Size.Z, 10, plot.Size.X)
	else
		claimPart.Size = Vector3.new(plot.Size.X, 10, plot.Size.Z)
	end
	
	claimPart.Position = plot.Position + Vector3.new(0, 5, 0)
	claimPart.Parent = workspace

	-- Create ClickDetector with close range only
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 25
	clickDetector.Parent = claimPart

	-- Proximity detection for visibility
	local function checkPlayerDistance()
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local playerOwnsAnyPlot = (playerPlots[player.UserId] ~= nil)
				local plotIsClaimed = claimedPlots[plotNumber] ~= nil

				local gui = claimPart:FindFirstChild("ClaimGui")
				if gui then
					if playerOwnsAnyPlot and not plotIsClaimed then
						gui.Enabled = false
					else
						gui.Enabled = true
					end
				end
			end
		end
	end

	spawn(function()
		while claimPart.Parent do
			checkPlayerDistance()
			wait(0.1)
		end
	end)

	-- Handle clicks
	clickDetector.MouseClick:Connect(function(player)
		print("🖱️ CLICK DETECTED on Plot " .. plotNumber .. " by " .. player.Name)
		onPlotClicked(player, plotNumber)
	end)

	print("✅ Created ClickDetector for Plot " .. plotNumber)

	-- Create claim GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ClaimGui"
	billboardGui.Size = UDim2.new(6, 0, 3, 0)
	billboardGui.StudsOffset = Vector3.new(0, 8, 0)
	billboardGui.Parent = claimPart

	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(1, 0, 0.5, 0)
	claimButton.Position = UDim2.new(0, 0, 0.25, 0)
	claimButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	claimButton.Text = "🥤 CLAIM DRINK STAND " .. plotNumber .. " 🥤"
	claimButton.TextColor3 = Color3.new(1, 1, 1)
	claimButton.TextScaled = true
	claimButton.Font = Enum.Font.GothamBold
	claimButton.BorderSizePixel = 3
	claimButton.BorderColor3 = Color3.fromRGB(76, 175, 80)
	claimButton.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = claimButton

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(46, 125, 50))
	}
	gradient.Rotation = 90
	gradient.Parent = claimButton

	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.Size = UDim2.new(1, 0, 0.5, 0)
	ownerLabel.Position = UDim2.new(0, 0, 0.25, 0)
	ownerLabel.BackgroundColor3 = Color3.fromRGB(46, 125, 50)
	ownerLabel.Text = ""
	ownerLabel.TextColor3 = Color3.new(1, 1, 1)
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.GothamBold
	ownerLabel.Visible = false
	ownerLabel.Parent = billboardGui

	local ownerCorner = Instance.new("UICorner")
	ownerCorner.CornerRadius = UDim.new(0, 8)
	ownerCorner.Parent = ownerLabel

	local ownerGradient = Instance.new("UIGradient")
	ownerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(46, 125, 50))
	}
	ownerGradient.Rotation = 90
	ownerGradient.Parent = ownerLabel

	return claimPart, claimButton, ownerLabel
end

-- Event handlers
claimPlotRemote.OnServerEvent:Connect(function(player, plotNumber)
	print("📡 Remote event received from " .. player.Name .. " for plot " .. plotNumber)
	onPlotClicked(player, plotNumber)
end)

-- Free plot when player leaves
Players.PlayerRemoving:Connect(function(player)
	local plotNumber = playerPlots[player.UserId]
	if plotNumber then
		claimedPlots[plotNumber] = nil
		playerPlots[player.UserId] = nil
		-- 🌿 NEW: Also clear garden ownership (handled by garden script)
		updatePlotAppearance(plotNumber, false, "")
		print("Plot " .. plotNumber .. " is now available (player left)")
	end
end)

-- Initialize system
local function initializePlots()
	local existingPlots = findExistingPlots()

	for plotNumber = 1, 6 do
		local plot = existingPlots[plotNumber]
		if plot then
			local claimPart, claimButton, ownerLabel = setupPlotClaiming(plot, plotNumber)
			print("Setup claiming for Plot " .. plotNumber)
		else
			warn("Could not find Plot " .. plotNumber .. " in workspace!")
		end
	end
end

initializePlots()