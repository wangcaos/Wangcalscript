-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT - HYBRID MINECRAFT STYLE V3 (MAX EDITION)
-- VOLUMETRIC EXPANSION - 1000 LINES ARCHITECTURE
-- ALL RIGHTS RESERVED BY DAI CA WANG (2026)
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- 1. MASTER GLOBAL CONFIGURATION STRUCTURE
-- ==============================================================================
local Config = {
    -- State Management
    CurrentTab = "Combat",
    MenuKeybind = Enum.KeyCode.LeftBracket,
    MenuVisible = true,
    
    -- Combat / Aimbot Matrix
    Aimbot = false,
    AimbotTarget = "Head",
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 0.2,
    Prediction = false,
    PredictionFactor = 0.05,
    
    -- Visuals / Graphics Matrix
    EspMaster = false,
    FovCircle = false,
    FovRadius = 120,
    FovColor = Color3.fromRGB(255, 255, 255)
        -- Visuals / Graphics Matrix (Tiếp diễn)
    EspBox = false,              -- Trạng thái bật/tắt Hộp Đặc 3D
    EspTracer = false,           -- Đường kẻ nối chân thực thể
    EspName = false,             -- Bảng chữ thông tin động trên đầu
    EspTransparency = 80,        -- Độ mờ mặc định 80% (Kéo trượt từ 0-100)
    MaxDistance = 500,           -- Khoảng cách giới hạn quét ESP (Studs)
    BoxColorMode = "TeamColor",  -- Tùy chọn hệ màu: TeamColor hoặc Custom
    CustomBoxColor = Color3.fromRGB(0, 255, 0),
    CustomTextColor = Color3.fromRGB(255, 255, 255),
    
    -- Player / Movement Modification
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50,
    NoClipToggle = false,
    InfiniteJump = false,
    
    -- World / Environmental Modifier
    FullBright = false,
    AmbientColor = Color3.fromRGB(255, 255, 25
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

-- ==============================================================================
-- 2. SAFETY VECTOR DRAWING MEMORY ALLOCATION (NON-BLOCKING)
-- ==============================================================================
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Config.FovColor
FOV_Drawing.Thickness = 1.5
FOV_Drawing.NumSides = 64
FOV_Drawing.Filled = false
FOV_Drawing.Transparency = 0.7
FOV_Drawing.Visible = false

local Tracer_Cache = {}
local Character_Cache = {}

-- Cấp phát bộ nhớ đồ họa vector an toàn cho thực thể người chơi nhập phòng
local function CreateTracerObject(Player)
    if Tracer_Cache[Player] then return end
    local Line = Drawing.new("Line")
    Line.Thickness = 1.2
    Line.Color = Color3.fromRGB(255, 255, 255)
    Line.Transparency = 1
    Line.Visible = false
    Tracer_Cache[Player] = Line
end

-- Thu hồi vùng nhớ tránh hiện tượng rò rỉ bộ nhớ (Memory Leak)
local function ClearTracerObject(Player)
    if Tracer_Cache[Player] then
        pcall(function()
            Tracer_Cache[Player].Visible = false
            Tracer_Cache[Player]:Remove()
        end)
        Tracer_Cache[Player] = nil
    end
end

-- ==============================================================================
-- 3. CHAMS UTILITIES & MATH ENGINE
-- ==============================================================================
local function IsAlive(Character)
    if not Character or not Character.Parent then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    return true
end

local function CheckWallOcclusion(TargetPart, Character)
    if not Config.WallCheck then return true end
    local Origin = Camera.CFrame.Position
    local Direction = TargetPart.Position - Origin
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Character, Camera}
    local Result = workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end
-- ==============================================================================
-- 4. PLAYER ENVIRONMENT & RECOGNITION EXTENSION MATH
-- ==============================================================================

-- Hàm xác định màu sắc động dựa trên cấu hình tùy chọn của đại ca
local function GetPlayerColor(Player)
    if Config.BoxColorMode == "Custom" then
        return Config.CustomBoxColor
    end
    if Player.Team then
        return Player.TeamColor.Color
    end
    if Player.TeamColor ~= BrickColor.new("White") and Player.TeamColor ~= BrickColor.new("Medium stone grey") then
        return Player.TeamColor.Color
    end
    return Color3.fromRGB(0, 255, 0)
end

-- Hàm trích xuất tên vũ khí/công cụ đang trang bị an toàn tuyệt đối
local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        return Tool.Name
    end
    return "None"
end

-- Thuật toán tìm kiếm thực thể tối ưu không gây drop FPS
local function GetClosestPlayerToCrosshair()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ClosestTarget = nil
    local MaxDist = Config.FovRadius

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and IsAlive(Player.Character) then
            if Config.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local TargetPart = Player.Character:FindFirstChild(Config.AimbotTarget)
            if TargetPart then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
                if OnScreen and CheckWallOcclusion(TargetPart, Player.Character) then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Center).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        ClosestTarget = TargetPart
                    end
                end
            end
        end
    end
    return ClosestTarget
