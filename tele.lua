--[[
    TELEPORT TO HIDER SCRIPT - PAINT AND SEEK
    Dịch chuyển đến người chơi đang trốn
    Hỗ trợ: Delta Executor
    Game: Paint and Seek [CHRISTMAS]
    Fix: Menu thu nhỏ thành icon kéo được
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
        Position = UDim2.new(0, 20, 0, 100)
    }
}

-- Biến toàn cục
local TeleportConnection = nil
local CurrentTarget = nil
local PlayerList = {}
local HiderList = {}
local SeekerList = {}

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

-- Hàm tạo thông báo nổi
local function CreateNotification(text, duration)
    if not Drawing or not Drawing.new then return end
    
    local notif = Drawing.new("Text")
    notif.Text = text
    notif.Size = 20
    notif.Color = Color3.fromRGB(0, 255, 100)
    notif.Center = true
    notif.Outline = true
    notif.OutlineColor = Color3.new(0, 0, 0)
    notif.Position = Vector2.new(
        workspace.CurrentCamera.ViewportSize.X / 2,
        workspace.CurrentCamera.ViewportSize.Y - 100
    )
    notif.Visible = true
    
    task.delay(duration or 2, function()
        pcall(function() notif:Destroy() end)
    end)
    
    return notif
end

-- Tạo Toggle Button
local function CreateToggle(parent, text, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(1, -50, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
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

-- Tạo Button thường
local function CreateButton(parent, text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(70, 70, 100)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.new(
            math.min(color.R + 30, 255),
            math.min(color.G + 30, 255),
            math.min(color.B + 30, 255)
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
            CreateNotification("✅ Dịch chuyển đến: " .. target.Name, 2)
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
        
        CreateNotification("✅ Dịch chuyển đến: " .. target.Name, 2)
        CurrentTarget = target
        UpdateTargetInfo()
        return true
    end
    
    pcall(function()
        humanoid:MoveTo(finalPos)
        task.wait(0.1)
    end)
    
    if (rootPart.Position - finalPos).Magnitude < 10 then
        CreateNotification("✅ Đã đến gần: " .. target.Name, 2)
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
            "👤 Hiders: %d | 🔍 Seekers: %d\n🎯 Target: %s",
            #HiderList,
            #SeekerList,
            CurrentTarget and CurrentTarget.Name or "None"
        )
        TargetInfoLabel.Text = info
    end
    
    -- Cập nhật text trên icon thu nhỏ
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
    print("📌 Menu đã thu nhỏ - Click icon để mở lại")
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
    print("📂 Menu đã mở rộng")
end

-- Tạo icon thu nhỏ có thể kéo
local function CreateMinimizedIcon()
    MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizedTeleport"
    MinimizeButton.Size = UDim2.new(0, 55, 0, 55)
    MinimizeButton.Position = UDim2.new(0, 20, 0, 100)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "🎯\n0"
    MinimizeButton.TextColor3 = Color3.fromRGB(100, 255, 150)
    MinimizeButton.TextSize = 16
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Active = true
    MinimizeButton.Draggable = true
    MinimizeButton.Visible = Settings.Menu.Minimized
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = ScreenGui
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 28)
    iconCorner.Parent = MinimizeButton
    
    -- Border glow effect
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 6, 1, 6)
    border.Position = UDim2.new(0, -3, 0, -3)
    border.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    border.BackgroundTransparency = 0.4
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = MinimizeButton
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 31)
    borderCorner.Parent = border
    
    -- Hiệu ứng hover
    MinimizeButton.MouseEnter:Connect(function()
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        border.BackgroundTransparency = 0.2
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        border.BackgroundTransparency = 0.4
    end)
    
    -- Click để mở lại menu
    MinimizeButton.MouseButton1Click:Connect(function()
        MaximizeMenu()
    end)
    
    return MinimizeButton
end

