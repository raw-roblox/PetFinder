if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then warn("Hindi mahanap ang PlayerGui!") return end

if PlayerGui:FindFirstChild("VisualItemResizer") then
    PlayerGui.VisualItemResizer:Destroy()
end

-- ===================== CORE PET FINDER LOGIC =====================
local selectedPetID = nil -- unique ID for selected pet
local selectedPetName = nil -- pet name for display
local isJoining = false 
local currentPetList = {} 
local petServerData = {} -- store data per pet (id-based)
local petButtons = {} 

local petsBase = {
    "Frog", "Bunny", "Owl", "Deer", "Turtle", "Robin", "Bee", "Monkey", "Bear", "Dragonfly", "Unicorn", "Raccoon", "Ice Serpent", "Black Dragon",
    "Frog", "Bunny", "Owl", "Deer", "Turtle", "Robin", "Bee", "Monkey", "Bear", "Dragonfly", "Unicorn", "Raccoon", "Ice Serpent", "Black Dragon",
    "Frog", "Bunny", "Owl", "Deer", "Turtle", "Robin", "Bee", "Monkey", "Bear", "Dragonfly", "Unicorn", "Raccoon", "Ice Serpent", "Black Dragon"
}

local allAvailablePets = {}
for i = 1, 5 do
    for _, pet in ipairs(petsBase) do
        table.insert(allAvailablePets, pet)
    end
end

local function getRandomNewPet()
    local availablePool = {}
    for _, pName in ipairs(allAvailablePets) do
        local alreadyExists = false
        for _, petData in ipairs(currentPetList) do
            if petData.name == pName then
                alreadyExists = true
                break
            end
        end
        if not alreadyExists then
            table.insert(availablePool, pName)
        end
    end
    if #availablePool == 0 then availablePool = allAvailablePets end
    return availablePool[math.random(1, #availablePool)]
end

local function generateFakeData()
    local maxPlayers = 8 
    local currentPlayers = math.random(0, maxPlayers - 1) 
    local randomTime = math.random(5, 25) 
    return {
        players = currentPlayers .. " / " .. maxPlayers,
        timeLeft = randomTime
    }
end

-- Initialize first 15 pets with unique IDs
local maxDisplayCount = 15
for i = 1, maxDisplayCount do
    local pName = getRandomNewPet()
    local petID = HttpService:GenerateGUID(false) -- generate unique ID
    table.insert(currentPetList, {id=petID, name=pName})
    petServerData[petID] = generateFakeData()
end

-- ===================== BULLETPROOF SERVER HOPPING FUNCTION =====================
local function serverHop()
    local placeId = game.PlaceId
    local jobId = game.JobId

    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)

    if success and result and result.data then
        local possibleServers = {}
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.playing and server.maxPlayers then
                if server.playing < server.maxPlayers and server.id ~= jobId then
                    table.insert(possibleServers, server.id)
                end
            end
        end

        if #possibleServers > 0 then
            local randomServerId = possibleServers[math.random(1, #possibleServers)]
            local teleportSuccess, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, randomServerId, LocalPlayer)
            end)
            
            if teleportSuccess then return end
        end
    end

    local fallbackSuccess = pcall(function()
        TeleportService:Teleport(placeId, LocalPlayer)
    end)

    if not fallbackSuccess then
        pcall(function()
            TeleportService:TeleportToSpawnPoint(placeId, LocalPlayer)
        end)
    end
end

-- ===================== UI SETUP =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VisualItemResizer"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 130) 
panel.Position = UDim2.new(0.5, -160, 0.5, -65)
panel.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(124, 58, 237)
panelStroke.Thickness = 1.2
panelStroke.Transparency = 0.2
panelStroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 32) 
header.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
header.BorderSizePixel = 0
header.Parent = panel

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 8)
headerFix.Position = UDim2.new(0, 0, 1, -8)
headerFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1.5)
headerLine.Position = UDim2.new(0, 0, 1, -1.5)
headerLine.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐾 PET FINDER" 
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13 
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -20, 1, -44)
body.Position = UDim2.new(0, 10, 0, 38)
body.BackgroundTransparency = 1
body.Parent = panel 

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.Parent = body

