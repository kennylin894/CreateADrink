-- SELL NPC LocalScript - Place in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("Sell NPC LocalScript started for", player.Name)

-- Wait for RemoteEvent
local sellRemote = ReplicatedStorage:WaitForChild("SellRemote", 10)
if not sellRemote then
    warn("Could not find SellRemote!")
    return
end

print("Found SellRemote!")

-- Create sell GUI
local sellGui = Instance.new("ScreenGui")
sellGui.Name = "SellShopGui"
sellGui.ResetOnSpawn = false
sellGui.Parent = playerGui

-- Confirmation dialog (separate ScreenGui to appear on top)
local confirmGui = Instance.new("ScreenGui")
confirmGui.Name = "ConfirmationGui"
confirmGui.ResetOnSpawn = false
confirmGui.Parent = playerGui

local confirmationFrame = Instance.new("Frame")
confirmationFrame.Name = "ConfirmationFrame"
confirmationFrame.Size = UDim2.new(0, 350, 0, 150)
confirmationFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
confirmationFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
confirmationFrame.BorderSizePixel = 0
confirmationFrame.Visible = false
confirmationFrame.Parent = confirmGui

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 15)
confirmCorner.Parent = confirmationFrame

-- Confirmation title
local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -20, 0, 35)
confirmTitle.Position = UDim2.new(0, 10, 0, 10)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Text = "💰 Sell All Confirmation"
confirmTitle.TextColor3 = Color3.fromRGB(139, 69, 19)
confirmTitle.TextScaled = true
confirmTitle.Font = Enum.Font.SourceSansBold
confirmTitle.Parent = confirmationFrame

-- Confirmation message
local confirmMessage = Instance.new("TextLabel")
confirmMessage.Size = UDim2.new(1, -20, 0, 50)
confirmMessage.Position = UDim2.new(0, 10, 0, 40)
confirmMessage.BackgroundTransparency = 1
confirmMessage.Text = "Sell all crops for sippies?"
confirmMessage.TextColor3 = Color3.fromRGB(80, 80, 80)
confirmMessage.TextScaled = true
confirmMessage.Font = Enum.Font.SourceSansBold
confirmMessage.TextWrapped = true
confirmMessage.Parent = confirmationFrame

-- Yes button
local yesButton = Instance.new("TextButton")
yesButton.Size = UDim2.new(0, 100, 0, 35)
yesButton.Position = UDim2.new(0, 40, 0, 100)
yesButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
yesButton.BorderSizePixel = 0
yesButton.Text = "Sell All"
yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
yesButton.TextScaled = true
yesButton.Font = Enum.Font.SourceSansBold
yesButton.Parent = confirmationFrame

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 8)
yesCorner.Parent = yesButton

-- No button
local noButton = Instance.new("TextButton")
noButton.Size = UDim2.new(0, 100, 0, 35)
noButton.Position = UDim2.new(0, 210, 0, 100)
noButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
noButton.BorderSizePixel = 0
noButton.Text = "Cancel"
noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noButton.TextScaled = true
noButton.Font = Enum.Font.SourceSansBold
noButton.Parent = confirmationFrame

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 8)
noCorner.Parent = noButton

-- Main sell frame (FIXED: Same size as buy shop)
local sellFrame = Instance.new("Frame")
sellFrame.Name = "SellFrame"
sellFrame.Size = UDim2.new(0, 600, 0, 450)
sellFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
sellFrame.BackgroundColor3 = Color3.fromRGB(139, 69, 19) -- Brown theme for selling
sellFrame.BorderSizePixel = 0
sellFrame.Visible = false
sellFrame.Parent = sellGui

-- Add corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = sellFrame

-- Add gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 69, 19)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 133, 63))
}
gradient.Rotation = 45
gradient.Parent = sellFrame

-- Shop title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 0, 50)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💰 CROP MARKET 💰"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.fromRGB(101, 67, 33)
titleLabel.Parent = sellFrame

