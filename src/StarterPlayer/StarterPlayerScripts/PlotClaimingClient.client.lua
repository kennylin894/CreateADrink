-- CLIENT SCRIPT - LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local plotEvents = ReplicatedStorage:WaitForChild("PlotEvents")
local notificationRemote = plotEvents:WaitForChild("ShowNotification")

-- Create notification GUI
local function createNotificationGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlotNotifications"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.ScreenInsets = Enum.ScreenInsets.None
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "NotificationFrame"
	notificationFrame.Size = UDim2.new(0, 500, 0, 150)
	notificationFrame.Position = UDim2.new(0.5, -250, 0, -150)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	notificationFrame.BorderSizePixel = 0
	notificationFrame.ZIndex = 1000
	notificationFrame.Parent = screenGui

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notificationFrame

	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Notification"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.ZIndex = 1001
	titleLabel.Parent = notificationFrame

	-- Message label
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, 0, 0.6, 0)
	messageLabel.Position = UDim2.new(0, 0, 0.4, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "Message"
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextSize = 14
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Center
	messageLabel.TextYAlignment = Enum.TextYAlignment.Center
	messageLabel.TextStrokeTransparency = 0.5
	messageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	messageLabel.ZIndex = 1001
	messageLabel.Parent = notificationFrame

	return screenGui, notificationFrame, titleLabel, messageLabel
end

-- Show notification
local function showNotification(notificationType, title, message)
	local screenGui, notificationFrame, titleLabel, messageLabel = createNotificationGui()

	-- Set colors based on type
	if notificationType == "success" then
		notificationFrame.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		messageLabel.TextColor3 = Color3.new(1, 1, 1)
	elseif notificationType == "error" then
		notificationFrame.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		messageLabel.TextColor3 = Color3.new(1, 1, 1)
	end

	titleLabel.Text = title
	messageLabel.Text = message

	-- Slide down animation
	local slideDownTween = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -250, 0, 30)}
	)

	-- Slide up and fade out
	local slideUpTween = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0.5, -250, 0, -150),
			BackgroundTransparency = 1
		}
	)

	local titleFadeTween = TweenService:Create(
		titleLabel,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)

	local messageFadeTween = TweenService:Create(
		messageLabel,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1}
	)

	slideDownTween:Play()

	spawn(function()
		wait(3)
		slideUpTween:Play()
		titleFadeTween:Play()
		messageFadeTween:Play()

		slideUpTween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

-- Connect to remote event
notificationRemote.OnClientEvent:Connect(function(notificationType, title, message)
	showNotification(notificationType, title, message)
end)

--Commit Test
--Hey