-- ==============================================================================
-- WANGCAOS ADVANCED HYBRID V3 - MINECRAFT FIGMA STYLE UI
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình gốc đồng bộ hệ thống của đại ca
local Config = {
    CurrentTab = "Combat",
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 0.2,
    
    -- Visuals Matrix
    EspMaster = false,
    FovCircle = false,
    FovRadius = 120,
    EspBox = false,
    EspTracer = false,
    EspName = false,
    EspChams = false,
    
    -- Movement Vector
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50
}

local ESP_Cache = {}

-- Khởi tạo Drawing Vòng Tròn FOV
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Color3.fromRGB(255, 255, 255)
FOV_Drawing.Thickness = 1.5
FOV_Drawing.NumSides = 64
FOV_Drawing.Filled = false
FOV_Drawing.Transparency = 0.7
FOV_Drawing.Visible = false

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

local function GetSafeGui()
    if gethui then return gethui() end
    local success, core = pcall(function() return CoreGui end)
    if success then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local SafeParent = GetSafeGui()
for _, old in pairs(SafeParent:GetChildren()) do
    if old.Name == "Wangcaos_Minecraft_Figma_UI" then old:Destroy() end
end
-- ==============================================================================
-- 4. ESP GRAPHICS LAYER (CORNER BOX, FOOT TRACER, NAME VECTOR)
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
    
    for Name, Obj in pairs(CoreLines) do
        if string.find(Name, "Box_") then
            Obj.Thickness = 1.5
            Obj.Color = Color3.fromRGB(120, 255, 120)
        elseif Name == "Tracer" then
            Obj.Thickness = 1.2
            Obj.Color = Color3.fromRGB(240, 240, 240)
        elseif Name == "Name" then
            Obj.Size = 13
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
    
    local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local LegPos = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
    
    local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
    local BoxWidth = BoxHeight / 2
    local Box_X = RootPos.X - BoxWidth / 2
    local Box_Y = RootPos.Y - BoxHeight / 2
    local CornerLen = BoxWidth / 3
    
    -- VẼ KHUNG GÓC CORNER BOX
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
    
    -- VẼ TÊN NHÂN VẬT
    if Config.EspName then
        Elements.Name.Position = Vector2.new(Box_X + BoxWidth / 2, Box_Y - 16)
        Elements.Name.Text = Player.Name
        Elements.Name.Visible = true
    else
        Elements.Name.Visible = false
    end
    
    -- VẼ TRACER NỐI XUỐNG BÀN CHÂN CHUẨN CHỈ
    if Config.EspTracer then
        Elements.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        Elements.Tracer.To = Vector2.new(LegPos.X, LegPos.Y)
        Elements.Tracer.Visible = true
    else
        Elements.Tracer.Visible = false
    end
    
    -- ĐỔ MÀU XUYÊN TƯỜNG CHAMS
    local TargetHighlight = Char:FindFirstChild("WangUnifiedChams")
    if Config.EspChams then
        if not TargetHighlight then
            local NewChams = Instance.new("Highlight")
            NewChams.Name = "WangUnifiedChams"
            NewChams.FillColor = Color3.fromRGB(120, 255, 120)
            NewChams.OutlineColor = Color3.fromRGB(255, 255, 255)
            NewChams.FillTransparency = 0.5
            NewChams.OutlineTransparency = 0.2
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
-- 5. MINECRAFT HUD DESIGN - MAIN FRAME & HORIZONTAL NAVIGATION BAR
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Minecraft_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

-- Nút bấm Logo W mở Menu riêng biệt chống kẹt/trượt trên Mobile
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "MinecraftToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Position = UDim2.new(0, 15, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
local LogoStroke = Instance.new("UIStroke", ToggleButton)
LogoStroke.Color = Color3.fromRGB(80, 80, 80)
LogoStroke.Thickness = 1.2

-- Dragging Logic độc lập cho nút mở Logo
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

-- KHUNG CHÍNH CLIENT FIGMA DESIGN (Nền tối mờ, bo viền thanh lịch)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Visible = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(50, 50, 50)
FrameStroke.Thickness = 1.2

-- Thanh tiêu đề tích hợp chức năng Dragging chống kéo nhầm vào Tab
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Parent = MainFrame
HeaderBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HeaderBar.BackgroundTransparency = 1
HeaderBar.Size = UDim2.new(1, 0, 0, 35)

