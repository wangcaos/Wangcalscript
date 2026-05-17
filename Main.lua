-- ==============================================================================
-- WANGCAOS SUPER UNIFIED - ESP/AIM/CHAMS & ABOUT DISCORD FIX
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==============================================================================
-- 1. MASTER CONFIGURATION (CORE OLD REQUESTS)
-- ==============================================================================
local Config = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 0.2, -- Aimbot Speed
    
    -- Visuals ESP MASTER开关
    EspMaster = false,
    FovCircle = false, -- FOV vòng tròn
    FovRadius = 120,
    EspBox = false,   -- Khung góc Corner
    EspTracer = false, -- Đường kẻ tâm
    EspName = false,   -- Tên
    EspChams = false,  -- Chams xuyên tường
    
    -- Movement MASTER开关
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50
}

-- Caching data cho hệ thống Drawing Vector
local ESP_Cache = {}

-- Khởi tạo vòng tròn FOV chuẩn Drawing Vector
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Color3.fromRGB(255, 255, 255)
FOV_Drawing.Thickness = 1.5
FOV_Drawing.NumSides = 64
FOV_Drawing.Filled = false
FOV_Drawing.Transparency = 0.8
FOV_Drawing.Visible = false

-- ==============================================================================
-- 2. CORE UTILITIES & TARGET FILTERING
-- ==============================================================================
local function IsAlive(Character)
    if not Character then return false end
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

-- Tìm mục tiêu gần tâm chuột nhất (Ưu tiên HEAD)
local function GetClosestHeadToCrosshair()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ClosestTarget = nil
    local MaxDist = Config.FovRadius

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and IsAlive(Player.Character) then
            if Config.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local Head = Player.Character:FindFirstChild("Head")
            if Head then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                if OnScreen and CheckWallOcclusion(Head, Player.Character) then
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

-- ==============================================================================
-- 3. SAFE GUI INJECTION & CLEANUP
-- ==============================================================================
local function GetSafeGui()
    if gethui then return gethui() end
    local success, core = pcall(function() return CoreGui end)
    if success then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local SafeParent = GetSafeGui()
for _, old in pairs(SafeParent:GetChildren()) do
    if old.Name == "Wangcaos_SuperUnified_Menu" then old:Destroy() end
end
-- ==============================================================================
-- 4. ESP VECTOR INFRASTRUCTURE (CORNER BOX, TRACER, NAME DRAWING)
-- ==============================================================================

