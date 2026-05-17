-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V3.1 - MONOLITHIC EDITION (FIXED GUI)
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
    EspBox = false,
    EspTracer = false,
    EspName = false,
    EspTransparency = 80,
    MaxDistance = 500,
    
    SpeedToggle = false,
    WalkSpeed = 16,
    JumpToggle = false,
    JumpPower = 50,
    FullBright = false,
    
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

-- ==============================================================================
-- 2. SECURE GUI PARENTING (FIXED GUI NOT OPENING)
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
    warn("[WANGCAOS] CRITICAL ERROR: Cannot find Safe Parent for GUI!")
    return
end

for _, old in pairs(SafeParent:GetChildren()) do
    if old.Name == "Wangcaos_Minecraft_Figma_UI" then old:Destroy() end
end

-- ==============================================================================
-- 3. CACHE & MEMORY ALLOCATION
-- ==============================================================================
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Color3.fromRGB(255, 255, 255)
FOV_Drawing.Thickness = 1.5
FOV_Drawing.NumSides = 64
FOV_Drawing.Filled = false
FOV_Drawing.Transparency = 0.7
FOV_Drawing.Visible = false

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
-- 4. MATH & TARGETING ENGINE
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
    return Color3.fromRGB(0, 255, 0)
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

-- ==============================================================================
-- 5. GUI CONSTRUCTION (FIGMA MINECRAFT HYBRID V3.1)
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Minecraft_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

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
ClientTitle.Text = "WANGCAOS CLIENT // MONOLITHIC V3.1 (FIXED)"
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

-- DRAG LOGIC (Header & Toggle Button)
local function MakeDraggable(UIElement, DragHandle)
    local dragToggle = nil
    local dragSpeed = 0
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

MakeDraggable(ToggleButton, ToggleButton)
MakeDraggable(MainFrame, HeaderBar)

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

-- ==============================================================================
-- 6. TABS & PAGES SYSTEM
-- ==============================================================================
local TabNavBar = Instance.new("Frame")
TabNavBar.Parent = MainFrame
TabNavBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
TabNavBar.Position = UDim2.new(0, 15, 0, 45)
TabNavBar.Size = UDim2.new(1, -30, 0, 36)
Instance.new("UICorner", TabNavBar).CornerRadius = UDim.new(0, 6)

local TabLayout = Instance.new("UIListLayout", TabNavBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 8)
local TabPad = Instance.new("UIPadding", TabNavBar)
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.PaddingTop = UDim.new(0, 4)

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 92)
ContentContainer.Size = UDim2.new(1, -30, 1, -110)

local CombatPage = Instance.new("ScrollingFrame", ContentContainer)
local VisualPage = Instance.new("ScrollingFrame", ContentContainer)
local PlayerPage = Instance.new("ScrollingFrame", ContentContainer)

for _, page in pairs({CombatPage, VisualPage, PlayerPage}) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 400)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
end
CombatPage.Visible = true

local function CreateTab(Name, Order, TargetPage)
    local TabBtn = Instance.new("TextButton", TabNavBar)
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(0, 160, 0, 28)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = Name:upper()
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
    TabBtn.TextSize = 11
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    
    local TabStroke = Instance.new("UIStroke", TabBtn)
    TabStroke.Color = Color3.fromRGB(85, 255, 85)
    TabStroke.Enabled = Order == 1
    
    TabBtn.MouseButton1Click:Connect(function()
        CombatPage.Visible = false
        VisualPage.Visible = false
        PlayerPage.Visible = false
        
        for _, btn in pairs(TabNavBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(140, 140, 140)
                btn.UIStroke.Enabled = false
            end
        end
        TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabStroke.Enabled = true
        TargetPage.Visible = true
    end)
end

CreateTab("Combat", 1, CombatPage)
CreateTab("Visuals", 2, VisualPage)
CreateTab("Player", 3, PlayerPage)

-- ==============================================================================
-- 7. UI COMPONENTS (TOGGLES & SLIDERS)
-- ==============================================================================
local function AddToggle(Page, LabelText, Key, Callback)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundTransparency = 1
    TFrame.Size = UDim2.new(1, 0, 0, 36)
    
    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 6, 0, 0)
    Lbl.Size = UDim2.new(1, -70, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText:upper()
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local SwitchBg = Instance.new("Frame", TFrame)
    SwitchBg.BackgroundColor3 = Config[Key] and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(32, 32, 32)
    SwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    SwitchBg.Size = UDim2.new(0, 36, 0, 18)
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    local SwStrk = Instance.new("UIStroke", SwitchBg)
    SwStrk.Color = Config[Key] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(75, 75, 75)

    local Ball = Instance.new("Frame", SwitchBg)
    Ball.BackgroundColor3 = Config[Key] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(160, 160, 160)
    Ball.Position = Config[Key] and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Ball.Size = UDim2.new(0, 14, 0, 14)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", TFrame)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""

    Btn.MouseButton1Click:Connect(function()
        Config[Key] = not Config[Key]
        TweenService:Create(Ball, TweenInfo.new(0.12), {
            Position = Config[Key] and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Config[Key] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(160, 160, 160)
        }):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.12), {
            BackgroundColor3 = Config[Key] and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(32, 32, 32)
        }):Play()
        SwStrk.Color = Config[Key] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(75, 75, 75)
        if Callback then Callback(Config[Key]) end
    end)
