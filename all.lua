--[[
    UNIVERSAL SCRIPT - ESP, AIMBOT, VISUALS, OTHER
    Hỗ trợ: Delta Executor
    Fix: Tắt/Bật hoạt động, Box ngay người, GUI đẹp
    Hoạt động: All Game
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Settings
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        Tracers = true,
        Names = true,
        HealthBar = true,
        Distance = true,
        MaxDistance = 3000,
    },
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        VisibleCheck = true,
        FOV = 100,
        AimPart = "Head",
        Smoothness = 1,
    },
    Visuals = {
        FOVCircle = false,
    },
    Other = {
        SpeedHack = false,
        SpeedValue = 16,
    },
    Menu = {
        Keybind = Enum.KeyCode.Delete,
        Visible = true,
    }
}

-- ESP Data
local ESPData = {}
local AimbotConnection = nil
local SpeedConnection = nil

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalScript"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MenuGui
local MainFrame
local ContentFrame
local TabButtons = {}

-- FOV Circle
local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(255, 80, 80)
    FOVCircle.Thickness = 1.5
    FOVCircle.Transparency = 0.6
    FOVCircle.Filled = false
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Notify
local function Notify(text, duration)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "Notify"
        gui.Parent = CoreGui
        gui.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 320, 0, 40)
        frame.Position = UDim2.new(0.5, -160, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0.1
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        
        local glow = Instance.new("Frame")
        glow.Size = UDim2.new(1, 4, 1, 4)
        glow.Position = UDim2.new(0, -2, 0, -2)
        glow.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        glow.BackgroundTransparency = 0.7
        glow.BorderSizePixel = 0
        glow.ZIndex = 0
        glow.Parent = frame
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(200, 255, 200)
        label.TextSize = 15
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        task.delay(duration or 3, function() pcall(function() gui:Destroy() end) end)
    end)
end

-- Toggle
local function CreateToggle(parent, text, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 32)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)

    local state = default
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
            btn.Text = "OFF"
        end
    end
    updateVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if callback then callback(state) end
    end)

    return {
        GetState = function() return state end,
        SetState = function(s)
            state = s
            updateVisual()
            if callback then callback(state) end
        end
    }
end

