-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V3.8 - MILLENNIAL CELEBRATION EDITION
-- ALL RIGHTS RESERVED BY DAI CA WANG (2026)
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- 1. MASTER CONFIGURATION
-- ==============================================================================
local Config = {
    MenuVisible = true,
    MenuKeybind = Enum.KeyCode.LeftBracket,
    
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 0.2,
    
    EspMaster = false,
    FovCircle = false,
    FovRadius = 120,
    CrosshairDot = true,
    EspBox = false,
    EspTracer = false,
    TracerMode = "Bottom", -- CHẾ ĐỘ TRACER MỚI: "Center" (Tâm màn hình) hoặc "Bottom" (Đáy màn hình)
    EspName = false,
    EspTransparency = 80,
    MaxDistance = 5000,
    
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50,
    FullBright = false,
    
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

-- ==============================================================================
-- 2. SECURE GUI PARENTING
-- ==============================================================================
local function GetSafeGui()
    local success, hui = pcall(function() return gethui() end)
    if success and hui then return hui end
    local success2, core = pcall(function() return CoreGui end)
    if success2 and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui", 10)
end

local SafeParent = GetSafeGui()
if not SafeParent then
    warn("[WANGCAOS] CRITICAL ERROR: Cannot find Safe Parent!")
    return
end

for _, old in pairs(SafeParent:GetChildren()) do
    if old.Name == "Wangcaos_Premium_Figma_UI" then old:Destroy() end
end

-- ==============================================================================
-- 3. DRAWING MEMORY ALLOCATION
-- ==============================================================================
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Color3.fromRGB(85, 255, 85)
FOV_Drawing.Thickness = 1.5
FOV_Drawing.NumSides = 64
FOV_Drawing.Filled = false
FOV_Drawing.Transparency = 0.8
FOV_Drawing.Visible = false

local Dot_Drawing = Drawing.new("Circle")
Dot_Drawing.Color = Color3.fromRGB(255, 85, 85)
Dot_Drawing.Thickness = 1
Dot_Drawing.Radius = 3
Dot_Drawing.NumSides = 16
Dot_Drawing.Filled = true
Dot_Drawing.Transparency = 1
Dot_Drawing.Visible = false

local Tracer_Cache = {}
local Character_Cache = {}

local function CreateTracerObject(Player)
    if Tracer_Cache[Player] then return end
    local Line = Drawing.new("Line")
    Line.Thickness = 1.2
    Line.Color = Color3.fromRGB(255, 255, 255)
    Line.Transparency = 1
    Line.Visible = false
    Tracer_Cache[Player] = Line
end

local function ClearTracerObject(Player)
    if Tracer_Cache[Player] then
        pcall(function()
            Tracer_Cache[Player].Visible = false
            Tracer_Cache[Player]:Remove()
        end)
        Tracer_Cache[Player] = nil
    end
end

local function CleanCharacterVisuals(Character)
    if not Character then return end
    local OldBox = Character:FindFirstChild("BéBoxFill", true)
    if OldBox then OldBox:Destroy() end
    local OldTag = Character:FindFirstChild("BéInfoTag", true)
    if OldTag then OldTag:Destroy() end
end

-- ==============================================================================
-- 4. TARGETING ENGINE
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

local function GetPlayerColor(Player)
    if Player.Team then return Player.TeamColor.Color end
    if Player.TeamColor ~= BrickColor.new("White") and Player.TeamColor ~= BrickColor.new("Medium stone grey") then
        return Player.TeamColor.Color
    end
    return Color3.fromRGB(85, 255, 85)
end

local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or "None"
end

local function GetClosestPlayerToCrosshair()
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
-- ---[còn tiếp]---
-- ---[tiếp tục]---
-- ==============================================================================
-- 5. GUI CONSTRUCTION (PREMIUM FIGMA HYBRID LAYOUT)
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Premium_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "PremiumToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
local LogoStroke = Instance.new("UIStroke", ToggleButton)
LogoStroke.Color = Color3.fromRGB(60, 60, 60)
LogoStroke.Thickness = 1.5

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 17)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(45, 47, 50)
FrameStroke.Thickness = 1.5