local ClientTitle = Instance.new("TextLabel")
ClientTitle.Parent = HeaderBar
ClientTitle.BackgroundTransparency = 1
ClientTitle.Position = UDim2.new(0, 15, 0, 0)
ClientTitle.Size = UDim2.new(0, 250, 1, 0)
ClientTitle.Font = Enum.Font.GothamBold
ClientTitle.Text = "WANGCAOS CLIENT | ADVANCED HYBRID V3"
ClientTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ClientTitle.TextSize = 13
ClientTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Nút đóng X khẩn cấp đặt sát góc phải HeaderBar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = HeaderBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Size = UDim2.new(0, 35, 1, 0)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 14

-- Dragging logic tách biệt cho khung giao diện Client tại HeaderBar
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
    MainFrame.Visible = not MainFrame.Visible
end)

-- THANH CHỨA TABS NGANG THEO ĐÚNG HÌNH ẢNH MINECRAFT FIGMA
local TabNavBar = Instance.new("Frame")
TabNavBar.Name = "TabNavBar"
TabNavBar.Parent = MainFrame
TabNavBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
TabNavBar.Position = UDim2.new(0, 15, 0, 40)
TabNavBar.Size = UDim2.new(1, -30, 0, 32)
Instance.new("UICorner", TabNavBar).CornerRadius = UDim.new(0, 6)

local TabPadding = Instance.new("UIPadding", TabNavBar)
TabPadding.PaddingLeft = UDim.new(0, 4)
TabPadding.PaddingRight = UDim.new(0, 4)
TabPadding.PaddingTop = UDim.new(0, 3)

local TabLayout = Instance.new("UIListLayout", TabNavBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 6)

-- Vùng hiển thị Nội dung tính năng (Content Container) ở phía dưới
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 82)
ContentContainer.Size = UDim2.new(1, -30, 1, -97)

local CombatPage = Instance.new("ScrollingFrame", ContentContainer)
local VisualPage = Instance.new("ScrollingFrame", ContentContainer)
local PlayerPage = Instance.new("ScrollingFrame", ContentContainer)
local AboutPage = Instance.new("ScrollingFrame", ContentContainer)

for _, page in pairs({CombatPage, VisualPage, PlayerPage, AboutPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 280)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    page.Visible = false
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
end
CombatPage.Visible = true
-- ==============================================================================
-- 6. MINECRAFT STYLED UI COMPONENTS (CAPSULE BUTTONS & MINIMAL SLIDERS)
-- ==============================================================================

local function CreateFigmaTab(Name, Order, PageTarget)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = Name .. "_Tab"
    TabBtn.Parent = TabNavBar
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(0, 98, 0, 26)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = Name:upper()
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 11
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 5)
    
    local TabStroke = Instance.new("UIStroke", TabBtn)
    TabStroke.Color = Order == 1 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 80, 80)
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
                btn.TextColor3 = Color3.fromRGB(150, 150, 150)
                local strk = btn:FindFirstChildOfClass("UIStroke")
                if strk then strk.Enabled = false end
            end
        end
        
        TabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabStroke.Color = Color3.fromRGB(100, 255, 100)
        TabStroke.Enabled = true
        PageTarget.Visible = true
    end)
end

CreateFigmaTab("Combat", 1, CombatPage)
CreateFigmaTab("Visuals", 2, VisualPage)
CreateFigmaTab("Player", 3, PlayerPage)
CreateFigmaTab("About", 4, AboutPage)

-- Thiết kế nút Toggle dẹt ngang kèm Switch chấm tròn di chuyển
local function AddMinecraftToggle(ParentPage, LabelText, ConfigKey, Callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Parent = ParentPage
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Size = UDim2.new(1, 0, 0, 32)

    local Label = Instance.new("TextLabel")
    Label.Parent = ToggleFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.Text = LabelText:upper()
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SwitchBg = Instance.new("Frame")
    SwitchBg.Parent = ToggleFrame
    SwitchBg.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(45, 75, 45) or Color3.fromRGB(35, 35, 35)
    SwitchBg.Position = UDim2.new(1, -40, 0.5, -8)
    SwitchBg.Size = UDim2.new(0, 32, 0, 16)
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    local SwStroke = Instance.new("UIStroke", SwitchBg)
    SwStroke.Color = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(70, 70, 70)
    SwStroke.Thickness = 1

    local Ball = Instance.new("Frame")
    Ball.Parent = SwitchBg
    Ball.BackgroundColor3 = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
    Ball.Position = Config[ConfigKey] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    Ball.Size = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Parent = ToggleFrame
    ActionBtn.BackgroundTransparency = 1
    ActionBtn.Size = UDim2.new(1, 0, 1, 0)
    ActionBtn.Text = ""

    ActionBtn.MouseButton1Click:Connect(function()
        Config[ConfigKey] = not Config[ConfigKey]
        
        local targetPos = Config[ConfigKey] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local targetBgColor = Config[ConfigKey] and Color3.fromRGB(45, 75, 45) or Color3.fromRGB(35, 35, 35)
        local targetBallColor = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
        local targetStrokeColor = Config[ConfigKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(70, 70, 70)
        
        TweenService:Create(Ball, TweenInfo.new(0.15), {Position = targetPos, BackgroundColor3 = targetBallColor}):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = targetBgColor}):Play()
        SwStroke.Color = targetStrokeColor
        
        if Callback then Callback(Config[ConfigKey]) end
    end)
