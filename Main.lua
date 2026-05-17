-- ==============================================================================
-- WANGCAOS ADVANCED HYBRID V3 - BOX ADORNMENT & CHAMS UPDATE
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình Master tích hợp hệ thống Chams Hộp Đặc theo ý đại ca
local Config = {
    CurrentTab = "Combat",
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 0.2,
    
    -- Visuals Matrix New Remake
    EspMaster = false,
    FovCircle = false,
    FovRadius = 120,
    EspBox = false,      -- Bật/Tắt Hộp Đặc (BéBoxFill)
    EspTracer = false,   -- Đường kẻ tâm chân
    EspName = false,     -- Bật/Tắt Bảng Chữ Đỉnh Đầu (BéInfoTag)
    
    -- Khống chế thuộc tính di chuyển
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50
}

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

-- Xác định màu sắc chuẩn (Ưu tiên màu Team, không có trả về Xanh lá mặc định)
local function GetPlayerColor(Player)
    if Player.Team then
        return Player.TeamColor.Color
    end
    if Player.TeamColor ~= BrickColor.new("White") and Player.TeamColor ~= BrickColor.new("Medium stone grey") then
        return Player.TeamColor.Color
    end
    return Color3.fromRGB(0, 255, 0)
end

-- Trích xuất tên công cụ/vũ khí đang cầm trên tay thực thể
local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        return Tool.Name
    end
    return "None"
end

-- Tìm mục tiêu khóa đầu gần tâm chuột nhất
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
-- 3. CORE ESP INFRASTRUCTURE - BOX ADORNMENT & BILLBOARD TAG GENERATOR
-- ==============================================================================

local Tracer_Cache = {}

local function CreateTracerObject(Player)
    if Tracer_Cache[Player] then return end
    local Line = Drawing.new("Line")
    Line.Thickness = 1.2
    Line.Color = Color3.fromRGB(240, 240, 240)
    Line.Transparency = 1
    Line.Visible = false
    Tracer_Cache[Player] = Line
end

local function ClearTracerObject(Player)
    if Tracer_Cache[Player] then
        Tracer_Cache[Player]:Remove()
        Tracer_Cache[Player] = nil
    end
end

-- Hàm khởi tạo và xử lý đồng bộ cấu trúc Adornment + Billboard cho từng Player
local function SetupAdornmentESP(Player)
    if Player == LocalPlayer then return end

    local function CoreSetup(Character)
        local Root = Character:WaitForChild("HumanoidRootPart", 15)
        local Head = Character:WaitForChild("Head", 15)
        if not Root or not Head then return end

        -- Khởi tạo hoặc dọn dẹp Box Hộp Đặc 3D (20% màu)
        if Root:FindFirstChild("BéBoxFill") then Root["BéBoxFill"]:Destroy() end
        local Box = Instance.new("BoxHandleAdornment")
        Box.Name = "BéBoxFill"
        Box.Parent = Root
        Box.Adornee = Root
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Size = Vector3.new(4, 6, 4)
        Box.Transparency = 0.8
        Box.Visible = false

        -- Khởi tạo hoặc dọn dẹp Bảng Chữ Thông Tin Đỉnh Đầu
        if Head:FindFirstChild("BéInfoTag") then Head["BéInfoTag"]:Destroy() end
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
        Label.TextColor3 = Color3.new(1, 1, 1)
        Gui.Parent = Head

        -- Vòng lặp lắng nghe Render để đồng bộ hóa trạng thái theo Menu Config
        local RenderConn
        RenderConn = RunService.RenderStepped:Connect(function()
            if not Character.Parent or not Root.Parent or not Head.Parent then
                RenderConn:Disconnect()
                Gui:Destroy()
                return
            end

            local Hum = Character:FindFirstChildOfClass("Humanoid")
            local LocalChar = LocalPlayer.Character
            
            if Config.EspMaster and Hum and Hum.Health > 0 and LocalChar and LocalChar:FindFirstChild("HumanoidRootPart") then
                local PlayerColor = GetPlayerColor(Player)
                local Distance = math.floor((Root.Position - LocalChar.HumanoidRootPart.Position).Magnitude)
                local TeamName = Player.Team and Player.Team.Name or "No Team"
                local ToolName = GetEquippedTool(Character)

                -- Đồng bộ trạng thái Hộp Đặc 3D theo Menu Toggle
                if Config.EspBox then
                    Box.Visible = true
                    Box.Color3 = PlayerColor
                else
                    Box.Visible = false
                end

                -- Đồng bộ trạng thái Bảng chữ Thông tin Đỉnh Đầu theo Menu Toggle
                if Config.EspName then
                    Gui.Enabled = true
                    Label.Visible = true
                    Label.TextColor3 = PlayerColor
                    Label.Text = string.format("%s (%dm)\n(%s)(%s)", Player.Name, Distance, TeamName, ToolName)
                else
                    Label.Visible = false
                    Gui.Enabled = false
                end
                
                -- Xử lý đường kẻ Tracer chân đồng bộ bằng Vector Drawing
                local TracerLine = Tracer_Cache[Player]
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
                Box.Visible = false
                Label.Visible = false
                local TracerLine = Tracer_Cache[Player]
                if TracerLine then TracerLine.Visible = false end
            end
        end)
    end

    Player.CharacterAdded:Connect(CoreSetup)
    if Player.Character then CoreSetup(Player.Character) end
