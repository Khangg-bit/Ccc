--[[
    AUTO STOP TIMER - Roblox Script
    Game: Dừng bộ đếm thời gian (Stop the Timer)
    Tự động quét màn hình, bấm nút bắt đầu và dừng chính xác
    Hỗ trợ Delta Executor
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    Auto = false,               -- Bật/tắt tự động
    Target = 0,                 -- Thời gian mục tiêu (tự động quét)
    Offset = 0.02,              -- Bấm trước khi đến đích một chút (giây)
    ScanInterval = 2,           -- Thời gian quét lại màn hình (giây)
    Status = "Đang chờ...",
}

-- Biến lưu trữ UI elements tìm thấy
local StartButton = nil
local TimerLabel = nil
local TargetLabel = nil

-- GUI
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

-- Hàm tạo thông báo nhỏ
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

-- Hàm tạo Toggle
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

-- Hàm tạo Button
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

-- Quét toàn bộ PlayerGui để tìm các thành phần cần thiết
local function ScanScreen()
    StartButton = nil
    TimerLabel = nil
    TargetLabel = nil

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        Settings.Status = "Chưa vào game (PlayerGui)"
        return false
    end

    -- 1. Tìm nút Start/Stop
    -- Thường là TextButton màu đỏ, chữ "Start", "Stop", "Click to start", ...
    local buttons = {}
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local text = ""
            if obj:IsA("TextButton") then
                text = obj.Text:lower()
            else
                -- ImageButton có thể có TextLabel con
                local childText = obj:FindFirstChildWhichIsA("TextLabel")
                if childText then text = childText.Text:lower() end
            end
            if text:find("start") or text:find("stop") or text:find("click") then
                table.insert(buttons, obj)
            end
        end
    end
    -- Nếu không tìm thấy bằng text, thử tìm nút lớn nhất
    if #buttons == 0 then
        local maxSize = 0
        for _, obj in pairs(playerGui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local size = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
                if size > maxSize then
                    maxSize = size
                    StartButton = obj
                end
            end
        end
    else
        -- Chọn nút có kích thước lớn nhất trong số tìm thấy
        local maxSize = 0
        for _, btn in pairs(buttons) do
            local size = btn.AbsoluteSize.X * btn.AbsoluteSize.Y
            if size > maxSize then
                maxSize = size
                StartButton = btn
            end
        end
    end

    -- 2. Tìm nhãn thời gian mục tiêu (chứa "stop", "target", "goal", "at:")
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local text = obj.Text:lower()
            if text:find("stop at") or text:find("target") or text:find("goal") or text:find("at:") then
                -- Trích xuất số từ chuỗi
                local num = tonumber(text:match("%d+%.?%d*"))
                if num then
                    TargetLabel = obj
                    Settings.Target = num
                    break
                end
            end
        end
    end

    -- Nếu không tìm thấy, thử tìm nhãn chứa số duy nhất (có thể là target)
    if not TargetLabel then
        for _, obj in pairs(playerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local num = tonumber(obj.Text)
                if num and num > 0 then
                    TargetLabel = obj
                    Settings.Target = num
                    break
                end
            end
        end
    end

    -- 3. Tìm nhãn thời gian hiện tại (timer)
    -- Thường là TextLabel hiển thị số kiểu "0.00" và cập nhật liên tục, font size lớn
    local candidates = {}
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local num = tonumber(obj.Text)
            if num and obj.Text:match("%d+%.%d%d") then
                table.insert(candidates, obj)
            end
        end
    end
    if #candidates > 0 then
        -- Chọn nhãn có font size lớn nhất (vì timer thường to)
        local maxFont = 0
        for _, lbl in pairs(candidates) do
            if lbl.TextSize > maxFont and lbl ~= TargetLabel then
                maxFont = lbl.TextSize
                TimerLabel = lbl
            end
        end
    end

    -- Cập nhật trạng thái
    if StartButton and TimerLabel and TargetLabel then
        Settings.Status = "✅ Quét thành công"
        UpdateDisplay()
        return true
    else
        local missing = {}
        if not StartButton then table.insert(missing, "nút") end
        if not TimerLabel then table.insert(missing, "đồng hồ") end
        if not TargetLabel then table.insert(missing, "mục tiêu") end
        Settings.Status = "❌ Thiếu: " .. table.concat(missing, ", ")
        UpdateDisplay()
        return false
    end
end

-- Cập nhật hiển thị GUI
function UpdateDisplay()
    if TargetDisplayLabel then
        TargetDisplayLabel.Text = "🎯 Mục tiêu: " .. Settings.Target .. "s"
    end
    if TimerDisplayLabel and TimerLabel then
        local current = tonumber(TimerLabel.Text) or 0
        TimerDisplayLabel.Text = "⏱️ Hiện tại: " .. string.format("%.2f", current) .. "s"
    end
    if StatusLabel then
        StatusLabel.Text = "📌 " .. Settings.Status
    end
end

-- Click vào nút Start/Stop
local function ClickButton()
    if not StartButton then return false end
    -- Thử nhiều cách để click
    local success = pcall(function()
        -- Cách 1: Fire MouseButton1Click
        firesignal(StartButton.MouseButton1Click)
    end)
    if not success then
        success = pcall(function()
            -- Cách 2: VirtualInputManager
            local pos = StartButton.AbsolutePosition + StartButton.AbsoluteSize / 2
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
    end
    if not success then
        pcall(function()
            -- Cách 3: firetouchinterest (nếu là GUI button)
            if StartButton:IsA("ImageButton") then
                firetouchinterest(StartButton, game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), 0)
                firetouchinterest(StartButton, game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), 1)
            end
        end)
    end
    return true
end

-- Vòng lặp tự động
local function AutoLoop()
    while Settings.Auto do
        -- Đảm bảo đã quét được các thành phần
        if not StartButton or not TimerLabel or not TargetLabel then
            ScanScreen()
            if not StartButton or not TimerLabel or not TargetLabel then
                task.wait(Settings.ScanInterval)
                continue
            end
        end

        -- Đọc thời gian mục tiêu mới nhất (phòng khi thay đổi)
        if TargetLabel then
            local newTarget = tonumber(TargetLabel.Text:match("%d+%.?%d*"))
            if newTarget then Settings.Target = newTarget end
        end

        Settings.Status = "🔄 Bắt đầu..."
        UpdateDisplay()

        -- Click nút Start
        ClickButton()
        task.wait(0.1)

        -- Chờ đến khi timer đạt mục tiêu
        Settings.Status = "⏳ Đang chờ đúng thời điểm..."
        local stopped = false
        local lastTime = 0
        while Settings.Auto and not stopped do
            if not TimerLabel or not TimerLabel.Parent then
                ScanScreen()
                if not TimerLabel then break end
            end
            local current = tonumber(TimerLabel.Text)
            if current then
                lastTime = current
                UpdateDisplay()
                if current >= Settings.Target - Settings.Offset then
                    -- Click dừng
                    ClickButton()
                    Settings.Status = "✅ Đã dừng tại " .. string.format("%.2f", current) .. "s"
                    UpdateDisplay()
                    stopped = true
                end
            end
            task.wait()
        end

        -- Đợi vòng mới (thường sau khi dừng game tự reset sau vài giây)
        Settings.Status = "🔄 Đợi vòng mới..."
        UpdateDisplay()
        task.wait(2) -- Chờ reset
        ScanScreen() -- Quét lại vì UI có thể thay đổi
    end
end

-- Bắt đầu tự động
local function StartAuto()
    if Settings.Auto then return end
    Settings.Auto = true
    if AutoToggle then AutoToggle.SetState(true) end
    -- Chạy vòng lặp trong coroutine
    coroutine.wrap(AutoLoop)()
end

-- Dừng tự động
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
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 250)
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
    border.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    border.BorderSizePixel = 0
    border.BackgroundTransparency = 0.5
    border.ZIndex = 0
    border.Parent = MainFrame

    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 11)
    borderCorner.Parent = border

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

    -- Target display
    TargetDisplayLabel = Instance.new("TextLabel")
    TargetDisplayLabel.Size = UDim2.new(1, -16, 0, 22)
    TargetDisplayLabel.Position = UDim2.new(0, 8, 0, 65)
    TargetDisplayLabel.BackgroundTransparency = 1
    TargetDisplayLabel.Text = "🎯 Mục tiêu: ?"
    TargetDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    TargetDisplayLabel.TextSize = 11
    TargetDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetDisplayLabel.Font = Enum.Font.GothamBold
    TargetDisplayLabel.Parent = MainFrame

    -- Timer display
    TimerDisplayLabel = Instance.new("TextLabel")
    TimerDisplayLabel.Size = UDim2.new(1, -16, 0, 22)
    TimerDisplayLabel.Position = UDim2.new(0, 8, 0, 90)
    TimerDisplayLabel.BackgroundTransparency = 1
    TimerDisplayLabel.Text = "⏱️ Hiện tại: ?"
    TimerDisplayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimerDisplayLabel.TextSize = 11
    TimerDisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimerDisplayLabel.Font = Enum.Font.Gotham
    TimerDisplayLabel.Parent = MainFrame

    -- Scan button
    CreateButton(MainFrame, "🔍 Quét màn hình", 120, Color3.fromRGB(0, 150, 200), function()
        ScanScreen()
        Notify("Đã quét lại!", 1)
    end)

    -- Auto Toggle
    AutoToggle = CreateToggle(MainFrame, "🤖 Tự động bấm giờ", 160, false, function(state)
        if state then
            StartAuto()
        else
            StopAuto()
        end
    end)

    -- Test click button
    CreateButton(MainFrame, "🖱️ Click thử nút", 200, Color3.fromRGB(200, 100, 0), function()
        if StartButton then
            ClickButton()
            Notify("Đã click nút!", 1)
        else
            Notify("Chưa tìm thấy nút! Hãy quét.", 2)
        end
    end)

    return MenuGui
end

-- Khởi tạo
CreateMenu()
ScanScreen()

-- Cập nhật UI liên tục
coroutine.wrap(function()
    while true do
        if Settings.Auto and TimerLabel then
            UpdateDisplay()
        end
        task.wait(0.1)
    end
end)()

-- Dọn dẹp khi thoát
LocalPlayer.OnTeleport:Connect(function()
    StopAuto()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

Notify("⏱️ Auto Stop Timer đã sẵn sàng!", 2)
print("Auto Stop Timer Script Loaded!")