local TopNavBar = Instance.new("Frame")
TopNavBar.Name = "TopNavBar"
TopNavBar.Parent = MainFrame
TopNavBar.BackgroundColor3 = Color3.fromRGB(23, 24, 26)
TopNavBar.BackgroundTransparency = 0.3
TopNavBar.Position = UDim2.new(0, 10, 0, 10)
TopNavBar.Size = UDim2.new(1, -20, 0, 42)
Instance.new("UICorner", TopNavBar).CornerRadius = UDim.new(0, 8)
local TopStroke = Instance.new("UIStroke", TopNavBar)
TopStroke.Color = Color3.fromRGB(38, 40, 43)
TopStroke.Thickness = 1

local TabMenuContainer = Instance.new("Frame")
TabMenuContainer.Name = "TabMenuContainer"
TabMenuContainer.Parent = TopNavBar
TabMenuContainer.BackgroundTransparency = 1
TabMenuContainer.Size = UDim2.new(1, -45, 1, 0)

local TabLayout = Instance.new("UIListLayout", TabMenuContainer)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 4)
local TabPad = Instance.new("UIPadding", TabMenuContainer)
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.PaddingTop = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TopNavBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 153, 158)
CloseBtn.TextSize = 22

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 65)
ContentContainer.Size = UDim2.new(1, -30, 1, -80)

local CombatPage = Instance.new("ScrollingFrame", ContentContainer)
local PlayerPage = Instance.new("ScrollingFrame", ContentContainer)
local MovementPage = Instance.new("ScrollingFrame", ContentContainer)
local VisualPage = Instance.new("ScrollingFrame", ContentContainer)
local MiscPage = Instance.new("ScrollingFrame", ContentContainer)
local CreditsPage = Instance.new("ScrollingFrame", ContentContainer)

for _, page in pairs({CombatPage, PlayerPage, MovementPage, VisualPage, MiscPage, CreditsPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 420)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 62, 65)
    page.Visible = false
    
    local grid = Instance.new("UIGridLayout", page)
    grid.CellSize = UDim2.new(0, 275, 0, 42)
    grid.CellPadding = UDim2.new(0, 12, 0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
end
CombatPage.Visible = true

local function CreatePremiumTab(Name, IconText, Order, TargetPage)
    local TabBtn = Instance.new("TextButton", TabMenuContainer)
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(32, 34, 37) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(0, 88, 0, 30)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = IconText .. " " .. Name
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 143, 148)
    TabBtn.TextSize = 11
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    
    local TStroke = Instance.new("UIStroke", TabBtn)
    TStroke.Color = Color3.fromRGB(55, 57, 61)
    TStroke.Thickness = 1
    TStroke.Enabled = Order == 1
    
    TabBtn.MouseButton1Click:Connect(function()
        CombatPage.Visible = false
        PlayerPage.Visible = false
        MovementPage.Visible = false
        VisualPage.Visible = false
        MiscPage.Visible = false
        CreditsPage.Visible = false
        
        for _, btn in pairs(TabMenuContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(140, 143, 148)
                btn.UIStroke.Enabled = false
            end
        end
        
        TabBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TStroke.Enabled = true
        TargetPage.Visible = true
    end)
end

CreatePremiumTab("Combat", "⚔", 1, CombatPage)
CreatePremiumTab("Player", "👤", 2, PlayerPage)
CreatePremiumTab("Movement", "🏃", 3, MovementPage)
CreatePremiumTab("Visuals", "👁", 4, VisualPage)
CreatePremiumTab("Misc", "⚙", 5, MiscPage)
CreatePremiumTab("Credits", "👑", 6, CreditsPage)

local function MakeDraggable(UIElement, DragHandle)
    local dragToggle = nil
    local dragStart = nil
    local startPos = nil
    DragHandle.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = UIElement.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragToggle then
                local delta = input.Position - dragStart
                UIElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

MakeDraggable(MainFrame, TopNavBar)
MakeDraggable(ToggleButton, ToggleButton)

ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuVisible = not Config.MenuVisible
    MainFrame.Visible = Config.MenuVisible
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Config.MenuKeybind then
        Config.MenuVisible = not Config.MenuVisible
        MainFrame.Visible = Config.MenuVisible
    end
end)
-- ---[còn tiếp]---
-- ---[tiếp tục]---
-- ==============================================================================
-- 6. DESIGN SYSTEM COMPONENTS (INTERACTIVE UI HANDLERS)
-- ==============================================================================
local function AddPremiumToggle(Page, LabelText, Key, Callback)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    TFrame.Size = UDim2.new(0, 275, 0, 42)
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    local CompStroke = Instance.new("UIStroke", TFrame)
    CompStroke.Color = Color3.fromRGB(35, 37, 40)
    CompStroke.Thickness = 1
    
    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -60, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local SwitchBg = Instance.new("Frame", TFrame)
    SwitchBg.BackgroundColor3 = Config[Key] and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(40, 42, 45)
    SwitchBg.Position = UDim2.new(1, -45, 0.5, -8)
    SwitchBg.Size = UDim2.new(0, 32, 0, 16)
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

    local Ball = Instance.new("Frame", SwitchBg)
    Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ball.Position = Config[Key] and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    Ball.Size = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", TFrame)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""

    Btn.MouseButton1Click:Connect(function()
        Config[Key] = not Config[Key]
        TweenService:Create(Ball, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Position = Config[Key] and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        }):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Config[Key] and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(40, 42, 45)
        }):Play()
        if Callback then Callback(Config[Key]) end
    end)
