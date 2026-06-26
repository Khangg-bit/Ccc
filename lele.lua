--[[
    AUTO STOP TIMER - FIXED
    Quét chính xác số giây mục tiêu
    Game: Dừng bộ đếm thời gian / Stop the Timer
    Delta Executor
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
    Auto = false,
    Target = 0,
    Offset = 0.03,        -- Bấm trước 0.03s để bù lag
    Status = "Đang chờ...",
}

-- Các thành phần UI của game đã tìm thấy
local GameUI = {
    TargetLabel = nil,     -- Nhãn hiển thị số giây mục tiêu
    TimerLabel = nil,      -- Nhãn đồng hồ đếm
    StopButton = nil,      -- Nút dừng (màu đỏ)
    StartButton = nil,     -- Nút bắt đầu
}

-- GUI của script
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoStopTimer"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MenuGui
local MainFrame
local StatusLabel
local TargetDisplayLabel
local TimerDisplayLabel
local AutoToggle

-- Notify
local function Notify(text, duration)
    local gui = Instance.new("ScreenGui")
    gui.Name = "Notification"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 36)
    frame.Position = UDim2.new(0.5, -140, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = text
    text.TextColor3 = Color3.fromRGB(0, 255, 150)
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = frame
    task.delay(duration or 2, function()
        pcall(function() gui:Destroy() end)
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

-- Tạo Button
local function CreateButton(parent, text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 30)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = color
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

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- Cập nhật hiển thị
function UpdateDisplay()
    if TargetDisplayLabel then
        TargetDisplayLabel.Text = "🎯 Mục tiêu: " .. Settings.Target .. "s"
    end
    if TimerDisplayLabel and GameUI.TimerLabel then
        local current = tonumber(GameUI.TimerLabel.Text) or 0
        TimerDisplayLabel.Text = "⏱️ Hiện tại: " .. string.format("%.2f", current) .. "s"
    end
    if StatusLabel then
        StatusLabel.Text = "📌 " .. Settings.Status
    end
end

-- QUÉT MÀN HÌNH CHÍNH XÁC
local function ScanScreen()
    -- Reset
    GameUI.TargetLabel = nil
    GameUI.TimerLabel = nil
    GameUI.StopButton = nil
    GameUI.StartButton = nil
    Settings.Target = 0

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        Settings.Status = "Chưa vào game"
        UpdateDisplay()
        return false
    end

    -- CÁCH TIẾP CẬN MỚI: Duyệt TẤT CẢ TextLabel, tìm số giây mục tiêu
    -- Trong game Stop the Timer, số giây mục tiêu thường là số nguyên từ 0-15
    -- và nằm trong một TextLabel riêng biệt, KHÔNG PHẢI đồng hồ đếm

    local allLabels = {}
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            table.insert(allLabels, obj)
        end
    end

    -- Bước 1: Tìm Target Label (số nguyên, KHÔNG có dấu chấm)
    -- Đặc điểm: Text là số nguyên (1-15), KHÔNG thay đổi liên tục
    local targetCandidates = {}
    for _, lbl in pairs(allLabels) do
        local text = lbl.Text:gsub("%s+", "") -- Xóa khoảng trắng
        local num = tonumber(text)
        if num and num == math.floor(num) and num >= 1 and num <= 15 then
            -- Đây là số nguyên 1-15, có thể là target
            table.insert(targetCandidates, lbl)
        end
    end

    -- Nếu có nhiều, ưu tiên cái có font size trung bình (không quá to, không quá nhỏ)
    if #targetCandidates > 0 then
        -- Lọc: loại bỏ những label có chứa dấu chấm (số thập phân)
        local filtered = {}
        for _, lbl in pairs(targetCandidates) do
            if not lbl.Text:find("%.") then
                table.insert(filtered, lbl)
            end
        end
        if #filtered > 0 then
            targetCandidates = filtered
        end
        
        -- Chọn label có font size vừa phải (thường target không phải chữ to nhất)
        local bestLabel = targetCandidates[1]
        for _, lbl in pairs(targetCandidates) do
            -- Ưu tiên label có text là số nguyên thuần túy, không có ký tự khác
            if lbl.Text:match("^%s*%d+%s*$") then
                bestLabel = lbl
                break
            end
        end
        
        GameUI.TargetLabel = bestLabel
        Settings.Target = tonumber(bestLabel.Text) or 0
        Settings.Status = "✅ Tìm thấy target: " .. Settings.Target .. "s"
    end

    -- Bước 2: Tìm Timer Label (số thập phân, cập nhật liên tục)
    -- Đặc điểm: Text có dấu chấm (vd: 3.45), font size LỚN
    local timerCandidates = {}
    for _, lbl in pairs(allLabels) do
        local text = lbl.Text:gsub("%s+", "")
        if text:find("%.") then
            local num = tonumber(text)
            if num then
                table.insert(timerCandidates, lbl)
            end
        end
    end

    if #timerCandidates > 0 then
        -- Timer thường có font size lớn nhất
        local maxFont = 0
        for _, lbl in pairs(timerCandidates) do
            if lbl.TextSize > maxFont then
                maxFont = lbl.TextSize
                GameUI.TimerLabel = lbl
            end
        end
    end

    -- Bước 3: Tìm nút bấm
    -- Nút Stop thường là nút đỏ, lớn nhất màn hình
    local allButtons = {}
    for _, obj in pairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            table.insert(allButtons, obj)
        end
    end

    if #allButtons > 0 then
        -- Tìm nút lớn nhất (thường là nút chính)
        local maxSize = 0
        local biggestButton = nil
        for _, btn in pairs(allButtons) do
            local size = btn.AbsoluteSize.X * btn.AbsoluteSize.Y
            if size > maxSize and size < 500000 then -- Giới hạn tránh fullscreen
                maxSize = size
                biggestButton = btn
            end
        end
        
        if biggestButton then
            -- Kiểm tra màu sắc để phân biệt Start/Stop
            local bgColor = biggestButton.BackgroundColor3
            -- Nút đỏ = Stop, nút xanh = Start
            if bgColor.R > 0.5 and bgColor.G < 0.3 and bgColor.B < 0.3 then
                GameUI.StopButton = biggestButton
                GameUI.StartButton = biggestButton -- Cùng 1 nút
            else
                GameUI.StopButton = biggestButton
                GameUI.StartButton = biggestButton
            end
        end
    end

    -- Nếu không tìm thấy target, thử cách khác
    if not GameUI.TargetLabel then
        -- Tìm trong tất cả text, kể cả text có chứa chữ
        for _, lbl in pairs(allLabels) do
            local text = lbl.Text:lower()
            if text:find("stop at") or text:find("target") or text:find("goal") then
                local num = tonumber(text:match("(%d+%.?%d*)"))
                if num and num <= 15 then
                    GameUI.TargetLabel = lbl
                    Settings.Target = num
                    Settings.Status = "✅ Target: " .. num .. "s"
                    break
                end
            end
        end
    end

    UpdateDisplay()
    
    if GameUI.TargetLabel and GameUI.TimerLabel and GameUI.StopButton then
        Settings.Status = "✅ Sẵn sàng! Target: " .. Settings.Target .. "s"
        UpdateDisplay()
        return true
    else
        local missing = {}
        if not GameUI.TargetLabel then table.insert(missing, "mục tiêu") end
        if not GameUI.TimerLabel then table.insert(missing, "đồng hồ") end
        if not GameUI.StopButton then table.insert(missing, "nút") end
        Settings.Status = "❌ Thiếu: " .. table.concat(missing, ", ")
        UpdateDisplay()
        return false
    end
end

-- Click nút
local function ClickStopButton()
    if not GameUI.StopButton then return false end
    
    local success = false
    
    -- Cách 1: firesignal
    success = pcall(function()
        if GameUI.StopButton.MouseButton1Click then
            firesignal(GameUI.StopButton.MouseButton1Click)
        end
    end)
    
    if not success then
        -- Cách 2: VirtualInputManager
        success = pcall(function()
            local pos = GameUI.StopButton.AbsolutePosition + GameUI.StopButton.AbsoluteSize / 2
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end
    
    return success
end

-- Vòng lặp tự động
local function AutoLoop()
    while Settings.Auto do
        -- Quét lại để chắc chắn
        if not GameUI.TargetLabel or not GameUI.TimerLabel then
            ScanScreen()
            if not GameUI.TargetLabel then
                Settings.Status = "Đang quét lại..."
                UpdateDisplay()
                task.wait(1)
                continue
            end
        end

        -- Đọc target mới nhất
        if GameUI.TargetLabel then
            local newTarget = tonumber(GameUI.TargetLabel.Text)
            if newTarget and newTarget >= 1 and newTarget <= 15 then
                Settings.Target = newTarget
            end
        end

        Settings.Status = "🔄 Bắt đầu..."
        UpdateDisplay()

        -- Click Start
        ClickStopButton()
        task.wait(0.2)

        -- Chờ timer chạm target
        Settings.Status = "⏳ Đang chờ..."
        local stopped = false
        local lastTime = 0
        
        while Settings.Auto and not stopped do
            if not GameUI.TimerLabel or not GameUI.TimerLabel.Parent then
                ScanScreen()
                if not GameUI.TimerLabel then break end
            end
            
            local currentText = GameUI.TimerLabel.Text
            local current = tonumber(currentText)
            
            if current then
                lastTime = current
                UpdateDisplay()
                
                -- Khi current >= target - offset, click dừng
                if current >= Settings.Target - Settings.Offset then
                    ClickStopButton()
                    Settings.Status = "✅ Dừng tại " .. string.format("%.3f", current) .. "s (target: " .. Settings.Target .. "s)"
                    UpdateDisplay()
                    stopped = true
                end
            end
            
            task.wait() -- 1 frame
        end

        -- Chờ reset
        Settings.Status = "🔄 Chờ vòng mới..."
        UpdateDisplay()
        task.wait(1.5)
        ScanScreen()
    end
end

-- Bắt đầu
local function StartAuto()
    if Settings.Auto then return end
    ScanScreen() -- Quét trước khi bắt đầu
    Settings.Auto = true
    if AutoToggle then AutoToggle.SetState(true) end
    coroutine.wrap(AutoLoop)()
end

-- Dừng
local function StopAuto()
    Settings.Auto = false
    if AutoToggle then AutoToggle.SetState(false) end
    Settings.Status = "Đã dừng"
    UpdateDisplay()
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "AutoStopMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = true

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 220, 0, 240)
    MainFrame.Position = UDim2.new(0, 10, 0, 50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    title.BorderSizePixel = 0
    title.Text = "⏱️ AUTO STOP TIMER"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.Parent = MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    -- Status
    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -16, 0, 22)
    StatusLabel.Position = UDim2.new(0, 8, 0, 40)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "📌 Đang chờ..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame

    -- Target
    TargetDisplayLabel = Instance.new("TextLabel")
    TargetDisplayLabel.Size = UDim2.new(1, -16, 0, 22)
    TargetDisplayLabel.Position = UDim2.new(0, 8, 0, 62)
    TargetDisplayLabel.BackgroundTransparency = 1
    TargetDisplayLabel.Text = "🎯 Mục tiêu: ?"
    TargetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    TargetDisplayLabel.TextSize = 11
    TargetDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetDisplayLabel.Font = Enum.Font.GothamBold
    TargetDisplayLabel.Parent = MainFrame

    -- Timer
    TimerDisplayLabel = Instance.new("TextLabel")
    TimerDisplayLabel.Size = UDim2.new(1, -16, 0, 22)
    TimerDisplayLabel.Position = UDim2.new(0, 8, 0, 84)
    TimerDisplayLabel.BackgroundTransparency = 1
    TimerDisplayLabel.Text = "⏱️ Hiện tại: ?"
    TimerDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimerDisplayLabel.TextSize = 11
    TimerDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimerDisplayLabel.Font = Enum.Font.Gotham
    TimerDisplayLabel.Parent = MainFrame

    -- Nút quét
    CreateButton(MainFrame, "🔍 Quét màn hình", 115, Color3.fromRGB(0, 150, 200), function()
        ScanScreen()
        Notify("Đã quét!", 1)
    end)

    -- Auto toggle
    AutoToggle = CreateToggle(MainFrame, "🤖 Tự động", 155, false, function(state)
        if state then
            StartAuto()
        else
            StopAuto()
        end
    end)

    -- Nút test
    CreateButton(MainFrame, "🖱️ Click nút (test)", 195, Color3.fromRGB(200, 150, 0), function()
        if GameUI.StopButton then
            ClickStopButton()
            Notify("Đã click!", 1)
        else
            ScanScreen()
            if GameUI.StopButton then
                ClickStopButton()
                Notify("Đã click sau khi quét!", 1)
            else
                Notify("Không tìm thấy nút!", 2)
            end
        end
    end)

    return MenuGui
end

-- Khởi tạo
CreateMenu()
task.wait(0.5)
ScanScreen()

-- Cập nhật display
coroutine.wrap(function()
    while true do
        if Settings.Auto and GameUI.TimerLabel then
            UpdateDisplay()
        end
        task.wait(0.1)
    end
end)()

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    StopAuto()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

Notify("⏱️ Auto Stop Timer đã sẵn sàng!", 2)
print("Auto Stop Timer Script Loaded!")