end

-- ==============================================================================
-- 5. NON-BLOCKING DYNAMIC ADORNMENT CHAMS INJECTION
-- ==============================================================================

-- Giải phóng các instance rác của một người chơi cũ
local function CleanCharacterVisuals(Character)
    if not Character then return end
    local OldBox = Character:FindFirstChild("BéBoxFill", true)
    if OldBox then OldBox:Destroy() end
    local OldTag = Character:FindFirstChild("BéInfoTag", true)
    if OldTag then OldTag:Destroy() end
end

-- Hàm lõi xử lý dựng Chams nhìn xuyên tường & Text 3D không chặn luồng chính
local function RenderVisualsForCharacter(Player, Character)
    if not Character or not Character.Parent then return end
    
    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Head = Character:FindFirstChild("Head")
    if not Root or not Head then return end
    
    CleanCharacterVisuals(Character)

    -- Tạo BoxHandleAdornment nhìn xuyên tường (AlwaysOnTop = true)
    local Box = Instance.new("BoxHandleAdornment")
    Box.Name = "BéBoxFill"
    Box.Parent = Root
    Box.Adornee = Root
    Box.AlwaysOnTop = true
    Box.ZIndex = 10
    Box.Size = Vector3.new(4, 6, 4)
    Box.Transparency = Config.EspTransparency / 100
    Box.Visible = false

    -- Tạo BillboardGui thông tin động trên đầu thực thể
    local Gui = Instance.new("BillboardGui")
    Gui.Name = "BéInfoTag"
    Gui.Adornee = Head
    Gui.Size = UDim2.new(0, 200, 0, 100)
    Gui.StudsOffset = Vector3.new(0, 4, 0)
    Gui.AlwaysOnTop = true

    local Label = Instance.new("TextLabel", Gui)
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextScaled = false
    Label.TextSize = 14
    Label.TextStrokeTransparency = 0
    Label.TextColor3 = Config.CustomTextColor
    Gui.Parent = Head
    
    Character_Cache[Character] = {
        BoxInstance = Box,
        GuiInstance = Gui,
        LabelInstance = Label,
        PlayerOwner = Player
    }
    end
    -- ==============================================================================
-- 6. CORE REFRESH CONNECTIONS & WORKSPACE MONITORING
-- ==============================================================================

-- Cơ chế giám sát vòng đời Character không sử dụng hàm đợi gây treo Luồng
local function MonitorPlayerCharacter(Player)
    if Player == LocalPlayer then return end
    
    Player.CharacterAdded:Connect(function(Character)
        task.wait(0.1) -- Giảm tải chu kỳ khởi tạo để dữ liệu Part đồng bộ kịp
        if Character.Parent then
            RenderVisualsForCharacter(Player, Character)
        end
    end)
    
    if Player.Character and Player.Character.Parent then
        RenderVisualsForCharacter(Player, Player.Character)
    end
end

-- ==============================================================================
-- 7. MINECRAFT FIGMA GUI - MASTER CANVAS INITIALIZATION
-- ==============================================================================
local function GetSafeGui()
    if gethui then return gethui() end
    local success, core = pcall(function() return CoreGui end)
    if success then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
        end

local SafeParent = GetSafeGui()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Minecraft_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