local function CreatePlayerESP(Player)
    if ESP_Cache[Player] then return end
    
    local CoreLines = {
        Box_TL1 = Drawing.new("Line"), Box_TL2 = Drawing.new("Line"),
        Box_TR1 = Drawing.new("Line"), Box_TR2 = Drawing.new("Line"),
        Box_BL1 = Drawing.new("Line"), Box_BL2 = Drawing.new("Line"),
        Box_BR1 = Drawing.new("Line"), Box_BR2 = Drawing.new("Line"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text")
    }
    
    -- Gán thuộc tính đồ họa nền tảng cho Drawing Objects
    for Name, Obj in pairs(CoreLines) do
        if string.find(Name, "Box_") then
            Obj.Thickness = 1.5
            Obj.Color = Color3.fromRGB(100, 255, 100)
        elseif Name == "Tracer" then
            Obj.Thickness = 1.2
            Obj.Color = Color3.fromRGB(100, 100, 255)
        elseif Name == "Name" then
            Obj.Size = 14
            Obj.Center = true
            Obj.Outline = true
            Obj.OutlineColor = Color3.fromRGB(0, 0, 0)
            Obj.Color = Color3.fromRGB(255, 255, 255)
        end
        Obj.Transparency = 1
        Obj.Visible = false
    end
    
    ESP_Cache[Player] = CoreLines
end

local function ClearPlayerESP(Player)
    if ESP_Cache[Player] then
        for _, Obj in pairs(ESP_Cache[Player]) do
            Obj:Remove()
        end
        ESP_Cache[Player] = nil
    end
end

-- Vòng lặp xử lý vẽ dữ liệu màn hình động cho từng Player
local function ProcessRenderESP(Player, Elements)
    local Char = Player.Character
    if not Config.EspMaster or not Char or not IsAlive(Char) then
        for _, Obj in pairs(Elements) do Obj.Visible = false end
        return
    end
    
    local RootPart = Char:FindFirstChild("HumanoidRootPart")
    local Head = Char:FindFirstChild("Head")
    if not RootPart or not Head then
        for _, Obj in pairs(Elements) do Obj.Visible = false end
        return
    end
    
    local RootPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
    if not OnScreen then
        for _, Obj in pairs(Elements) do Obj.Visible = false end
        return
    end
    
    -- Trích xuất tọa độ 2 chiều từ không gian 3D
    local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local LegPos = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
    
    local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
    local BoxWidth = BoxHeight / 2
    local Box_X = RootPos.X - BoxWidth / 2
    local Box_Y = RootPos.Y - BoxHeight / 2
    local CornerLen = BoxWidth / 3
    
    -- XỬ LÝ RENDERING KHUNG GÓC (CORNER BOX)
    if Config.EspBox then
        Elements.Box_TL1.From = Vector2.new(Box_X, Box_Y) Elements.Box_TL1.To = Vector2.new(Box_X + CornerLen, Box_Y)
        Elements.Box_TL2.From = Vector2.new(Box_X, Box_Y) Elements.Box_TL2.To = Vector2.new(Box_X, Box_Y + CornerLen)
        
        Elements.Box_TR1.From = Vector2.new(Box_X + BoxWidth, Box_Y) Elements.Box_TR1.To = Vector2.new(Box_X + BoxWidth - CornerLen, Box_Y)
        Elements.Box_TR2.From = Vector2.new(Box_X + BoxWidth, Box_Y) Elements.Box_TR2.To = Vector2.new(Box_X + BoxWidth, Box_Y + CornerLen)
        
        Elements.Box_BL1.From = Vector2.new(Box_X, Box_Y + BoxHeight) Elements.Box_BL1.To = Vector2.new(Box_X + CornerLen, Box_Y + BoxHeight)
        Elements.Box_BL2.From = Vector2.new(Box_X, Box_Y + BoxHeight) Elements.Box_BL2.To = Vector2.new(Box_X, Box_Y + BoxHeight - CornerLen)
        
        Elements.Box_BR1.From = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight) Elements.Box_BR1.To = Vector2.new(Box_X + BoxWidth - CornerLen, Box_Y + BoxHeight)
        Elements.Box_BR2.From = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight) Elements.Box_BR2.To = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight - CornerLen)
        
        for Name, Obj in pairs(Elements) do if string.find(Name, "Box_") then Obj.Visible = true end end
    else
        for Name, Obj in pairs(Elements) do if string.find(Name, "Box_") then Obj.Visible = false end end
    end
    
    -- XỬ LÝ RENDERING TÊN (NAME TAG)
    if Config.EspName then
        Elements.Name.Position = Vector2.new(Box_X + BoxWidth / 2, Box_Y - 16)
        Elements.Name.Text = Player.Name
        Elements.Name.Visible = true
    else
        Elements.Name.Visible = false
    end
    
    -- XỬ LÝ RENDERING ĐƯỜNG KẺ TÂM CHUỘT (TRACER)
    if Config.EspTracer then
        Elements.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        Elements.Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
        Elements.Tracer.Visible = true
    else
        Elements.Tracer.Visible = false
    end
    
    -- XỬ LÝ KHỐI MÀU XUYÊN TƯỜNG (CHAMS)
    local TargetHighlight = Char:FindFirstChild("WangUnifiedChams")
    if Config.EspChams then
        if not TargetHighlight then
            local NewChams = Instance.new("Highlight")
            NewChams.Name = "WangUnifiedChams"
            NewChams.FillColor = Color3.fromRGB(255, 50, 50)
            NewChams.OutlineColor = Color3.fromRGB(255, 255, 255)
            NewChams.FillTransparency = 0.5
            NewChams.OutlineTransparency = 0
            NewChams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            NewChams.Parent = Char
        else
            TargetHighlight.Enabled = true
        end
    else
        if TargetHighlight then TargetHighlight.Enabled = false end
    end
end
-- ==============================================================================
-- 5. FIXED DRAG INTERACTION - SCREEN MASTER GUI INFRASTRUCTURE
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_SuperUnified_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

-- Logo mở Menu (Được cố định trục riêng, tuyệt đối không bị trượt khi nhấn)
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

-- Cơ chế Kéo Thả độc lập cho nút Logo bật/tắt
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