end

-- Thiết kế thanh chạy Slider dạng vạch kẻ ngang của Figma Client
local function AddMinecraftSlider(ParentPage, LabelText, Min, Max, ConfigKey, Callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Parent = ParentPage
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Size = UDim2.new(1, 0, 0, 38)

    local Label = Instance.new("TextLabel")
    Label.Parent = SliderFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 4, 0, 2)
    Label.Size = UDim2.new(1, -80, 0, 14)
    Label.Font = Enum.Font.Gotham
    Label.Text = LabelText:upper()
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValueText = Instance.new("TextLabel")
    ValueText.Parent = SliderFrame
    ValueText.BackgroundTransparency = 1
    ValueText.Position = UDim2.new(1, -70, 0, 2)
    ValueText.Size = UDim2.new(0, 65, 0, 14)
    ValueText.Font = Enum.Font.GothamBold
    ValueText.Text = tostring(Config[ConfigKey])
    ValueText.TextColor3 = Color3.fromRGB(100, 255, 100)
    ValueText.TextSize = 11
    ValueText.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "SliderBar"
    SliderBar.Parent = SliderFrame
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    SliderBar.BorderSizePixel = 0
    SliderBar.Position = UDim2.new(0, 4, 0, 22)
    SliderBar.Size = UDim2.new(1, -8, 0, 4)
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local Progress = Instance.new("Frame")
    Progress.Parent = SliderBar
    Progress.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
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
    UserInputService.InputEnded:Connect(function(input)
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

-- Đấu nối cấu hình dữ liệu cho từng tab phân mục
AddMinecraftToggle(CombatPage, "Enable Head Aimbot", "Aimbot")
AddMinecraftToggle(CombatPage, "Team Check (Ignore Allies)", "TeamCheck")
AddMinecraftToggle(CombatPage, "Wall Check (Ignore Walls)", "WallCheck")
AddMinecraftSlider(CombatPage, "Aimbot Smoothness Engine", 1, 10, "Smoothness", function(val)
    Config.Smoothness = val / 20
end)

AddMinecraftToggle(VisualPage, "Visual Master Switch", "EspMaster")
AddMinecraftToggle(VisualPage, "Show FOV Circle", "FovCircle")
AddMinecraftSlider(VisualPage, "FOV Circle Radius", 30, 500, "FovRadius")
AddMinecraftToggle(VisualPage, "Corner ESP Boxes", "EspBox")
AddMinecraftToggle(VisualPage, "Bottom Foot Tracers", "EspTracer")
AddMinecraftToggle(VisualPage, "Identity Name Text", "EspName")
AddMinecraftToggle(VisualPage, "Xray Body Chams", "EspChams")

AddMinecraftToggle(PlayerPage, "Override WalkSpeed", "SpeedToggle")
AddMinecraftSlider(PlayerPage, "Speed Custom Power", 16, 150, "WalkSpeed")
AddMinecraftToggle(PlayerPage, "Override JumpPower", "JumpToggle")
AddMinecraftSlider(PlayerPage, "Jump Custom Power", 50, 250, "JumpPower")
-- ==============================================================================
-- 7. ABOUT PAGE DESIGN (DISCORD EMBED) & CENTRAL RENDERING LOOP SYSTEM
-- ==============================================================================

-- Thiết lập khối nhãn thông tin tác giả và bản quyền
local CreditText = Instance.new("TextLabel")
CreditText.Parent = AboutPage
CreditText.BackgroundTransparency = 1
CreditText.Size = UDim2.new(1, 0, 0, 55)
CreditText.Font = Enum.Font.GothamBold
CreditText.Text = "WANGCAOS CLIENT PREMIUM\nSTYLE MINECRAFT HYBRID V3 (2026)\nĐẠI CA SỬ DỤNG VUI VẺ CHUẨN CHỈ!"
CreditText.TextColor3 = Color3.fromRGB(180, 180, 180)
CreditText.TextSize = 11
CreditText.TextYAlignment = Enum.TextYAlignment.Center

local DiscordBox = Instance.new("Frame")
DiscordBox.Parent = AboutPage
DiscordBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
DiscordBox.BorderSizePixel = 0
DiscordBox.Size = UDim2.new(1, 0, 0, 52)
Instance.new("UICorner", DiscordBox).CornerRadius = UDim.new(0, 6)
local BoxStrk = Instance.new("UIStroke", DiscordBox)
BoxStrk.Color = Color3.fromRGB(60, 60, 60)
BoxStrk.Thickness = 1

local DisTitle = Instance.new("TextLabel")
DisTitle.Parent = DiscordBox
DisTitle.BackgroundTransparency = 1
DisTitle.Position = UDim2.new(0, 10, 0, 4)
DisTitle.Size = UDim2.new(1, -20, 0, 14)
DisTitle.Font = Enum.Font.Gotham
DisTitle.Text = "CỘNG ĐỒNG DISCORD CHÍNH THỨC:"
DisTitle.TextColor3 = Color3.fromRGB(140, 140, 140)
DisTitle.TextSize = 10
DisTitle.TextXAlignment = Enum.TextXAlignment.Left

local CopyLinkBtn = Instance.new("TextButton")
CopyLinkBtn.Parent = DiscordBox
CopyLinkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CopyLinkBtn.Position = UDim2.new(0, 10, 0, 22)
CopyLinkBtn.Size = UDim2.new(1, -20, 0, 22)
CopyLinkBtn.Font = Enum.Font.GothamBold
CopyLinkBtn.Text = "https://discord.gg/GmDYZEGSE"
CopyLinkBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
CopyLinkBtn.TextSize = 11
Instance.new("UICorner", CopyLinkBtn).CornerRadius = UDim.new(0, 4)

CopyLinkBtn.MouseButton1Click:Connect(function()
    local InviteLink = "https://discord.gg/GmDYZEGSE"
    if setclipboard then
        setclipboard(InviteLink)
        CopyLinkBtn.Text = "ĐÃ SAO CHÉP THÀNH CÔNG!"
    elseif toclipboard then
        toclipboard(InviteLink)
        CopyLinkBtn.Text = "ĐÃ SAO CHÉP THÀNH CÔNG!"
    else
        CopyLinkBtn.Text = "HÃY TỰ BÔI ĐEN COPY LINK"
    end
    task.wait(2)
    CopyLinkBtn.Text = InviteLink
end)

-- Xử lý chức năng tắt dọn dẹp bộ nhớ khi bấm nút X trên HeaderBar
local MasterPipeline = nil

CloseBtn.MouseButton1Click:Connect(function()
    if MasterPipeline then MasterPipeline:Disconnect() end
    FOV_Drawing.Visible = false
    FOV_Drawing:Remove()
    for _, Player in pairs(Players:GetPlayers()) do
        ClearPlayerESP(Player)
        if Player.Character then
            local OldChams = Player.Character:FindFirstChild("WangUnifiedChams")
            if OldChams then OldChams:Destroy() end
        end
    end
    ScreenGui:Destroy()
end)

-- ==============================================================================
-- 8. MASTER LOOP TIMING OPERATION (AIMBOT, FOV & GRAPHICS ESP CONNECTED)
-- ==============================================================================
MasterPipeline = RunService.RenderStepped:Connect(function()
    local MouseCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Điều phối hiển thị vòng tròn FOV drawing
    if Config.FovCircle then
        FOV_Drawing.Position = MouseCenter
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    -- Khống chế thuộc tính di chuyển của nhân vật
    local MyChar = LocalPlayer.Character
    if MyChar and IsAlive(MyChar) then
        local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
        if MyHum then
            if Config.SpeedToggle then MyHum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpToggle then
                MyHum.UseJumpPower = true
                MyHum.JumpPower = Config.JumpPower
            end
        end
    end

    -- Khóa cứng camera vào ĐẦU mục tiêu (HEAD AIMBOT)
    if Config.Aimbot then
        local TargetHeadPart = GetClosestHeadToCrosshair()
        if TargetHeadPart then
            local AimCFrame = CFrame.new(Camera.CFrame.Position, TargetHeadPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Config.Smoothness)
        end
    end

    -- Cập nhật dữ liệu đồ họa vẽ ESP cho toàn phòng đấu
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local PlayerElements = ESP_Cache[Player]
            if PlayerElements then
                pcall(ProcessRenderESP, Player, PlayerElements)
            end
        end
    end
end)

-- Quản lý vòng đời gia nhập phòng của người chơi
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
print("--- [WANGCAOS ADVANCED V3 CLIENT INITIALIZED COMPLETE] ---")
print("--- [FIGMA MINECRAFT THEME & FOOT TRACERS DEPLOYED] ---")
print("================================================================")