-- Slider
local function CreateSlider(parent, text, yPos, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 55)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 20)
    sliderFrame.Position = UDim2.new(0, 0, 0, 25)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 10)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 10)

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 18, 0, 18)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -9, 0, 1)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""
    sliderBtn.AutoButtonColor = false
    sliderBtn.Parent = sliderFrame
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(0, 9)

    local isDragging = false
    local currentValue = default

    local function updateSlider(input)
        local mousePos = input.Position.X
        local sliderPos = sliderFrame.AbsolutePosition.X
        local sliderWidth = sliderFrame.AbsoluteSize.X
        local percent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
        currentValue = math.floor((min + (max - min) * percent) * 10) / 10
        fill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -9, 0, 0)
        label.Text = text .. ": " .. currentValue
        if callback then callback(currentValue) end
    end

    sliderBtn.MouseButton1Down:Connect(function() isDragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
    end)
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; updateSlider(input) end
    end)

    return {
        GetValue = function() return currentValue end,
        SetValue = function(val)
            currentValue = val
            local percent = (val - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            sliderBtn.Position = UDim2.new(percent, -9, 0, 0)
            label.Text = text .. ": " .. val
            if callback then callback(val) end
        end
    }
end

-- World to Screen
local function WorldToScreen(position)
    if not Camera then return nil end
    local screenPos, onScreen = Camera:WorldToScreenPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- ESP Functions
local function RemoveESP(player)
    local data = ESPData[player]
    if not data then return end
    if data.Connection then data.Connection:Disconnect() end
    for _, obj in pairs(data.Objects or {}) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    ESPData[player] = nil
end

local function ClearAllESP()
    for player in pairs(ESPData) do
        RemoveESP(player)
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    RemoveESP(player)

    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not head or not humanoid then return end

    local objects = {}
    
    if Drawing then
        -- Box
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false
        box.ZIndex = 1
        objects.Box = box

        -- Tracer
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Color = Color3.fromRGB(255, 255, 255)
        tracer.Thickness = 1
        tracer.Transparency = 1
        tracer.ZIndex = 1
        objects.Tracer = tracer

        -- Name
        local nameTag = Drawing.new("Text")
        nameTag.Visible = false
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Size = 14
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.OutlineColor = Color3.new(0, 0, 0)
        nameTag.ZIndex = 2
        objects.NameTag = nameTag

        -- Health Bar BG
        local healthBg = Drawing.new("Line")
        healthBg.Visible = false
        healthBg.Color = Color3.new(0, 0, 0)
        healthBg.Thickness = 4
        healthBg.Transparency = 1
        healthBg.ZIndex = 1
        objects.HealthBg = healthBg

        -- Health Bar
        local healthBar = Drawing.new("Line")
        healthBar.Visible = false
        healthBar.Color = Color3.new(0, 255, 100)
        healthBar.Thickness = 2
        healthBar.Transparency = 1
        healthBar.ZIndex = 2
        objects.HealthBar = healthBar

        -- Distance
        local distanceTag = Drawing.new("Text")
        distanceTag.Visible = false
        distanceTag.Color = Color3.fromRGB(255, 255, 255)
        distanceTag.Size = 13
        distanceTag.Center = true
        distanceTag.Outline = true
        distanceTag.OutlineColor = Color3.new(0, 0, 0)
        distanceTag.ZIndex = 2
        objects.DistanceTag = distanceTag
    end

    ESPData[player] = { Objects = objects, Connection = nil }

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local data = ESPData[player]
        if not data then if connection then connection:Disconnect() end; return end

        -- Nếu ESP tắt, ẩn tất cả và return
        if not Settings.ESP.Enabled then
            for _, obj in pairs(data.Objects) do
                if obj then obj.Visible = false end
            end
            return
        end

        -- Kiểm tra player còn tồn tại
        if not player.Parent then RemoveESP(player); return end
        local char = player.Character
        if not char or not char.Parent then
            for _, obj in pairs(data.Objects) do obj.Visible = false end
            return
        end

        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hd = char:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not hrp or not hd then
            for _, obj in pairs(data.Objects) do obj.Visible = false end
            return
        end

        -- Team check
        if LocalPlayer.Team and player.Team == LocalPlayer.Team then
            for _, obj in pairs(data.Objects) do obj.Visible = false end
            return
        end

        local rootPos = hrp.Position
        local headPos = hd.Position
        
        -- Khoảng cách
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local distance = localRoot and (localRoot.Position - rootPos).Magnitude or 9999
        if distance > Settings.ESP.MaxDistance then
            for _, obj in pairs(data.Objects) do obj.Visible = false end
            return
        end

        -- World to Screen
        local feetPos = rootPos - Vector3.new(0, 3, 0)
        local headTopPos = headPos + Vector3.new(0, 0.5, 0)
        local feetScreen, feetOnScreen, feetDepth = WorldToScreen(feetPos)
        local headScreen, headOnScreen = WorldToScreen(headTopPos)
        local centerScreen = WorldToScreen(rootPos)

        if not feetOnScreen or not headOnScreen or feetDepth < 0 then
            for _, obj in pairs(data.Objects) do obj.Visible = false end
            return
        end

        -- Kích thước box
        local boxHeight = math.abs(headScreen.Y - feetScreen.Y)
        local boxWidth = boxHeight * 0.55

        -- Box
        if data.Objects.Box and Settings.ESP.Box then
            data.Objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            data.Objects.Box.Position = Vector2.new(centerScreen.X - boxWidth/2, feetScreen.Y - boxHeight)
            data.Objects.Box.Visible = true
            data.Objects.Box.Color = Color3.fromRGB(255, 255, 255)
        elseif data.Objects.Box then
            data.Objects.Box.Visible = false
        end

        -- Tracer
        if data.Objects.Tracer and Settings.ESP.Tracers then
            data.Objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Objects.Tracer.To = Vector2.new(centerScreen.X, feetScreen.Y)
            data.Objects.Tracer.Visible = true
        elseif data.Objects.Tracer then
            data.Objects.Tracer.Visible = false
        end

        -- Name
        if data.Objects.NameTag and Settings.ESP.Names then
            data.Objects.NameTag.Text = player.DisplayName or player.Name
            data.Objects.NameTag.Position = Vector2.new(centerScreen.X, headScreen.Y - 25)
            data.Objects.NameTag.Visible = true
        elseif data.Objects.NameTag then
            data.Objects.NameTag.Visible = false
        end

        -- Health Bar
        if data.Objects.HealthBar and Settings.ESP.HealthBar then
            local healthPercent = hum.Health / hum.MaxHealth
            local barX = centerScreen.X - boxWidth/2 - 6
            local barTop = feetScreen.Y - boxHeight
            local barBottom = feetScreen.Y
            local barHeight = boxHeight * healthPercent

            data.Objects.HealthBg.From = Vector2.new(barX, barTop)
            data.Objects.HealthBg.To = Vector2.new(barX, barBottom)
            data.Objects.HealthBg.Visible = true

            data.Objects.HealthBar.From = Vector2.new(barX, barBottom - barHeight)
            data.Objects.HealthBar.To = Vector2.new(barX, barBottom)
            data.Objects.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            data.Objects.HealthBar.Visible = true
        elseif data.Objects.HealthBar then
            data.Objects.HealthBar.Visible = false
            if data.Objects.HealthBg then data.Objects.HealthBg.Visible = false end
        end

        -- Distance
        if data.Objects.DistanceTag and Settings.ESP.Distance then
            data.Objects.DistanceTag.Text = math.floor(distance) .. "m"
            data.Objects.DistanceTag.Position = Vector2.new(centerScreen.X, feetScreen.Y + 5)
            data.Objects.DistanceTag.Visible = true
        elseif data.Objects.DistanceTag then
            data.Objects.DistanceTag.Visible = false
        end
    end)

    ESPData[player].Connection = connection
