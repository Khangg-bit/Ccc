--[[
    ESP SCRIPT - PAINT AND SEEK
    Chỉ ESP người đang trốn trong map
    Box + Khoảng cách
    Hỗ trợ: Delta Executor
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Settings
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        BoxColor = Color3.fromRGB(255, 50, 50),
        BoxThickness = 2,
        Distance = true,
        DistanceColor = Color3.fromRGB(255, 255, 255),
        DistanceSize = 14,
        MaxDistance = 500,
        OnlyInGame = true,
        OnlyHiders = true,
    },
    Menu = {
        Keybind = Enum.KeyCode.Delete,
        Visible = true,
        Minimized = false,
    }
}

-- ESP Data
local ESPData = {}

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESPGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Menu elements
local MenuGui
local MainFrame
local PlayerCountLabel
local MinimizeButton

-- Hàm tạo thông báo
local function CreateNotification(text, duration)
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "Notification"
    notifGui.Parent = CoreGui
    notifGui.ResetOnSpawn = false
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 40)
    notifFrame.Position = UDim2.new(0.5, -150, 0, 20)
    notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notifFrame
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.fromRGB(255, 100, 100)
    notifText.TextSize = 16
    notifText.Font = Enum.Font.GothamBold
    notifText.Parent = notifFrame
    
    task.delay(duration or 2, function()
        pcall(function() notifGui:Destroy() end)
    end)
end

-- Tạo Toggle
local function CreateToggle(parent, text, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 28)
    frame.Position = UDim2.new(0, 8, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 18)
    btn.Position = UDim2.new(1, -42, 0.5, -9)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    local state = default
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
        btn.Text = state and "ON" or "OFF"
        if callback then
            callback(state)
        end
    end)
    
    return {
        GetState = function() return state end,
        SetState = function(s)
            state = s
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
            btn.Text = state and "ON" or "OFF"
            if callback then
                callback(state)
            end
        end
    }
end

-- Kiểm tra người chơi có trong map không
local function IsPlayerInGame(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local position = rootPart.Position
    
    if character:FindFirstChild("Lobby") or character:FindFirstChild("Waiting") then
        return false
    end
    
    if position.Y > 100 then
        return false
    end
    
    local spawnDistance = (position - Vector3.new(0, 20, 0)).Magnitude
    if spawnDistance < 30 then
        return false
    end
    
    if player.Team then
        local teamName = player.Team.Name:lower()
        if teamName:find("lobby") or teamName:find("wait") then
            return false
        end
    end
    
    return true
end

-- Kiểm tra có phải người trốn không
local function IsHider(player)
    local character = player.Character
    if not character then return false end
    
    if player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return true
        end
    end
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Transparency > 0.3 then
            return true
        end
    end
    
    return false
end

-- World to Screen
local function WorldToScreen(position)
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    
    local screenPos, onScreen = camera:WorldToScreenPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Xóa ESP của một player
local function RemoveESP(player)
    local data = ESPData[player]
    if not data then return end
    
    if data.Connection then
        data.Connection:Disconnect()
        data.Connection = nil
    end
    
    if data.Box then
        pcall(function() data.Box:Destroy() end)
        data.Box = nil
    end
    if data.DistanceTag then
        pcall(function() data.DistanceTag:Destroy() end)
        data.DistanceTag = nil
    end
    
    ESPData[player] = nil
end

-- Xóa tất cả ESP
local function ClearAllESP()
    for player, data in pairs(ESPData) do
        if data.Connection then
            data.Connection:Disconnect()
        end
        if data.Box then
            pcall(function() data.Box:Destroy() end)
        end
        if data.DistanceTag then
            pcall(function() data.DistanceTag:Destroy() end)
        end
    end
    ESPData = {}
end

-- Refresh tất cả ESP
local function RefreshAllESP()
    ClearAllESP()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end
    
    UpdatePlayerCount()
end

-- Tạo ESP cho một player
function CreateESP(player)
    RemoveESP(player)
    
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not head or not humanoid then return end
    
    ESPData[player] = {
        Box = nil,
        DistanceTag = nil,
        Connection = nil
    }
    
    -- Tạo Box
    if Drawing then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Settings.ESP.BoxColor
        box.Thickness = Settings.ESP.BoxThickness
        box.Transparency = 1
        box.Filled = false
        box.ZIndex = 1
        ESPData[player].Box = box
    end
    
    -- Tạo Distance
    if Drawing then
        local distTag = Drawing.new("Text")
        distTag.Visible = false
        distTag.Color = Settings.ESP.DistanceColor
        distTag.Size = Settings.ESP.DistanceSize
        distTag.Center = true
        distTag.Outline = true
        distTag.OutlineColor = Color3.new(0, 0, 0)
        distTag.ZIndex = 2
        ESPData[player].DistanceTag = distTag
    end
    
    -- Render loop
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local data = ESPData[player]
        if not data then
            if connection then connection:Disconnect() end
            return
        end
        
        local box = data.Box
        local distTag = data.DistanceTag
        
        -- Kiểm tra ESP Master Enable
        if not Settings.ESP.Enabled then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- Kiểm tra player còn tồn tại
        if not player or not player.Parent then
            RemoveESP(player)
            return
        end
        
        local char = player.Character
        if not char or not char.Parent then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hd = char:FindFirstChild("Head")
        
        if not hum or hum.Health <= 0 or not hrp or not hd then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- Kiểm tra OnlyHiders
        if Settings.ESP.OnlyHiders and not IsHider(player) then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- Kiểm tra OnlyInGame
        if Settings.ESP.OnlyInGame and not IsPlayerInGame(player) then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- Tính toán vị trí
        local rootPos = hrp.Position
        local headPos = hd.Position
        
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local distance = localRoot and (localRoot.Position - rootPos).Magnitude or 9999
        
        -- Kiểm tra khoảng cách
        if distance > Settings.ESP.MaxDistance then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- World to Screen
        local feetPos = rootPos - Vector3.new(0, 3, 0)
        local headTopPos = headPos + Vector3.new(0, 0.5, 0)
        
        local feetScreen, feetOnScreen, feetDepth = WorldToScreen(feetPos)
        local headScreen, headOnScreen = WorldToScreen(headTopPos)
        local centerScreen = WorldToScreen(rootPos)
        
        if not feetOnScreen or not headOnScreen or feetDepth < 0 then
            if box then box.Visible = false end
            if distTag then distTag.Visible = false end
            return
        end
        
        -- Kích thước box
        local boxHeight = math.abs(headScreen.Y - feetScreen.Y)
        local boxWidth = boxHeight * 0.5
        
        -- Vẽ Box
        if box and Settings.ESP.Box then
            box.Size = Vector2.new(boxWidth, boxHeight)
            box.Position = Vector2.new(centerScreen.X - boxWidth/2, feetScreen.Y - boxHeight)
            box.Visible = true
            box.Color = Settings.ESP.BoxColor
        elseif box then
            box.Visible = false
        end
        
        -- Vẽ Khoảng cách
        if distTag and Settings.ESP.Distance then
            distTag.Text = math.floor(distance) .. "m"
            distTag.Position = Vector2.new(centerScreen.X, headScreen.Y - 25)
            distTag.Visible = true
            distTag.Color = Settings.ESP.DistanceColor
        elseif distTag then
            distTag.Visible = false
        end
    end)
    
    ESPData[player].Connection = connection
