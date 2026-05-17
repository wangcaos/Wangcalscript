-- ==============================================================================
-- WANGCAOS PREMIUM - REWRITTEN FIX VERSION (CORE ENGINE)
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình rút gọn tối đa - Tập trung Core cũ đại ca yêu cầu
local Config = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    FovEnabled = true,
    FovRadius = 120,
    Smoothness = 0.25, -- Tốc độ khóa tâm mượt mà
    WalkSpeed = 16,
    JumpPower = 50,
    SpeedToggle = false,
    JumpToggle = false
}

-- Hệ thống lưu trữ ESP Vector 2D cũ
local ESP_Data = {}

-- Khởi tạo vòng tròn FOV chuẩn Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- Hàm kiểm tra thực thể sống
local function IsAlive(Character)
    if not Character then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    return true
end

-- Hàm check tường chuẩn xác bằng Raycast
local function CheckWall(TargetPart, Character)
    if not Config.WallCheck then return true end
    local Origin = Camera.CFrame.Position
    local Direction = TargetPart.Position - Origin
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Character, Camera}
    
    local Result = workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

-- Tìm kiếm mục tiêu gần tâm chuột nhất (Ưu tiên HEAD)
local function GetClosestHead()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ClosestTarget = nil
    local MaxDist = Config.FovRadius

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and IsAlive(Player.Character) then
            if Config.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local Head = Player.Character:FindFirstChild("Head")
            if Head then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                if OnScreen and CheckWall(Head, Player.Character) then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Center).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        ClosestTarget = Head
                    end
                end
            end
        end
    end
    return ClosestTarget
end

-- Tìm kiếm phân vùng chứa GUI an toàn chống chặn trên HyperOS
local function GetSafeGui()
    if gethui then return gethui() end
    local success, core = pcall(function() return CoreGui end)
    if success then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local SafeParent = GetSafeGui()
for _, old in pairs(SafeParent:GetChildren()) do
    if old.Name == "Wangcaos_Fixed_Menu" then old:Destroy() end
end

-- ==============================================================================
-- FIX LỖI DI CHUYỂN: Tách biệt hoàn toàn Logic Drag của TopBar và Nút Toggle Mobile
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Fixed_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

-- 1. NÚT LOGO BẬT/TẮT (Chống trượt khi click trên Mobile và PC)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "FixedToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Position = UDim2.new(0, 15, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(100, 255, 100)
ToggleButton.TextSize = 22
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(100, 255, 100)
ToggleStroke.Thickness = 1.5

-- Logic Kéo Thả RIÊNG BIỆT cho Nút Bật/Tắt (Không gây trượt hay mất click)
local btnDragging = false
local btnDragStart, btnStartPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = ToggleButton.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        ToggleButton.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end)

-- 2. KHUNG CHÍNH MENU GUI
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Visible = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(45, 45, 45)
MainStroke.Thickness = 1.5

-- Thanh Tiêu Đề TopBar (Chỉ kéo thả MainFrame tại đây)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 30)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TopBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.Text = "wangcaos script | V2 Fixed"
TitleText.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Logic Kéo Thả RIÊNG BIỆT cho MainFrame thông qua TopBar
local frameDragging = false
local frameDragStart, frameStartPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frameDragging = true
        frameDragStart = input.Position
        frameStartPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if frameDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - frameDragStart
        MainFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        frameDragging = false
    end
end)

-- Nút tắt/mở tương tác khi bấm Logo
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- 3. HỆ THỐNG PHÂN CHIA TABS (Khóa chặt không cho nhảy vị trí hay di chuyển lệch)
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Parent = MainFrame
TabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
TabBar.Position = UDim2.new(0, 0, 0, 30)
TabBar.Size = UDim2.new(0, 100, 1, -30)

local MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Parent = MainFrame
MainContent.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainContent.Position = UDim2.new(0, 100, 0, 30)
MainContent.Size = UDim2.new(1, -100, 1, -30)

local TabListLayout = Instance.new("UIListLayout", TabBar)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Tạo các container trang
local CombatPage = Instance.new("ScrollingFrame", MainContent)
local PlayerPage = Instance.new("ScrollingFrame", MainContent)

