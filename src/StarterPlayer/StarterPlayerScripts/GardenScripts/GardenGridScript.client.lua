-- GRID CLIENT SCRIPT - Put in StarterPlayerScripts as a LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("📱 Grid client script starting...")

local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
print("📁 Found PlotEvents folder")

-- Wait for the GridVisibility remote to be created by the garden script
local gridRemote = plotEvents:WaitForChild("GridVisibility", 5)
if not gridRemote then
    warn("❌ Could not find GridVisibility remote!")
    warn("🔍 Available remotes in PlotEvents:")
    for _, child in pairs(plotEvents:GetChildren()) do
        if child:IsA("RemoteEvent") then
            warn("  - " .. child.Name)
        end
    end
    return
end

print("✅ Found GridVisibility remote!")

local myGrids = {}  -- Store references to my grids

-- Handle grid visibility commands from server
gridRemote.OnClientEvent:Connect(function(action, plotNumber, showGrid)
    print("🎯 Client received:", action, "plot:", plotNumber, "show:", showGrid)
    
    if action == "grid_created" then
        -- Store reference to my grid
        local plotFolder = workspace.PlayerPlots:FindFirstChild("Plot" .. plotNumber)
        if plotFolder then
            local spotsFolder = plotFolder:FindFirstChild("PlantingSpots")
            if spotsFolder then
                myGrids[plotNumber] = spotsFolder
                print("✅ Grid stored for plot", plotNumber, "with", #spotsFolder:GetChildren(), "spots")
            else
                print("❌ No PlantingSpots folder found in", plotFolder.Name)
            end
        else
            print("❌ No plot folder found for Plot" .. plotNumber)
        end
        
    elseif action == "update_grid" then
        -- Show/hide my grid
        local grid = myGrids[plotNumber]
        if grid then
            local spotsUpdated = 0
            for _, spot in pairs(grid:GetChildren()) do
                if spot:IsA("Part") then
                    local newTransparency = showGrid and 0.7 or 1
                    spot.Transparency = newTransparency
                    spotsUpdated = spotsUpdated + 1
                end
            end
            print("🔄 Updated", spotsUpdated, "spots for plot", plotNumber, "transparency:", showGrid and 0.7 or 1)
        else
            print("❌ No grid found for plot", plotNumber, "in myGrids table")
        end
    end
end)

print("📱 Grid client script loaded and ready!")