-- 1. NÚT LOGO TRÒN ĐIỀU KHIỂN ĐỂ BẬT/TẮT MENU CHỐNG TRƯỢT KẸT
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MinecraftToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Position = UDim2.new(0, 20, 0, 150)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 22
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 10)

local LogoStroke = Instance.new("UIStroke", ToggleButton)
LogoStroke.Color = Color3.fromRGB(90, 90, 90)
LogoStroke.Thickness = 1.5

-- Logic kéo thả an toàn cho Nút Logo
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

-- 2. KHUNG MENU CHÍNH PHONG CÁCH FIGMA MINECRAFT CLIENT PREMIUM
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -185)
MainFrame.Size = UDim2.new(0, 550, 0, 370)
MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(60, 60, 60)
FrameStroke.Thickness = 1.5

-- Thanh tiêu đề Header điều khiển Drag chính của Menu
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Parent = MainFrame
HeaderBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HeaderBar.BackgroundTransparency = 1
HeaderBar.Size = UDim2.new(1, 0, 0, 40)

local ClientTitle = Instance.new("TextLabel")
ClientTitle.Parent = HeaderBar
ClientTitle.BackgroundTransparency = 1
ClientTitle.Position = UDim2.new(0, 18, 0, 0)
ClientTitle.Size = UDim2.new(0, 350, 1, 0)
ClientTitle.Font = Enum.Font.GothamBold
ClientTitle.Text = "WANGCAOS CLIENT // MULTI-THREADING V3 (2026 EDITION)"
ClientTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ClientTitle.TextSize = 13
ClientTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = HeaderBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
CloseBtn.TextSize = 15

-- Logic kéo thả độc lập cho Khung Giao Diện tại HeaderBar
local frameDragging = false
local frameDragStart, frameStartPos
HeaderBar.InputBegan:Connect(function(input)
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

ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuVisible = not Config.MenuVisible
    MainFrame.Visible = Config.MenuVisible
end)
    -- ==============================================================================
-- 8. HORIZONTAL NAVIGATION SYSTEM & PAGE CONTAINERS
-- ==============================================================================

local TabNavBar = Instance.new("Frame")
TabNavBar.Name = "TabNavBar"
TabNavBar.Parent = MainFrame
TabNavBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
TabNavBar.Position = UDim2.new(0, 15, 0, 45)
TabNavBar.Size = UDim2.new(1, -30, 0, 36)
Instance.new("UICorner", TabNavBar).CornerRadius = UDim.new(0, 6)

local TabPadding = Instance.new("UIPadding", TabNavBar)
TabPadding.PaddingLeft = UDim.new(0, 6)
TabPadding.PaddingRight = UDim.new(0, 6)
TabPadding.PaddingTop = UDim.new(0, 4)

local TabLayout = Instance.new("UIListLayout", TabNavBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 8)

-- Khung hiển thị nội dung độc lập quản lý các phân trang
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 92)
ContentContainer.Size = UDim2.new(1, -30, 1, -110)

local CombatPage = Instance.new("ScrollingFrame", ContentContainer)
local VisualPage = Instance.new("ScrollingFrame", ContentContainer)
local PlayerPage = Instance.new("ScrollingFrame", ContentContainer)
local AboutPage = Instance.new("ScrollingFrame", ContentContainer)

