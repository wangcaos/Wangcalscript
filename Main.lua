-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V5.5 - DYNAMIC TOGGLE FOR MOBILE SHORTCUTS
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
local Mouse = LocalPlayer:GetMouse()
local MasterLoop

-- ==============================================================================
-- 1. MASTER CONFIGURATION (ALL OFF BY DEFAULT, SHORTCUTS HIDDEN)
-- ==============================================================================
local Config = {
    MenuVisible = true,
    MenuKeybind = Enum.KeyCode.LeftBracket,
    
    Aimbot = false,
    AimbotKeybind = Enum.KeyCode.E,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 5,
    TargetPart = "Head",
    
    Triggerbot = false,
    TriggerbotKeybind = Enum.KeyCode.T,
    TriggerWallCheck = true,
    
    Spinbot = false,
    SpinbotKeybind = Enum.KeyCode.K,
    SpinSpeed = 25,
    
    EspMaster = false,
    EspMasterKeybind = Enum.KeyCode.O,
    FovCircle = false,
    FovRadius = 120,
    FovThickness = 1.5,
    FovSides = 64,
    FovColor = Color3.fromRGB(255, 255, 255),
    FovTransparency = 0.8,
    FovFilled = false,
    
    CrosshairDot = false,
    EspBox = false,
    EspTracer = false,
    TracerMode = "Bottom",
    
    EspName = false,
    EspTransparency = 80,
    MaxDistance = 5000,
    
    SpeedToggle = false,
    SpeedKeybind = Enum.KeyCode.Q,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpKeybind = Enum.KeyCode.G,
    JumpPower = 50,
    FullBright = false,
    
    MobileButton = false, -- Tắt từ đầu: Ẩn tất cả các nút di động khi mới chạy script
    CustomBackground = true,
    BackgroundAssetId = "rbxassetid://118670919014080",
    
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

local CurrentSpinAngle = 0
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

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
FOV_Drawing.Color = Config.FovColor
FOV_Drawing.Thickness = Config.FovThickness
FOV_Drawing.NumSides = Config.FovSides
FOV_Drawing.Filled = Config.FovFilled
FOV_Drawing.Transparency = Config.FovTransparency
FOV_Drawing.Visible = false

local Dot_Drawing = Drawing.new("Circle")
Dot_Drawing.Color = Color3.fromRGB(255, 255, 255)
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
-- 4. TARGETING ENGINE & TRIGGERBOT MECHANICS
-- ==============================================================================
local function IsAlive(Character)
    if not Character or not Character.Parent then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    return true
end

local function IsTeammate(Player)
    if not Config.TeamCheck then return false end
    if Player.Team and LocalPlayer.Team then
        return Player.Team == LocalPlayer.Team
    end
    if Player.TeamColor and LocalPlayer.TeamColor then
        return Player.TeamColor == LocalPlayer.TeamColor and Player.TeamColor.Name ~= "White" and Player.TeamColor.Name ~= "Medium stone grey"
    end
    return false
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

local function CheckTriggerWall(Position)
    if not Config.TriggerWallCheck then return true end
    local Origin = Camera.CFrame.Position
    local Direction = Position - Origin
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local Result = workspace:Raycast(Origin, Direction, Params)
    return Result == nil or Result.Instance:IsDescendantOf(workspace)
end

local function GetPlayerColor(Player)
    if IsTeammate(Player) then
        return Color3.fromRGB(0, 170, 255)
    else
        return Color3.fromRGB(255, 50, 50)
    end
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
            if IsTeammate(Player) then continue end
            
            local TargetPartInstance = Player.Character:FindFirstChild(Config.TargetPart)
            if TargetPartInstance then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPartInstance.Position)
                if OnScreen and CheckWallOcclusion(TargetPartInstance, Player.Character) then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Center).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        ClosestTarget = TargetPartInstance
                    end
                end
            end
        end
    end
    return ClosestTarget
end

local function PerformTriggerbotClick()
    local TargetInstance = Mouse.Target
    if TargetInstance and TargetInstance.Parent then
        local Char = TargetInstance.Parent
        if Char:IsA("Accessory") then Char = Char.Parent end
        
        local Plr = Players:GetPlayerFromCharacter(Char)
        if Plr and Plr ~= LocalPlayer and IsAlive(Char) and not IsTeammate(Plr) then
            local TargetPart = Char:FindFirstChild("Head") or Char:FindFirstChild("HumanoidRootPart")
            if TargetPart and CheckTriggerWall(TargetPart.Position) then
                pcall(function()
                    mouse1click()
                end)
            end
        end
    end