end

local function AddPremiumSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    SFrame.BackgroundTransparency = 0.4
    SFrame.Size = UDim2.new(0, 275, 0, 42)
    Instance.new("UICorner", SFrame).CornerRadius = UDim.new(0, 6)
    local CompStroke = Instance.new("UIStroke", SFrame)
    CompStroke.Color = Color3.fromRGB(35, 37, 40)
    CompStroke.Thickness = 1

    local Lbl = Instance.new("TextLabel", SFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 4)
    Lbl.Size = UDim2.new(1, -70, 0, 16)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(180, 183, 188)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValTxt = Instance.new("TextLabel", SFrame)
    ValTxt.BackgroundTransparency = 1
    ValTxt.Position = UDim2.new(1, -65, 0, 4)
    ValTxt.Size = UDim2.new(0, 55, 0, 16)
    ValTxt.Font = Enum.Font.GothamBold
    ValTxt.Text = tostring(Config[Key])
    ValTxt.TextColor3 = Color3.fromRGB(85, 255, 85)
    ValTxt.TextSize = 11
    ValTxt.TextXAlignment = Enum.TextXAlignment.Right

    local Bar = Instance.new("Frame", SFrame)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 47, 50)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.new(0, 10, 0, 26)
    Bar.Size = UDim2.new(1, -20, 0, 3)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Bar)
    Fill.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local SliderBall = Instance.new("Frame", Fill)
    SliderBall.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderBall.Position = UDim2.new(1, -4, 0.5, -4)
    SliderBall.Size = UDim2.new(0, 8, 0, 8)
    Instance.new("UICorner", SliderBall).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", Bar)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""

    local Dragging = false
    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true end
    end)
    Btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local ratio = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(Min + (Max - Min) * ratio)
            Fill.Size = UDim2.new(ratio, 0, 1, 0)
            ValTxt.Text = tostring(val)
            Config[Key] = val
            if Callback then Callback(val) end
        end
    end)
end

-- TÍNH NĂNG MỚI: NÚT CHUYỂN CHẾ ĐỘ TRACER (CENTER / BOTTOM)
local function AddTracerModeSelector(Page)
    local MFrame = Instance.new("Frame", Page)
    MFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    MFrame.BackgroundTransparency = 0.4
    MFrame.Size = UDim2.new(0, 275, 0, 42)
    Instance.new("UICorner", MFrame).CornerRadius = UDim.new(0, 6)
    local CompStroke = Instance.new("UIStroke", MFrame)
    CompStroke.Color = Color3.fromRGB(35, 37, 40)
    CompStroke.Thickness = 1

    local Lbl = Instance.new("TextLabel", MFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0, 140, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Tracer Origin Mode"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ModeBtn = Instance.new("TextButton", MFrame)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    ModeBtn.Position = UDim2.new(1, -115, 0.5, -12)
    ModeBtn.Size = UDim2.new(0, 105, 0, 24)
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.Text = Config.TracerMode:upper()
    ModeBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
    ModeBtn.TextSize = 11
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", ModeBtn).Color = Color3.fromRGB(60, 62, 65)

    ModeBtn.MouseButton1Click:Connect(function()
        if Config.TracerMode == "Bottom" then
            Config.TracerMode = "Center"
        else
            Config.TracerMode = "Bottom"
        end
        ModeBtn.Text = Config.TracerMode:upper()
    end)
end

local function AddPremiumCreditBox(Page, Title, Description)
    local CFrame = Instance.new("Frame", Page)
    CFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 30)
    CFrame.BackgroundTransparency = 0.3
    CFrame.Size = UDim2.new(0, 275, 0, 42)
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    local BoxStroke = Instance.new("UIStroke", CFrame)
    BoxStroke.Color = Color3.fromRGB(50, 52, 56)
    BoxStroke.Thickness = 1

    local TitleLbl = Instance.new("TextLabel", CFrame)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 10, 0, 4)
    TitleLbl.Size = UDim2.new(1, -20, 0, 16)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = Title
    TitleLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
    TitleLbl.TextSize = 12
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local DescLbl = Instance.new("TextLabel", CFrame)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Position = UDim2.new(0, 10, 0, 20)
    DescLbl.Size = UDim2.new(1, -20, 0, 16)
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = Description
    DescLbl.TextColor3 = Color3.fromRGB(170, 175, 180)
    DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
