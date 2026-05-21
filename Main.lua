-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V6.2 - TEAM FILTER OVERHAUL & ANTI-AIM ADDITION
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
-- 1. MASTER CONFIGURATION
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
    
    CuiDau = false, -- TÍNH NĂNG MỚI: CÚI ĐẦU NHÂN VẬT
    ThirdPerson = false, -- TÍNH NĂNG MỚI: GÓC NHÌN THỨ BA
    ThirdPersonDistance = 12,
    
    AutoFarmPlayer = false,
    AutoFarmDelay = 0.05,
    
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
    EspHealth = false,
    EspTransparency = 80,
    MaxDistance = 5000,
    
    SpeedToggle = false,
    SpeedKeybind = Enum.KeyCode.Q,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpKeybind = Enum.KeyCode.G,
    JumpPower = 50,
    FullBright = false,
    
    ShowMobileAim = false,
    ShowMobileTrig = false,
    ShowMobileSpeed = false,
    ShowMobileFarm = false,
    ShowMobileCui = false,
    ShowMobileThird = false,
    
    CustomBackground = true,
    BackgroundAssetId = "rbxassetid://118670919014080",
    
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

local CurrentSpinAngle = 0
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local LastFarmTime = 0
local CurrentFarmIndex = 1

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
if not SafeParent then return end

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
-- 4. TARGETING ENGINE & CORE FILTERS
-- ==============================================================================
local function IsAlive(Character)
    if not Character or not Character.Parent then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    return true
end

-- LÀM LẠI HOÀN TOÀN LOGIC CHECK TEAM: Đồng bộ hóa cấu hình bộ lọc cho cả Aimbot và ESP
local function IsTeammate(Player)
    if not Config.TeamCheck then return false end -- Nếu tắt TeamCheck thì không coi ai là đồng đội
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
    return IsTeammate(Player) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(255, 50, 50)
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
            if IsTeammate(Player) then continue end -- Aimbot bỏ qua nếu CheckTeam bật và trùng team
            
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
                pcall(function() mouse1click() end)
            end
        end
    end
end

local IsFiring = false
local function ProcessAutoFarmPlayer()
    if not Config.AutoFarmPlayer then 
        if IsFiring then IsFiring = false pcall(function() mouse1release() end) end
        return 
    end
    
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot or not IsAlive(MyChar) then return end
    
    local Targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) and not IsTeammate(p) then
            local TRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local THead = p.Character:FindFirstChild("Head")
            if TRoot and THead then 
                table.insert(Targets, {Root = TRoot, Head = THead}) 
            end
        end
    end
    
    if #Targets == 0 then 
        if IsFiring then IsFiring = false pcall(function() mouse1release() end) end
        return 
    end
    
    if CurrentFarmIndex > #Targets then CurrentFarmIndex = 1 end
    local ActiveTargetData = Targets[CurrentFarmIndex]
    local EnemyRoot = ActiveTargetData.Root
    local EnemyHead = ActiveTargetData.Head
    
    if EnemyRoot and EnemyHead then
        local BehindPosition = EnemyRoot.Position - (EnemyRoot.CFrame.LookVector * 3)
        MyRoot.CFrame = CFrame.new(BehindPosition, EnemyRoot.Position)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, EnemyHead.Position)
        
        if not IsFiring then
            IsFiring = true
            pcall(function() mouse1press() end)
        end
        
        if tick() - LastFarmTime >= Config.AutoFarmDelay then
            LastFarmTime = tick()
            CurrentFarmIndex = CurrentFarmIndex + 1
        end
    end
end
-- ==============================================================================
-- 5. GUI CONSTRUCTION & MOBILE LAYER
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
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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

local function RegisterTouchFriendlyClick(TextButton, Callback)
    local HoldingTouch = false
    
    TextButton.MouseButton1Click:Connect(function()
        if not HoldingTouch then Callback() end
    end)
    
    TextButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then HoldingTouch = true end
    end)

    TextButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if HoldingTouch then
                HoldingTouch = false
                Callback()
            end
        end
    end)
end