end
-- ==============================================================================
-- 5. GUI CONSTRUCTION & INDEPENDENT DRAG SHORTCUTS LOGIC
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Premium_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

local GlobalMobileButtons = {}
local GlobalSyncToggles = {}

local function MakeDraggable(UIElement, DragHandle)
    local dragging = false
    local dragInput, mousePos, framePos

    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = UIElement.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            UIElement.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

local function CreateIndependentMobileButton(Name, TextOn, TextOff, Key, DefaultColor, InitPos)
    local ShortcutBtn = Instance.new("TextButton")
    ShortcutBtn.Name = "IndependentMobile_" .. Key
    ShortcutBtn.Parent = ScreenGui
    ShortcutBtn.BackgroundColor3 = DefaultColor
    ShortcutBtn.BackgroundTransparency = 0.2
    ShortcutBtn.Position = InitPos
    ShortcutBtn.Size = UDim2.new(0, 60, 0, 60)
    ShortcutBtn.Font = Enum.Font.GothamBold
    ShortcutBtn.Text = TextOff
    ShortcutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShortcutBtn.TextSize = 10
    ShortcutBtn.Visible = (Config.MobileButton and IsMobile) -- Phụ thuộc vào Config.MobileButton (Tắt từ đầu)
    
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn)
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.Thickness = 1.5
    
    MakeDraggable(ShortcutBtn, ShortcutBtn)
    
    GlobalMobileButtons[Key] = ShortcutBtn
    return ShortcutBtn
end

-- Tạo 3 nút nhanh hoạt động hoàn toàn độc lập (Mặc định ẩn hoàn toàn từ đầu)
local MobAim = CreateIndependentMobileButton("Aimbot", "AIM\nON", "AIM\nOFF", "Aimbot", Color3.fromRGB(255, 50, 50), UDim2.new(0.85, 0, 0.20, 0))
local MobTrig = CreateIndependentMobileButton("Triggerbot", "TRIG\nON", "TRIG\nOFF", "Triggerbot", Color3.fromRGB(230, 125, 30), UDim2.new(0.85, 0, 0.32, 0))
local MobSpeed = CreateIndependentMobileButton("Speed", "SPD\nON", "SPD\nOFF", "SpeedToggle", Color3.fromRGB(140, 30, 230), UDim2.new(0.85, 0, 0.44, 0))

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
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(60, 60, 60)
Instance.new("UIStroke", ToggleButton).Thickness = 1.5

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
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(45, 47, 50)
Instance.new("UIStroke", MainFrame).Thickness = 1.5

local CustomBackgroundImage = Instance.new("ImageLabel")
CustomBackgroundImage.Name = "MenuCustomWallpaper"
CustomBackgroundImage.Parent = MainFrame
CustomBackgroundImage.BackgroundTransparency = 1
CustomBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
CustomBackgroundImage.Image = Config.BackgroundAssetId
CustomBackgroundImage.ImageTransparency = 0.75
CustomBackgroundImage.ScaleType = Enum.ScaleType.Crop
CustomBackgroundImage.ZIndex = 0
CustomBackgroundImage.Visible = Config.CustomBackground
Instance.new("UICorner", CustomBackgroundImage).CornerRadius = UDim.new(0, 10)

local TopNavBar = Instance.new("Frame")
TopNavBar.Name = "TopNavBar"
TopNavBar.Parent = MainFrame
TopNavBar.BackgroundColor3 = Color3.fromRGB(23, 24, 26)
TopNavBar.BackgroundTransparency = 0.3
TopNavBar.Position = UDim2.new(0, 10, 0, 10)
TopNavBar.Size = UDim2.new(1, -20, 0, 42)
TopNavBar.ZIndex = 2
Instance.new("UICorner", TopNavBar).CornerRadius = UDim.new(0, 8)
local TabMenuContainer = Instance.new("Frame")
TabMenuContainer.Name = "TabMenuContainer"
TabMenuContainer.Parent = TopNavBar
TabMenuContainer.BackgroundTransparency = 1
TabMenuContainer.Size = UDim2.new(1, -45, 1, 0)

local TabLayout = Instance.new("UIListLayout", TabMenuContainer)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
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