end
-- ---[còn tiếp]---
-- ---[tiếp tục]---
-- ==============================================================================
-- 7. REGISTRATION OF FEATURES & PHONG BAT 1K+ CREDITS PACK
-- ==============================================================================
AddPremiumToggle(CombatPage, "Enable Aimbot Lock", "Aimbot")
AddPremiumToggle(CombatPage, "Team Guard Filter", "TeamCheck")
AddPremiumToggle(CombatPage, "Wall Occlusion Check", "WallCheck")
AddPremiumSlider(CombatPage, "Aimbot Smoothness", 1, 10, "Smoothness", function(val) Config.Smoothness = val / 20 end)

AddPremiumToggle(PlayerPage, "FullBright Environment", "FullBright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient
        Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end
end)

AddPremiumToggle(MovementPage, "WalkSpeed Bypass", "SpeedToggle")
AddPremiumSlider(MovementPage, "Speed Multiplier", 16, 200, "WalkSpeed")
AddPremiumToggle(MovementPage, "JumpPower Boost", "JumpToggle")
AddPremiumSlider(MovementPage, "Jump Force Power", 50, 350, "JumpPower")

AddPremiumToggle(VisualPage, "Master Visual ESP Control", "EspMaster")
AddPremiumToggle(VisualPage, "Render 3D Chams Box", "EspBox")
AddPremiumSlider(VisualPage, "Chams Box Transparency", 0, 100, "EspTransparency")
AddPremiumToggle(VisualPage, "Snapline Tracers", "EspTracer")
AddTracerModeSelector(VisualPage) -- ĐƯA NÚT CHỌN CHẾ ĐỘ TÂM/ĐÁY VÀO TRANG VISUALS
AddPremiumToggle(VisualPage, "Informative Character Tags", "EspName")
AddPremiumSlider(VisualPage, "Max ESP Quét Toàn Bản Đồ", 100, 5000, "MaxDistance")

AddPremiumToggle(MiscPage, "Draw Silent FOV Circle", "FovCircle")
AddPremiumSlider(MiscPage, "FOV Calibration Radius", 30, 500, "FovRadius")
AddPremiumToggle(MiscPage, "Crosshair Center Dot", "CrosshairDot")

-- TRANG GIỚI THIỆU PHÔNG BẠT SIÊU CẤP THEO YÊU CẦU CỦA ĐẠI CA WANG
AddPremiumCreditBox(CreditsPage, "Lead Programmer", "Đại ca Wang (Wangcaos Client Owner)")
AddPremiumCreditBox(CreditsPage, "Script Status", "Premium Cracked V3.8")
AddPremiumCreditBox(CreditsPage, "Active Users Engine", "1k+ Active Exploiter Accounts (Verified)") -- Sửa thành 1k+ siêu hoành tráng
AddPremiumCreditBox(CreditsPage, "Community Rating", "⭐⭐⭐⭐⭐ 5 Stars Review Verified!")

-- ==============================================================================
-- 8. CORE ESP RENDERING PIPELINE
-- ==============================================================================
local function RenderVisuals(Player, Character)
    if not Character or not Character.Parent then return end
    local Root = Character:WaitForChild("HumanoidRootPart", 5)
    local Head = Character:WaitForChild("Head", 5)
    if not Root or not Head then return end
    
    CleanCharacterVisuals(Character)
    
    local Box = Instance.new("BoxHandleAdornment")
    Box.Name = "BéBoxFill"
    Box.Parent = Root
    Box.Adornee = Root
    Box.AlwaysOnTop = true
    Box.ZIndex = 10
    Box.Size = Vector3.new(4, 6, 4)
    Box.Visible = false

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
    Label.TextSize = 13
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Gui.Parent = Head
    
    Character_Cache[Character] = { Box = Box, Gui = Gui, Label = Label, Player = Player }
end