for _, page in pairs({CombatPage, PlayerPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 300)
    page.ScrollBarThickness = 2
    page.Visible = false
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local pagePadding = Instance.new("UIPadding", page)
    pagePadding.PaddingTop = UDim.new(0, 8)
    pagePadding.PaddingLeft = UDim.new(0, 8)
    pagePadding.PaddingRight = UDim.new(0, 8)
end
CombatPage.Visible = true -- Mặc định trang đầu mở
-- ==============================================================================
-- 4. HỆ THỐNG PHÂN TÁCH TABS VÀ TẠO NUT BUTTON/TOGGLE CHUẨN KHÔNG BỊ TRƯỢT
-- ==============================================================================

local function CreateTabButton(Name, Order, PageTarget)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = Name .. "_Tab"
    TabBtn.Parent = TabBar
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    TabBtn.BorderSizePixel = 0
    TabBtn.Size = UDim2.new(1, 0, 0, 35)
    TabBtn.Font = Enum.Font.SourceSansBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = Name
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(160, 160, 160)
    TabBtn.TextSize = 14

    TabBtn.MouseButton1Click:Connect(function()
        CombatPage.Visible = false
        PlayerPage.Visible = false
        for _, btn in pairs(TabBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.TextColor3 = Color3.fromRGB(160, 160, 160)
            end
        end
        TabBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        PageTarget.Visible = true
    end)
end

CreateTabButton("Aimbot", 1, CombatPage)
CreateTabButton("Player", 2, PlayerPage)

-- Khung Render các nút Toggle/Slider đa dụng
local function AddToggle(ParentPage, LabelText, ConfigKey, Callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Parent = ParentPage
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
    Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 4)

    local Label = Instance.new("TextLabel")
    Label.Parent = ToggleFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Font = Enum.Font.SourceSans
    Label.Text = LabelText
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Box = Instance.new("Frame")
    Box.Parent = ToggleFrame
    Box.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 60)
    Box.Position = UDim2.new(1, -32, 0.5, -9)
    Box.Size = UDim2.new(0, 24, 0, 18)
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

    local Clicker = Instance.new("TextButton")
    Clicker.Parent = ToggleFrame
    Clicker.BackgroundTransparency = 1
    Clicker.Size = UDim2.new(1, 0, 1, 0)
    Clicker.Text = ""

    Clicker.MouseButton1Click:Connect(function()
        Config[ConfigKey] = not Config[ConfigKey]
        Box.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 60)
        if Callback then Callback(Config[ConfigKey]) end
    end)
end