for _, page in pairs({CombatPage, VisualPage, PlayerPage, AboutPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 420) -- Tăng diện tích cuộn chứa nhiều tính năng
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
    page.Visible = false
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
end
CombatPage.Visible = true

-- Khởi tạo các nút chuyển trang Capsule dẹt phong cách Figma Figma V3
local function CreateFigmaTab(Name, Order, PageTarget)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = Name .. "_Tab"
    TabBtn.Parent = TabNavBar
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(0, 118, 0, 28)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = Name:upper()
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
    TabBtn.TextSize = 11
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    
    local TabStroke = Instance.new("UIStroke", TabBtn)
    TabStroke.Color = Order == 1 and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(70, 70, 70)
    TabStroke.Thickness = 1
    TabStroke.Enabled = Order == 1 and true or false

    TabBtn.MouseButton1Click:Connect(function()
        CombatPage.Visible = false
        VisualPage.Visible = false
        PlayerPage.Visible = false
        AboutPage.Visible = false
        
        for _, btn in pairs(TabNavBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(140, 140, 140)
                local strk = btn:FindFirstChildOfClass("UIStroke")
                if strk then strk.Enabled = false end
            end
        end
        
        TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabStroke.Color = Color3.fromRGB(85, 255, 85)
        TabStroke.Enabled = true
        PageTarget.Visible = true
    end)
end

CreateFigmaTab("Combat Engine", 1, CombatPage)
CreateFigmaTab("Visual Matrix", 2, VisualPage)
CreateFigmaTab("Player Custom", 3, PlayerPage)
CreateFigmaTab("Client Status", 4, AboutPage)
-- ==============================================================================
-- 9. PREMIUM UI COMPONENTS DESIGN FRAMEWORK (MINECRAFT SLIDERS & CAPSULES)
-- ==============================================================================

-- Thiết kế linh kiện Toggle kèm công tắc gạt viên bi chuyển động mượt mà
local function AddMinecraftToggle(ParentPage, LabelText, ConfigKey, Callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Parent = ParentPage
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Size = UDim2.new(1, 0, 0, 36)

    local Label = Instance.new("TextLabel")
    Label.Parent = ToggleFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.Text = LabelText:upper()
    Label.TextColor3 = Color3.fromRGB(210, 210, 210)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SwitchBg = Instance.new("Frame")
    SwitchBg.Parent = ToggleFrame
    SwitchBg.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(32, 32, 32)
    SwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    SwitchBg.Size = UDim2.new(0, 36, 0, 18)
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    local SwStroke = Instance.new("UIStroke", SwitchBg)
    SwStroke.Color = Config[ConfigKey] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(75, 75, 75)
    SwStroke.Thickness = 1

    local Ball = Instance.new("Frame")
    Ball.Parent = SwitchBg
    Ball.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(160, 160, 160)
    Ball.Position = Config[ConfigKey] and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Ball.Size = UDim2.new(0, 14, 0, 14)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Parent = ToggleFrame
    ActionBtn.BackgroundTransparency = 1
    ActionBtn.Size = UDim2.new(1, 0, 1, 0)
    ActionBtn.Text = ""

    ActionBtn.MouseButton1Click:Connect(function()
        Config[ConfigKey] = not Config[ConfigKey]
        
        local targetPos = Config[ConfigKey] and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetBgColor = Config[ConfigKey] and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(32, 32, 32)
        local targetBallColor = Config[ConfigKey] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(160, 160, 160)
        local targetStrokeColor = Config[ConfigKey] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(75, 75, 75)
        
        TweenService:Create(Ball, TweenInfo.new(0.12), {Position = targetPos, BackgroundColor3 = targetBallColor}):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.12), {BackgroundColor3 = targetBgColor}):Play()
        SwStroke.Color = targetStrokeColor
        
        if Callback then Callback(Config[ConfigKey]) end
    end)
end

-- Thiết kế linh kiện Slider vạch kẻ ngang tối giản hiển thị số liệu chính xác
local function AddMinecraftSlider(ParentPage, LabelText, Min, Max, ConfigKey, Callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Parent = ParentPage
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Size = UDim2.new(1, 0, 0, 42)

    local Label = Instance.new("TextLabel")
    Label.Parent = SliderFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 6, 0, 2)
    Label.Size = UDim2.new(1, -90, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.Text = LabelText:upper()
    Label.TextColor3 = Color3.fromRGB(210, 210, 210)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValueText = Instance.new("TextLabel")
    ValueText.Parent = SliderFrame
    ValueText.BackgroundTransparency = 1
    ValueText.Position = UDim2.new(1, -80, 0, 2)
    ValueText.Size = UDim2.new(0, 75, 0, 16)
    ValueText.Font = Enum.Font.GothamBold
    ValueText.Text = tostring(Config[ConfigKey])
    ValueText.TextColor3 = Color3.fromRGB(85, 255, 85)
    ValueText.TextSize = 11
    ValueText.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "SliderBar"
    SliderBar.Parent = SliderFrame
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SliderBar.BorderSizePixel = 0
    SliderBar.Position = UDim2.new(0, 6, 0, 24)
    SliderBar.Size = UDim2.new(1, -12, 0, 4)
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local Progress = Instance.new("Frame")
    Progress.Parent = SliderBar
    Progress.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
    Progress.BorderSizePixel = 0
    Progress.Size = UDim2.new((Config[ConfigKey] - Min) / (Max - Min), 0, 1, 0)
    Instance.new("UICorner", Progress).CornerRadius = UDim.new(1, 0)

    local InteractBtn = Instance.new("TextButton")
    InteractBtn.Parent = SliderBar
    InteractBtn.BackgroundTransparency = 1
    InteractBtn.Size = UDim2.new(1, 0, 1, 0)
    InteractBtn.Text = ""

    local isHolding = false
    InteractBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isHolding = true end
    end)
    InteractBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isHolding = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isHolding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local currentX = UserInputService:GetMouseLocation().X
            local barAbsoluteX = SliderBar.AbsolutePosition.X
            local barAbsoluteWidth = SliderBar.AbsoluteSize.X
            local ratio = math.clamp((currentX - barAbsoluteX) / barAbsoluteWidth, 0, 1)
            local currentVal = math.floor(Min + (Max - Min) * ratio)
            
            Progress.Size = UDim2.new(ratio, 0, 1, 0)
            ValueText.Text = tostring(currentVal)
            Config[ConfigKey] = currentVal
            if Callback then Callback(currentVal) end
        end
    end)
 end