-- Subtitle (FIXED: Smaller to prevent overlap)
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, -20, 0, 20)
subtitleLabel.Position = UDim2.new(0, 10, 0, 55)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Sell your harvested crops for sippies!"
subtitleLabel.TextColor3 = Color3.fromRGB(240, 248, 255)
subtitleLabel.TextScaled = true
subtitleLabel.Font = Enum.Font.SourceSans
subtitleLabel.Parent = sellFrame

-- Close button (FIXED: Proper X button)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
closeButton.BackgroundTransparency = 0
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = sellFrame

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
        BackgroundColor3 = Color3.fromRGB(139, 69, 19),
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
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(139, 69, 19)
scrollFrame.Parent = sellFrame

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
local function getCropEmoji(itemType)
    if itemType == "strawberry" then return "🍓"
    elseif itemType == "orange" then return "🍊"
    elseif itemType == "apple" then return "🍎"
    elseif itemType == "carrot" then return "🥕"
    elseif itemType == "blueberry" then return "🔵"
    elseif itemType == "mint" then return "🌿"
    elseif itemType == "watermelon" then return "🍉"
    elseif itemType == "lemon" then return "🍋"
    elseif itemType == "grape" then return "🍇"
    elseif itemType == "cucumber" then return "🥒"
    else return "🌱"
    end
end

