-- GRID CLIENT SCRIPT - Put in StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local gridRemote = plotEvents:WaitForChild("GridVisibility")

local myGrids = {}  -- Store references to my grids

-- Handle grid visibility commands from server
gridRemote.OnClientEvent:Connect(function(action, plotNumber, showGrid)
	print("🎯 Client received:", action, plotNumber, showGrid)
	
	if action == "grid_created" then
		-- Store reference to my grid
		local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
		if plotFolder then
			local spotsFolder = plotFolder:FindFirstChild("PlantingSpots")
			if spotsFolder then
				myGrids[plotNumber] = spotsFolder
				print("✅ Grid stored for plot", plotNumber)
			else
				print("❌ No PlantingSpots folder found")
			end
		else
			print("❌ No plot folder found")
		end
		
	elseif action == "update_grid" then
		-- Show/hide my grid
		local grid = myGrids[plotNumber]
		if grid then
			local spotsUpdated = 0
			for _, spot in pairs(grid:GetChildren()) do
				if spot:IsA("Part") then
					spot.Transparency = showGrid and 0.7 or 1
					spotsUpdated = spotsUpdated + 1
				end
			end
			print("🔄 Updated", spotsUpdated, "spots for plot", plotNumber, "visible:", showGrid)
		else
			print("❌ No grid found for plot", plotNumber)
		end
	end
end)

print("📱 Grid client script loaded!")