end

-- Cập nhật số lượng
local function UpdatePlayerCount()
    local inGameCount = 0
    local totalHiders = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    if IsHider(player) then
                        totalHiders = totalHiders + 1
                        if IsPlayerInGame(player) then
                            inGameCount = inGameCount + 1
                        end
                    end
                end
            end
        end
    end
    
    if PlayerCountLabel then
        PlayerCountLabel.Text = string.format("🟢 Trốn: %d (Map: %d)", totalHiders, inGameCount)
    end
    
    if MinimizeButton then
        MinimizeButton.Text = "👁\n" .. inGameCount
    end
end

-- Thu nhỏ menu
local function MinimizeMenu()
    Settings.Menu.Minimized = true
    Settings.Menu.Visible = false
    if MenuGui then
        MenuGui.Enabled = false
    end
    if MinimizeButton then
        MinimizeButton.Visible = true
    end
end

-- Mở rộng menu
local function MaximizeMenu()
    Settings.Menu.Minimized = false
    Settings.Menu.Visible = true
    if MenuGui then
        MenuGui.Enabled = true
    end
    if MinimizeButton then
        MinimizeButton.Visible = false
    end
    UpdatePlayerCount()
end

-- Tạo icon thu nhỏ
local function CreateMinimizedIcon()
    MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizedESP"
    MinimizeButton.Size = UDim2.new(0, 45, 0, 45)
    MinimizeButton.Position = UDim2.new(0, 15, 0, 100)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "👁\n0"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    MinimizeButton.TextSize = 14
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Active = true
    MinimizeButton.Draggable = true
    MinimizeButton.Visible = Settings.Menu.Minimized
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = ScreenGui
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 23)
    iconCorner.Parent = MinimizeButton
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 4, 1, 4)
    border.Position = UDim2.new(0, -2, 0, -2)
    border.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    border.BackgroundTransparency = 0.5
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = MinimizeButton
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 25)
    borderCorner.Parent = border
    
    MinimizeButton.MouseButton1Click:Connect(function()
        MaximizeMenu()
    end)
    
    return MinimizeButton
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "ESPMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = Settings.Menu.Visible and not Settings.Menu.Minimized
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 220)
    MainFrame.Position = UDim2.new(0, 10, 0, 50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 3, 1, 3)
    border.Position = UDim2.new(0, -1.5, 0, -1.5)
    border.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    border.BorderSizePixel = 0
    border.BackgroundTransparency = 0.5
    border.ZIndex = 0
    border.Parent = MainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 11)
    borderCorner.Parent = border
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 26, 0, 26)
    miniBtn.Position = UDim2.new(1, -32, 0.5, -13)
    miniBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
    miniBtn.BorderSizePixel = 0
    miniBtn.Text = "—"
    miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    miniBtn.TextSize = 16
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.AutoButtonColor = false
    miniBtn.Parent = titleBar
    
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0, 13)
    miniCorner.Parent = miniBtn
    
    miniBtn.MouseButton1Click:Connect(function()
        MinimizeMenu()
    end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "👁 ESP HIDER"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    -- Player Count
    PlayerCountLabel = Instance.new("TextLabel")
    PlayerCountLabel.Size = UDim2.new(1, -16, 0, 25)
    PlayerCountLabel.Position = UDim2.new(0, 8, 0, 43)
    PlayerCountLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    PlayerCountLabel.BorderSizePixel = 0
    PlayerCountLabel.Text = "🟢 Trốn: 0 (Map: 0)"
    PlayerCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PlayerCountLabel.TextSize = 11
    PlayerCountLabel.Font = Enum.Font.Gotham
    PlayerCountLabel.Parent = MainFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 5)
    infoCorner.Parent = PlayerCountLabel
    
    -- Toggles
    local btnY = 75
    
    CreateToggle(MainFrame, "👁 ESP", btnY, 
        Settings.ESP.Enabled, function(state)
        Settings.ESP.Enabled = state
        if state then
            RefreshAllESP()
        else
            for _, data in pairs(ESPData) do
                if data.Box then data.Box.Visible = false end
                if data.DistanceTag then data.DistanceTag.Visible = false end
            end
        end
    end)
    
    btnY = btnY + 33
    
    CreateToggle(MainFrame, "📦 Box", btnY, 
        Settings.ESP.Box, function(state)
        Settings.ESP.Box = state
        for _, data in pairs(ESPData) do
            if data.Box then
                data.Box.Visible = state and Settings.ESP.Enabled
            end
        end
        if state and Settings.ESP.Enabled then
            RefreshAllESP()
        end
    end)
    
    btnY = btnY + 33
    
    CreateToggle(MainFrame, "📏 Khoảng cách", btnY, 
        Settings.ESP.Distance, function(state)
        Settings.ESP.Distance = state
        for _, data in pairs(ESPData) do
            if data.DistanceTag then
                data.DistanceTag.Visible = state and Settings.ESP.Enabled
            end
        end
        if state and Settings.ESP.Enabled then
            RefreshAllESP()
        end
    end)
    
    btnY = btnY + 33
    
    CreateToggle(MainFrame, "🎯 Chỉ người trốn", btnY, 
        Settings.ESP.OnlyHiders, function(state)
        Settings.ESP.OnlyHiders = state
        if Settings.ESP.Enabled then
            RefreshAllESP()
        end
    end)
    
    btnY = btnY + 33
    
    CreateToggle(MainFrame, "🗺️ Chỉ trong map", btnY, 
        Settings.ESP.OnlyInGame, function(state)
        Settings.ESP.OnlyInGame = state
        if Settings.ESP.Enabled then
            RefreshAllESP()
        end
    end)
    
    return MenuGui
