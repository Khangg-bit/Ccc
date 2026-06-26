--[[
    UNIVERSAL SCRIPT - ESP, AIMBOT, VISUALS, OTHER
    Hỗ trợ: Delta Executor
    Tính năng: ESP, Aimbot, Visuals, Speed Hack
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Settings
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        BoxThickness = 2,
        Tracers = true,
        TracerColor = Color3.fromRGB(255, 255, 255),
        TracerThickness = 1,
        Names = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 14,
        HealthBar = true,
        Distance = true,
        DistanceColor = Color3.fromRGB(255, 255, 255),
        DistanceSize = 13,
        MaxDistance = 3000,
    },
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        VisibleCheck = true,
        FOV = 100,
        AimPart = "Head", -- Head, HumanoidRootPart
        Smoothness = 1,
    },
    Visuals = {
        FOVCircle = false,
        FOVCircleColor = Color3.fromRGB(255, 50, 50),
        FOVCircleRadius = 100,
    },
    Other = {
        SpeedHack = false,
        SpeedValue = 16,
    },
    Menu = {
        Keybind = Enum.KeyCode.Delete,
        Visible = true,
        Minimized = false,
    }
}

-- ESP Data
local ESPData = {}

-- Aimbot Data
local AimbotTarget = nil

-- Speed Hack Data
local SpeedConnection = nil

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalScript"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Menu elements
local MenuGui
local MainFrame
local MinimizeButton
local TabButtons = {}
local TabFrames = {}
local CurrentTab = "ESP"

-- FOV Circle Drawing
local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Settings.Visuals.FOVCircleColor
    FOVCircle.Thickness = 1.5
    FOVCircle.Transparency = 0.7
    FOVCircle.Filled = false
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Aimbot Circle Drawing
local AimbotCircle = nil
if Drawing then
    AimbotCircle = Drawing.new("Circle")
    AimbotCircle.Visible = false
    AimbotCircle.Color = Color3.fromRGB(255, 255, 255)
    AimbotCircle.Thickness = 1
    AimbotCircle.Transparency = 0.5
    AimbotCircle.Filled = false
    AimbotCircle.Radius = Settings.Aimbot.FOV
    AimbotCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Notify
local function Notify(text, duration)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "Notification"
        gui.Parent = CoreGui
        gui.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 36)
        frame.Position = UDim2.new(0.5, -150, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(0, 255, 150)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        task.delay(duration or 2, function()
            pcall(function() gui:Destroy() end)
        end)
    end)
end

-- Tạo Toggle
local function CreateToggle(parent, text, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.Position = UDim2.new(0, 5, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
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
        if callback then callback(state) end
    end)

    return {
        GetState = function() return state end,
        SetState = function(s)
            state = s
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
            btn.Text = state and "ON" or "OFF"
            if callback then callback(state) end
        end
    }
end

-- Tạo Slider
local function CreateSlider(parent, text, yPos, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.Position = UDim2.new(0, 5, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 18)
    sliderFrame.Position = UDim2.new(0, 0, 0, 22)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 9)
    sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 9)
    fillCorner.Parent = fill

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 18, 0, 18)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -9, 0, 0)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""
    sliderBtn.AutoButtonColor = false
    sliderBtn.Parent = sliderFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 9)
    btnCorner.Parent = sliderBtn

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

    sliderBtn.MouseButton1Down:Connect(function()
        isDragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input)
        end
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

-- Lấy kẻ địch gần nhất trong FOV
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
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHead = targetChar:FindFirstChild("Head")

                if targetHum and targetHum.Health > 0 and targetRoot and targetHead then
                    -- Team check
                    if LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        continue
                    end

                    -- Visible check
                    if Settings.Aimbot.VisibleCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {character, targetChar}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local ray = Workspace:Raycast(rootPart.Position, (targetHead.Position - rootPart.Position).Unit * 1000, rayParams)
                        if ray and ray.Instance and ray.Instance:IsDescendantOf(targetChar) then
                            -- Visible
                        else
                            continue
                        end
                    end

                    -- Lấy vị trí aim
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

