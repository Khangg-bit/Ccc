--[[
    KILL AURA SCRIPT - DELTA EXECUTOR
    Tự động tấn công người chơi xung quanh
    Hỗ trợ: Dao, kiếm, tool và tất cả vũ khí
    Phím tắt: Delete để mở/tắt menu
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Settings
local Settings = {
    KillAura = {
        Enabled = false,
        Range = 15, -- Phạm vi tấn công (studs)
        TargetTeam = false, -- Tấn công đồng đội
        AttackMethod = "Auto", -- Auto, Click, Equip
        FOV = 360, -- Góc tấn công (độ)
        FOVVisible = false, -- Hiển thị vòng tròn FOV
        Delay = 0.1, -- Thời gian giữa các lần tấn công
    },
    Menu = {
        Keybind = Enum.KeyCode.Delete,
        Visible = true
    }
}

-- Biến toàn cục
local KillAuraConnection = nil
local CurrentTool = nil
local HitConnections = {}

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillAuraGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- FOV Circle
local FOVCircle = nil
if Drawing and Drawing.new then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(255, 50, 50)
    FOVCircle.Thickness = 1
    FOVCircle.Transparency = 0.7
    FOVCircle.Filled = false
    FOVCircle.Radius = 100
    FOVCircle.Position = Vector2.new(0, 0)
end

-- Menu elements
local MenuGui
local MainFrame
local SliderConnections = {}

-- Hàm tạo Toggle
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
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(1, -50, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
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
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    
    return {
        Button = btn,
        GetState = function() return state end,
        SetState = function(s)
            state = s
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end
    }
end

-- Hàm tạo Slider
local function CreateSlider(parent, text, yPos, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -10, 0, 20)
    sliderFrame.Position = UDim2.new(0, 5, 0, 25)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 10)
    sliderCorner.Parent = sliderFrame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = fill
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 20, 0, 20)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -10, 0, 0)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""
    sliderBtn.AutoButtonColor = false
    sliderBtn.Parent = sliderFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = sliderBtn
    
    local isDragging = false
    local currentValue = default
    
    local function updateSlider(input)
        local mousePos = input.Position.X
        local sliderPos = sliderFrame.AbsolutePosition.X
        local sliderWidth = sliderFrame.AbsoluteSize.X
        
        local percent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
        currentValue = min + (max - min) * percent
        currentValue = math.floor(currentValue * 10) / 10
        
        fill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -10, 0, 0)
        label.Text = text .. ": " .. currentValue
        
        callback(currentValue)
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
            sliderBtn.Position = UDim2.new(percent, -10, 0, 0)
            label.Text = text .. ": " .. val
            callback(val)
        end
    }
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "KillAuraMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = Settings.Menu.Visible
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame
    
    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 25, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚔️ KILL AURA"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    -- Status Indicator
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 10, 0, 10)
    statusIndicator.Position = UDim2.new(0, 10, 0.5, -5)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = titleBar
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 5)
    statusCorner.Parent = statusIndicator
    
    -- Toggles
    local function updateStatusIndicator()
        if statusIndicator then
            statusIndicator.BackgroundColor3 = Settings.KillAura.Enabled and 
                Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        end
    end
    
    CreateToggle(MainFrame, "Kill Aura", 55, Settings.KillAura.Enabled, function(state)
        Settings.KillAura.Enabled = state
        updateStatusIndicator()
        if state then
            StartKillAura()
        else
            StopKillAura()
        end
    end)
    
    CreateToggle(MainFrame, "Tấn công đồng đội", 95, Settings.KillAura.TargetTeam, function(state)
        Settings.KillAura.TargetTeam = state
    end)
    
    CreateToggle(MainFrame, "Hiện vòng tròn FOV", 135, Settings.KillAura.FOVVisible, function(state)
        Settings.KillAura.FOVVisible = state
        if FOVCircle then
            FOVCircle.Visible = state and Settings.KillAura.Enabled
        end
    end)
    
    -- Sliders
    local rangeSlider = CreateSlider(MainFrame, "🔴 Phạm vi (studs)", 180, 5, 50, Settings.KillAura.Range, function(val)
        Settings.KillAura.Range = val
        if FOVCircle then
            FOVCircle.Radius = val * 10
        end
    end)
    
    local delaySlider = CreateSlider(MainFrame, "⏱️ Tốc độ đánh (giây)", 245, 0.05, 1, Settings.KillAura.Delay, function(val)
        Settings.KillAura.Delay = val
    end)
    
    local fovSlider = CreateSlider(MainFrame, "👁️ Góc FOV (độ)", 310, 30, 360, Settings.KillAura.FOV, function(val)
        Settings.KillAura.FOV = val
    end)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 100, 0, 35)
    closeBtn.Position = UDim2.new(0.5, -50, 0, 375)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "ĐÓNG MENU"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = MainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        Settings.Menu.Visible = false
        MenuGui.Enabled = false
    end)
    
    updateStatusIndicator()
    return MenuGui
