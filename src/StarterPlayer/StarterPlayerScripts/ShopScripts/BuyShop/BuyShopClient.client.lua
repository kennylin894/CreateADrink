-- CropSystemScript.server.lua
-- LocalScript in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("Crop Shop LocalScript started for", player.Name)

-- Wait for RemoteEvent
local shopRemote = ReplicatedStorage:WaitForChild("ShopRemote", 10)
if not shopRemote then
    warn("Could not find ShopRemote in ReplicatedStorage!")
    return
end

print("Found ShopRemote!")

-- Create shop GUI
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "CropShopGui"
shopGui.ResetOnSpawn = false
shopGui.Parent = playerGui

print("Created CropShopGui")

-- Main shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 600, 0, 450)
shopFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
shopFrame.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Forest green theme
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = shopGui

-- Add corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = shopFrame

-- Add gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 205, 50))
}
gradient.Rotation = 45
gradient.Parent = shopFrame

-- Shop title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 0, 50)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌱 CROP SEEDS SHOP 🌱"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 100, 0)
titleLabel.Parent = shopFrame

-- Subtitle
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, -20, 0, 25)
subtitleLabel.Position = UDim2.new(0, 10, 0, 50)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Grow fresh ingredients for your drinks!"
subtitleLabel.TextColor3 = Color3.fromRGB(240, 248, 255)
subtitleLabel.TextScaled = true
subtitleLabel.Font = Enum.Font.SourceSans
subtitleLabel.Parent = shopFrame

-- Close button (FIXED)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
closeButton.BackgroundTransparency = 0
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Close button hover effects
closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(220, 20, 60),
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)
closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(34, 139, 34),
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)

-- Scrolling frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemsScrollFrame"
scrollFrame.Size = UDim2.new(1, -20, 1, -90)
scrollFrame.Position = UDim2.new(0, 10, 0, 80)
scrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
scrollFrame.BackgroundTransparency = 0.1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 12
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(34, 139, 34)
scrollFrame.Parent = shopFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 10)
scrollCorner.Parent = scrollFrame

-- Layout for items
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = scrollFrame

-- Function to get crop emoji
local function getCropEmoji(itemId)
    if string.find(itemId, "strawberry") then return "🍓"
    elseif string.find(itemId, "orange") then return "🍊"
    elseif string.find(itemId, "apple") then return "🍎"
    elseif string.find(itemId, "carrot") then return "🥕"
    elseif string.find(itemId, "blueberry") then return "🫐"
    elseif string.find(itemId, "mint") then return "🌿"
    elseif string.find(itemId, "watermelon") then return "🍉"
    elseif string.find(itemId, "lemon") then return "🍋"
    elseif string.find(itemId, "grape") then return "🍇"
    elseif string.find(itemId, "cucumber") then return "🥒"
    else return "🌱"
    end
end

-- DEBOUNCE TABLE TO PREVENT DOUBLE CLICKING
local clickDebounce = {}