local itemRow = Instance.new("Frame")
itemRow.Name = "PetDropdownRow"
itemRow.Size = UDim2.new(1, 0, 0, 30) 
itemRow.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
itemRow.LayoutOrder = 1
itemRow.ClipsDescendants = true 
itemRow.Parent = body

Instance.new("UICorner", itemRow).CornerRadius = UDim.new(0, 8)
local itemStroke = Instance.new("UIStroke")
itemStroke.Color = Color3.fromRGB(90, 90, 120)
itemStroke.Thickness = 1
itemStroke.Transparency = 0.5
itemStroke.Parent = itemRow

local dropdownBar = Instance.new("Frame")
dropdownBar.Name = "DropdownBar"
dropdownBar.Size = UDim2.new(1, 0, 0, 30)
dropdownBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
dropdownBar.BorderSizePixel = 0
dropdownBar.Parent = itemRow

local dropdownTitle = Instance.new("TextLabel")
dropdownTitle.Size = UDim2.new(1, -60, 1, 0)
dropdownTitle.Position = UDim2.new(0, 10, 0, 0)
dropdownTitle.BackgroundTransparency = 1
dropdownTitle.Text = "🐶 Select Pet"
dropdownTitle.TextColor3 = Color3.fromRGB(170, 170, 170)
dropdownTitle.Font = Enum.Font.GothamBold
dropdownTitle.TextSize = 12
dropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
dropdownTitle.Parent = dropdownBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleListButton"
toggleBtn.Size = UDim2.new(0, 50, 1, -8)
toggleBtn.Position = UDim2.new(1, -56, 0, 4)
toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
toggleBtn.Text = "OPEN" 
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 10
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = dropdownBar
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -36)
scroll.Position = UDim2.new(0, 5, 0, 33)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(124, 58, 237)
scroll.Parent = itemRow

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 4)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

-- ===================== REFRESH & RENDER SYSTEM =====================
local function refreshPetListUI()
    for _, oldBtn in pairs(scroll:GetChildren()) do
        if oldBtn:IsA("TextButton") then oldBtn:Destroy() end
    end
    table.clear(petButtons)

    for _, petData in ipairs(currentPetList) do
        local petName = petData.name
        local petID = petData.id
        local data = petServerData[petID]
        if not data then continue end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 26) 
        btn.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
        
        if selectedPetID == petID then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
        elseif data.timeLeft <= 3 then
            btn.TextColor3 = Color3.fromRGB(231, 76, 60)
        else
            btn.TextColor3 = Color3.fromRGB(46, 204, 113)
        end
        
        local timeString = string.format("%02d Seconds Left", data.timeLeft)
        btn.Text = "  ▶  " .. petName .. "   (👥 Players: " .. data.players .. "  |  ⏱️ " .. timeString .. ")"
        btn.Font = Enum.Font.GothamBold 
        btn.TextSize = 10.5 
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.Parent = scroll

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(90, 90, 120)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.6
        bStroke.Parent = btn

        petButtons[petID] = btn

        -- Kapag pinindot ang pet button, i-update ang selectedPetID at UI
        btn.MouseButton1Down:Connect(function()
            if isJoining then return end 
            selectedPetID = petID
            selectedPetName = petName
            dropdownTitle.Text = "🐶 Selected: " .. petName
            refreshPetListUI()
        end)
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, #currentPetList * 30)
end

refreshPetListUI()