-- Aimbot Loop
local function AimbotLoop()
    RunService.RenderStepped:Connect(function()
        if not Settings.Aimbot.Enabled then
            AimbotTarget = nil
            return
        end

        local target = GetClosestEnemyInFOV()
        if target and target.Character then
            AimbotTarget = target
            local aimPart = target.Character:FindFirstChild(Settings.Aimbot.AimPart == "Head" and "Head" or "HumanoidRootPart")
            if aimPart then
                local aimPos = aimPart.Position
                if Settings.Aimbot.SilentAim then
                    -- Silent Aim
                    local cameraCFrame = Camera.CFrame
                    local newCFrame = CFrame.new(cameraCFrame.Position, aimPos)
                    Camera.CFrame = newCFrame
                else
                    -- Normal Aim
                    local cameraCFrame = Camera.CFrame
                    local newCFrame = cameraCFrame:Lerp(CFrame.new(cameraCFrame.Position, aimPos), Settings.Aimbot.Smoothness)
                    Camera.CFrame = newCFrame
                end
            end
        else
            AimbotTarget = nil
        end

        -- Cập nhật FOV Circle
        if FOVCircle then
            FOVCircle.Visible = Settings.Visuals.FOVCircle or Settings.Aimbot.Enabled
            FOVCircle.Radius = Settings.Aimbot.FOV
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end

        -- Cập nhật Aimbot Circle
        if AimbotCircle then
            AimbotCircle.Visible = Settings.Aimbot.Enabled
            AimbotCircle.Radius = Settings.Aimbot.FOV
            AimbotCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end)
end

-- ESP Functions
local function RemoveESP(player)
    local data = ESPData[player]
    if not data then return end
    if data.Connection then data.Connection:Disconnect() end
    if data.Box then pcall(function() data.Box:Destroy() end) end
    if data.Tracer then pcall(function() data.Tracer:Destroy() end) end
    if data.NameTag then pcall(function() data.NameTag:Destroy() end) end
    if data.HealthBar then pcall(function() data.HealthBar:Destroy() end) end
    if data.HealthBg then pcall(function() data.HealthBg:Destroy() end) end
    if data.DistanceTag then pcall(function() data.DistanceTag:Destroy() end) end
    ESPData[player] = nil
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

    ESPData[player] = {
        Box = nil, Tracer = nil, NameTag = nil,
        HealthBar = nil, HealthBg = nil, DistanceTag = nil,
        Connection = nil
    }

    if Drawing then
        -- Box
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = Settings.ESP.BoxColor
        box.Thickness = Settings.ESP.BoxThickness
        box.Transparency = 1
        box.Filled = false
        box.ZIndex = 1
        ESPData[player].Box = box

        -- Tracer
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Color = Settings.ESP.TracerColor
        tracer.Thickness = Settings.ESP.TracerThickness
        tracer.Transparency = 1
        tracer.ZIndex = 1
        ESPData[player].Tracer = tracer

        -- Name
        local nameTag = Drawing.new("Text")
        nameTag.Visible = false
        nameTag.Color = Settings.ESP.NameColor
        nameTag.Size = Settings.ESP.NameSize
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.OutlineColor = Color3.new(0, 0, 0)
        nameTag.ZIndex = 2
        ESPData[player].NameTag = nameTag

        -- Health Bar Background
        local healthBg = Drawing.new("Line")
        healthBg.Visible = false
        healthBg.Color = Color3.new(0, 0, 0)
        healthBg.Thickness = 3
        healthBg.Transparency = 1
        healthBg.ZIndex = 1
        ESPData[player].HealthBg = healthBg

        -- Health Bar
        local healthBar = Drawing.new("Line")
        healthBar.Visible = false
        healthBar.Color = Color3.new(0, 255, 0)
        healthBar.Thickness = 2
        healthBar.Transparency = 1
        healthBar.ZIndex = 2
        ESPData[player].HealthBar = healthBar

        -- Distance
        local distanceTag = Drawing.new("Text")
        distanceTag.Visible = false
        distanceTag.Color = Settings.ESP.DistanceColor
        distanceTag.Size = Settings.ESP.DistanceSize
        distanceTag.Center = true
        distanceTag.Outline = true
        distanceTag.OutlineColor = Color3.new(0, 0, 0)
        distanceTag.ZIndex = 2
        ESPData[player].DistanceTag = distanceTag
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        local data = ESPData[player]
        if not data then
            if connection then connection:Disconnect() end
            return
        end

        if not Settings.ESP.Enabled then
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
            return
        end

        if not player.Parent or not character or not character.Parent then
            RemoveESP(player)
            return
        end

        local hum = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local hd = character:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not hrp or not hd then
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
            return
        end

        -- Team check
        if LocalPlayer.Team and player.Team == LocalPlayer.Team then
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
            return
        end

        local rootPos = hrp.Position
        local headPos = hd.Position
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local distance = localRoot and (localRoot.Position - rootPos).Magnitude or 9999

        if distance > Settings.ESP.MaxDistance then
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
            return
        end

        local feetPos = rootPos - Vector3.new(0, 3, 0)
        local headTopPos = headPos + Vector3.new(0, 0.5, 0)
        local feetScreen, feetOnScreen, feetDepth = WorldToScreen(feetPos)
        local headScreen, headOnScreen = WorldToScreen(headTopPos)
        local centerScreen = WorldToScreen(rootPos)

        if not feetOnScreen or not headOnScreen or feetDepth < 0 then
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then obj.Visible = false end
            end
            return
        end

        local boxHeight = math.abs(headScreen.Y - feetScreen.Y)
        local boxWidth = boxHeight * 0.5

        -- Box
        if data.Box and Settings.ESP.Box then
            data.Box.Size = Vector2.new(boxWidth, boxHeight)
            data.Box.Position = Vector2.new(centerScreen.X - boxWidth/2, feetScreen.Y - boxHeight)
            data.Box.Visible = true
            data.Box.Color = Settings.ESP.BoxColor
        elseif data.Box then
            data.Box.Visible = false
        end

        -- Tracer
        if data.Tracer and Settings.ESP.Tracers then
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Tracer.To = Vector2.new(centerScreen.X, feetScreen.Y)
            data.Tracer.Visible = true
            data.Tracer.Color = Settings.ESP.TracerColor
        elseif data.Tracer then
            data.Tracer.Visible = false
        end

        -- Name
        if data.NameTag and Settings.ESP.Names then
            data.NameTag.Text = player.DisplayName or player.Name
            data.NameTag.Position = Vector2.new(centerScreen.X, headScreen.Y - 25)
            data.NameTag.Visible = true
            data.NameTag.Color = Settings.ESP.NameColor
        elseif data.NameTag then
            data.NameTag.Visible = false
        end

        -- Health Bar
        if data.HealthBar and Settings.ESP.HealthBar then
            local healthPercent = hum.Health / hum.MaxHealth
            local barX = centerScreen.X - boxWidth/2 - 5
            local barTop = feetScreen.Y - boxHeight
            local barBottom = feetScreen.Y
            local barHeight = boxHeight * healthPercent

            data.HealthBg.From = Vector2.new(barX, barTop)
            data.HealthBg.To = Vector2.new(barX, barBottom)
            data.HealthBg.Visible = true

            data.HealthBar.From = Vector2.new(barX, barBottom - barHeight)
            data.HealthBar.To = Vector2.new(barX, barBottom)
            data.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            data.HealthBar.Visible = true
        elseif data.HealthBar then
            data.HealthBar.Visible = false
            if data.HealthBg then data.HealthBg.Visible = false end
        end

        -- Distance
        if data.DistanceTag and Settings.ESP.Distance then
            data.DistanceTag.Text = math.floor(distance) .. "m"
            data.DistanceTag.Position = Vector2.new(centerScreen.X, feetScreen.Y + 5)
            data.DistanceTag.Visible = true
            data.DistanceTag.Color = Settings.ESP.DistanceColor
        elseif data.DistanceTag then
            data.DistanceTag.Visible = false
        end
    end)

    ESPData[player].Connection = connection