end
-- ==============================================================================
-- 4. MINECRAFT HUD DESIGN - HORIZONTAL TAB CONTROL & DRAG LOGIC
-- ==============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Minecraft_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

-- Nút mở Menu hình tròn cố định riêng biệt chống trượt kẹt
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

-- Cơ chế Kéo Thả cho nút bật tắt Logo
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

-- KHUNG MENU CHÍNH STYLE FIGMA MINECRAFT CLIENT
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

-- Thanh tiêu đề Header điều khiển Drag chính của Menu
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

-- Nút đóng góc trên bên phải thanh Header
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

-- Cơ chế Kéo Thả độc lập cho Khung Giao Diện tại HeaderBar
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

-- THANH CHỨA TABS TÙY CHỌN ĐẶT NGANG PHÍA TRÊN
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

-- Content Container quản lý lật trang nội dung
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
-- 5. MINECRAFT STYLED UI COMPONENTS (CAPSULE BUTTONS & MINIMAL SLIDERS)
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

-- Thiết kế nút Toggle dẹt ngang kèm Switch chấm tròn di chuyển phong cách Figma Client
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

-- Thiết kế thanh chạy Slider vạch kẻ ngang tối giản
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

-- Đấu nối trực tiếp hệ thống cấu hình vào các trang menu tương tác
AddMinecraftToggle(CombatPage, "Enable Head Aimbot", "Aimbot")
AddMinecraftToggle(CombatPage, "Team Check", "TeamCheck")
AddMinecraftToggle(CombatPage, "Wall Check", "WallCheck")
AddMinecraftSlider(CombatPage, "Lock Smoothness", 1, 10, "Smoothness", function(val)
    Config.Smoothness = val / 20
end)

-- Gán nhãn điều khiển tương ứng cấu trúc Adornment mới của đại ca
AddMinecraftToggle(VisualPage, "Visual Master Switch", "EspMaster")
AddMinecraftToggle(VisualPage, "Show FOV Circle", "FovCircle")
AddMinecraftSlider(VisualPage, "Fov Circle Radius", 30, 500, "FovRadius")
AddMinecraftToggle(VisualPage, "Corner ESP Boxes", "EspBox")     -- Bật tắt Hộp Đặc 3D
AddMinecraftToggle(VisualPage, "Bottom Foot Tracers", "EspTracer") -- Bật tắt Tracer chân Drawing
AddMinecraftToggle(VisualPage, "Identity Name Text", "EspName")   -- Bật tắt Bảng thông tin động

AddMinecraftToggle(PlayerPage, "Override WalkSpeed", "SpeedToggle")
AddMinecraftSlider(PlayerPage, "Speed Custom Power", 16, 150, "WalkSpeed")
AddMinecraftToggle(PlayerPage, "Override JumpPower", "JumpToggle")
AddMinecraftSlider(PlayerPage, "Jump Custom Power", 50, 250, "JumpPower")
-- ==============================================================================
-- 6. DISCORD INFO PANEL DESIGN & MASTER CONNECTION OPERATION SYSTEM
-- ==============================================================================

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

-- Phím tắt nhanh [ giúp đại ca ẩn/hiện nhanh Menu UI Figma
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.LeftBracket then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

local MasterConnection = nil

-- Dọn dẹp bộ nhớ và hủy bỏ kết nối khi click nút X đóng Client
CloseBtn.MouseButton1Click:Connect(function()
    if MasterConnection then MasterConnection:Disconnect() end
    FOV_Drawing.Visible = false
    FOV_Drawing:Remove()
    
    for _, p in pairs(Players:GetPlayers()) do
        ClearTracerObject(p)
        if p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head")
            if root and root:FindFirstChild("BéBoxFill") then root["BéBoxFill"]:Destroy() end
            if head and head:FindFirstChild("BéInfoTag") then head["BéInfoTag"]:Destroy() end
        end
    end
    ScreenGui:Destroy()
end)

-- ==============================================================================
-- 7. RENDERSTEPPED LOOP MANAGEMENT - PIPELINE RUN ENGINE
-- ==============================================================================
MasterConnection = RunService.RenderStepped:Connect(function()
    local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Xử lý vòng tròn FOV Safe Circle
    if Config.FovCircle then
        FOV_Drawing.Position = ViewportCenter
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    -- Khống chế thuộc tính WalkSpeed và JumpPower của đại ca
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

    -- Khóa cứng tâm mượt vào ĐẦU thực thể (HEAD AIMBOT ENGINE)
    if Config.Aimbot then
        local TargetHead = GetClosestHeadToCrosshair()
        if TargetHead then
            local AimCFrame = CFrame.new(Camera.CFrame.Position, TargetHead.Position)
            Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Config.Smoothness)
        end
    end
end)

-- Quản lý vòng đời gia nhập phòng của người chơi để vẽ đồ họa
Players.PlayerAdded:Connect(function(Player)
    CreateTracerObject(Player)
    SetupAdornmentESP(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    ClearTracerObject(Player)
end)

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then 
        CreateTracerObject(Player)
        SetupAdornmentESP(Player) 
    end
end

print("================================================================")
print("--- [WANGCAOS ADVANCED V3 CLIENT CHAMS UPDATED COMPLETELY] ---")
print("--- [BOX ADORNMENT & BILLBOARD TAG FULLY OPERATED] ---")
print("================================================================")