end

local function RefreshAllESP()
    ClearAllESP()
    if not Settings.ESP.Enabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end
end

-- Aimbot
local function GetClosestEnemyInFOV()
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetHum = targetChar:FindFirstChild("Humanoid")
                local targetHead = targetChar:FindFirstChild("Head")
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetHum and targetHum.Health > 0 and targetHead and targetRoot then
                    if LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
                    
                    if Settings.Aimbot.VisibleCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {character}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local ray = Workspace:Raycast(rootPart.Position, (targetHead.Position - rootPart.Position).Unit * 1000, rayParams)
                        if not ray or not ray.Instance:IsDescendantOf(targetChar) then continue end
                    end

                    local aimPart = Settings.Aimbot.AimPart == "Head" and targetHead or targetRoot
                    local aimPos, onScreen = WorldToScreen(aimPart.Position)
                    if onScreen then
                        local distToCenter = (aimPos - screenCenter).Magnitude
                        if distToCenter <= Settings.Aimbot.FOV and distToCenter < closestDistance then
                            closestDistance = distToCenter
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function StartAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() end
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Aimbot.Enabled then
            if FOVCircle then FOVCircle.Visible = Settings.Visuals.FOVCircle end
            return
        end
        local target = GetClosestEnemyInFOV()
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(Settings.Aimbot.AimPart == "Head" and "Head" or "HumanoidRootPart")
            if aimPart then
                if Settings.Aimbot.SilentAim then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                else
                    local newCFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.Aimbot.Smoothness)
                end
            end
        end
        if FOVCircle then
            FOVCircle.Visible = Settings.Aimbot.Enabled or Settings.Visuals.FOVCircle
            FOVCircle.Radius = Settings.Aimbot.FOV
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end)
end

local function StopAimbot()
    if AimbotConnection then AimbotConnection:Disconnect(); AimbotConnection = nil end
    if FOVCircle then FOVCircle.Visible = Settings.Visuals.FOVCircle end
end

-- Speed Hack
local function UpdateSpeed()
    if Settings.Other.SpeedHack then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = Settings.Other.SpeedValue end
        end
    end
end

local function StartSpeedHack()
    if SpeedConnection then SpeedConnection:Disconnect() end
    SpeedConnection = RunService.RenderStepped:Connect(UpdateSpeed)
end

local function StopSpeedHack()
    if SpeedConnection then SpeedConnection:Disconnect(); SpeedConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- Build Tabs
local function BuildESPTab(parent)
    local y = 5
    CreateToggle(parent, "ESP Enabled", y, Settings.ESP.Enabled, function(state)
        Settings.ESP.Enabled = state
        if state then RefreshAllESP() else
            for _, data in pairs(ESPData) do
                for _, obj in pairs(data.Objects) do if obj then obj.Visible = false end end
            end
        end
    end)
    y = y + 37
    CreateToggle(parent, "Box", y, Settings.ESP.Box, function(state)
        Settings.ESP.Box = state
        if Settings.ESP.Enabled then RefreshAllESP() end
    end)
    y = y + 37
    CreateToggle(parent, "Tracers", y, Settings.ESP.Tracers, function(state)
        Settings.ESP.Tracers = state
        if Settings.ESP.Enabled then RefreshAllESP() end
    end)
    y = y + 37
    CreateToggle(parent, "Names", y, Settings.ESP.Names, function(state)
        Settings.ESP.Names = state
        if Settings.ESP.Enabled then RefreshAllESP() end
    end)
    y = y + 37
    CreateToggle(parent, "Health Bar", y, Settings.ESP.HealthBar, function(state)
        Settings.ESP.HealthBar = state
        if Settings.ESP.Enabled then RefreshAllESP() end
    end)
    y = y + 37
    CreateToggle(parent, "Distance", y, Settings.ESP.Distance, function(state)
        Settings.ESP.Distance = state
        if Settings.ESP.Enabled then RefreshAllESP() end
    end)
end