end

-- Lấy tool tốt nhất trong inventory
local function GetBestWeapon()
    local backpack = LocalPlayer.Backpack
    local character = LocalPlayer.Character
    
    local tools = {}
    
    -- Thu thập tool từ backpack
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    -- Thu thập tool đang cầm
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if #tools == 0 then return nil end
    
    -- Ưu tiên tool có thể gây sát thương
    -- Kiểm tra tool có Handle và script tấn công
    for _, tool in pairs(tools) do
        local handle = tool:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            -- Kiểm tra các thuộc tính đặc biệt
            if tool:FindFirstChild("Damage") or 
               tool:FindFirstChild("DamageScript") or
               tool:FindFirstChild("SlashScript") or
               tool:FindFirstChild("StabScript") then
                return tool
            end
        end
    end
    
    -- Nếu không tìm thấy tool đặc biệt, trả về tool đầu tiên
    return tools[1]
end

-- Kích hoạt tấn công với tool
local function AttackWithTool(tool, target)
    if not tool or not target then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Đảm bảo tool được trang bị
    if tool.Parent ~= character then
        -- Trang bị tool
        humanoid:EquipTool(tool)
        task.wait(0.05) -- Đợi tool equip
    end
    
    -- Phương pháp 1: Sử dụng Activate
    pcall(function()
        if tool:FindFirstChild("Handle") then
            -- Di chuyển character đến gần mục tiêu
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local targetRoot = target:FindFirstChild("HumanoidRootPart")
            
            if rootPart and targetRoot then
                -- Tính toán hướng
                local direction = (targetRoot.Position - rootPart.Position).unit
                
                -- Cập nhật hướng nhìn
                character:SetPrimaryPartCFrame(CFrame.new(rootPart.Position, rootPart.Position + direction * 10))
            end
            
            -- Kích hoạt tool
            tool:Activate()
            
            -- Đợi một chút rồi deactivate
            task.wait(0.1)
            pcall(function()
                tool:Deactivate()
            end)
        end
    end)
    
    -- Phương pháp 2: Fire RemoteEvent nếu có
    pcall(function()
        local handle = tool:FindFirstChild("Handle")
        if handle then
            -- Tìm remote events trong tool
            for _, child in pairs(tool:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    -- Fire remote với thông tin mục tiêu
                    pcall(function()
                        child:FireServer(target)
                    end)
                end
            end
        end
    end)
    
    -- Phương pháp 3: Click chuột ảo
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(
            workspace.CurrentCamera.ViewportSize.X / 2,
            workspace.CurrentCamera.ViewportSize.Y / 2,
            0,
            true,
            game,
            1
        )
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(
            workspace.CurrentCamera.ViewportSize.X / 2,
            workspace.CurrentCamera.ViewportSize.Y / 2,
            0,
            false,
            game,
            1
        )
    end)
    
    return true
end

-- Kiểm tra mục tiêu có trong FOV không
local function IsInFOV(target)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not targetRoot then return false end
    
    -- Tính khoảng cách
    local distance = (rootPart.Position - targetRoot.Position).Magnitude
    if distance > Settings.KillAura.Range then return false end
    
    -- Tính góc
    local lookVector = rootPart.CFrame.LookVector
    local direction = (targetRoot.Position - rootPart.Position).unit
    local angle = math.acos(lookVector:Dot(direction))
    local angleDeg = math.deg(angle)
    
    return angleDeg <= (Settings.KillAura.FOV / 2)
end