-- ==============================================================================
-- 10. CONNECTIONS & FUNCTIONALITIES INJECTION MAP
-- ==============================================================================

-- Liên kết các thành phần điều khiển phân hệ Combat Engine
AddMinecraftToggle(CombatPage, "Enable Aimbot Lock", "Aimbot")
AddMinecraftToggle(CombatPage, "Team Guard Filter", "TeamCheck")
AddMinecraftToggle(CombatPage, "Wall Occlusion Check", "WallCheck")
AddMinecraftSlider(CombatPage, "Smoothing Interpolation", 1, 10, "Smoothness", function(val)
    Config.Smoothness = val / 20
end)

-- Liên kết các thành phần điều khiển phân hệ Visual Matrix Cao Cấp
AddMinecraftToggle(VisualPage, "ESP Master Control", "EspMaster")
AddMinecraftToggle(VisualPage, "Draw FOV Calibration", "FovCircle")
AddMinecraftSlider(VisualPage, "FOV Dynamic Radius", 30, 500, "FovRadius")
AddMinecraftToggle(VisualPage, "AlwaysOnTop Chams 3D", "EspBox")
AddMinecraftSlider(VisualPage, "Chams Opacity Power", 0, 100, "EspTransparency") -- CẬP NHẬT TRỰC TIẾP ĐỘ MỜ HỘP 3D
AddMinecraftToggle(VisualPage, "Bottom Center Tracers", "EspTracer")
AddMinecraftToggle(VisualPage, "Dynamic Informative Tag", "EspName")
AddMinecraftSlider(VisualPage, "Max Scan Distance Range", 100, 2000, "MaxDistance")

-- Liên kết các thành phần điều khiển phân hệ Player Custom Modifiers
AddMinecraftToggle(PlayerPage, "Velocity WalkSpeed Hack", "SpeedToggle")
AddMinecraftSlider(PlayerPage, "Custom Velocity Power", 16, 200, "WalkSpeed")
AddMinecraftToggle(PlayerPage, "Internal JumpPower Hack", "JumpToggle")
AddMinecraftSlider(PlayerPage, "Custom Jump Force", 50, 350, "JumpPower")

-- Tính năng mở rộng phụ trợ: Thế giới sáng rực rỡ (FullBright Engine)
AddMinecraftToggle(PlayerPage, "Environmental FullBright", "FullBright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient
        Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end
end)