local function CreateIndependentMobileButton(Name, TextOn, TextOff, Key, ShowKey, DefaultColor, InitPos)
    local ShortcutBtn = Instance.new("TextButton")
    ShortcutBtn.Name = "IndependentMobile_" .. Key
    ShortcutBtn.Parent = ScreenGui
    ShortcutBtn.BackgroundColor3 = DefaultColor
    ShortcutBtn.BackgroundTransparency = 0.2
    ShortcutBtn.Position = InitPos
    ShortcutBtn.Size = UDim2.new(0, 52, 0, 52)
    ShortcutBtn.Font = Enum.Font.GothamBold
    ShortcutBtn.Text = TextOff
    ShortcutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShortcutBtn.TextSize = 9
    ShortcutBtn.Visible = (Config[ShowKey] and IsMobile)
    
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn)
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.Thickness = 1.5
    
    MakeDraggable(ShortcutBtn, ShortcutBtn)
    GlobalMobileButtons[Key] = { Btn = ShortcutBtn, ShowKey = ShowKey }
    return ShortcutBtn
end

local MobAim = CreateIndependentMobileButton("Aimbot", "AIM\nON", "AIM\nOFF", "Aimbot", "ShowMobileAim", Color3.fromRGB(255, 50, 50), UDim2.new(0.85, 0, 0.15, 0))
local MobTrig = CreateIndependentMobileButton("Triggerbot", "TRIG\nON", "TRIG\nOFF", "Triggerbot", "ShowMobileTrig", Color3.fromRGB(230, 125, 30), UDim2.new(0.85, 0, 0.26, 0))
local MobSpeed = CreateIndependentMobileButton("Speed", "SPD\nON", "SPD\nOFF", "SpeedToggle", "ShowMobileSpeed", Color3.fromRGB(140, 30, 230), UDim2.new(0.85, 0, 0.37, 0))
local MobFarm = CreateIndependentMobileButton("AutoFarm", "FRM\nON", "FRM\nOFF", "AutoFarmPlayer", "ShowMobileFarm", Color3.fromRGB(45, 140, 75), UDim2.new(0.85, 0, 0.48, 0))

-- THÊM PHÍM TẮT MOBILE CHO CÚI ĐẦU VÀ GÓC NHÌN THỨ 3
local MobCui = CreateIndependentMobileButton("CuiDau", "CÚI\nON", "CÚI\nOFF", "CuiDau", "ShowMobileCui", Color3.fromRGB(200, 40, 120), UDim2.new(0.77, 0, 0.15, 0))
local MobThird = CreateIndependentMobileButton("ThirdPerson", "CAM\n3RD", "CAM\n1ST", "ThirdPerson", "ShowMobileThird", Color3.fromRGB(40, 150, 200), UDim2.new(0.77, 0, 0.26, 0))

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

if not IsMobile then MakeDraggable(ToggleButton, ToggleButton) end
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
MainFrame.UIStroke.Thickness = 1.5

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

RegisterTouchFriendlyClick(CloseBtn, function()
    Config.MenuVisible = false
    MainFrame.Visible = false
end)