-- Lấy mục tiêu gần nhất
local function GetNearestTarget()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                
                if targetHumanoid and targetHumanoid.Health > 0 and targetRoot then
                    -- Kiểm tra team
                    if not Settings.KillAura.TargetTeam and 
                       LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        continue
                    end
                    
                    -- Tính khoảng cách
                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                    
                    -- Kiểm tra phạm vi và FOV
                    if distance <= Settings.KillAura.Range then
                        if Settings.KillAura.FOV >= 360 or IsInFOV(targetChar) then
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestTarget = targetChar
                            end
                        end
                    end
                end
            end
        end
    end
    
    return nearestTarget
end

-- Main Kill Aura Loop
local function KillAuraLoop()
    while Settings.KillAura.Enabled do
        -- Lấy mục tiêu gần nhất
        local target = GetNearestTarget()
        
        if target then
            -- Lấy tool tốt nhất
            local weapon = GetBestWeapon()
            
            if weapon then
                -- Tấn công với tool
                AttackWithTool(weapon, target)
            else
                -- Nếu không có tool, vẫn tấn công bằng click
                local character = LocalPlayer.Character
                if character then
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local targetRoot = target:FindFirstChild("HumanoidRootPart")
                    
                    if rootPart and targetRoot then
                        -- Hướng về mục tiêu
                        local direction = (targetRoot.Position - rootPart.Position).unit
                        character:SetPrimaryPartCFrame(CFrame.new(rootPart.Position, rootPart.Position + direction * 10))
                        
                        -- Click để tấn công
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(
                                workspace.CurrentCamera.ViewportSize.X / 2,
                                workspace.CurrentCamera.ViewportSize.Y / 2,
                                0,
                                true,
                                game,
                                1
                            )
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(
                                workspace.CurrentCamera.ViewportSize.X / 2,
                                workspace.CurrentCamera.ViewportSize.Y / 2,
                                0,
                                false,
                                game,
                                1
                            )
                        end)
                    end
                end
            end
        end
        
        -- Cập nhật FOV Circle
        if FOVCircle and Settings.KillAura.FOVVisible then
            local camera = workspace.CurrentCamera
            if camera then
                FOVCircle.Position = Vector2.new(
                    camera.ViewportSize.X / 2,
                    camera.ViewportSize.Y / 2
                )
                FOVCircle.Radius = Settings.KillAura.Range * 8
            end
        end
        
        task.wait(Settings.KillAura.Delay)
    end
end

-- Bắt đầu Kill Aura
function StartKillAura()
    -- Dừng loop cũ nếu có
    StopKillAura()
    
    -- Cập nhật FOV
    if FOVCircle and Settings.KillAura.FOVVisible then
        FOVCircle.Visible = true
    end
    
    -- Bắt đầu loop mới
    Settings.KillAura.Enabled = true
    KillAuraConnection = coroutine.wrap(KillAuraLoop)
    KillAuraConnection()
    
    print("⚔️ Kill Aura đã bắt đầu!")
end

-- Dừng Kill Aura
function StopKillAura()
    Settings.KillAura.Enabled = false
    
    if FOVCircle then
        FOVCircle.Visible = false
    end
    
    if KillAuraConnection then
        KillAuraConnection = nil
    end
    
    print("⏸️ Kill Aura đã dừng!")
end

-- Tạo Menu
MenuGui = CreateMenu()

-- Toggle Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Menu.Keybind then
        Settings.Menu.Visible = not Settings.Menu.Visible
        if MenuGui then
            MenuGui.Enabled = Settings.Menu.Visible
        end
    end
end)

-- Auto equip tool khi spawn
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if Settings.KillAura.Enabled then
        StartKillAura()
    end
end)

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    StopKillAura()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
    if FOVCircle then FOVCircle:Destroy() end
end)

-- Thông báo
if Drawing and Drawing.new then
    local Notif = Drawing.new("Text")
    Notif.Text = "⚔️ Kill Aura Loaded! [Delete] để mở menu"
    Notif.Size = 18
    Notif.Color = Color3.fromRGB(255, 100, 100)
    Notif.Center = true
    Notif.Outline = true
    Notif.OutlineColor = Color3.new(0, 0, 0)
    local camera = workspace.CurrentCamera
    if camera then
        Notif.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2 - 50)
    end
    Notif.Visible = true
    
    task.delay(4, function()
        pcall(function() Notif:Destroy() end)
    end)
end

print("=================================")
print("⚔️ KILL AURA SCRIPT LOADED!")
print("🎯 Delete = Mở/Tắt Menu")
print("🔪 Hỗ trợ: Dao, kiếm, tất cả vũ khí")
print("=================================")