end

-- Khởi tạo
print("Đang tạo ESP...")
MenuGui = CreateMenu()
MinimizeButton = CreateMinimizedIcon()
print("ESP đã tạo!")

-- Tạo ESP cho tất cả player hiện tại
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        CreateESP(player)
    end
end

-- Player Added
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    
    local function OnCharacterAdded(character)
        task.wait(0.3)
        if Settings.ESP.Enabled then
            CreateESP(player)
        end
    end
    
    if player.Character then
        OnCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(OnCharacterAdded)
end)

-- Player Removing
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Cập nhật player count
coroutine.wrap(function()
    while task.wait(1) do
        pcall(UpdatePlayerCount)
    end
end)()

-- Refresh ESP khi LocalPlayer respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Settings.ESP.Enabled then
        RefreshAllESP()
    end
end)

-- Keybind Delete
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Menu.Keybind then
        if Settings.Menu.Minimized then
            MaximizeMenu()
        else
            MinimizeMenu()
        end
    end
end)

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    ClearAllESP()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

-- Thông báo load
task.wait(0.5)
CreateNotification("👁 ESP Hider Loaded! [Delete] Menu", 3)

print("=================================")
print("👁 ESP HIDER LOADED!")
print("✅ Box đỏ + Khoảng cách")
print("✅ Chỉ người trốn trong map")
print("✅ Tắt/Bật không lỗi")
print("📋 Delete = Menu")
print("=================================")