MakeDraggable(MainFrame, TopNavBar)
MakeDraggable(ToggleButton, ToggleButton)

CloseBtn.MouseButton1Click:Connect(function()
    Config.MenuVisible = false
    MainFrame.Visible = false
end)

ToggleButton.MouseButton1Click:Connect(function()
    Config.MenuVisible = not Config.MenuVisible
    MainFrame.Visible = Config.MenuVisible
end)

-- ==============================================================================
-- 6. DESIGN SYSTEM TABS & INTERACTIVE UI COMPONENTS
-- ==============================================================================
local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 65)
ContentContainer.Size = UDim2.new(1, -30, 1, -80)
ContentContainer.ZIndex = 2

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
    page.CanvasSize = UDim2.new(0, 0, 0, 450)
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
    TStroke.Enabled = Order == 1
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs({CombatPage, PlayerPage, MovementPage, VisualPage, MiscPage, CreditsPage}) do p.Visible = false end
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
local function UpdateToggleVisual(Key)
    local TargetData = GlobalSyncToggles[Key]
    if not TargetData then return end
    
    local state = Config[Key]
    local Ball = TargetData.Ball
    local SwitchBg = TargetData.SwitchBg
    
    TweenService:Create(Ball, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
    TweenService:Create(SwitchBg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(40, 42, 45)}):Play()
    
    if GlobalMobileButtons[Key] then
        local MBtn = GlobalMobileButtons[Key]
        MBtn.BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or TargetData.DefMobColor
        if Key == "Aimbot" then MBtn.Text = state and "AIM\nON" or "AIM\nOFF"
        elseif Key == "Triggerbot" then MBtn.Text = state and "TRIG\nON" or "TRIG\nOFF"
        elseif Key == "SpeedToggle" then MBtn.Text = state and "SPD\nON" or "SPD\nOFF"
        end
    end
end

local function AddPremiumToggle(Page, LabelText, Key, Callback, DefMobColor)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)
    
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

    GlobalSyncToggles[Key] = {Ball = Ball, SwitchBg = SwitchBg, DefMobColor = DefMobColor or Color3.fromRGB(40, 42, 45)}

    Btn.MouseButton1Click:Connect(function()
        Config[Key] = not Config[Key]
        UpdateToggleVisual(Key)
        if Callback then Callback(Config[Key]) end
    end)
end

local function AddPremiumSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    SFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", SFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", SFrame).Color = Color3.fromRGB(35, 37, 40)

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
    ValTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValTxt.TextSize = 11
    ValTxt.TextXAlignment = Enum.TextXAlignment.Right

    local Bar = Instance.new("Frame", SFrame)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 47, 50)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.new(0, 10, 0, 26)
    Bar.Size = UDim2.new(1, -20, 0, 3)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Bar)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
local function AddPremiumButton(Page, LabelText, ButtonText, Callback)
    local BFrame = Instance.new("Frame", Page)
    BFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    BFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", BFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", BFrame).Color = Color3.fromRGB(35, 37, 40)
    
    local Lbl = Instance.new("TextLabel", BFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0, 140, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ActionBtn = Instance.new("TextButton", BFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    ActionBtn.Position = UDim2.new(1, -115, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 105, 0, 24)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = ButtonText
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 11
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)
    
    ActionBtn.MouseButton1Click:Connect(function()
        if Callback then Callback() end
    end)
end

local function AddHitboxSelector(Page)
    local HFrame = Instance.new("Frame", Page)
    HFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    HFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", HFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", HFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", HFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0, 140, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Aimbot Target Hitbox"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local HitboxBtn = Instance.new("TextButton", HFrame)
    HitboxBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    HitboxBtn.Position = UDim2.new(1, -115, 0.5, -12)
    HitboxBtn.Size = UDim2.new(0, 105, 0, 24)
    HitboxBtn.Font = Enum.Font.GothamBold
    HitboxBtn.Text = Config.TargetPart == "Head" and "HEAD" or "TORSO"
    HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    HitboxBtn.TextSize = 11
    Instance.new("UICorner", HitboxBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", HitboxBtn).Color = Color3.fromRGB(60, 62, 65)

    HitboxBtn.MouseButton1Click:Connect(function()
        if Config.TargetPart == "Head" then
            Config.TargetPart = "HumanoidRootPart"
            HitboxBtn.Text = "TORSO"
        else
            Config.TargetPart = "Head"
            HitboxBtn.Text = "HEAD"
        end
    end)
end

local function AddTracerModeSelector(Page)
    local MFrame = Instance.new("Frame", Page)
    MFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    MFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", MFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", MFrame).Color = Color3.fromRGB(35, 37, 40)

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
    ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(50, 52, 56)

    local TitleLbl = Instance.new("TextLabel", CFrame)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 10, 0, 4)
    TitleLbl.Size = UDim2.new(1, -20, 0, 16)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = Title
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- ==============================================================================
-- 7. FUNCTION REGISTER PIPELINE
-- ==============================================================================
AddPremiumToggle(CombatPage, "Enable Aimbot Lock [E]", "Aimbot", nil, Color3.fromRGB(255, 50, 50))
AddPremiumToggle(CombatPage, "Team Guard Filter", "TeamCheck")
AddPremiumToggle(CombatPage, "Wall Occlusion Check", "WallCheck")
AddPremiumSlider(CombatPage, "Aimbot Smoothness", 0, 10, "Smoothness")
AddHitboxSelector(CombatPage)
AddPremiumToggle(CombatPage, "Triggerbot (Auto Click) [T]", "Triggerbot", nil, Color3.fromRGB(230, 125, 30))
AddPremiumToggle(CombatPage, "Triggerbot Gun WallCheck", "TriggerWallCheck")

