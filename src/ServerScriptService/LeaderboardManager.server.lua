-- -- LEADERBOARD SCRIPT - Script
-- local Players = game:GetService("Players")

-- -- Create leaderstats for new players
-- local function createLeaderstats(player)
-- 	local leaderstats = Instance.new("Folder")
-- 	leaderstats.Name = "leaderstats"
-- 	leaderstats.Parent = player

-- 	local sippies = Instance.new("IntValue")
-- 	sippies.Name = "Sippies"
-- 	sippies.Value = 0
-- 	sippies.Parent = leaderstats
-- end

-- -- Handle new players joining
-- Players.PlayerAdded:Connect(createLeaderstats)

-- -- Handle existing players (if script runs after players join)
-- for _, player in pairs(Players:GetPlayers()) do
-- 	if not player:FindFirstChild("leaderstats") then
-- 		createLeaderstats(player)
-- 	end
-- end

-- -- Test