-- ==============================================================================
-- 11. WORLD INFORMATION DESIGN PANEL (ABOUT PAGE)
-- ==============================================================================
local CreditText = Instance.new("TextLabel")
CreditText.Parent = AboutPage
CreditText.BackgroundTransparency = 1
CreditText.Size = UDim2.new(1, 0, 0, 60)
CreditText.Font = Enum.Font.Code
CreditText.Text = "WANGCAOS PRIVATE BUILD VERSION 3.0\nSTABLE ENGINE INTEGRATION (2026)\nAUTHENTICATED DEVELOPER: DAI CA WANG"
CreditText.TextColor3 = Color3.fromRGB(170, 170, 170)
CreditText.TextSize = 12
CreditText.TextYAlignment = Enum.TextYAlignment.Center

local DiscordBox = Instance.new("Frame")
DiscordBox.Parent = AboutPage
DiscordBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
DiscordBox.BorderSizePixel = 0
DiscordBox.Size = UDim2.new(1, 0, 0, 56)
Instance.new("UICorner", DiscordBox).CornerRadius = UDim.new(0, 8)
local BoxStrk = Instance.new("UIStroke", DiscordBox)
BoxStrk.Color = Color3.fromRGB(55, 55, 55)
BoxStrk.Thickness = 1

local DisTitle = Instance.new("TextLabel")
DisTitle.Parent = DiscordBox
DisTitle.BackgroundTransparency = 1
DisTitle.Position = UDim2.new(0, 12, 0, 6)
DisTitle.Size = UDim2.new(1, -24, 0, 14)
DisTitle.Font = Enum.Font.Gotham
DisTitle.Text = "OFFICIAL COMMUNITY SERVER DISCORD LINK:"
DisTitle.TextColor3 = Color3.fromRGB(130, 130, 130)
DisTitle.TextSize = 10
DisTitle.TextXAlignment = Enum.TextXAlignment.Left
    local CopyLinkBtn = Instance.new("TextButton")
CopyLinkBtn.Parent = DiscordBox
CopyLinkBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
CopyLinkBtn.Position = UDim2.new(0, 12, 0, 24)
CopyLinkBtn.Size = UDim2.new(1, -24, 0, 24)
CopyLinkBtn.Font = Enum.Font.Code
CopyLinkBtn.Text = "https://discord.gg/GmDYZEGSE"
CopyLinkBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
CopyLinkBtn.TextSize = 12
Instance.new("UICorner", CopyLinkBtn).CornerRadius = UDim.new(0, 5)

CopyLinkBtn.MouseButton1Click:Connect(function()
    local InviteLink = "https://discord.gg/GmDYZEGSE"
    if setclipboard then
        setclipboard(InviteLink)
        CopyLinkBtn.Text = "SAO CHÉP THÀNH CÔNG RỒI ĐẠI CA!"
    elseif toclipboard then
        toclipboard(InviteLink)
        CopyLinkBtn.Text = "SAO CHÉP THÀNH CÔNG RỒI ĐẠI CA!"
    else
        CopyLinkBtn.Text = "HÃY TỰ COPY TRÊN ĐÂY ĐẠI CA ƠI"
    end
    task.wait(2)
    CopyLinkBtn.Text = InviteLink
end)

-- Phím tắt [ hỗ trợ đại ca ẩn/hiện nhanh Menu Giao Diện Figma
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Config.MenuKeybind then
        Config.MenuVisible = not Config.MenuVisible
        MainFrame.Visible = Config.MenuVisible
    end
end)

local MasterConnection = nil