-- Function to create shop items
local function createShopItems(items)
    print("Creating crop shop items, count:", #items)
    
    -- Clear existing items
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child.Name == "ShopItem" then
            child:Destroy()
        end
    end
    
    for i, item in pairs(items) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "ShopItem"
        itemFrame.Size = UDim2.new(1, -15, 0, 90)
        itemFrame.BackgroundColor3 = Color3.fromRGB(248, 248, 255)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 12)
        itemCorner.Parent = itemFrame
        
        -- Item shadow effect
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.Position = UDim2.new(0, 2, 0, 2)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.8
        shadow.BorderSizePixel = 0
        shadow.ZIndex = itemFrame.ZIndex - 1
        shadow.Parent = itemFrame
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 12)
        shadowCorner.Parent = shadow
        
        -- Crop emoji
        local cropEmoji = Instance.new("TextLabel")
        cropEmoji.Name = "CropEmoji"
        cropEmoji.Size = UDim2.new(0, 60, 0, 60)
        cropEmoji.Position = UDim2.new(0, 15, 0.5, -30)
        cropEmoji.BackgroundTransparency = 1
        cropEmoji.Text = getCropEmoji(item.id)
        cropEmoji.TextScaled = true
        cropEmoji.Font = Enum.Font.SourceSans
        cropEmoji.Parent = itemFrame
        
        -- Item name - FIXED: Made wider to accommodate price
        local itemName = Instance.new("TextLabel")
        itemName.Name = "ItemName"
        itemName.Size = UDim2.new(0.25, 0, 0.4, 0) -- Reduced from 0.35 to 0.25
        itemName.Position = UDim2.new(0, 85, 0, 8)
        itemName.BackgroundTransparency = 1
        itemName.Text = item.name
        itemName.TextColor3 = Color3.fromRGB(34, 139, 34)
        itemName.TextScaled = true
        itemName.Font = Enum.Font.SourceSansBold
        itemName.TextXAlignment = Enum.TextXAlignment.Left
        itemName.Parent = itemFrame
        
        -- Item description - FIXED: Made wider and repositioned
        local itemDesc = Instance.new("TextLabel")
        itemDesc.Name = "ItemDescription"
        itemDesc.Size = UDim2.new(0.25, 0, 0.35, 0) -- Reduced from 0.35 to 0.25
        itemDesc.Position = UDim2.new(0, 85, 0.45, 0)
        itemDesc.BackgroundTransparency = 1
        itemDesc.Text = item.description
        itemDesc.TextColor3 = Color3.fromRGB(105, 105, 105)
        itemDesc.TextScaled = true
        itemDesc.Font = Enum.Font.SourceSans
        itemDesc.TextXAlignment = Enum.TextXAlignment.Left
        itemDesc.TextWrapped = true
        itemDesc.Parent = itemFrame
        
        -- Item price - FIXED: Moved to center between item and buy button
        local itemPrice = Instance.new("TextLabel")
        itemPrice.Name = "ItemPrice"
        itemPrice.Size = UDim2.new(0.18, 0, 0.4, 0) -- Adjusted width
        itemPrice.Position = UDim2.new(0.45, 0, 0, 8) -- Moved right to center between item and button
        itemPrice.BackgroundTransparency = 1
        itemPrice.Text = item.price .. " 🥤"
        itemPrice.TextColor3 = Color3.fromRGB(255, 140, 0)
        itemPrice.TextScaled = true
        itemPrice.Font = Enum.Font.SourceSansBold
        itemPrice.Parent = itemFrame
        
        -- Count display - NEW: Show how many seeds you get
        local countDisplay = Instance.new("TextLabel")
        countDisplay.Name = "CountDisplay"
        countDisplay.Size = UDim2.new(0.18, 0, 0.3, 0)
        countDisplay.Position = UDim2.new(0.45, 0, 0.4, 0) -- Moved to align with price
        countDisplay.BackgroundTransparency = 1
        countDisplay.Text = "+1 seed"
        countDisplay.TextColor3 = Color3.fromRGB(34, 139, 34)
        countDisplay.TextScaled = true
        countDisplay.Font = Enum.Font.SourceSans
        countDisplay.Parent = itemFrame
        
        -- Buy button - FIXED: Made smaller and repositioned
        local buyButton = Instance.new("TextButton")
        buyButton.Name = "BuyButton"
        buyButton.Size = UDim2.new(0.2, -10, 0.55, -10) -- Reduced from 0.25 to 0.2 width, reduced height slightly
        buyButton.Position = UDim2.new(0.78, 0, 0.225, 8) -- Moved right and adjusted position
        buyButton.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        buyButton.BorderSizePixel = 0
        buyButton.Text = "BUY"
        buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyButton.TextScaled = true
        buyButton.Font = Enum.Font.SourceSansBold
        buyButton.TextStrokeTransparency = 0
        buyButton.TextStrokeColor3 = Color3.fromRGB(0, 100, 0)
        buyButton.Parent = itemFrame
        
        local buyCorner = Instance.new("UICorner")
        buyCorner.CornerRadius = UDim.new(0, 8)
        buyCorner.Parent = buyButton
        
        -- Buy button click - FIXED: Added debounce to prevent double clicking
        buyButton.MouseButton1Click:Connect(function()
            -- DEBOUNCE CHECK
            local itemKey = player.UserId .. "_" .. item.id
            if clickDebounce[itemKey] then
                print("Click blocked - too fast!")
                return
            end
            
            -- Set debounce for 1 second
            clickDebounce[itemKey] = true
            spawn(function()
                wait(1)
                clickDebounce[itemKey] = nil
            end)
            
            print("Buy button clicked for", item.name)
            shopRemote:FireServer("buyItem", item)
        end)
        
        -- Hover effects
        buyButton.MouseEnter:Connect(function()
            TweenService:Create(buyButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(70, 225, 70),
                Size = UDim2.new(0.21, -10, 0.57, -10)
            }):Play()
        end)
        
        buyButton.MouseLeave:Connect(function()
            TweenService:Create(buyButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 205, 50),
                Size = UDim2.new(0.2, -10, 0.55, -10)
            }):Play()
        end)
    end
    
    -- Update scroll frame size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 98)
    print("Crop shop items created successfully!")
end

-- Function to show notification
local function showNotification(message, isSuccess)
    print("Showing notification:", message)
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 350, 0, 70)
    notification.Position = UDim2.new(0.5, -175, 0, 30)
    notification.BackgroundColor3 = isSuccess and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(220, 20, 60)
    notification.BorderSizePixel = 0
    notification.Parent = shopGui
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -20)
    notifText.Position = UDim2.new(0, 10, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.TextScaled = true
    notifText.Font = Enum.Font.SourceSansBold
    notifText.TextStrokeTransparency = 0
    notifText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    notifText.Parent = notification
    
    -- Remove after 4 seconds
    game:GetService("Debris"):AddItem(notification, 4)
end

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    print("Close button clicked")
    local tween = TweenService:Create(shopFrame, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        shopFrame.Visible = false
        shopFrame.Size = UDim2.new(0, 600, 0, 450)
        shopFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    end)
end)

-- Handle remote events
shopRemote.OnClientEvent:Connect(function(action, data)
    print("Client received event:", action)
    
    if action == "openShop" then
        print("Opening crop shop with", #data, "items")
        shopFrame.Visible = true
        createShopItems(data)
        
        -- Opening animation
        shopFrame.Size = UDim2.new(0, 0, 0, 0)
        shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        local tween = TweenService:Create(shopFrame, TweenInfo.new(0.4), {
            Size = UDim2.new(0, 600, 0, 450),
            Position = UDim2.new(0.5, -300, 0.5, -225)
        })
        tween:Play()
        
    elseif action == "purchaseSuccess" then
        showNotification("🌱 Successfully bought " .. data.name .. "! 🌱", true)
        
    elseif action == "purchaseFailed" then
        showNotification("❌ " .. data, false)
    end
end)

print("Crop Shop LocalScript setup complete!")