-- ===================== AUTOMATIC TICKER SYSTEM (LIVE COOLDOWN) =====================
task.spawn(function()
    while true do
        task.wait(1)
        for i = #currentPetList, 1, -1 do
            local petData = currentPetList[i]
            local petID = petData.id
            local data = petServerData[petID]
            if data then
                data.timeLeft = data.timeLeft - 1
                if data.timeLeft <= 0 then
                    -- Agad na palitan ang pet at i-refresh ang UI
                    if selectedPetID == petID then
                        selectedPetID = nil
                        selectedPetName = nil
                        dropdownTitle.Text = "🐶 Select Pet"
                    end
                    table.remove(currentPetList, i)
                    petServerData[petID] = nil
                    local newName = getRandomNewPet()
                    local newID = HttpService:GenerateGUID(false)
                    table.insert(currentPetList, {id=newID, name=newName})
                    petServerData[newID] = generateFakeData()
                    -- Agad na i-refresh ang UI para makita ang bagong pets
                    refreshPetListUI()
                else
                    local currentBtn = petButtons[petID]
                    if currentBtn then
                        local timeString = string.format("%02d Seconds Left", data.timeLeft)
                        currentBtn.Text = "  ▶  " .. petData.name .. "   (👥 Players: " .. data.players .. "  |  ⏱️ " .. timeString .. ")"
                        if selectedPetID ~= petID then
                            if data.timeLeft <= 3 then
                                currentBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
                            else
                                currentBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ===================== BUTTON JOIN LOGIC =====================
local button = Instance.new("TextButton")
button.Name = "MainActionButton"
button.Size = UDim2.new(1, 0, 0, 36) 
button.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 13
button.Text = "🔗 Join Server"
button.LayoutOrder = 2
button.Parent = body
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 12)
footer.BackgroundTransparency = 1
footer.LayoutOrder = 3
footer.Parent = body

local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.new(1, 0, 1, 0)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "Made by Mark L."
creditsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
creditsLabel.TextTransparency = 0.6
creditsLabel.Font = Enum.Font.GothamBold
creditsLabel.TextSize = 9
creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel.Parent = footer

-- DRAG LOGIC (same as before)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===================== DROP DOWN TOGGLE =====================
local listIsOpen = false 
toggleBtn.MouseButton1Click:Connect(function()
    if listIsOpen then
        listIsOpen = false
        toggleBtn.Text = "OPEN"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
        TweenService:Create(itemRow, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 30)}):Play()
        TweenService:Create(panel, TweenInfo.new(0.18), {Size = UDim2.new(0, 320, 0, 130)}):Play() 
    else
        listIsOpen = true
        toggleBtn.Text = "CLOSE"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
        TweenService:Create(itemRow, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 120)}):Play()
        TweenService:Create(panel, TweenInfo.new(0.18), {Size = UDim2.new(0, 320, 0, 220)}):Play() 
    end
end)

button.MouseEnter:Connect(function() if not isJoining then TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(147, 85, 255)}):Play() end end)
button.MouseLeave:Connect(function() if not isJoining then TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(124, 58, 237)}):Play() end end)

-- ===================== JOIN BUTTON LOGIC =====================
button.MouseButton1Click:Connect(function()
    if isJoining then return end 
    
    if selectedPetID then
        local petID = selectedPetID
        local data = petServerData[petID]
        
        if not data then 
            button.Text = "❌ Expired!"
            button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            task.wait(1)
            button.Text = "🔗 Join Server"
            button.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
            return 
        end
        
        isJoining = true
        button.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
        local connectTime = 3
        while connectTime > 0 do
            button.Text = "⏳ Joining Server ("..connectTime.."s)..."
            task.wait(1)
            connectTime = connectTime - 1
        end
        button.Text = "🚀 Teleporting..."
        task.spawn(function()
            serverHop()
        end)
        -- Update list after teleport
        local indexToRemove = nil
        for i, petData in ipairs(currentPetList) do
            if petData.id == petID then
                indexToRemove = i
                break
            end
        end
        if indexToRemove then
            table.remove(currentPetList, indexToRemove)
            petServerData[petID] = nil
            local newName = getRandomNewPet()
            local newID = HttpService:GenerateGUID(false)
            table.insert(currentPetList, {id=newID, name=newName})
            petServerData[newID] = generateFakeData()
        end
        selectedPetID = nil
        selectedPetName = nil
        dropdownTitle.Text = "🐶 Select Pet"
        refreshPetListUI()
        task.wait(1.5)
        isJoining = false
    else
        button.Text = "❌ Select a pet!"
        button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        task.wait(0.8)
        button.Text = "🔗 Join Server"
        button.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    end
end)

print("🚀 Failsafe Server Hop Loaded: Teleport at Rejoin mechanics are fully armed!")