-- Khung chính chứa toàn bộ Layout UI Library
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

-- Thanh bar tiêu đề phía trên (Chỉ cho phép kéo thả toàn bộ khung tại đây)
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
TitleText.Text = "WANGCAOS PRIVATE | CORE V2"
TitleText.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Cơ chế Kéo Thả độc lập cho MainFrame thông qua thanh TopBar
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

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Phân vùng kiến trúc quản lý Tabs
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

-- Tạo vùng chứa dữ liệu cho 4 trang danh mục chính
local CombatPage = Instance.new("ScrollingFrame", MainContent)
local VisualPage = Instance.new("ScrollingFrame", MainContent)
local PlayerPage = Instance.new("ScrollingFrame", MainContent)
local AboutPage = Instance.new("ScrollingFrame", MainContent)

for _, page in pairs({CombatPage, VisualPage, PlayerPage, AboutPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 320)
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
CombatPage.Visible = true
-- ==============================================================================
-- 6. UI LIBRARY ELEMENTS CREATION ENGINE (TOGGLE, SLIDER & ABOUT LINK)
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
    TabBtn.TextSize = 13

    TabBtn.MouseButton1Click:Connect(function()
        CombatPage.Visible = false
        VisualPage.Visible = false
        PlayerPage.Visible = false
        AboutPage.Visible = false
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
CreateTabButton("Visuals", 2, VisualPage)
CreateTabButton("Player", 3, PlayerPage)
CreateTabButton("About", 4, AboutPage)

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

-- ==============================================================================
-- 7. FILLING CONTROLS INTO RESPECTIVE PAGES
-- ==============================================================================

-- Tab Aimbot Lock Đầu
AddToggle(CombatPage, "Enable Head Aimbot", "Aimbot")
AddToggle(CombatPage, "Team Check (Ignore Allies)", "TeamCheck")
AddToggle(CombatPage, "Wall Check (Ignore Obstacles)", "WallCheck")
AddSlider(CombatPage, "Lock Smoothness Engine", 1, 10, "Smoothness", function(val)
    Config.Smoothness = val / 20 -- Quy đổi mượt từ 0.05 đến 0.5
end)

-- Tab Visuals (Khôi phục toàn bộ các mục vẽ cũ)
AddToggle(VisualPage, "Visual Master Switch", "EspMaster")
AddToggle(VisualPage, "Show FOV Safe Circle", "FovCircle")
AddSlider(VisualPage, "Adjust FOV Radius Circle", 30, 500, "FovRadius")
AddToggle(VisualPage, "Enable Corner Boxes ESP", "EspBox")
AddToggle(VisualPage, "Enable Bottom Tracers Line", "EspTracer")
AddToggle(VisualPage, "Enable Identity Text Name", "EspName")
AddToggle(VisualPage, "Enable 3D Xray Body Chams", "EspChams")

-- Tab Player Movement 
AddToggle(PlayerPage, "Override WalkSpeed", "SpeedToggle")
AddSlider(PlayerPage, "Speed Custom Power", 16, 150, "WalkSpeed")
AddToggle(PlayerPage, "Override JumpPower", "JumpToggle")
AddSlider(PlayerPage, "Jump Custom Power", 50, 250, "JumpPower")
-- ==============================================================================
-- 8. ABOUT DESIGN (DISCORD SYSTEM) & CENTRAL PIPELINE LOGIC
-- ==============================================================================

-- Thiết kế giao diện thông tin bản quyền và tích hợp Link sao chép
local InfoText = Instance.new("TextLabel")
InfoText.Parent = AboutPage
InfoText.BackgroundTransparency = 1
InfoText.Size = UDim2.new(1, 0, 0, 60)
InfoText.Font = Enum.Font.SourceSansBold
InfoText.Text = "Wangcaos Premium Hub\nPhiên Bản Tối Ưu Hóa Sửa Lỗi 2026\nĐại ca sử dụng vui vẻ!"
InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoText.TextSize = 14
InfoText.TextYAlignment = Enum.TextYAlignment.Center

local DiscordFrame = Instance.new("Frame")
DiscordFrame.Parent = AboutPage
DiscordFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DiscordFrame.BorderSizePixel = 0
DiscordFrame.Size = UDim2.new(1, 0, 0, 50)
Instance.new("UICorner", DiscordFrame).CornerRadius = UDim.new(0, 4)

local DiscordLabel = Instance.new("TextLabel")
DiscordLabel.Parent = DiscordFrame
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Position = UDim2.new(0, 8, 0, 4)
DiscordLabel.Size = UDim2.new(1, -16, 0, 16)
DiscordLabel.Font = Enum.Font.SourceSans
DiscordLabel.Text = "Cộng Đồng Discord chính thức:"
DiscordLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
DiscordLabel.TextSize = 12
DiscordLabel.TextXAlignment = Enum.TextXAlignment.Left

local LinkBtn = Instance.new("TextButton")
LinkBtn.Parent = DiscordFrame
LinkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LinkBtn.Position = UDim2.new(0, 8, 0, 22)
LinkBtn.Size = UDim2.new(1, -16, 0, 22)
LinkBtn.Font = Enum.Font.SourceSansBold
LinkBtn.Text = "https://discord.gg/GmDYZEGSE"
LinkBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
LinkBtn.TextSize = 13
Instance.new("UICorner", LinkBtn).CornerRadius = UDim.new(0, 4)

-- Cơ chế tự động sao chép link khi click trên mọi loại Executor thiết bị
LinkBtn.MouseButton1Click:Connect(function()
    local TargetLink = "https://discord.gg/GmDYZEGSE"
    if setclipboard then
        setclipboard(TargetLink)
        LinkBtn.Text = "Đã Sao Chép Vào Bộ Nhớ!"
    elseif toclipboard then
        toclipboard(TargetLink)
        LinkBtn.Text = "Đã Sao Chép Vào Bộ Nhớ!"
    else
        LinkBtn.Text = "Vui lòng tự bôi đen copy link"
    end
    task.wait(2)
    LinkBtn.Text = TargetLink
end)

-- Nút thoát dọn dẹp bộ nhớ khẩn cấp trên thanh tiêu đề
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

local MasterLoopConnection = nil

CloseMenuBtn.MouseButton1Click:Connect(function()
    if MasterLoopConnection then MasterLoopConnection:Disconnect() end
    FOV_Drawing.Visible = false
    FOV_Drawing:Remove()
    for _, Player in pairs(Players:GetPlayers()) do
        ClearPlayerESP(Player)
        if Player.Character then
            local Tag = Player.Character:FindFirstChild("WangUnifiedChams")
            if Tag then Tag:Destroy() end
        end
    end
    ScreenGui:Destroy()
end)

-- ==============================================================================
-- 9. CENTRAL RENDERSTEPPED LOOP MANAGEMENT PIPELINE
-- ==============================================================================
MasterLoopConnection = RunService.RenderStepped:Connect(function()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Xử lý hiển thị vòng tròn FOV chuẩn không bị tàng hình
    if Config.FovCircle then
        FOV_Drawing.Position = Center
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    -- Xử lý can thiệp thuộc tính nhân vật WalkSpeed / JumpPower
    local Char = LocalPlayer.Character
    if Char and IsAlive(Char) then
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        if Hum then
            if Config.SpeedToggle then Hum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpToggle then
                Hum.UseJumpPower = true
                Hum.JumpPower = Config.JumpPower
            end
        end
    end

    -- Xử lý khóa tâm mượt vào ĐẦU (HEAD AIMBOT ENGINE)
    if Config.Aimbot then
        local TargetHead = GetClosestHeadToCrosshair()
        if TargetHead then
            local TargetCFrame = CFrame.new(Camera.CFrame.Position, TargetHead.Position)
            Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Config.Smoothness)
        end
    end

    -- Xử lý render Vector Visuals ESP màn hình cho từng thực thể người chơi
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Elements = ESP_Cache[Player]
            if Elements then
                pcall(ProcessRenderESP, Player, Elements)
            end
        end
    end
end)

-- Quản lý lắng nghe vòng đời kết nối thực thể phòng đấu
Players.PlayerAdded:Connect(function(Player)
    CreatePlayerESP(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    ClearPlayerESP(Player)
end)

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then CreatePlayerESP(Player) end
end

print("================================================================")
print("--- [WANGCAOS PRIVATE FIXED SCRIPT INITIALIZED 100%] ---")
print("--- [AIMBOT HEAD / FOV CIRCLE / ALL VISUALS RE-CONNECTED] ---")
print("================================================================")