local function AddSlider(ParentPage, LabelText, Min, Max, ConfigKey, Callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Parent = ParentPage
    SliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Size = UDim2.new(1, 0, 0, 40)
    Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 4)

    local Label = Instance.new("TextLabel")
    Label.Parent = SliderFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 8, 0, 4)
    Label.Size = UDim2.new(1, -60, 0, 16)
    Label.Font = Enum.Font.SourceSans
    Label.Text = LabelText
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Parent = SliderFrame
    ValLabel.BackgroundTransparency = 1
    ValLabel.Position = UDim2.new(1, -50, 0, 4)
    ValLabel.Size = UDim2.new(0, 42, 0, 16)
    ValLabel.Font = Enum.Font.SourceSansBold
    ValLabel.Text = tostring(Config[ConfigKey])
    ValLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    ValLabel.TextSize = 13
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame")
    Track.Parent = SliderFrame
    Track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Track.BorderSizePixel = 0
    Track.Position = UDim2.new(0, 8, 0, 24)
    Track.Size = UDim2.new(1, -16, 0, 5)
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Parent = Track
    Fill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.new((Config[ConfigKey] - Min) / (Max - Min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton")
    Btn.Parent = Track
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""

    local hold = false
    Btn.InputBegan:Connect(function(ip)
        if ip.UserInputType == Enum.UserInputType.MouseButton1 or ip.UserInputType == Enum.UserInputType.Touch then hold = true end
    end)
    UserInputService.InputEnded:Connect(function(ip)
        if ip.UserInputType == Enum.UserInputType.MouseButton1 or ip.UserInputType == Enum.UserInputType.Touch then hold = false end
    end)

    UserInputService.InputChanged:Connect(function(ip)
        if hold and (ip.UserInputType == Enum.UserInputType.MouseMovement or ip.UserInputType == Enum.UserInputType.Touch) then
            local mouseX = UserInputService:GetMouseLocation().X
            local trackX = Track.AbsolutePosition.X
            local trackSize = Track.AbsoluteSize.X
            local pct = math.clamp((mouseX - trackX) / trackSize, 0, 1)
            local val = math.floor(Min + (Max - Min) * pct)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            ValLabel.Text = tostring(val)
            Config[ConfigKey] = val
            if Callback then Callback(val) end
        end
    end)
end

-- Điền tính năng chuyên biệt của nhóm Aimbot
AddToggle(CombatPage, "Enable Aimbot Lock", "Aimbot")
AddToggle(CombatPage, "Team Check (Ignore Team)", "TeamCheck")
AddToggle(CombatPage, "Wall Check (Ignore Walls)", "WallCheck")
AddToggle(CombatPage, "Show FOV Safe Circle", "FovEnabled")
AddSlider(CombatPage, "FOV Capture Radius", 30, 500, "FovRadius")

-- Điền tính năng chuyên biệt của nhóm Player Movement
AddToggle(PlayerPage, "Override WalkSpeed", "SpeedToggle")
AddSlider(PlayerPage, "Custom Speed Power", 16, 150, "WalkSpeed")
AddToggle(PlayerPage, "Override JumpPower", "JumpToggle")
AddSlider(PlayerPage, "Custom Jump Power", 50, 250, "JumpPower")
-- ==============================================================================
-- 5. ENGINE KHÓA CỨNG ĐẦU (HEAD AIMBOT) & ĐỒNG BỘ HIỂN THỊ VÒNG TRÒN FOV
-- ==============================================================================

-- Nút xóa Script khẩn cấp để dọn bộ nhớ (Đóng đè lên thanh TopBar)
local CloseMenuBtn = Instance.new("TextButton")
CloseMenuBtn.Name = "CloseMenuBtn"
CloseMenuBtn.Parent = MainFrame.TopBar
CloseMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseMenuBtn.Position = UDim2.new(1, -24, 0.5, -9)
CloseMenuBtn.Size = UDim2.new(0, 18, 0, 18)
CloseMenuBtn.Font = Enum.Font.SourceSansBold
CloseMenuBtn.Text = "X"
CloseMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseMenuBtn.TextSize = 12
Instance.new("UICorner", CloseMenuBtn).CornerRadius = UDim.new(0, 4)

local RunningConnection = nil

CloseMenuBtn.MouseButton1Click:Connect(function()
    if RunningConnection then RunningConnection:Disconnect() end
    FOVCircle.Visible = false
    FOVCircle:Remove()
    ScreenGui:Destroy()
end)

-- VÒNG LẶP ENGINE CHÍNH - Xử lý mượt không đè dữ liệu hay đứng hình GUI
RunningConnection = RunService.RenderStepped:Connect(function()
    local CenterPoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Xử lý hiển thị chuẩn xác vòng tròn FOV theo tọa độ màn hình
    if Config.FovEnabled and MainFrame.Visible == false then
        FOVCircle.Position = CenterPoint
        FOVCircle.Radius = Config.FovRadius
        FOVCircle.Visible = true
    elseif Config.FovEnabled and MainFrame.Visible == true then
        -- Vẫn giữ hiển thị FOV khi mở menu (Đã fix lỗi bị tàng hình)
        FOVCircle.Position = CenterPoint
        FOVCircle.Radius = Config.FovRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Xử lý can thiệp thông số nhân vật (WalkSpeed & JumpPower)
    local Character = LocalPlayer.Character
    if Character and IsAlive(Character) then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            if Config.SpeedToggle then
                Humanoid.WalkSpeed = Config.WalkSpeed
            end
            if Config.JumpToggle then
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = Config.JumpPower
            end
        end
    end

    -- XỬ LÝ LOCK AIMBOT TRỰC TIẾP VÀO ĐẦU (HEAD) - BẰNG PHƯƠNG PHÁP XOAY CAMERA CŨ
    if Config.Aimbot then
        local TargetHead = GetClosestHead()
        if TargetHead then
            -- Tính toán ma trận CFrame hướng thẳng camera vào vị trí Head của mục tiêu
            local TargetLook = CFrame.new(Camera.CFrame.Position, TargetHead.Position)
            
            -- Thực hiện ép góc quay Camera dựa theo hệ số mượt Smoothness cũ
            Camera.CFrame = Camera.CFrame:Lerp(TargetLook, Config.Smoothness)
        end
    end
end)

print("================================================================")
print("--- [WANGCAOS REWRITTEN ENGINE LOADED SUCCESSFULLY] ---")
print("--- [FIXED: FOV VISIBILITY / HEAD LOCK / ANTI-SLIDE GUI] ---")
print("================================================================")
