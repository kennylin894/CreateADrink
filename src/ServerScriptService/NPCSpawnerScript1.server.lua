local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local NPCModelsFolder = ReplicatedStorage:WaitForChild("NPCModels")
local NPCPathFolder = Workspace:WaitForChild("NPCPath")
local waypoints = {}

-- Logging setup
print("Starting NPCSpawnerScript...")

-- Sort and validate waypoints
for _, child in ipairs(NPCPathFolder:GetChildren()) do
	if child:IsA("BasePart") then
		table.insert(waypoints, child)
	end
end

table.sort(waypoints, function(a, b)
	local aNum = tonumber(string.match(a.Name, "%d+")) or 0
	local bNum = tonumber(string.match(b.Name, "%d+")) or 0
	return aNum < bNum
end)


if #waypoints < 2 then
	warn("Not enough waypoints! Need at least 2.")
	return
end

print("Loaded", #waypoints, "waypoints.")

-- Walk animation
local WALK_ANIMATION_ID = "rbxassetid://507777826" -- Default R15 walk animation

-- Play animation
local function playWalkAnimation(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = WALK_ANIMATION_ID
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Movement
	track:Play()

	return track
end

-- Move using MoveTo
local function moveToWaypoint(npc, target)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:MoveTo(target.Position)
	local done = false

	local conn
	conn = humanoid.MoveToFinished:Connect(function()
		done = true
		conn:Disconnect()
	end)

	local t = 0
	while not done and t < 10 do
		task.wait(0.1)
		t += 0.1
	end
end

-- Fade out + cleanup
local function playDisappearAnimation(npc)
	for _, part in ipairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			local tween = TweenService:Create(part, TweenInfo.new(1), {Transparency = 1})
			tween:Play()
		end
	end
	task.wait(1.2)
	npc:Destroy()
end

-- Generate mirrored path like 1-2-3-2-1
local function generateRandomPath()
	local count = #waypoints
	local maxIndex = math.random(2, count)
	local path = {}

	for i = 1, maxIndex do
		table.insert(path, waypoints[i])
	end
	for i = maxIndex - 1, 1, -1 do
		table.insert(path, waypoints[i])
	end

	return path
end

-- Main function to spawn and walk NPC
local function spawnNPC()
	print("Attempting to spawn NPC...")

	local models = NPCModelsFolder:GetChildren()
	if #models == 0 then
		warn("No NPC models found in ReplicatedStorage.NPCModels")
		return
	end

	local npcTemplate = models[math.random(1, #models)]:Clone()
	if not npcTemplate:FindFirstChild("HumanoidRootPart") then
		warn("NPC model missing HumanoidRootPart")
		return
	end

	npcTemplate.Parent = Workspace
	npcTemplate:SetPrimaryPartCFrame(waypoints[1].CFrame)

	task.wait(0.5)

	local path = generateRandomPath()
	local walkTrack = playWalkAnimation(npcTemplate)

	for _, wp in ipairs(path) do
		moveToWaypoint(npcTemplate, wp)
	end

	if walkTrack then walkTrack:Stop() end
	playDisappearAnimation(npcTemplate)

	print("NPC completed path and despawned.")
end

-- Controlled loop (spawns multiple concurrently)
local SPAWN_INTERVAL = 5
local MAX_ACTIVE_NPCS = 10

while true do
	task.wait(SPAWN_INTERVAL)

	local activeCount = 0
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
			activeCount += 1
		end
	end

	if activeCount < MAX_ACTIVE_NPCS then
		print("Active NPCs:", activeCount, " - Spawning new NPC")
		task.spawn(spawnNPC)
	end
end