AddPremiumToggle(PlayerPage, "FullBright Environment", "FullBright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient
        Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end
end)
AddPremiumToggle(PlayerPage, "Enable Spinbot [K]", "Spinbot")
AddPremiumSlider(PlayerPage, "Spinbot Rotate Speed", 5, 100, "SpinSpeed")

AddPremiumToggle(MovementPage, "WalkSpeed Bypass [Q]", "SpeedToggle", nil, Color3.fromRGB(140, 30, 230))
AddPremiumSlider(MovementPage, "Speed Multiplier", 16, 200, "WalkSpeed")
AddPremiumToggle(MovementPage, "JumpPower Boost [G]", "JumpToggle")
AddPremiumSlider(MovementPage, "Jump Force Power", 50, 350, "JumpPower")

AddPremiumToggle(VisualPage, "Master Visual ESP Control [O]", "EspMaster", nil, Color3.fromRGB(30, 140, 230))
AddPremiumToggle(VisualPage, "Render 3D Chams Box", "EspBox")
AddPremiumSlider(VisualPage, "Chams Box Transparency", 0, 100, "EspTransparency")
AddPremiumToggle(VisualPage, "Snapline Tracers", "EspTracer")
AddTracerModeSelector(VisualPage)
AddPremiumToggle(VisualPage, "Informative Character Tags", "EspName")
AddPremiumSlider(VisualPage, "Max ESP Quét Toàn Bản Đồ", 100, 5000, "MaxDistance")

AddPremiumToggle(MiscPage, "Draw Silent FOV Circle", "FovCircle")
AddPremiumSlider(MiscPage, "FOV Calibration Radius", 30, 500, "FovRadius")
AddPremiumToggle(MiscPage, "Crosshair Center Dot", "CrosshairDot")

-- NÚT BẬT HOẶC TẮT CHO CÁC NÚT MOBILE ĐỘC LẬP
AddPremiumToggle(MiscPage, "Show Mobile Fast Toggles", "MobileButton", function(state)
    for _, btn in pairs(GlobalMobileButtons) do
        btn.Visible = (state and IsMobile)
    end
end)

AddPremiumToggle(MiscPage, "Menu Custom Background", "CustomBackground", function(state)
    CustomBackgroundImage.Visible = state
end)