RegisterTouchFriendlyClick(ToggleButton, function()
    Config.MenuVisible = not Config.MenuVisible
    MainFrame.Visible = Config.MenuVisible
end)

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
    page.CanvasSize = UDim2.new(0, 0, 0, 480)
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
    
    RegisterTouchFriendlyClick(TabBtn, function()
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

local function UpdateToggleVisual(Key)
    local TargetData = GlobalSyncToggles[Key]
    if not TargetData then return end
    
    local state = Config[Key]
    local Ball = TargetData.Ball
    local SwitchBg = TargetData.SwitchBg
    
    TweenService:Create(Ball, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
    TweenService:Create(SwitchBg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(40, 42, 45)}):Play()
    
    if GlobalMobileButtons[Key] then
        local MData = GlobalMobileButtons[Key]
        MData.Btn.BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or TargetData.DefMobColor
        if Key == "Aimbot" then MData.Btn.Text = state and "AIM\nON" or "AIM\nOFF"
        elseif Key == "Triggerbot" then MData.Btn.Text = state and "TRIG\nON" or "TRIG\nOFF"
        elseif Key == "SpeedToggle" then MData.Btn.Text = state and "SPD\nON" or "SPD\nOFF"
        elseif Key == "AutoFarmPlayer" then MData.Btn.Text = state and "FRM\nON" or "FRM\nOFF"
        elseif Key == "CuiDau" then MData.Btn.Text = state and "CÚI\nON" or "CÚI\nOFF"
        elseif Key == "ThirdPerson" then MData.Btn.Text = state and "CAM\n3RD" or "CAM\n1ST"
        end
    end
end

local function AddPremiumToggle(Page, LabelText, Key, Callback, DefMobColor, BindKey)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)
    
    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -110, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
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
    Btn.Size = UDim2.new(1, -55, 1, 0)
    Btn.Text = ""

    GlobalSyncToggles[Key] = {Ball = Ball, SwitchBg = SwitchBg, DefMobColor = DefMobColor or Color3.fromRGB(40, 42, 45)}

    RegisterTouchFriendlyClick(Btn, function()
        Config[Key] = not Config[Key]
        UpdateToggleVisual(Key)
        if Callback then Callback(Config[Key]) end
    end)

    if BindKey then
        local BindBtn = Instance.new("TextButton", TFrame)
        BindBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
        BindBtn.Position = UDim2.new(1, -100, 0.5, -10)
        BindBtn.Size = UDim2.new(0, 50, 0, 20)
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE"
        BindBtn.TextColor3 = Color3.fromRGB(200, 205, 210)
        BindBtn.TextSize = 10
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", BindBtn).Color = Color3.fromRGB(55, 57, 60)

        local Listening = false
        local ListenConnection
        local TouchConnection
        local CurrentSessionID = 0

        local function EndListening(NewKey)
            Listening = false
            if ListenConnection then ListenConnection:Disconnect() end
            if TouchConnection then TouchConnection:Disconnect() end
            if NewKey then
                Config[BindKey] = NewKey
                BindBtn.Text = NewKey.Name:upper()
            else
                BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE"
            end
            BindBtn.TextColor3 = Color3.fromRGB(200, 205, 210)
        end

        RegisterTouchFriendlyClick(BindBtn, function()
            if Listening then return end
            Listening = true
            BindBtn.Text = "..."
            BindBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
            
            CurrentSessionID = math.random()
            local ThisSession = CurrentSessionID

            task.delay(5, function()
                if Listening and CurrentSessionID == ThisSession then EndListening(nil) end
            end)

            ListenConnection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    EndListening(input.KeyCode)
                end
            end)
        end)
    end
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
            local val = Min + (Max - Min) * ratio
            if Max - Min > 10 then val = math.floor(val) else val = math.floor(val * 10) / 10 end
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
     
    RegisterTouchFriendlyClick(ActionBtn, Callback)
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

    RegisterTouchFriendlyClick(HitboxBtn, function()
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

    RegisterTouchFriendlyClick(ModeBtn, function()
        Config.TracerMode = Config.TracerMode == "Bottom" and "Center" or "Bottom"
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

-- REGISTERING ALL TAB HOOKS
CreatePremiumTab("Combat", "⚔️", 1, CombatPage)
CreatePremiumTab("Player", "👤", 2, PlayerPage)
CreatePremiumTab("Movement", "⚡", 3, MovementPage)
CreatePremiumTab("Visuals", "👁️", 4, VisualPage)
CreatePremiumTab("Misc", "⚙️", 5, MiscPage)
CreatePremiumTab("Credits", "🎖️", 6, CreditsPage)

-- REGISTERING RENDER CONSTRUCTS
AddPremiumToggle(CombatPage, "Enable Aimbot Lock", "Aimbot", nil, Color3.fromRGB(255, 50, 50), "AimbotKeybind")
AddPremiumToggle(CombatPage, "Team Guard Filter", "TeamCheck") -- ĐỒNG BỘ: Nút này điều khiển lọc team cho cả Aimbot & ESP
AddPremiumToggle(CombatPage, "Wall Occlusion Check", "WallCheck")
AddPremiumSlider(CombatPage, "Aimbot Smoothness", 0, 10, "Smoothness")
AddHitboxSelector(CombatPage)
AddPremiumToggle(CombatPage, "Triggerbot Click", "Triggerbot", nil, Color3.fromRGB(230, 125, 30), "TriggerbotKeybind")
AddPremiumToggle(CombatPage, "Triggerbot Gun WallCheck", "TriggerWallCheck")

-- THÊM PHÍM BẬT CÚI ĐẦU VÀO TAB PLAYER
AddPremiumToggle(PlayerPage, "Character Anti-Aim (Cúi Đầu)", "CuiDau", nil, Color3.fromRGB(200, 40, 120))
AddPremiumToggle(PlayerPage, "Auto Farm Player (Behind)", "AutoFarmPlayer", nil, Color3.fromRGB(45, 140, 75))
AddPremiumSlider(PlayerPage, "Farm TP Delay Interval", 0.01, 5, "AutoFarmDelay")
AddPremiumToggle(PlayerPage, "FullBright Environment", "FullBright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient
        Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end
end)
AddPremiumToggle(PlayerPage, "Enable Spinbot", "Spinbot", nil, nil, "SpinbotKeybind")
AddPremiumSlider(PlayerPage, "Spinbot Rotate Speed", 5, 100, "SpinSpeed")
AddPremiumToggle(MovementPage, "WalkSpeed Bypass", "SpeedToggle", nil, Color3.fromRGB(140, 30, 230), "SpeedKeybind")
AddPremiumSlider(MovementPage, "Speed Multiplier", 16, 200, "WalkSpeed")
AddPremiumToggle(MovementPage, "JumpPower Boost", "JumpToggle", nil, nil, "JumpKeybind")
AddPremiumSlider(MovementPage, "Jump Force Power", 50, 350, "JumpPower")

-- THÊM NÚT BẬT GÓC NHÌN THỨ BA VÀO TAB VISUALS
AddPremiumToggle(VisualPage, "Enable Third Person View", "ThirdPerson", nil, Color3.fromRGB(40, 150, 200))
AddPremiumSlider(VisualPage, "Third Person Distance", 5, 30, "ThirdPersonDistance")
AddPremiumToggle(VisualPage, "Master Visual ESP Control", "EspMaster", nil, Color3.fromRGB(30, 140, 230), "EspMasterKeybind")
AddPremiumToggle(VisualPage, "Render 3D Chams Box", "EspBox")
AddPremiumToggle(VisualPage, "Snap Tracers Rendering", "EspTracer")
AddTracerModeSelector(VisualPage)
AddPremiumToggle(VisualPage, "Overhead Identity Nametag", "EspName")
AddPremiumToggle(VisualPage, "Integrated Health Metrics", "EspHealth")
AddPremiumSlider(VisualPage, "Figma UI Transparency", 10, 100, "EspTransparency", function(v)
    MainFrame.BackgroundTransparency = (v / 100) * 0.15
end)
AddPremiumSlider(VisualPage, "Maximise Vision Distance", 100, 10000, "MaxDistance")
AddPremiumToggle(VisualPage, "Draw FOV SafeCircle", "FovCircle")
AddPremiumSlider(VisualPage, "FOV Dynamic Radius", 30, 600, "FovRadius")

AddPremiumToggle(MiscPage, "Show Mobile Aimbot Button", "ShowMobileAim", function(s) if MobAim then MobAim.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Show Mobile Trigger Button", "ShowMobileTrig", function(s) if MobTrig then MobTrig.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Show Mobile Speed Button", "ShowMobileSpeed", function(s) if MobSpeed then MobSpeed.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Show Mobile Farm Button", "ShowMobileFarm", function(s) if MobFarm then MobFarm.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Show Mobile Cúi Đầu Button", "ShowMobileCui", function(s) if MobCui then MobCui.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Show Mobile ThirdCam Button", "ShowMobileThird", function(s) if MobThird then MobThird.Visible = (s and IsMobile) end end)
AddPremiumToggle(MiscPage, "Apply Customized Wallpaper", "CustomBackground", function(s) CustomBackgroundImage.Visible = s end)
AddPremiumButton(MiscPage, "Force Safely Unload Client", "UNLOAD", function()
    if MasterLoop then MasterLoop:Disconnect() end
    ScreenGui:Destroy()
    FOV_Drawing:Remove()
    Dot_Drawing:Remove()
    for _, l in pairs(Tracer_Cache) do l:Remove() end
    for _, c in pairs(Character_Cache) do CleanCharacterVisuals(c) end
end)

AddPremiumCreditBox(CreditsPage, "Lead Engine Scripting", "Powered by Be for Dai Ca Wang (2026)")
AddPremiumCreditBox(CreditsPage, "UI UX Engineering Designer", "Figma Premium Visual Framework Optimization")

-- ==============================================================================
-- 6. DYNAMIC TICK LOOP (AIMBOT, SPIN, CÚI ĐẦU, THIRD PERSON, ESP)
-- ==============================================================================
MasterLoop = RunService.RenderStepped:Connect(function()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- XỬ LÝ FOV & CROSSHAIR DOT
    if Config.FovCircle then
        FOV_Drawing.Position = Center FOV_Drawing.Radius = Config.FovRadius FOV_Drawing.Visible = true
    else FOV_Drawing.Visible = false end
    if Config.CrosshairDot then Dot_Drawing.Position = Center Dot_Drawing.Visible = true else Dot_Drawing.Visible = false end
    
    -- XỬ LÝ AIMBOT
    if Config.Aimbot and UserInputService:IsKeyDown(Config.AimbotKeybind) then
        local TargetedPart = GetClosestPlayerToCrosshair()
        if TargetedPart then
            local ScreenPos, _ = Camera:WorldToViewportPoint(TargetedPart.Position)
            local MoveX = (ScreenPos.X - Center.X) / Config.Smoothness
            local MoveY = (ScreenPos.Y - Center.Y) / Config.Smoothness
            mousemoverel(MoveX, MoveY)
        end
    end
    
    -- XỬ LÝ TRIGGERBOT & AUTOMATION
    if Config.Triggerbot and UserInputService:IsKeyDown(Config.TriggerbotKeybind) then PerformTriggerbotClick() end
    ProcessAutoFarmPlayer()
    
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    local MyHum = MyChar and MyChar:FindFirstChildOfClass("Humanoid")
    
    if MyChar and IsAlive(MyChar) and MyRoot then
        -- XỬ LÝ WALKSPEED & JUMPPOWER BYPASS
        if Config.SpeedToggle then MyHum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpToggle then MyHum.JumpPower = Config.JumpPower MyHum.UseJumpPower = true end
        
        -- XỬ LÝ SPINBOT
        if Config.Spinbot and UserInputService:IsKeyDown(Config.SpinbotKeybind) then
            CurrentSpinAngle = (CurrentSpinAngle + Config.SpinSpeed) % 360
            MyRoot.CFrame = CFrame.new(MyRoot.Position) * CFrame.Angles(0, math.radians(CurrentSpinAngle), 0)
      end
        
        -- TÍNH NĂNG MỚI: XỬ LÝ CÚI ĐẦU NHÂN VẬT (Thay đổi khớp xoay cổ hoặc ép góc HRP)
        if Config.CuiDau then
            local Neck = MyChar:FindFirstChild("Neck", true)
            if Neck and Neck:IsA("Motor6D") then
                Neck.C0 = CFrame.new(Neck.C0.Position) * CFrame.Angles(math.radians(-90), 0, math.radians(180))
            end
        end
        
        -- TÍNH NĂNG MỚI: XỬ LÝ GÓC NHÌN THỨ BA (Bẻ Camera góc rộng ra xa vị trí nhân vật)
        if Config.ThirdPerson then
            LocalPlayer.CameraMaxZoomDistance = Config.ThirdPersonDistance
            LocalPlayer.CameraMinZoomDistance = Config.ThirdPersonDistance
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0)
        else
            LocalPlayer.CameraMaxZoomDistance = 12.5
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
       end 
            -- VÒNG LẶP XỬ LÝ QUÉT VẼ ESP CHO TẤT CẢ NGƯỜI CHƠI TRONG SERVER
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        local Char = Player.Character
        local Tracer = Tracer_Cache[Player]
        
        -- ĐỒNG BỘ LOGIC LOC TEAM CHO ESP: Nếu trùng team và bật TeamCheck thì ẩn toàn bộ ESP hình vẽ
        if Char and IsAlive(Char) and Config.EspMaster and not IsTeammate(Player) then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            if Root and Hum then
                local CamDist = (Camera.CFrame.Position - Root.Position).Magnitude
                if CamDist <= Config.MaxDistance then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                    local PColor = GetPlayerColor(Player)
                    
                    -- XỬ LÝ VẼ KHUNG CHAMS 3D TRÊN KHÔNG GIAN WORLD SPACE
                    if Config.EspBox then
                        local BoxFill = Char:FindFirstChild("BéBoxFill")
                        if not BoxFill then
                            BoxFill = Instance.new("BoxHandleAdornment")
                            BoxFill.Name = "BéBoxFill" BoxFill.AlwaysOnTop = true BoxFill.ZIndex = 5
                            BoxFill.Adornee = Char BoxFill.Size = Char:GetExtentsSize() + Vector3.new(0.1, 0.1, 0.1)
                            BoxFill.Parent = Char
                        end
                        BoxFill.Color3 = PColor BoxFill.Transparency = 1 - (Config.EspTransparency / 100)
                    else local b = Char:FindFirstChild("BéBoxFill") if b then b:Destroy() end end
                    
                    -- XỬ LÝ VẼ THẺ TÊN VÀ ĐỒNG BỘ THANH MÁU HOÀN CHỈNH
                    if Config.EspName or Config.EspHealth then
                        local Tag = Char:FindFirstChild("BéInfoTag")
                        if not Tag then
                            Tag = Instance.new("BillboardGui")
                            Tag.Name = "BéInfoTag" Tag.AlwaysOnTop = true Tag.Size = UDim2.new(0, 200, 0, 50)
                            Tag.StudsOffset = Vector3.new(0, 3, 0) Tag.Parent = Char
                            local l = Instance.new("TextLabel", Tag)
                            l.Name = "Label" l.BackgroundTransparency = 1 l.Size = UDim2.new(1, 0, 1, 0)
                            l.Font = Enum.Font.GothamBold l.TextSize = 13 l.TextStrokeTransparency = 0
                        end
                        local DisplayText = ""
                        if Config.EspName then DisplayText = Player.Name .. " [" .. math.floor(CamDist) .. "m]" end
                        if Config.EspHealth then DisplayText = DisplayText .. " \n[Máu: " .. math.floor(Hum.Health) .. "/" .. math.floor(Hum.MaxHealth) .. "]" end
                        Tag.Label.Text = DisplayText Tag.Label.TextColor3 = PColor
                    else local t = Char:FindFirstChild("BéInfoTag") if t then t:Destroy() end end
                    
                    -- XỬ LÝ VẼ ĐƯỜNG TRACERS THEO GÓC NHÌN ĐẠI CA CHỌN
                    if Config.EspTracer and Tracer then
                        local Leg, LegOnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                        if LegOnScreen then
                            Tracer.From = Config.TracerMode == "Center" and Center or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            Tracer.To = Vector2.new(Leg.X, Leg.Y) Tracer.Color = PColor Tracer.Visible = true
                        else Tracer.Visible = false end
                    elseif Tracer then Tracer.Visible = false end
                else
                    CleanCharacterVisuals(Char)
                    if Tracer then Tracer.Visible = false end
                end
            else
                CleanCharacterVisuals(Char)
                if Tracer then Tracer.Visible = false end
            end
        else
            CleanCharacterVisuals(Char)
            if Tracer then Tracer.Visible = false end
        end
    end
end)

Players.PlayerAdded:Connect(function(Player) CreateTracerObject(Player) end)
Players.PlayerRemoving:Connect(function(Player) ClearTracerObject(Player) end)

for _, P in pairs(Players:GetPlayers()) do CreateTracerObject(P) end
for K, _ in pairs(GlobalSyncToggles) do UpdateToggleVisual(K) end

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "WANGCAOS CLIENT V6.2",
        Text = "Đã làm lại đồng bộ CheckTeam, thêm nút Cúi Đầu và Góc Nhìn Thứ Ba cho đại ca!",
        Duration = 7
    })
end)
-- ==============================================================================
-- END OF SCRIPT - POWERED BY BE FOR DAI CA WANG (2026)
-- ==============================================================================