-- Dọn dẹp tài nguyên rác khi đại ca click nút X đóng client hoàn toàn
CloseBtn.MouseButton1Click:Connect(function()
    if MasterConnection then MasterConnection:Disconnect() end
    pcall(function() FOV_Drawing:Remove() end)
    
    for _, Line in pairs(Tracer_Cache) do
        pcall(function() Line:Remove() end)
    end
    
    for Character, Instances in pairs(Character_Cache) do
        CleanCharacterVisuals(Character)
    end
    
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

-- ==============================================================================
-- 12. RUNSERVICE PIPELINE ENGINE - THUẬT TOÁN KÉO TÂM & VẼ KHUNG 3D REAL-TIME
-- ==============================================================================
MasterConnection = RunService.RenderStepped:Connect(function()
    local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Vận hành vòng tròn FOV chuẩn chỉ
    if Config.FovCircle then
        FOV_Drawing.Position = ViewportCenter
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    -- Khống chế WalkSpeed & JumpPower của Đại ca không lo bị kẹt chết luồng
    local MyChar = LocalPlayer.Character
    if IsAlive(MyChar) then
        local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
        if MyHum then
            if Config.SpeedToggle then MyHum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpToggle then
                MyHum.UseJumpPower = true
                MyHum.JumpPower = Config.JumpPower
            end
        end
    end

    -- Khóa cứng mục tiêu vào Đầu thực thể (Aimbot Engine)
    if Config.Aimbot then
        local TargetPart = GetClosestPlayerToCrosshair()
        if TargetPart then
            local AimCFrame = CFrame.new(Camera.CFrame.Position, TargetPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Config.Smoothness)
        end
    end

    -- Pipeline xử lý dựng đồ họa Chams xuyên tường & Bảng chữ thông tin
    for Character, Data in pairs(Character_Cache) do
        if Character and Character.Parent and IsAlive(Character) then
            local Root = Character:FindFirstChild("HumanoidRootPart")
            local LocalChar = LocalPlayer.Character
            
            if Config.EspMaster and Root and LocalChar and LocalChar:FindFirstChild("HumanoidRootPart") then
                local PlayerColor = GetPlayerColor(Data.PlayerOwner)
                local Distance = math.floor((Root.Position - LocalChar.HumanoidRootPart.Position).Magnitude)
                local TeamName = Data.PlayerOwner.Team and Data.PlayerOwner.Team.Name or "No Team"
                local ToolName = GetEquippedTool(Character)

                -- Render Hộp đặc Chams nhìn xuyên tường kết hợp thanh trượt mờ động
                if Config.EspBox then
                    Data.BoxInstance.Visible = true
                    Data.BoxInstance.Color3 = PlayerColor
                    Data.BoxInstance.Transparency = Config.EspTransparency / 100
                else
                    Data.BoxInstance.Visible = false
                end

                -- Render Bảng chữ động đỉnh đầu
                if Config.EspName and Distance <= Config.MaxDistance then
                    Data.GuiInstance.Enabled = true
                    Data.LabelInstance.Visible = true
                    Data.LabelInstance.TextColor3 = PlayerColor
                    Data.LabelInstance.Text = string.format("%s (%dm)\n(%s)(%s)", Data.PlayerOwner.Name, Distance, TeamName, ToolName)
                else
                    Data.LabelInstance.Visible = false
                    Data.GuiInstance.Enabled = false
                end

                -- Render Đường kẻ Tracers Vector nối từ tâm dưới màn hình lên chân thực thể
                local TracerLine = Tracer_Cache[Data.PlayerOwner]
                if TracerLine then
                    if Config.EspTracer then
                        local LegPos, OnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                        if OnScreen then
                            TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            TracerLine.To = Vector2.new(LegPos.X, LegPos.Y)
                            TracerLine.Color = PlayerColor
                            TracerLine.Visible = true
                        else
                            TracerLine.Visible = false
                        end
                    else
                        TracerLine.Visible = false
                    end
                end
            else
                Data.BoxInstance.Visible = false
                Data.LabelInstance.Visible = false
                local TracerLine = Tracer_Cache[Data.PlayerOwner]
                if TracerLine then TracerLine.Visible = false end
            end
        else
            -- Giải phóng bộ nhớ của Character này nếu họ chết hoặc bị xóa instance
            CleanCharacterVisuals(Character)
            Character_Cache[Character] = nil
        end
    end
end)

-- ==============================================================================
-- 13. LIFECYCLE LISTENERS INTERACTION ENTRY
-- ==============================================================================
Players.PlayerAdded:Connect(function(Player)
    CreateTracerObject(Player)
    MonitorPlayerCharacter(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    ClearTracerObject(Player)
    if Player.Character then
        Character_Cache[Player.Character] = nil
    end
end)

-- Khởi động hệ thống an toàn cho toàn bộ danh sách người chơi hiện hữu trong phòng đấu
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateTracerObject(Player)
        MonitorPlayerCharacter(Player)
    end
end

print("================================================================================")
print("--- [WANGCAOS PREMIUM MULTI-THREADING V3 CLIENT COMPLETELY DEPLOYED 100%] ---")
print("================================================================================")
    