end

local function RefreshAllESP()
    for player in pairs(ESPData) do
        RemoveESP(player)
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end
end

-- Speed Hack
local function UpdateSpeed()
    if Settings.Other.SpeedHack then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Settings.Other.SpeedValue
            end
        end
    end
end

-- Build Tab Content
local function BuildESPTab(parent)
    local y = 5
    CreateToggle(parent, "Bật ESP", y, Settings.ESP.Enabled, function(state)
        Settings.ESP.Enabled = state
        if not state then
            for _, data in pairs(ESPData) do
                for _, obj in pairs(data) do
                    if obj and obj.Visible ~= nil then obj.Visible = false end
                end
            end
        else
            RefreshAllESP()
        end
    end)
    y = y + 35
    CreateToggle(parent, "Box ESP", y, Settings.ESP.Box, function(state)
        Settings.ESP.Box = state
        RefreshAllESP()
    end)
    y = y + 35
    CreateToggle(parent, "Tracers", y, Settings.ESP.Tracers, function(state)
        Settings.ESP.Tracers = state
        RefreshAllESP()
    end)
    y = y + 35
    CreateToggle(parent, "Tên", y, Settings.ESP.Names, function(state)
        Settings.ESP.Names = state
        RefreshAllESP()
    end)
    y = y + 35
    CreateToggle(parent, "Thanh máu", y, Settings.ESP.HealthBar, function(state)
        Settings.ESP.HealthBar = state
        RefreshAllESP()
    end)
    y = y + 35
    CreateToggle(parent, "Khoảng cách", y, Settings.ESP.Distance, function(state)
        Settings.ESP.Distance = state
        RefreshAllESP()
    end)