-- Function to create number input
local function createNumberInput(parent, maxValue, onChanged)
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0, 100, 0, 30)
    inputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inputFrame.BorderSizePixel = 1
    inputFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    inputFrame.Parent = parent
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 5)
    inputCorner.Parent = inputFrame
    
    local minusButton = Instance.new("TextButton")
    minusButton.Size = UDim2.new(0, 25, 1, 0)
    minusButton.Position = UDim2.new(0, 0, 0, 0)
    minusButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    minusButton.BorderSizePixel = 0
    minusButton.Text = "-"
    minusButton.TextScaled = true
    minusButton.Font = Enum.Font.SourceSansBold
    minusButton.Parent = inputFrame
    
    local plusButton = Instance.new("TextButton")
    plusButton.Size = UDim2.new(0, 25, 1, 0)
    plusButton.Position = UDim2.new(1, -25, 0, 0)
    plusButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    plusButton.BorderSizePixel = 0
    plusButton.Text = "+"
    plusButton.TextScaled = true
    plusButton.Font = Enum.Font.SourceSansBold
    plusButton.Parent = inputFrame
    
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Size = UDim2.new(1, -50, 1, 0)
    numberLabel.Position = UDim2.new(0, 25, 0, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = "1"
    numberLabel.TextScaled = true
    numberLabel.Font = Enum.Font.SourceSans
    numberLabel.Parent = inputFrame
    
    local currentValue = 1
    
    local function updateValue(newValue)
        currentValue = math.max(1, math.min(maxValue, newValue))
        numberLabel.Text = tostring(currentValue)
        if onChanged then
            onChanged(currentValue)
        end
    end
    
    minusButton.MouseButton1Click:Connect(function()
        updateValue(currentValue - 1)
    end)
    
    plusButton.MouseButton1Click:Connect(function()
        updateValue(currentValue + 1)
    end)
    
    return inputFrame, updateValue
end

-- Function to create sell items
local function createSellItems(inventory)
    print("Creating sell items, count:", #inventory)
    
    -- Clear existing items AND empty labels
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child.Name == "SellItem" or child.Name == "EmptyLabel" then
            child:Destroy()
        end
    end
    
    if #inventory == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyLabel"
        emptyLabel.Size = UDim2.new(1, 0, 0, 100)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "📦 No crops to sell!\nGo harvest some crops first!"
        emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        emptyLabel.TextScaled = true
        emptyLabel.Font = Enum.Font.SourceSans
        emptyLabel.Parent = scrollFrame
        return
    end
    
    for i, item in pairs(inventory) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "SellItem"
        itemFrame.Size = UDim2.new(1, -15, 0, 100)
        itemFrame.BackgroundColor3 = Color3.fromRGB(248, 248, 255)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 12)
        itemCorner.Parent = itemFrame
        
        -- Crop emoji
        local cropEmoji = Instance.new("TextLabel")
        cropEmoji.Name = "CropEmoji"
        cropEmoji.Size = UDim2.new(0, 70, 0, 70)
        cropEmoji.Position = UDim2.new(0, 15, 0.5, -35)
        cropEmoji.BackgroundTransparency = 1
        cropEmoji.Text = getCropEmoji(item.itemType)
        cropEmoji.TextScaled = true
        cropEmoji.Font = Enum.Font.SourceSans
        cropEmoji.Parent = itemFrame
        
        -- Item name and count (FIXED: Better sizing)
        local itemName = Instance.new("TextLabel")
        itemName.Name = "ItemName"
        itemName.Size = UDim2.new(0, 120, 0, 25)
        itemName.Position = UDim2.new(0, 95, 0, 8)
        itemName.BackgroundTransparency = 1
        itemName.Text = item.name .. " x" .. item.count
        itemName.TextColor3 = Color3.fromRGB(139, 69, 19)
        itemName.TextScaled = true
        itemName.Font = Enum.Font.SourceSansBold
        itemName.TextXAlignment = Enum.TextXAlignment.Left
        itemName.Parent = itemFrame
        
        -- Price per item (FIXED: Better positioning)
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "PriceLabel"
        priceLabel.Size = UDim2.new(0, 120, 0, 20)
        priceLabel.Position = UDim2.new(0, 95, 0, 35)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = item.sellPrice .. " 🥤 each"
        priceLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.SourceSans
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.Parent = itemFrame
        
        -- Amount selector label (FIXED: Moved right)
        local selectorLabel = Instance.new("TextLabel")
        selectorLabel.Size = UDim2.new(0, 60, 0, 20)
        selectorLabel.Position = UDim2.new(0, 230, 0, 8)
        selectorLabel.BackgroundTransparency = 1
        selectorLabel.Text = "Amount:"
        selectorLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        selectorLabel.TextScaled = true
        selectorLabel.Font = Enum.Font.SourceSans
        selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
        selectorLabel.Parent = itemFrame
        
        local currentSellAmount = 1
        local totalValueLabel = Instance.new("TextLabel")
        totalValueLabel.Name = "TotalValue"
        totalValueLabel.Size = UDim2.new(0, 100, 0, 20)
        totalValueLabel.Position = UDim2.new(0, 230, 0, 60)
        totalValueLabel.BackgroundTransparency = 1
        totalValueLabel.Text = "= " .. item.sellPrice .. " 🥤"
        totalValueLabel.TextColor3 = Color3.fromRGB(34, 139, 34)
        totalValueLabel.TextScaled = true
        totalValueLabel.Font = Enum.Font.SourceSansBold
        totalValueLabel.TextXAlignment = Enum.TextXAlignment.Left
        totalValueLabel.Parent = itemFrame
        
        local numberInput, updateAmount = createNumberInput(itemFrame, item.count, function(newAmount)
            currentSellAmount = newAmount
            totalValueLabel.Text = "= " .. (newAmount * item.sellPrice) .. " 🥤"
        end)
        numberInput.Position = UDim2.new(0, 230, 0, 30)
        
        -- Sell button (FIXED: Moved far right)
        local sellButton = Instance.new("TextButton")
        sellButton.Name = "SellButton"
        sellButton.Size = UDim2.new(0, 80, 0, 35)
        sellButton.Position = UDim2.new(0, 350, 0, 10)
        sellButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
        sellButton.BorderSizePixel = 0
        sellButton.Text = "SELL"
        sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        sellButton.TextScaled = true
        sellButton.Font = Enum.Font.SourceSansBold
        sellButton.Parent = itemFrame
        
        local sellCorner = Instance.new("UICorner")
        sellCorner.CornerRadius = UDim.new(0, 8)
        sellCorner.Parent = sellButton
        
        -- Sell All button (FIXED: Moved far right)
        local sellAllButton = Instance.new("TextButton")
        sellAllButton.Name = "SellAllButton"
        sellAllButton.Size = UDim2.new(0, 80, 0, 35)
        sellAllButton.Position = UDim2.new(0, 350, 0, 55)
        sellAllButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        sellAllButton.BorderSizePixel = 0
        sellAllButton.Text = "SELL ALL"
        sellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        sellAllButton.TextScaled = true
        sellAllButton.Font = Enum.Font.SourceSansBold
        sellAllButton.Parent = itemFrame
        
        local sellAllCorner = Instance.new("UICorner")
        sellAllCorner.CornerRadius = UDim.new(0, 8)
        sellAllCorner.Parent = sellAllButton
        
        -- Button events
        sellButton.MouseButton1Click:Connect(function()
            print("Selling", currentSellAmount, item.itemType)
            sellRemote:FireServer("sellItem", item.itemType, currentSellAmount)
        end)
        
        sellAllButton.MouseButton1Click:Connect(function()
            -- Show confirmation dialog
            confirmMessage.Text = "Sell all " .. item.name .. "?"
            confirmationFrame.Visible = true
            
            -- Store the item type for confirmation
            confirmationFrame:SetAttribute("ItemType", item.itemType)
            confirmationFrame:SetAttribute("ItemName", item.name)
        end)
        
        -- Hover effects
        sellButton.MouseEnter:Connect(function()
            TweenService:Create(sellButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 170, 50)}):Play()
        end)
        sellButton.MouseLeave:Connect(function()
            TweenService:Create(sellButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 139, 34)}):Play()
        end)
        
        sellAllButton.MouseEnter:Connect(function()
            TweenService:Create(sellAllButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 165, 0)}):Play()
        end)
        sellAllButton.MouseLeave:Connect(function()
            TweenService:Create(sellAllButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 140, 0)}):Play()
        end)
    end
    
    -- Update scroll frame size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #inventory * 108)
    print("Sell items created successfully!")