local function BuildAimbotTab(parent)
    local y = 5
    CreateToggle(parent, "Aimbot", y, Settings.Aimbot.Enabled, function(state)
        Settings.Aimbot.Enabled = state
        if state then StartAimbot() else StopAimbot() end
    end)
    y = y + 37
    CreateToggle(parent, "Silent Aim", y, Settings.Aimbot.SilentAim, function(state)
        Settings.Aimbot.SilentAim = state
    end)
    y = y + 37
    CreateToggle(parent, "Visible Check", y, Settings.Aimbot.VisibleCheck, function(state)
        Settings.Aimbot.VisibleCheck = state
    end)
    y = y + 37
    CreateSlider(parent, "FOV", y, 0, 300, Settings.Aimbot.FOV, function(val)
        Settings.Aimbot.FOV = val
        if FOVCircle then FOVCircle.Radius = val end
    end)
end

local function BuildVisualsTab(parent)
    local y = 5
    CreateToggle(parent, "FOV Circle", y, Settings.Visuals.FOVCircle, function(state)
        Settings.Visuals.FOVCircle = state
        if FOVCircle then
            FOVCircle.Visible = state or Settings.Aimbot.Enabled
        end
    end)
end

local function BuildOtherTab(parent)
    local y = 5
    CreateToggle(parent, "Speed Hack", y, Settings.Other.SpeedHack, function(state)
        Settings.Other.SpeedHack = state
        if state then StartSpeedHack() else StopSpeedHack() end
    end)
    y = y + 37
    CreateSlider(parent, "Speed", y, 16, 100, Settings.Other.SpeedValue, function(val)
        Settings.Other.SpeedValue = val
        UpdateSpeed()
    end)
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "UniversalMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = Settings.Menu.Visible

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 560, 0, 340)
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -170)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    -- Border gradient
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 4, 1, 4)
    border.Position = UDim2.new(0, -2, 0, -2)
    border.BackgroundColor3 = Color3.fromRGB(100, 160, 255)
    border.BackgroundTransparency = 0.6
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = MainFrame
    Instance.new("UICorner", border).CornerRadius = UDim.new(0, 14)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 130, 1, 0)
    sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainFrame
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

    local sidebarCover = Instance.new("Frame")
    sidebarCover.Size = UDim2.new(0, 15, 1, 0)
    sidebarCover.Position = UDim2.new(1, -15, 0, 0)
    sidebarCover.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    sidebarCover.BorderSizePixel = 0
    sidebarCover.Parent = sidebar

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    title.BorderSizePixel = 0
    title.Text = "🔮 UNIVERSAL"
    title.TextColor3 = Color3.fromRGB(180, 200, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.Parent = sidebar
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Content Area
    ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -140, 1, -10)
    ContentFrame.Position = UDim2.new(0, 135, 0, 5)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- Tabs
    local tabs = {
        {Name = "👁 ESP", Builder = BuildESPTab},
        {Name = "🎯 Aimbot", Builder = BuildAimbotTab},
        {Name = "👀 Visuals", Builder = BuildVisualsTab},
        {Name = "⚡ Other", Builder = BuildOtherTab},
    }

    local currentTabFrame = nil

    for i, tab in pairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -16, 0, 38)
        tabBtn.Position = UDim2.new(0, 8, 0, 55 + (i-1) * 43)
        tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(28, 28, 40)
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.Name
        tabBtn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 170)
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = sidebar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        TabButtons[i] = tabBtn

        -- Tab Frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = ContentFrame

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
        scroll.Parent = tabFrame

        tab.Builder(scroll)

        if i == 1 then currentTabFrame = tabFrame end

        tabBtn.MouseButton1Click:Connect(function()
            if currentTabFrame then currentTabFrame.Visible = false end
            currentTabFrame = tabFrame
            tabFrame.Visible = true
            for j, btn in pairs(TabButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
                btn.TextColor3 = Color3.fromRGB(170, 170, 170)
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end

    return MenuGui
end

-- Khởi tạo
CreateMenu()

-- ESP ban đầu
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        CreateESP(player)
    end
end

-- Events
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            task.wait(0.3)
            if Settings.ESP.Enabled then CreateESP(player) end
        end)
        if player.Character then CreateESP(player) end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    RefreshAllESP()
    if Settings.Other.SpeedHack then UpdateSpeed() end
end)

-- Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Menu.Keybind then
        Settings.Menu.Visible = not Settings.Menu.Visible
        if MenuGui then MenuGui.Enabled = Settings.Menu.Visible end
    end
end)

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    ClearAllESP()
    StopAimbot()
    StopSpeedHack()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
    if FOVCircle then FOVCircle:Destroy() end
end)

-- Start
StartAimbot()
Notify("✅ Script Loaded! [Delete] = Menu", 3)
print("Universal Script - ESP | Aimbot | Visuals | Other")