end

local function BuildAimbotTab(parent)
    local y = 5
    CreateToggle(parent, "Bật Aimbot", y, Settings.Aimbot.Enabled, function(state)
        Settings.Aimbot.Enabled = state
        if AimbotCircle then
            AimbotCircle.Visible = state
        end
    end)
    y = y + 35
    CreateToggle(parent, "Silent Aim", y, Settings.Aimbot.SilentAim, function(state)
        Settings.Aimbot.SilentAim = state
    end)
    y = y + 35
    CreateToggle(parent, "Visible Check", y, Settings.Aimbot.VisibleCheck, function(state)
        Settings.Aimbot.VisibleCheck = state
    end)
    y = y + 35
    CreateSlider(parent, "FOV", y, 0, 300, Settings.Aimbot.FOV, function(val)
        Settings.Aimbot.FOV = val
        if FOVCircle then
            FOVCircle.Radius = val
        end
        if AimbotCircle then
            AimbotCircle.Radius = val
        end
    end)
end

local function BuildVisualsTab(parent)
    local y = 5
    CreateToggle(parent, "FOV Circle", y, Settings.Visuals.FOVCircle, function(state)
        Settings.Visuals.FOVCircle = state
        if FOVCircle then
            FOVCircle.Visible = state
        end
    end)
end

local function BuildOtherTab(parent)
    local y = 5
    CreateToggle(parent, "Speed Hack", y, Settings.Other.SpeedHack, function(state)
        Settings.Other.SpeedHack = state
        if state then
            UpdateSpeed()
        else
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    end)
    y = y + 35
    CreateSlider(parent, "Tốc độ", y, 16, 100, Settings.Other.SpeedValue, function(val)
        Settings.Other.SpeedValue = val
        if Settings.Other.SpeedHack then
            UpdateSpeed()
        end
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
    MainFrame.Size = UDim2.new(0, 600, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, 0)
    sidebar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = MainFrame

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 10)
    sidebarCorner.Parent = sidebar

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title.BorderSizePixel = 0
    title.Text = "UNIVERSAL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = sidebar

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -130, 1, -10)
    contentArea.Position = UDim2.new(0, 125, 0, 5)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = MainFrame

    -- Tabs
    local tabs = {"ESP", "Aimbot", "Visuals", "Other"}
    local tabBuilders = {BuildESPTab, BuildAimbotTab, BuildVisualsTab, BuildOtherTab}

    for i, tabName in pairs(tabs) do
        -- Tab Button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 35)
        tabBtn.Position = UDim2.new(0, 5, 0, 50 + (i-1) * 40)
        tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(30, 30, 40)
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabName
        tabBtn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = sidebar

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn

        TabButtons[tabName] = tabBtn

        -- Tab Content Frame
        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = i == 1
        tabFrame.Parent = contentArea

        -- Scrolling Frame
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
        scroll.ScrollBarThickness = 4
        scroll.Parent = tabFrame

        TabFrames[tabName] = tabFrame

        -- Build content
        tabBuilders[i](scroll)

        -- Tab click
        tabBtn.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            for name, btn in pairs(TabButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            for name, frame in pairs(TabFrames) do
                frame.Visible = name == tabName
            end
        end)
    end

    return MenuGui
end

-- Khởi tạo
CreateMenu()

-- Tạo ESP ban đầu
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        CreateESP(player)
    end
end

-- Events
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.3)
            if Settings.ESP.Enabled then
                CreateESP(player)
            end
        end)
        if player.Character then
            CreateESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Aimbot Loop
coroutine.wrap(AimbotLoop)()

-- Speed Hack Loop
RunService.RenderStepped:Connect(function()
    if Settings.Other.SpeedHack then
        UpdateSpeed()
    end
end)

-- Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Menu.Keybind then
        Settings.Menu.Visible = not Settings.Menu.Visible
        if MenuGui then
            MenuGui.Enabled = Settings.Menu.Visible
        end
    end
end)

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    for player in pairs(ESPData) do
        RemoveESP(player)
    end
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
    if FOVCircle then FOVCircle:Destroy() end
    if AimbotCircle then AimbotCircle:Destroy() end
end)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Settings.ESP.Enabled then
        RefreshAllESP()
    end
    if Settings.Other.SpeedHack then
        UpdateSpeed()
    end
end)

Notify("✅ Universal Script Loaded! [Delete] Menu", 3)
print("Universal Script Loaded!")
print("ESP | Aimbot | Visuals | Other")