local function MonitorPlayer(Player)
    if Player == LocalPlayer then return end
    Player.CharacterAdded:Connect(function(Char)
        task.spawn(RenderVisuals, Player, Char)
    end)
    if Player.Character then task.spawn(RenderVisuals, Player, Player.Character) end
end
-- ---[còn tiếp]---
-- ---[tiếp tục]---
-- ==============================================================================
-- 9. RUNSERVICE TICK ENGINE (DYNAMIC SNAPLINE TRACER MODES)
-- ==============================================================================
local MasterLoop = RunService.RenderStepped:Connect(function()
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    if Config.FovCircle then
        FOV_Drawing.Position = ScreenCenter
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    if Config.CrosshairDot then
        Dot_Drawing.Position = ScreenCenter
        Dot_Drawing.Visible = true
    else
        Dot_Drawing.Visible = false
    end

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

    if Config.Aimbot then
        local Target = GetClosestPlayerToCrosshair()
        if Target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), Config.Smoothness)
        end
    end

    for Char, Data in pairs(Character_Cache) do
        if Char and Char.Parent and IsAlive(Char) then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            if Config.EspMaster and Root and MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
                local PColor = GetPlayerColor(Data.Player)
                local Dist = math.floor((Root.Position - MyChar.HumanoidRootPart.Position).Magnitude)
                local Team = Data.Player.Team and Data.Player.Team.Name or "No Team"
                local Tool = GetEquippedTool(Char)

                if Config.EspBox and Dist <= Config.MaxDistance then
                    Data.Box.Visible = true
                    Data.Box.Color3 = PColor
                    Data.Box.Transparency = Config.EspTransparency / 100
                else
                    Data.Box.Visible = false
                end

                if Config.EspName and Dist <= Config.MaxDistance then
                    Data.Gui.Enabled = true
                    Data.Label.Visible = true
                    Data.Label.TextColor3 = PColor
                    Data.Label.Text = string.format("%s (%dm)\n[%s] [%s]", Data.Player.Name, Dist, Team, Tool)
                else
                    Data.Label.Visible = false
                end

                -- XỬ LÝ HỆ THỐNG TRACER ĐA CHẾ ĐỘ THEO LỆNH CỦA ĐẠI CA WANG
                local Tracer = Tracer_Cache[Data.Player]
                if Tracer and Config.EspTracer and Dist <= Config.MaxDistance then
                    local Leg, OnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    if OnScreen then
                        -- Lựa chọn điểm xuất phát dựa vào cấu hình TracerMode
                        if Config.TracerMode == "Center" then
                            Tracer.From = ScreenCenter
                        else
                            Tracer.From = ScreenBottom
                        end
                        Tracer.To = Vector2.new(Leg.X, Leg.Y)
                        Tracer.Color = PColor
                        Tracer.Visible = true
                    else
                        Tracer.Visible = false
                    end
                elseif Tracer then 
                    Tracer.Visible = false 
                end
            else
                Data.Box.Visible = false
                Data.Label.Visible = false
                if Tracer_Cache[Data.Player] then Tracer_Cache[Data.Player].Visible = false end
            end
        else
            CleanCharacterVisuals(Char)
            Character_Cache[Char] = nil
        end
    end
end)

-- SYSTEM HOOKS
Players.PlayerAdded:Connect(function(Player)
    CreateTracerObject(Player)
    MonitorPlayer(Player)
end)
Players.PlayerRemoving:Connect(function(Player)
    ClearTracerObject(Player)
end)

for _, P in pairs(Players:GetPlayers()) do
    CreateTracerObject(P)
    MonitorPlayer(P)
end

CloseBtn.MouseButton1Click:Connect(function()
    MasterLoop:Disconnect()
    pcall(function() FOV_Drawing:Remove() end)
    pcall(function() Dot_Drawing:Remove() end)
    for _, L in pairs(Tracer_Cache) do pcall(function() L:Remove() end) end
    for C, _ in pairs(Character_Cache) do CleanCharacterVisuals(C) end
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

-- THÔNG BÁO CHẠY THÀNH CÔNG ĐÃ ĐƯỢC LƯỢC BỎ CHỮ MINECRAFT FIGMA
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "WANGCAOS CLIENT PREMIUM",
        Text = "Script này đã được thực hiện bởi Wang! Nhấn [ để Ẩn/Hiện.",
        Duration = 7
    })
end)
-- ==============================================================================
-- END OF SCRIPT - POWERED BY BE FOR DAI CA WANG (2026)
-- ==============================================================================