AddPremiumButton(MiscPage, "Force Uninject Script", "UNINJECT", function()
    MasterLoop:Disconnect()
    pcall(function() FOV_Drawing:Remove() end)
    pcall(function() Dot_Drawing:Remove() end)
    for _, L in pairs(Tracer_Cache) do pcall(function() L:Remove() end) end
    for C, _ in pairs(Character_Cache) do CleanCharacterVisuals(C) end
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

AddPremiumCreditBox(CreditsPage, "Lead Programmer", "Đại ca Wang (Wangcaos Client Owner)")
AddPremiumCreditBox(CreditsPage, "Script Status", "Premium Cracked V5.5 Cross-Platform")
AddPremiumCreditBox(CreditsPage, "Active Users Engine", "1k+ Active Exploiter Accounts (Verified)")
AddPremiumCreditBox(CreditsPage, "Community Rating", "⭐⭐⭐⭐⭐ 5 Stars Review Verified!")
-- CONNECT INDEPENDENT MOBILE SHORTCUTS CLICK EVENT
local function RegisterMobileClick(Btn, Key)
    Btn.MouseButton1Click:Connect(function()
        Config[Key] = not Config[Key]
        UpdateToggleVisual(Key)
    end)
end

RegisterMobileClick(MobAim, "Aimbot")
RegisterMobileClick(MobTrig, "Triggerbot")
RegisterMobileClick(MobSpeed, "SpeedToggle")

-- PC KEYBIND LISTENER SYSTEM (BẤM PHÍM BẬT/TẮT TRÊN PC)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Config.MenuKeybind then
        Config.MenuVisible = not Config.MenuVisible
        MainFrame.Visible = Config.MenuVisible
    elseif input.KeyCode == Config.AimbotKeybind then
        Config.Aimbot = not Config.Aimbot
        UpdateToggleVisual("Aimbot")
    elseif input.KeyCode == Config.TriggerbotKeybind then
        Config.Triggerbot = not Config.Triggerbot
        UpdateToggleVisual("Triggerbot")
    elseif input.KeyCode == Config.SpinbotKeybind then
        Config.Spinbot = not Config.Spinbot
        UpdateToggleVisual("Spinbot")
    elseif input.KeyCode == Config.EspMasterKeybind then
        Config.EspMaster = not Config.EspMaster
        UpdateToggleVisual("EspMaster")
    elseif input.KeyCode == Config.SpeedKeybind then
        Config.SpeedToggle = not Config.SpeedToggle
        UpdateToggleVisual("SpeedToggle")
    elseif input.KeyCode == Config.JumpKeybind then
        Config.JumpToggle = not Config.JumpToggle
        UpdateToggleVisual("JumpToggle")
    end
end)

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

-- ==============================================================================
-- 9. RUNSERVICE TICK ENGINE
-- ==============================================================================
MasterLoop = RunService.RenderStepped:Connect(function()
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    if Config.FovCircle then
        FOV_Drawing.Position = ScreenCenter
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Color = Config.FovColor
        FOV_Drawing.Thickness = Config.FovThickness
        FOV_Drawing.NumSides = Config.FovSides
        FOV_Drawing.Filled = Config.FovFilled
        FOV_Drawing.Transparency = Config.FovTransparency
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    if Config.CrosshairDot then
        Dot_Drawing.Position = ScreenCenter
        Dot_Drawing.Color = Color3.fromRGB(255, 255, 255)
        Dot_Drawing.Visible = true
    else
        Dot_Drawing.Visible = false
    end

    local MyChar = LocalPlayer.Character
    if IsAlive(MyChar) then
        local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
        local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
        
        if MyHum then
            if Config.SpeedToggle then MyHum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpToggle then
                MyHum.UseJumpPower = true
                MyHum.JumpPower = Config.JumpPower
            end
        end
        
        if Config.Spinbot and MyRoot then
            CurrentSpinAngle = (CurrentSpinAngle + Config.SpinSpeed) % 360
            MyRoot.CFrame = CFrame.new(MyRoot.CFrame.Position) * CFrame.Angles(0, math.rad(CurrentSpinAngle), 0)
        end
    end

    if Config.Triggerbot then
        task.spawn(PerformTriggerbotClick)
    end

    if Config.Aimbot then
        local Target = GetClosestPlayerToCrosshair()
        if Target then
            local LerpFactor = 1
            if Config.Smoothness > 0 then
                LerpFactor = math.clamp(1 / (Config.Smoothness * 3 + 1), 0.01, 1)
            end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), LerpFactor)
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

                local Tracer = Tracer_Cache[Data.Player]
                if Tracer and Config.EspTracer and Dist <= Config.MaxDistance then
                    local Leg, OnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    if OnScreen then
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

for K, _ in pairs(GlobalSyncToggles) do
    UpdateToggleVisual(K)
end

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "WANGCAOS CLIENT V5.5",
        Text = "Đã tắt tất cả chức năng & ẩn các nút nhanh. Hãy bật 'Show Mobile Fast Toggles' trong Misc để hiện nút bấm!",
        Duration = 7
    })
end)
-- ==============================================================================
-- END OF SCRIPT - UPGRADED BY BE FOR DAI CA WANG (2026)
-- ==============================================================================