end

-- Close button functionality (FIXED: Updated for new size)
closeButton.MouseButton1Click:Connect(function()
    print("Close button clicked")
    local tween = TweenService:Create(sellFrame, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        sellFrame.Visible = false
        sellFrame.Size = UDim2.new(0, 600, 0, 450)
        sellFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    end)
end)

-- Confirmation dialog functionality
yesButton.MouseButton1Click:Connect(function()
    local itemType = confirmationFrame:GetAttribute("ItemType")
    if itemType then
        print("Confirmed: Selling all", itemType)
        sellRemote:FireServer("sellAll", itemType)
    end
    confirmationFrame.Visible = false
end)

noButton.MouseButton1Click:Connect(function()
    print("Cancelled sell all")
    confirmationFrame.Visible = false
end)

-- Hover effects for confirmation buttons
yesButton.MouseEnter:Connect(function()
    TweenService:Create(yesButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 170, 50)}):Play()
end)
yesButton.MouseLeave:Connect(function()
    TweenService:Create(yesButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 139, 34)}):Play()
end)

noButton.MouseEnter:Connect(function()
    TweenService:Create(noButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
end)
noButton.MouseLeave:Connect(function()
    TweenService:Create(noButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}):Play()
end)

-- Handle remote events (FIXED: Updated for new size)
sellRemote.OnClientEvent:Connect(function(action, data)
    print("Client received event:", action)
    
    if action == "openSellShop" then
        print("Opening sell shop with", #data, "items")
        sellFrame.Visible = true
        createSellItems(data)
        
        -- Opening animation (FIXED: Updated for new size)
        sellFrame.Size = UDim2.new(0, 0, 0, 0)
        sellFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        local tween = TweenService:Create(sellFrame, TweenInfo.new(0.4), {
            Size = UDim2.new(0, 600, 0, 450),
            Position = UDim2.new(0.5, -300, 0.5, -225)
        })
        tween:Play()
        
    elseif action == "updateInventory" then
        -- Update the inventory display
        if sellFrame.Visible then
            createSellItems(data)
        end
    end
end)

print("Sell NPC LocalScript setup complete!")