-- Hiển thị danh sách người chơi
function ShowPlayerList()
    ClassifyPlayers()
    
    local subMenu = Instance.new("ScreenGui")
    subMenu.Name = "PlayerList"
    subMenu.Parent = CoreGui
    subMenu.ResetOnSpawn = false
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0, 250, 0, 400)
    listFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
    listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 37)
    listFrame.BorderSizePixel = 0
    listFrame.Active = true
    listFrame.Draggable = true
    listFrame.Parent = subMenu
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 10)
    listCorner.Parent = listFrame
    
    -- Title
    local listTitle = Instance.new("TextLabel")
    listTitle.Size = UDim2.new(1, 0, 0, 40)
    listTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 47)
    listTitle.BorderSizePixel = 0
    listTitle.Text = "👥 DANH SÁCH NGƯỜI CHƠI"
    listTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    listTitle.TextSize = 16
    listTitle.Font = Enum.Font.GothamBold
    listTitle.Parent = listFrame
    
    local listTitleCorner = Instance.new("UICorner")
    listTitleCorner.CornerRadius = UDim.new(0, 10)
    listTitleCorner.Parent = listTitle
    
    -- Scrolling Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -90)
    scrollFrame.Position = UDim2.new(0, 5, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = listFrame
    
    local scrollList = Instance.new("UIListLayout")
    scrollList.Padding = UDim.new(0, 5)
    scrollList.Parent = scrollFrame
    
    local ySize = 0
    
    -- Người trốn (Hiders)
    if #HiderList > 0 then
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -10, 0, 25)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "🟢 NGƯỜI TRỐN (" .. #HiderList .. ")"
        headerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        headerLabel.TextSize = 14
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.Parent = scrollFrame
        ySize = ySize + 30
        
        for _, hider in pairs(HiderList) do
            local playerBtn = Instance.new("TextButton")
            playerBtn.Size = UDim2.new(1, -10, 0, 35)
            playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            playerBtn.BorderSizePixel = 0
            playerBtn.Text = "🟢 " .. hider.Name
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerBtn.TextSize = 13
            playerBtn.TextXAlignment = Enum.TextXAlignment.Left
            playerBtn.Font = Enum.Font.Gotham
            playerBtn.AutoButtonColor = false
            playerBtn.Parent = scrollFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = playerBtn
            
            playerBtn.MouseButton1Click:Connect(function()
                TeleportToTarget(hider, Settings.Teleport.UseTween)
                subMenu:Destroy()
                UpdateTargetInfo()
            end)
            
            ySize = ySize + 40
        end
    end
    
    -- Người tìm (Seekers)
    if #SeekerList > 0 then
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, -10, 0, 25)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "🔴 NGƯỜI TÌM (" .. #SeekerList .. ")"
        headerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        headerLabel.TextSize = 14
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.Parent = scrollFrame
        ySize = ySize + 30
        
        for _, seeker in pairs(SeekerList) do
            local playerBtn = Instance.new("TextButton")
            playerBtn.Size = UDim2.new(1, -10, 0, 35)
            playerBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 50)
            playerBtn.BorderSizePixel = 0
            playerBtn.Text = "🔴 " .. seeker.Name
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerBtn.TextSize = 13
            playerBtn.TextXAlignment = Enum.TextXAlignment.Left
            playerBtn.Font = Enum.Font.Gotham
            playerBtn.AutoButtonColor = false
            playerBtn.Parent = scrollFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = playerBtn
            
            playerBtn.MouseButton1Click:Connect(function()
                TeleportToTarget(seeker, Settings.Teleport.UseTween)
                subMenu:Destroy()
                UpdateTargetInfo()
            end)
            
            ySize = ySize + 40
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -20, 0, 35)
    closeBtn.Position = UDim2.new(0, 10, 1, -40)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "ĐÓNG"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = listFrame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        subMenu:Destroy()
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
    MainFrame.Size = UDim2.new(0, 270, 0, 500)
    MainFrame.Position = Settings.Menu.Position
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = MainFrame
    
    -- Gradient Border Effect
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 4, 1, 4)
    border.Position = UDim2.new(0, -2, 0, -2)
    border.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    border.BorderSizePixel = 0
    border.BackgroundTransparency = 0.5
    border.ZIndex = 0
    border.Parent = MainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 13)
    borderCorner.Parent = border
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Minimize Button (nút thu nhỏ ở góc phải)
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 30, 0, 30)
    miniBtn.Position = UDim2.new(1, -38, 0.5, -15)
    miniBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    miniBtn.BorderSizePixel = 0
    miniBtn.Text = "—"
    miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    miniBtn.TextSize = 20
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.AutoButtonColor = false
    miniBtn.Parent = titleBar
    
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0, 5)
    miniCorner.Parent = miniBtn
    
    miniBtn.MouseButton1Click:Connect(function()
        MinimizeMenu()
    end)
    
    local titleIcon = Instance.new("TextLabel")
    titleIcon.Size = UDim2.new(0, 30, 0, 30)
    titleIcon.Position = UDim2.new(0, 15, 0.5, -15)
    titleIcon.BackgroundTransparency = 1
    titleIcon.Text = "🎯"
    titleIcon.TextSize = 24
    titleIcon.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 50, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "TELEPORT TO HIDER"
    title.TextColor3 = Color3.fromRGB(100, 255, 150)
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -20, 0, 1)
    separator.Position = UDim2.new(0, 10, 0, 55)
    separator.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    separator.BackgroundTransparency = 0.7
    separator.BorderSizePixel = 0
    separator.Parent = MainFrame
    
    -- Target Info
    TargetInfoLabel = Instance.new("TextLabel")
    TargetInfoLabel.Size = UDim2.new(1, -20, 0, 50)
    TargetInfoLabel.Position = UDim2.new(0, 10, 0, 65)
    TargetInfoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    TargetInfoLabel.BorderSizePixel = 0
    TargetInfoLabel.Text = "👤 Hiders: 0 | 🔍 Seekers: 0\n🎯 Target: None"
    TargetInfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TargetInfoLabel.TextSize = 13
    TargetInfoLabel.Font = Enum.Font.Gotham
    TargetInfoLabel.TextWrapped = true
    TargetInfoLabel.Parent = MainFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = TargetInfoLabel
    
    -- Buttons
    local btnY = 125
    
    CreateButton(MainFrame, "🎲 DỊCH CHUYỂN NGẪU NHIÊN", btnY, 
        Color3.fromRGB(0, 200, 100), function()
        local target = GetRandomTarget()
        if target then
            TeleportToTarget(target, Settings.Teleport.UseTween)
            UpdateTargetInfo()
        else
            CreateNotification("❌ Không tìm thấy mục tiêu!", 2)
        end
    end)
    
    btnY = btnY + 50
    
    CreateButton(MainFrame, "📍 DỊCH CHUYỂN GẦN NHẤT", btnY, 
        Color3.fromRGB(0, 150, 200), function()
        local target = GetNearestTarget()
        if target then
            TeleportToTarget(target, Settings.Teleport.UseTween)
            UpdateTargetInfo()
        else
            CreateNotification("❌ Không tìm thấy mục tiêu!", 2)
        end
    end)
    
    btnY = btnY + 50
    
    CreateButton(MainFrame, "🎯 CHỌN MỤC TIÊU CỤ THỂ", btnY, 
        Color3.fromRGB(200, 150, 0), function()
        ShowPlayerList()
    end)
    
    btnY = btnY + 55
    
    -- Separator 2
    local separator2 = Instance.new("Frame")
    separator2.Size = UDim2.new(1, -20, 0, 1)
    separator2.Position = UDim2.new(0, 10, 0, btnY)
    separator2.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    separator2.BackgroundTransparency = 0.5
    separator2.BorderSizePixel = 0
    separator2.Parent = MainFrame
    
    btnY = btnY + 15
    
    -- Toggles
    CreateToggle(MainFrame, "🤖 Auto Teleport", btnY, 
        Settings.Teleport.AutoTeleport, function(state)
        Settings.Teleport.AutoTeleport = state
        if state then
            StartAutoTeleport()
        else
            StopAutoTeleport()
        end
    end)
    
    btnY = btnY + 40
    
    CreateToggle(MainFrame, "🎯 Nhắm người trốn", btnY, 
        Settings.Teleport.TargetHiders, function(state)
        Settings.Teleport.TargetHiders = state
    end)
    
    btnY = btnY + 40
    
    CreateToggle(MainFrame, "🔍 Nhắm người tìm", btnY, 
        Settings.Teleport.TargetSeekers, function(state)
        Settings.Teleport.TargetSeekers = state
    end)
    
    btnY = btnY + 40
    
    CreateToggle(MainFrame, "🚫 Tránh đồng đội", btnY, 
        Settings.Teleport.AvoidTeam, function(state)
        Settings.Teleport.AvoidTeam = state
    end)
    
    btnY = btnY + 40
    
    CreateToggle(MainFrame, "🎲 Mục tiêu ngẫu nhiên", btnY, 
        Settings.Teleport.RandomTarget, function(state)
        Settings.Teleport.RandomTarget = state
    end)
    
    btnY = btnY + 40
    
    CreateToggle(MainFrame, "✨ Dịch chuyển mượt", btnY, 
        Settings.Teleport.UseTween, function(state)
        Settings.Teleport.UseTween = state
    end)
    
    btnY = btnY + 55
    
    -- Nút Thu Nhỏ (thay vì Đóng hẳn)
    CreateButton(MainFrame, "📌 THU NHỎ MENU", btnY, 
        Color3.fromRGB(255, 150, 50), function()
        MinimizeMenu()
    end)
    
    return MenuGui
end

-- Tạo Menu và Icon
MenuGui = CreateMenu()
MinimizeButton = CreateMinimizedIcon()

-- Cập nhật info định kỳ
coroutine.wrap(function()
    while task.wait(1) do
        UpdateTargetInfo()
    end
end)()

-- Toggle Keybind
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
    StopAutoTeleport()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

-- Thông báo khi load
task.delay(0.5, function()
    CreateNotification("🎯 Teleport Script Loaded!\n[Delete] để thu nhỏ/mở menu", 3)
    
    print("=================================")
    print("🎯 TELEPORT TO HIDER LOADED!")
    print("📋 Delete = Thu nhỏ/Mở Menu")
    print("🖱️ Kéo icon để di chuyển")
    print("🎮 Game: Paint and Seek")
    print("=================================")
end)