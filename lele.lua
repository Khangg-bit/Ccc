--[[
    TELEPORT TO HIDER SCRIPT - PAINT AND SEEK
    Dịch chuyển đến người chơi đang trốn
    Hỗ trợ: Delta Executor
    Game: Paint and Seek [CHRISTMAS]
    Fix: GUI hiển thị ngay lập tức
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Settings
local Settings = {
    Teleport = {
        Enabled = false,
        AutoTeleport = false,
        TeleportDelay = 1,
        TargetHiders = true,
        TargetSeekers = false,
        AvoidTeam = true,
        UseTween = true,
        TweenSpeed = 0.3,
        RandomTarget = true,
    },
    Menu = {
        Keybind = Enum.KeyCode.Delete,
        Visible = true,
        Minimized = false,
        Position = UDim2.new(0, 10, 0, 50)
    }
}

-- Biến toàn cục
local TeleportConnection = nil
local CurrentTarget = nil
local HiderList = {}
local SeekerList = {}
local PlayerListGui = nil

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Menu elements
local MenuGui
local MainFrame
local TargetInfoLabel
local MinimizeButton

-- Hàm tạo thông báo (dùng TextLabel thay vì Drawing)
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
    notifText.TextColor3 = Color3.fromRGB(0, 255, 100)
    notifText.TextSize = 16
    notifText.Font = Enum.Font.GothamBold
    notifText.Parent = notifFrame
    
    task.delay(duration or 2, function()
        pcall(function() notifGui:Destroy() end)
    end)
end

-- Tạo Toggle Button
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
        if callback then callback(state) end
    end)
    
    return {
        Button = btn,
        GetState = function() return state end,
        SetState = function(s)
            state = s
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
            btn.Text = state and "ON" or "OFF"
            if callback then callback(state) end
        end
    }
end

-- Tạo Button
local function CreateButton(parent, text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(70, 70, 100)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.new(
            math.min(color.R + 25, 255),
            math.min(color.G + 25, 255),
            math.min(color.B + 25, 255)
        )
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return btn
end

-- Phân loại người chơi
local function ClassifyPlayers()
    HiderList = {}
    SeekerList = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and humanoid.Health > 0 and rootPart then
                    if player.Team and LocalPlayer.Team then
                        if player.Team ~= LocalPlayer.Team then
                            table.insert(SeekerList, {
                                Player = player,
                                Character = character,
                                RootPart = rootPart,
                                Position = rootPart.Position,
                                Name = player.DisplayName or player.Name
                            })
                        else
                            table.insert(HiderList, {
                                Player = player,
                                Character = character,
                                RootPart = rootPart,
                                Position = rootPart.Position,
                                Name = player.DisplayName or player.Name
                            })
                        end
                    else
                        local isHiding = false
                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") and part.Transparency > 0.5 then
                                isHiding = true
                                break
                            end
                        end
                        
                        if isHiding then
                            table.insert(HiderList, {
                                Player = player,
                                Character = character,
                                RootPart = rootPart,
                                Position = rootPart.Position,
                                Name = player.DisplayName or player.Name
                            })
                        else
                            table.insert(SeekerList, {
                                Player = player,
                                Character = character,
                                RootPart = rootPart,
                                Position = rootPart.Position,
                                Name = player.DisplayName or player.Name
                            })
                        end
                    end
                end
            end
        end
    end
    
    return HiderList, SeekerList
end

-- Lấy mục tiêu ngẫu nhiên
local function GetRandomTarget()
    ClassifyPlayers()
    
    local targetList = {}
    
    if Settings.Teleport.TargetHiders then
        for _, hider in pairs(HiderList) do
            table.insert(targetList, hider)
        end
    end
    
    if Settings.Teleport.TargetSeekers then
        for _, seeker in pairs(SeekerList) do
            table.insert(targetList, seeker)
        end
    end
    
    if #targetList == 0 then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character then
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if rootPart and humanoid and humanoid.Health > 0 then
                        if Settings.Teleport.AvoidTeam and 
                           LocalPlayer.Team and player.Team == LocalPlayer.Team then
                            continue
                        end
                        
                        table.insert(targetList, {
                            Player = player,
                            Character = character,
                            RootPart = rootPart,
                            Position = rootPart.Position,
                            Name = player.DisplayName or player.Name
                        })
                    end
                end
            end
        end
    end
    
    if #targetList == 0 then return nil end
    
    local randomIndex = math.random(1, #targetList)
    return targetList[randomIndex]
end

-- Lấy mục tiêu gần nhất
local function GetNearestTarget()
    ClassifyPlayers()
    
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    local targetList = {}
    
    if Settings.Teleport.TargetHiders then
        for _, hider in pairs(HiderList) do
            table.insert(targetList, hider)
        end
    end
    
    if Settings.Teleport.TargetSeekers then
        for _, seeker in pairs(SeekerList) do
            table.insert(targetList, seeker)
        end
    end
    
    for _, target in pairs(targetList) do
        local distance = (localRoot.Position - target.Position).Magnitude
        
        if distance < nearestDistance then
            nearestDistance = distance
            nearestTarget = target
        end
    end
    
    return nearestTarget
end

-- Dịch chuyển đến mục tiêu
local function TeleportToTarget(target, useTween)
    if not target or not target.RootPart then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        CreateNotification("❌ Nhân vật đã chết!", 2)
        return false
    end
    
    local targetPos = target.RootPart.Position
    local offset = Vector3.new(
        math.random(-2, 2),
        0,
        math.random(-2, 2)
    )
    local finalPos = targetPos + offset
    
    if not useTween then
        pcall(function()
            rootPart.CFrame = CFrame.new(finalPos)
        end)
        
        if (rootPart.Position - finalPos).Magnitude < 5 then
            CreateNotification("✅ Đã đến: " .. target.Name, 2)
            CurrentTarget = target
            UpdateTargetInfo()
            return true
        end
    end
    
    if useTween then
        local tweenInfo = TweenInfo.new(
            Settings.Teleport.TweenSpeed,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        )
        
        local tween = TweenService:Create(rootPart, tweenInfo, {
            CFrame = CFrame.new(finalPos)
        })
        
        tween:Play()
        tween.Completed:Wait()
        
        CreateNotification("✅ Đã đến: " .. target.Name, 2)
        CurrentTarget = target
        UpdateTargetInfo()
        return true
    end
    
    pcall(function()
        humanoid:MoveTo(finalPos)
        task.wait(0.1)
    end)
    
    if (rootPart.Position - finalPos).Magnitude < 10 then
        CreateNotification("✅ Gần: " .. target.Name, 2)
        CurrentTarget = target
        UpdateTargetInfo()
        return true
    end
    
    CreateNotification("❌ Không thể dịch chuyển!", 2)
    return false
end

-- Cập nhật UI
local function UpdateTargetInfo()
    ClassifyPlayers()
    
    if TargetInfoLabel then
        local info = string.format(
            "👤 Trốn: %d | 🔍 Tìm: %d | 🎯: %s",
            #HiderList,
            #SeekerList,
            CurrentTarget and CurrentTarget.Name or "-"
        )
        TargetInfoLabel.Text = info
    end
    
    if MinimizeButton then
        local totalPlayers = #HiderList + #SeekerList
        MinimizeButton.Text = "🎯\n" .. totalPlayers
    end
end

-- Auto Teleport Loop
local function AutoTeleportLoop()
    while Settings.Teleport.AutoTeleport do
        UpdateTargetInfo()
        
        local target
        if Settings.Teleport.RandomTarget then
            target = GetRandomTarget()
        else
            target = GetNearestTarget()
        end
        
        if target then
            TeleportToTarget(target, Settings.Teleport.UseTween)
        end
        
        task.wait(Settings.Teleport.TeleportDelay)
    end
end

-- Bắt đầu Auto Teleport
local function StartAutoTeleport()
    if TeleportConnection then
        TeleportConnection = nil
    end
    
    Settings.Teleport.AutoTeleport = true
    TeleportConnection = coroutine.wrap(AutoTeleportLoop)
    TeleportConnection()
end

-- Dừng Auto Teleport
local function StopAutoTeleport()
    Settings.Teleport.AutoTeleport = false
    TeleportConnection = nil
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
    ClosePlayerList()
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
    UpdateTargetInfo()
end

-- Tạo icon thu nhỏ
local function CreateMinimizedIcon()
    MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizedTeleport"
    MinimizeButton.Size = UDim2.new(0, 45, 0, 45)
    MinimizeButton.Position = UDim2.new(0, 15, 0, 100)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "🎯\n0"
    MinimizeButton.TextColor3 = Color3.fromRGB(100, 255, 150)
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
    border.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    border.BackgroundTransparency = 0.5
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = MinimizeButton
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 25)
    borderCorner.Parent = border
    
    MinimizeButton.MouseEnter:Connect(function()
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    end)
    
    MinimizeButton.MouseButton1Click:Connect(function()
        MaximizeMenu()
    end)
    
    return MinimizeButton
end

-- Đóng danh sách người chơi
function ClosePlayerList()
    if PlayerListGui then
        PlayerListGui:Destroy()
        PlayerListGui = nil
    end
end

-- Hiển thị danh sách người chơi
function ShowPlayerList()
    if PlayerListGui then
        ClosePlayerList()
        return
    end
    
    ClassifyPlayers()
    
    PlayerListGui = Instance.new("ScreenGui")
    PlayerListGui.Name = "PlayerList"
    PlayerListGui.Parent = CoreGui
    PlayerListGui.ResetOnSpawn = false
    
    local bgBlur = Instance.new("TextButton")
    bgBlur.Size = UDim2.new(1, 0, 1, 0)
    bgBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgBlur.BackgroundTransparency = 0.5
    bgBlur.BorderSizePixel = 0
    bgBlur.Text = ""
    bgBlur.AutoButtonColor = false
    bgBlur.Parent = PlayerListGui
    
    bgBlur.MouseButton1Click:Connect(function()
        ClosePlayerList()
    end)
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0, 230, 0, 350)
    listFrame.Position = UDim2.new(0.5, -115, 0.5, -175)
    listFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    listFrame.BorderSizePixel = 0
    listFrame.Active = true
    listFrame.Draggable = true
    listFrame.Parent = PlayerListGui
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 10)
    listCorner.Parent = listFrame
    
    -- Title
    local listTitle = Instance.new("Frame")
    listTitle.Size = UDim2.new(1, 0, 0, 38)
    listTitle.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    listTitle.BorderSizePixel = 0
    listTitle.Parent = listFrame
    
    local listTitleCorner = Instance.new("UICorner")
    listTitleCorner.CornerRadius = UDim.new(0, 10)
    listTitleCorner.Parent = listTitle
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "👥 NGƯỜI CHƠI"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 15
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = listTitle
    
    local closeX = Instance.new("TextButton")
    closeX.Size = UDim2.new(0, 25, 0, 25)
    closeX.Position = UDim2.new(1, -32, 0.5, -12)
    closeX.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeX.BorderSizePixel = 0
    closeX.Text = "✕"
    closeX.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeX.TextSize = 14
    closeX.Font = Enum.Font.GothamBold
    closeX.AutoButtonColor = false
    closeX.Parent = listTitle
    
    local closeXCorner = Instance.new("UICorner")
    closeXCorner.CornerRadius = UDim.new(0, 13)
    closeXCorner.Parent = closeX
    
    closeX.MouseButton1Click:Connect(function()
        ClosePlayerList()
    end)
    
    -- Scrolling Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -83)
    scrollFrame.Position = UDim2.new(0, 5, 0, 43)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 255, 150)
    scrollFrame.Parent = listFrame
    
    local scrollList = Instance.new("UIListLayout")
    scrollList.Padding = UDim.new(0, 4)
    scrollList.Parent = scrollFrame
    
    local ySize = 0
    
    if #HiderList > 0 then
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -5, 0, 22)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "🟢 TRỐN (" .. #HiderList .. ")"
        headerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        headerLabel.TextSize = 12
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.Parent = scrollFrame
        ySize = ySize + 26
        
        for _, hider in pairs(HiderList) do
            local playerBtn = Instance.new("TextButton")
            playerBtn.Size = UDim2.new(1, -5, 0, 30)
            playerBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            playerBtn.BorderSizePixel = 0
            playerBtn.Text = "  🟢 " .. hider.Name
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerBtn.TextSize = 12
            playerBtn.TextXAlignment = Enum.TextXAlignment.Left
            playerBtn.Font = Enum.Font.Gotham
            playerBtn.AutoButtonColor = false
            playerBtn.Parent = scrollFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = playerBtn
            
            playerBtn.MouseButton1Click:Connect(function()
                TeleportToTarget(hider, Settings.Teleport.UseTween)
                ClosePlayerList()
                UpdateTargetInfo()
            end)
            
            ySize = ySize + 34
        end
    end
    
    if #SeekerList > 0 then
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -5, 0, 22)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "🔴 TÌM (" .. #SeekerList .. ")"
        headerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        headerLabel.TextSize = 12
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.Parent = scrollFrame
        ySize = ySize + 26
        
        for _, seeker in pairs(SeekerList) do
            local playerBtn = Instance.new("TextButton")
            playerBtn.Size = UDim2.new(1, -5, 0, 30)
            playerBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 45)
            playerBtn.BorderSizePixel = 0
            playerBtn.Text = "  🔴 " .. seeker.Name
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerBtn.TextSize = 12
            playerBtn.TextXAlignment = Enum.TextXAlignment.Left
            playerBtn.Font = Enum.Font.Gotham
            playerBtn.AutoButtonColor = false
            playerBtn.Parent = scrollFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = playerBtn
            
            playerBtn.MouseButton1Click:Connect(function()
                TeleportToTarget(seeker, Settings.Teleport.UseTween)
                ClosePlayerList()
                UpdateTargetInfo()
            end)
            
            ySize = ySize + 34
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -20, 0, 30)
    closeBtn.Position = UDim2.new(0, 10, 1, -35)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "ĐÓNG [ESC]"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = listFrame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 5)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        ClosePlayerList()
    end)
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "TeleportMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = Settings.Menu.Visible and not Settings.Menu.Minimized
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 230, 0, 370)
    MainFrame.Position = Settings.Menu.Position
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
    border.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
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
    title.Text = "🎯 TELEPORT"
    title.TextColor3 = Color3.fromRGB(100, 255, 150)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    -- Target Info
    TargetInfoLabel = Instance.new("TextLabel")
    TargetInfoLabel.Size = UDim2.new(1, -16, 0, 22)
    TargetInfoLabel.Position = UDim2.new(0, 8, 0, 43)
    TargetInfoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    TargetInfoLabel.BorderSizePixel = 0
    TargetInfoLabel.Text = "👤 Trốn: 0 | 🔍 Tìm: 0 | 🎯: -"
    TargetInfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TargetInfoLabel.TextSize = 11
    TargetInfoLabel.Font = Enum.Font.Gotham
    TargetInfoLabel.Parent = MainFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 5)
    infoCorner.Parent = TargetInfoLabel
    
    -- Buttons
    local btnY = 72
    
    CreateButton(MainFrame, "🎲 Dịch chuyển ngẫu nhiên", btnY, 
        Color3.fromRGB(0, 180, 90), function()
        local target = GetRandomTarget()
        if target then
            TeleportToTarget(target, Settings.Teleport.UseTween)
        else
            CreateNotification("❌ Không tìm thấy mục tiêu!", 2)
        end
    end)
    
    btnY = btnY + 38
    
    CreateButton(MainFrame, "📍 Dịch chuyển gần nhất", btnY, 
        Color3.fromRGB(0, 130, 180), function()
        local target = GetNearestTarget()
        if target then
            TeleportToTarget(target, Settings.Teleport.UseTween)
        else
            CreateNotification("❌ Không tìm thấy mục tiêu!", 2)
        end
    end)
    
    btnY = btnY + 38
    
    CreateButton(MainFrame, "👥 Danh sách người chơi", btnY, 
        Color3.fromRGB(160, 120, 0), function()
        ShowPlayerList()
    end)
    
    btnY = btnY + 42
    
    -- Separator
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -16, 0, 1)
    sep.Position = UDim2.new(0, 8, 0, btnY)
    sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sep.BorderSizePixel = 0
    sep.Parent = MainFrame
    
    btnY = btnY + 10
    
    CreateToggle(MainFrame, "🤖 Auto Teleport", btnY, 
        Settings.Teleport.AutoTeleport, function(state)
        Settings.Teleport.AutoTeleport = state
        if state then
            StartAutoTeleport()
        else
            StopAutoTeleport()
        end
    end)
    
    btnY = btnY + 32
    
    CreateToggle(MainFrame, "🎯 Nhắm người trốn", btnY, 
        Settings.Teleport.TargetHiders, function(state)
        Settings.Teleport.TargetHiders = state
    end)
    
    btnY = btnY + 32
    
    CreateToggle(MainFrame, "🔍 Nhắm người tìm", btnY, 
        Settings.Teleport.TargetSeekers, function(state)
        Settings.Teleport.TargetSeekers = state
    end)
    
    btnY = btnY + 32
    
    CreateToggle(MainFrame, "🚫 Tránh đồng đội", btnY, 
        Settings.Teleport.AvoidTeam, function(state)
        Settings.Teleport.AvoidTeam = state
    end)
    
    btnY = btnY + 32
    
    CreateToggle(MainFrame, "🎲 Ngẫu nhiên", btnY, 
        Settings.Teleport.RandomTarget, function(state)
        Settings.Teleport.RandomTarget = state
    end)
    
    btnY = btnY + 32
    
    CreateToggle(MainFrame, "✨ Mượt", btnY, 
        Settings.Teleport.UseTween, function(state)
        Settings.Teleport.UseTween = state
    end)
    
    btnY = btnY + 42
    
    CreateButton(MainFrame, "📌 Thu nhỏ menu", btnY, 
        Color3.fromRGB(220, 130, 40), function()
        MinimizeMenu()
    end)
    
    return MenuGui
end

-- Khởi tạo tất cả GUI
print("Đang tạo GUI...")
MenuGui = CreateMenu()
MinimizeButton = CreateMinimizedIcon()
print("GUI đã được tạo thành công!")

-- Cập nhật info
coroutine.wrap(function()
    while task.wait(0.8) do
        pcall(UpdateTargetInfo)
    end
end)()

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

-- Keybind ESC
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Escape then
        if PlayerListGui then
            ClosePlayerList()
        end
    end
end)

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    StopAutoTeleport()
    ClosePlayerList()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

-- Thông báo khi load thành công
task.wait(0.5)
CreateNotification("🎯 Teleport Loaded! [Delete] Menu", 3)

print("=================================")
print("🎯 TELEPORT SCRIPT LOADED!")
print("📋 Delete = Thu nhỏ/Mở Menu")
print("🖱️ Click icon = Mở menu")
print("❌ ESC = Tắt danh sách")
print("=================================")