end

local function AddSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.BackgroundTransparency = 1
    SFrame.Size = UDim2.new(1, 0, 0, 42)

    local Lbl = Instance.new("TextLabel", SFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 6, 0, 2)
    Lbl.Size = UDim2.new(1, -90, 0, 16)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText:upper()
    Lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValTxt = Instance.new("TextLabel", SFrame)
    ValTxt.BackgroundTransparency = 1
    ValTxt.Position = UDim2.new(1, -80, 0, 2)
    ValTxt.Size = UDim2.new(0, 75, 0, 16)
    ValTxt.Font = Enum.Font.GothamBold
    ValTxt.Text = tostring(Config[Key])
    ValTxt.TextColor3 = Color3.fromRGB(85, 255, 85)
    ValTxt.TextSize = 11
    ValTxt.TextXAlignment = Enum.TextXAlignment.Right

    local Bar = Instance.new("Frame", SFrame)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.new(0, 6, 0, 24)
    Bar.Size = UDim2.new(1, -12, 0, 4)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Bar)
    Fill.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

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

-- ==============================================================================
-- 8. BUILD UI BINDINGS
-- ==============================================================================
AddToggle(CombatPage, "Enable Aimbot Lock", "Aimbot")
AddToggle(CombatPage, "Team Guard Filter", "TeamCheck")
AddToggle(CombatPage, "Wall Occlusion Check", "WallCheck")
AddSlider(CombatPage, "Smoothing Factor", 1, 10, "Smoothness", function(val) Config.Smoothness = val / 20 end)

AddToggle(VisualPage, "ESP Master Control", "EspMaster")
AddToggle(VisualPage, "AlwaysOnTop Chams 3D", "EspBox")
AddSlider(VisualPage, "Chams Opacity Power", 0, 100, "EspTransparency")
AddToggle(VisualPage, "Bottom Center Tracers", "EspTracer")
AddToggle(VisualPage, "Dynamic Informative Tag", "EspName")
AddToggle(VisualPage, "Draw FOV Calibration", "FovCircle")
AddSlider(VisualPage, "FOV Dynamic Radius", 30, 500, "FovRadius")

AddToggle(PlayerPage, "Velocity WalkSpeed Hack", "SpeedToggle")
AddSlider(PlayerPage, "Custom Velocity Power", 16, 200, "WalkSpeed")
AddToggle(PlayerPage, "Internal JumpPower Hack", "JumpToggle")
AddSlider(PlayerPage, "Custom Jump Force", 50, 350, "JumpPower")
AddToggle(PlayerPage, "FullBright Environmental", "FullBright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient
        Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end
end)


-- =====================================================================
-- 9. ESP LOGIC PIPELINE (NON-BLOCKING)
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
    Label.TextSize = 14
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
-- 10. RUNSERVICE LOOP (THE ENGINE CORE)
-- ==============================================================================
local MasterLoop = RunService.RenderStepped:Connect(function()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if Config.FovCircle then
        FOV_Drawing.Position = Center
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
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

                if Config.EspBox then
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
                    Data.Label.Text = string.format("%s (%dm)\n(%s)(%s)", Data.Player.Name, Dist, Team, Tool)
                else
                    Data.Label.Visible = false
                end

                local Tracer = Tracer_Cache[Data.Player]
                if Tracer and Config.EspTracer then
                    local Leg, OnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    if OnScreen then
                        Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        Tracer.To = Vector2.new(Leg.X, Leg.Y)
                        Tracer.Color = PColor
                        Tracer.Visible = true
                    else
                        Tracer.Visible = false
                    end
                elseif Tracer then Tracer.Visible = false end
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

CloseBtn.MouseButton1Click:Connect(function()
    MasterLoop:Disconnect()
    pcall(function() FOV_Drawing:Remove() end)
    for _, L in pairs(Tracer_Cache) do pcall(function() L:Remove() end) end
    for C, _ in pairs(Character_Cache) do CleanCharacterVisuals(C) end
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

-- THÔNG BÁO XÁC NHẬN CHẠY THÀNH CÔNG
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "WANGCAOS CLIENT",
        Text = "LOAD THÀNH CÔNG! BẤM [ ĐỂ ẨN/HIỆN MENU HOẶC DÙNG NÚT W TRÊN MÀN HÌNH.",
        Duration = 10
    })
end)
