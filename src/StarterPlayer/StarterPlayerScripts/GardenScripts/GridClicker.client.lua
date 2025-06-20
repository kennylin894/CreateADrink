-- GridClicker.client.lua
-- Put in StarterPlayerScripts > GardenScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

print("🖱️ Grid clicker client script starting...")

local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local gridClickRemote = plotEvents:WaitForChild("GridClick")

print("✅ Found GridClick remote!")

-- Handle mouse clicks
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target and target.Name:match("Spot_%d+_%d+") then
		local plotNumber = target:GetAttribute("PlotNumber")
		local spotName = target:GetAttribute("SpotName")
		
		if plotNumber and spotName then
			print("🖱️ Clicked on " .. spotName .. " for plot " .. plotNumber)
			gridClickRemote:FireServer(plotNumber, spotName)
		end
	end
end)

print("🖱️ Grid clicker ready!")