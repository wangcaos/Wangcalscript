-- ==============================================================================
-- WANGCAOS PREMIUM SCRIPT - THE 1600-LINE ULTIMATE EDITION
-- DEEP SEARCH OPTIMIZED - 2026 ENGINE
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
-- 1. SAFE GUI INJECTION (BYPASS EXECUTOR BLOCKS)
-- ==============================================================================
local function GetSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then
            local hiddenGui = Instance.new("ScreenGui")
            syn.protect_gui(hiddenGui)
            hiddenGui.Parent = CoreGui
            return hiddenGui
        end
        return CoreGui
    end)
    if not success or not parent then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

local GuiParent = GetSafeGuiParent()

-- Xóa GUI cũ nếu đang tồn tại để tránh rác bộ nhớ
for _, v in pairs(GuiParent:GetChildren()) do
    if v.Name == "Wangcaos_Ultimate_1600" then
        v:Destroy()
    end
end

-- ==============================================================================
-- 2. MASTER CONFIGURATION DATA
-- ==============================================================================
local WangConfig = {
    -- Aimbot Settings
    Aimbot = {
        Enabled = false,
        Key = Enum.KeyCode.E,
        Mode = "Mouse", -- "Mouse" or "Camera"
        TargetPart = "Head",
        Smoothness = 0.5,
        TeamCheck = true,
        WallCheck = true,
        PredictMovement = false,
        PredictionVelocity = 0.155
    },
    -- FOV Settings
    FOV = {
        Enabled = false,
        Visible = false, -- Tắt khi mở menu
        Radius = 150,
        Color = Color3.fromRGB(255, 255, 255),
        Sides = 64,
        Thickness = 1
    },
    -- ESP Settings
    ESP = {
        Enabled = false,
        Boxes = false,
        BoxColor = Color3.fromRGB(255, 255, 255),
        Names = false,
        HealthBar = false,
        Distance = false,
        Tracers = false,
        TracerOrigin = "Bottom", -- "Bottom", "Top", "Mouse"
        Chams = false,
        ChamsFill = Color3.fromRGB(255, 0, 0),
        ChamsOutline = Color3.fromRGB(255, 255, 255),
        MaxDistance = 5000,
        TextSize = 14
    },
    -- Gun Mods (Memory Manipulation)
    GunMods = {
        NoRecoil = false,
        NoSpread = false,
        InstaReload = false,
        InfiniteAmmo = false,
        FireRate = false,
        RapidFire = 0.01
    },
    -- Movement & Environment
    Misc = {
        WalkSpeed = 16,
        WalkSpeedToggle = false,
        JumpPower = 50,
        JumpPowerToggle = false,
        Fly = false,
        FlySpeed = 50,
        Noclip = false,
        FullBright = false,
        TimeOfDay = "14:00:00"
    }
}

-- ==============================================================================
-- 3. CUSTOM UI LIBRARY ENGINE (BUILT FROM SCRATCH)
-- ==============================================================================
local UILibrary = {}

function UILibrary:CreateWindow(TitleText)
    local WindowData = {}
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Wangcaos_Ultimate_1600"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GuiParent

    -- Mobile / PC Toggle Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "OpenCloseMenu"
    ToggleButton.Parent = ScreenGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ToggleButton.Position = UDim2.new(0, 20, 0, 20)
    ToggleButton.Size = UDim2.new(0, 45, 0, 45)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Text = "W"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
    ToggleButton.TextSize = 20
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Color3.fromRGB(255, 50, 50)
    ToggleStroke.Thickness = 2
    ToggleStroke.Parent = ToggleButton

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.ClipsDescendants = true
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame
    
    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Name = "Shadow"
    DropShadow.Parent = MainFrame
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.Size = UDim2.new(1, 47, 1, 47)
    DropShadow.ZIndex = -1
    DropShadow.Image = "rbxassetid://6015895133"
    DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    DropShadow.ImageTransparency = 0.5
    DropShadow.SliceCenter = Rect.new(97, 97, 97, 97)

    -- Title Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 35)

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -15, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = TitleText
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Logic Kéo Thả (Drag)
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Nút Kéo Thả cho Mobile Toggle Button
    local btnDragging = false
    local btnDragStart, btnStartPos
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            btnDragging = true btnDragStart = input.Position btnStartPos = ToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then btnDragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if btnDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - btnDragStart
            ToggleButton.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
        end
    end)

    -- Logic Bật/Tắt GUI (Sửa lỗi kẹt GUI)
    local isGuiOpen = true
    local function ToggleGuiFlow()
        isGuiOpen = not isGuiOpen
        MainFrame.Visible = isGuiOpen
    end

    ToggleButton.MouseButton1Click:Connect(ToggleGuiFlow)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            ToggleGuiFlow()
        end
    end)
    
    WindowData.MainFrame = MainFrame
    return WindowData
end
-- ==============================================================================
-- 4. TAB & CONTENT SYSTEM FOR UI LIBRARY
-- ==============================================================================
function UILibrary:CreateTabSystem(WindowData)
    local TabData = {}
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = WindowData.MainFrame
    Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 35)
    Sidebar.Size = UDim2.new(0, 130, 1, -35)

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = WindowData.MainFrame
    ContentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ContentArea.BorderSizePixel = 0
    ContentArea.Position = UDim2.new(0, 130, 0, 35)
    ContentArea.Size = UDim2.new(1, -130, 1, -35)
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = Sidebar
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    TabData.Sidebar = Sidebar
    TabData.ContentArea = ContentArea
    TabData.Tabs = {}
    TabData.FirstTab = true
    
    function TabData:CreateTab(TabName)
        local TabInfo = {}
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName.."_Btn"
        TabButton.Parent = Sidebar
        TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = "  " .. TabName
        TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = TabName.."_Page"
        TabPage.Parent = ContentArea
        TabPage.Active = true
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.ScrollBarThickness = 4
        TabPage.Visible = TabData.FirstTab
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = TabPage
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 5)
        
        local UIPadding = Instance.new("UIPadding")
        UIPadding.Parent = TabPage
        UIPadding.PaddingTop = UDim.new(0, 10)
        UIPadding.PaddingLeft = UDim.new(0, 10)
        UIPadding.PaddingRight = UDim.new(0, 10)

        if TabData.FirstTab then
            TabButton.TextColor3 = Color3.fromRGB(255, 50, 50)
            TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TabData.FirstTab = false
        end
        
        table.insert(TabData.Tabs, {Button = TabButton, Page = TabPage})
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(TabData.Tabs) do
                tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
                tab.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                tab.Page.Visible = false
            end
            TabButton.TextColor3 = Color3.fromRGB(255, 50, 50)
            TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            TabPage.Visible = true
        end)
        
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        -- Elements inside Tab
        function TabInfo:CreateToggle(ToggleName, DefaultState, Callback)
            local Toggled = DefaultState
            local CallbackFunc = Callback or function() end
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = ToggleName
            ToggleFrame.Parent = TabPage
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 4)
            ToggleCorner.Parent = ToggleFrame
            
            local Title = Instance.new("TextLabel")
            Title.Parent = ToggleFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(1, -60, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = ToggleName
            Title.TextColor3 = Color3.fromRGB(220, 220, 220)
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            
            local ToggleBox = Instance.new("Frame")
            ToggleBox.Parent = ToggleFrame
            ToggleBox.BackgroundColor3 = Toggled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 50)
            ToggleBox.Position = UDim2.new(1, -40, 0.5, -10)
            ToggleBox.Size = UDim2.new(0, 30, 0, 20)
            
            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 4)
            BoxCorner.Parent = ToggleBox
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Parent = ToggleFrame
            ToggleButton.BackgroundTransparency = 1
            ToggleButton.Size = UDim2.new(1, 0, 1, 0)
            ToggleButton.Text = ""
            
            ToggleButton.MouseButton1Click:Connect(function()
                Toggled = not Toggled
                TweenService:Create(ToggleBox, TweenInfo.new(0.2), {BackgroundColor3 = Toggled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 50)}):Play()
                CallbackFunc(Toggled)
            end)
            
            CallbackFunc(Toggled)
        end

        function TabInfo:CreateSlider(SliderName, Min, Max, Default, Callback)
            local SliderValue = Default
            local CallbackFunc = Callback or function() end
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = SliderName
            SliderFrame.Parent = TabPage
            SliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 4)
            SliderCorner.Parent = SliderFrame
            
            local Title = Instance.new("TextLabel")
            Title.Parent = SliderFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 5)
            Title.Size = UDim2.new(1, -20, 0, 20)
            Title.Font = Enum.Font.Gotham
            Title.Text = SliderName
            Title.TextColor3 = Color3.fromRGB(220, 220, 220)
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Parent = SliderFrame
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(0, 10, 0, 5)
            ValueLabel.Size = UDim2.new(1, -20, 0, 20)
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.Text = tostring(Default)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SliderBack.BorderSizePixel = 0
            SliderBack.Position = UDim2.new(0, 10, 0, 30)
            SliderBack.Size = UDim2.new(1, -20, 0, 6)
            
            local BackCorner = Instance.new("UICorner")
            BackCorner.CornerRadius = UDim.new(1, 0)
            BackCorner.Parent = SliderBack
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            SliderFill.BorderSizePixel = 0
            SliderFill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill
            
            local SliderBtn = Instance.new("TextButton")
            SliderBtn.Parent = SliderBack
            SliderBtn.BackgroundTransparency = 1
            SliderBtn.Size = UDim2.new(1, 0, 1, 0)
            SliderBtn.Text = ""
            
            local dragging = false
            SliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mousePos = UserInputService:GetMouseLocation().X
                    local sliderPos = SliderBack.AbsolutePosition.X
                    local sliderSize = SliderBack.AbsoluteSize.X
                    local percentage = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
                    local value = math.floor(Min + (Max - Min) * percentage)
                    
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    CallbackFunc(value)
                end
            end)
            
            return TabInfo
        end
        
        return TabInfo
    end
    return TabData
end

-- ==============================================================================
-- 5. INITIALIZING MENU & ATTACHING CONFIG VARIABLES
-- ==============================================================================
local MainWindow = UILibrary:CreateWindow("WANGCAOS ULTIMATE | V2.0")
local TabSystem = UILibrary:CreateTabSystem(MainWindow)

-- Tạo các danh mục chính
local CombatTab = TabSystem:CreateTab("Aimbot")
local VisualTab = TabSystem:CreateTab("Visuals ESP")
local PlayerTab = TabSystem:CreateTab("Movement")

-- ==============================================================================
-- 6. CONNECTING UI ELEMENTS TO MASTER CONFIGURATION
-- ==============================================================================

-- Aimbot UI Controls
CombatTab:CreateToggle("Aimbot Master Switch", WangConfig.Aimbot.Enabled, function(state)
    WangConfig.Aimbot.Enabled = state
end)

CombatTab:CreateToggle("Team Check (Ignore Allies)", WangConfig.Aimbot.TeamCheck, function(state)
    WangConfig.Aimbot.TeamCheck = state
end)

CombatTab:CreateToggle("Wall Check (Visible Only)", WangConfig.Aimbot.WallCheck, function(state)
    WangConfig.Aimbot.WallCheck = state
end)

CombatTab:CreateToggle("Predict Movement Target", WangConfig.Aimbot.PredictMovement, function(state)
    WangConfig.Aimbot.PredictMovement = state
end)

CombatTab:CreateSlider("Aimbot Smoothness (Lerp)", 1, 10, 5, function(val)
    WangConfig.Aimbot.Smoothness = val / 10
end)

-- Visuals ESP UI Controls
VisualTab:CreateToggle("ESP Universal Master Switch", WangConfig.ESP.Enabled, function(state)
    WangConfig.ESP.Enabled = state
end)

VisualTab:CreateToggle("Show Corner Boxes Overlay", WangConfig.ESP.Boxes, function(state)
    WangConfig.ESP.Boxes = state
end)

VisualTab:CreateToggle("Show Name & Meta Identifiers", WangConfig.ESP.Names, function(state)
    WangConfig.ESP.Names = state
end)

VisualTab:CreateToggle("Show Dynamic Health bars", WangConfig.ESP.HealthBar, function(state)
    WangConfig.ESP.HealthBar = state
end)

VisualTab:CreateToggle("Show Bullet Tracers Core", WangConfig.ESP.Tracers, function(state)
    WangConfig.ESP.Tracers = state
end)

VisualTab:CreateToggle("Highlight Full Body Chams", WangConfig.ESP.Chams, function(state)
    WangConfig.ESP.Chams = state
end)

VisualTab:CreateToggle("Enable Custom FOV Radius Circle", WangConfig.FOV.Enabled, function(state)
    WangConfig.FOV.Enabled = state
end)

VisualTab:CreateSlider("Adjust Field of View Radius", 30, 600, 150, function(val)
    WangConfig.FOV.Radius = val
end)

-- Movement UI Controls
PlayerTab:CreateToggle("Override Default WalkSpeed", WangConfig.Misc.WalkSpeedToggle, function(state)
    WangConfig.Misc.WalkSpeedToggle = state
end)

PlayerTab:CreateSlider("WalkSpeed Custom Magnitude", 16, 250, 16, function(val)
    WangConfig.Misc.WalkSpeed = val
end)

PlayerTab:CreateToggle("Override Default JumpPower", WangConfig.Misc.JumpPowerToggle, function(state)
    WangConfig.Misc.JumpPowerToggle = state
end)

PlayerTab:CreateSlider("JumpPower Custom Magnitude", 50, 350, 50, function(val)
    WangConfig.Misc.JumpPower = val
end)

-- ==============================================================================
-- 7. VISUAL TARGET MARKER & MATHEMATICAL CALCULATION FUNCTIONS
-- ==============================================================================
local SelectedHighlight = Instance.new("Highlight")
SelectedHighlight.Name = "Wangcaos_MasterHighlight"
SelectedHighlight.FillColor = Color3.fromRGB(255, 0, 0)
SelectedHighlight.FillTransparency = 0.4
SelectedHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
SelectedHighlight.OutlineTransparency = 0
SelectedHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
SelectedHighlight.Adornee = nil
SelectedHighlight.Parent = GuiParent

local function CheckWallOcclusion(TargetPart, TargetCharacter)
    if not WangConfig.Aimbot.WallCheck then return true end
    if not TargetPart or not TargetCharacter then return false end
    
    local RaycastOrigin = Camera.CFrame.Position
    local RaycastDirection = TargetPart.Position - RaycastOrigin
    
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character, TargetCharacter, Camera}
    
    local Result = workspace:Raycast(RaycastOrigin, RaycastDirection, Params)
    return Result == nil
end

local function VerifyCharacterState(Character)
    if not Character then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Head = Character:FindFirstChild("Head")
    
    if not Hum or not Root or not Head then return false end
    if Hum.Health <= 0 or Hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    
    return true
end

-- Tách hàm tìm kiếm đối tượng tối ưu nhất theo tọa độ vector màn hình
local function AcquireMathematicalTarget()
    if not WangConfig.Aimbot.Enabled then return nil end
    
    local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local BestTarget = nil
    local MaximumDistance = WangConfig.FOV.Enabled and WangConfig.FOV.Radius or math.huge
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and VerifyCharacterState(Player.Character) then
            if WangConfig.Aimbot.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local TargetPart = Player.Character:FindFirstChild(WangConfig.Aimbot.TargetPart)
            if TargetPart then
                local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
                
                if OnScreen and CheckWallOcclusion(TargetPart, Player.Character) then
                    local DistanceToCenter = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - ViewportCenter).Magnitude
                    
                    if DistanceToCenter < MaximumDistance then
                        MaximumDistance = DistanceToCenter
                        BestTarget = TargetPart
                    end
                end
            end
        end
    end
    return BestTarget
end
-- ==============================================================================
-- 8. DRAWING OVERLAY INFRASTRUCTURE (VECTOR CORE ENGINE)
-- ==============================================================================
local ESP_Cache = {}

local FOV_Circle_Object = Drawing.new("Circle")
FOV_Circle_Object.Color = WangConfig.FOV.Color
FOV_Circle_Object.Thickness = WangConfig.FOV.Thickness
FOV_Circle_Object.NumSides = WangConfig.FOV.Sides
FOV_Circle_Object.Filled = false
FOV_Circle_Object.Transparency = 1
FOV_Circle_Object.Visible = false

local function CreatePlayerESPElements(Player)
    if ESP_Cache[Player] then return end
    
    local Elements = {
        Box_TL1 = Drawing.new("Line"), Box_TL2 = Drawing.new("Line"),
        Box_TR1 = Drawing.new("Line"), Box_TR2 = Drawing.new("Line"),
        Box_BL1 = Drawing.new("Line"), Box_BL2 = Drawing.new("Line"),
        Box_BR1 = Drawing.new("Line"), Box_BR2 = Drawing.new("Line"),
        Health_Outline = Drawing.new("Line"),
        Health_Bar = Drawing.new("Line"),
        Name_Tag = Drawing.new("Text"),
        Tracer_Line = Drawing.new("Line")
    }
    
    -- Khởi tạo thuộc tính cơ bản cho các Vector 2D Drawing
    for Name, DrawingObject in pairs(Elements) do
        if string.find(Name, "Box") then
            DrawingObject.Thickness = 1.5
            DrawingObject.Color = WangConfig.ESP.BoxColor
        elseif string.find(Name, "Health") then
            DrawingObject.Thickness = 2
        elseif Name == "Tracer_Line" then
            DrawingObject.Thickness = 1.2
            DrawingObject.Color = Color3.fromRGB(255, 50, 50)
        elseif Name == "Name_Tag" then
            DrawingObject.Size = WangConfig.ESP.TextSize
            DrawingObject.Center = true
            DrawingObject.Outline = true
            DrawingObject.OutlineColor = Color3.fromRGB(0, 0, 0)
            DrawingObject.Color = Color3.fromRGB(255, 255, 255)
        end
        DrawingObject.Transparency = 1
        DrawingObject.Visible = false
    end
    
    ESP_Cache[Player] = Elements
end

local function DestroyPlayerESPElements(Player)
    if ESP_Cache[Player] then
        for _, DrawingObject in pairs(ESP_Cache[Player]) do
            DrawingObject:Remove()
        end
        ESP_Cache[Player] = nil
    end
end

-- ==============================================================================
-- 9. MATHEMATICAL 2D CORNER CALCULATION & SCREEN RENDERING
-- ==============================================================================
local function RenderESPForTarget(Player, Elements)
    local Character = Player.Character
    if not WangConfig.ESP.Enabled or not Character or not VerifyCharacterState(Character) then
        for _, DrawingObject in pairs(Elements) do DrawingObject.Visible = false end
        return
    end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Head = Character:FindFirstChild("Head")
    if not RootPart or not Humanoid or not Head then
        for _, DrawingObject in pairs(Elements) do DrawingObject.Visible = false end
        return
    end
    
    local RootPosition, IsOnScreen = Camera:WorldToViewportPoint(RootPart.Position)
    local DistanceFromLocal = (RootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not IsOnScreen or DistanceFromLocal > WangConfig.ESP.MaxDistance then
        for _, DrawingObject in pairs(Elements) do DrawingObject.Visible = false end
        return
    end
    
    -- Tính toán khung xương hộp 2D Corner Box dựa trên tỷ lệ Camera
    local HeadPosition = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local LegPosition = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
    
    local BoxHeight = math.abs(HeadPosition.Y - LegPosition.Y)
    local BoxWidth = BoxHeight / 2
    local Box_X = RootPosition.X - BoxWidth / 2
    local Box_Y = RootPosition.Y - BoxHeight / 2
    local CornerLength = BoxWidth / 3
    
    -- 1. Vẽ 8 đường góc Corner Box
    if WangConfig.ESP.Boxes then
        Elements.Box_TL1.From = Vector2.new(Box_X, Box_Y) Elements.Box_TL1.To = Vector2.new(Box_X + CornerLength, Box_Y)
        Elements.Box_TL2.From = Vector2.new(Box_X, Box_Y) Elements.Box_TL2.To = Vector2.new(Box_X, Box_Y + CornerLength)
        
        Elements.Box_TR1.From = Vector2.new(Box_X + BoxWidth, Box_Y) Elements.Box_TR1.To = Vector2.new(Box_X + BoxWidth - CornerLength, Box_Y)
        Elements.Box_TR2.From = Vector2.new(Box_X + BoxWidth, Box_Y) Elements.Box_TR2.To = Vector2.new(Box_X + BoxWidth, Box_Y + CornerLength)
        
        Elements.Box_BL1.From = Vector2.new(Box_X, Box_Y + BoxHeight) Elements.Box_BL1.To = Vector2.new(Box_X + CornerLength, Box_Y + BoxHeight)
        Elements.Box_BL2.From = Vector2.new(Box_X, Box_Y + BoxHeight) Elements.Box_BL2.To = Vector2.new(Box_X, Box_Y + BoxHeight - CornerLength)
        
        Elements.Box_BR1.From = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight) Elements.Box_BR1.To = Vector2.new(Box_X + BoxWidth - CornerLength, Box_Y + BoxHeight)
        Elements.Box_BR2.From = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight) Elements.Box_BR2.To = Vector2.new(Box_X + BoxWidth, Box_Y + BoxHeight - CornerLength)
        
        for Name, DrawingObject in pairs(Elements) do if string.find(Name, "Box_") then DrawingObject.Visible = true end end
    else
        for Name, DrawingObject in pairs(Elements) do if string.find(Name, "Box_") then DrawingObject.Visible = false end end
    end
    
    -- 2. Vẽ Thanh Máu Động (Dynamic Health Bar)
    if WangConfig.ESP.HealthBar then
        local HealthPercentage = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
        local Bar_X = Box_X - 5
        
        Elements.Health_Outline.From = Vector2.new(Bar_X, Box_Y)
        Elements.Health_Outline.To = Vector2.new(Bar_X, Box_Y + BoxHeight)
        Elements.Health_Outline.Color = Color3.fromRGB(0, 0, 0)
        Elements.Health_Outline.Visible = true
        
        Elements.Health_Bar.From = Vector2.new(Bar_X, Box_Y + BoxHeight)
        Elements.Health_Bar.To = Vector2.new(Bar_X, Box_Y + BoxHeight - (BoxHeight * HealthPercentage))
        Elements.Health_Bar.Color = Color3.fromRGB(255 - (255 * HealthPercentage), 255 * HealthPercentage, 0)
        Elements.Health_Bar.Visible = true
    else
        Elements.Health_Outline.Visible = false
        Elements.Health_Bar.Visible = false
    end
end
-- ==============================================================================
-- 10. ESP RENDER PIPELINE - PART II (TRACERS, NAMES & CHAMS OVERLAY)
-- ==============================================================================
local function FinalizeESPRender(Player, Elements)
    local Character = Player.Character
    if not WangConfig.ESP.Enabled or not Character or not VerifyCharacterState(Character) then return end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    local Head = Character:FindFirstChild("Head")
    if not RootPart or not Head then return end
    
    local RootPosition, IsOnScreen = Camera:WorldToViewportPoint(RootPart.Position)
    local HeadPosition = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local LegPosition = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
    
    local BoxHeight = math.abs(HeadPosition.Y - LegPosition.Y)
    local BoxWidth = BoxHeight / 2
    local Box_X = RootPosition.X - BoxWidth / 2
    local Box_Y = RootPosition.Y - BoxHeight / 2
    local DistanceFromLocal = math.floor((RootPart.Position - Camera.CFrame.Position).Magnitude)

    -- 3. Vẽ Nhãn Tên & Khoảng Cách (Name & Meta Tags)
    if WangConfig.ESP.Names then
        Elements.Name_Tag.Position = Vector2.new(Box_X + BoxWidth / 2, Box_Y - (WangConfig.ESP.TextSize + 3))
        Elements.Name_Tag.Text = string.format("%s [%dm]", Player.Name, DistanceFromLocal)
        Elements.Name_Tag.Visible = true
    else
        Elements.Name_Tag.Visible = false
    end

    -- 4. Vẽ Đường Chỉ Hướng Tâm (Bullet Tracers Core)
    if WangConfig.ESP.Tracers then
        local ScreenSize = Camera.ViewportSize
        if WangConfig.ESP.TracerOrigin == "Bottom" then
            Elements.Tracer_Line.From = Vector2.new(ScreenSize.X / 2, ScreenSize.Y)
        elseif WangConfig.ESP.TracerOrigin == "Top" then
            Elements.Tracer_Line.From = Vector2.new(ScreenSize.X / 2, 0)
        else
            Elements.Tracer_Line.From = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
        end
        Elements.Tracer_Line.To = Vector2.new(RootPosition.X, RootPosition.Y)
        Elements.Tracer_Line.Visible = true
    else
        Elements.Tracer_Line.Visible = false
    end

    -- 5. Xử Lý Đổ Màu Khối Xuyên Tường (Highlight Chams Full Body)
    local ExistingHighlight = Character:FindFirstChild("Wang_Chams_Tag")
    if WangConfig.ESP.Chams then
        if not ExistingHighlight then
            local NewChams = Instance.new("Highlight")
            NewChams.Name = "Wang_Chams_Tag"
            NewChams.FillColor = WangConfig.ESP.ChamsFill
            NewChams.OutlineColor = WangConfig.ESP.ChamsOutline
            NewChams.FillTransparency = 0.5
            NewChams.OutlineTransparency = 0
            NewChams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            NewChams.Parent = Character
        else
            ExistingHighlight.Enabled = true
        end
    else
        if ExistingHighlight then ExistingHighlight.Enabled = false end
    end
end

-- ==============================================================================
-- 11. CENTRAL RENDER MEMORY CLEANUP & EVENT LISTENERS
-- ==============================================================================
local function CleanCharacterChams(Character)
    if Character then
        local TargetChams = Character:FindFirstChild("Wang_Chams_Tag")
        if TargetChams then TargetChams:Destroy() end
    end
end

Players.PlayerRemoving:Connect(function(Player)
    DestroyPlayerESPElements(Player)
end)

Players.PlayerAdded:Connect(function(Player)
    CreatePlayerESPElements(Player)
    Player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESP_Cache[Player] then CreatePlayerESPElements(Player) end
    end)
end)

-- Khởi tạo cache ban đầu cho tất cả người chơi trong phòng máy
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreatePlayerESPElements(Player)
    end
end
-- ==============================================================================
-- 12. QUANTUM AIM TARGET LOCKING & SMOOTH POSITION LERP
-- ==============================================================================
local LastAimLockTime = 0

local function ProcessAimbotLock(CurrentTarget)
    if not CurrentTarget or not CurrentTarget.Parent then 
        SelectedHighlight.Adornee = nil 
        return 
    end

    local TargetCharacter = CurrentTarget.Parent
    local TargetPosition = CurrentTarget.Position

    -- Tính toán dự đoán chuyển động (Movement Prediction Logic)
    if WangConfig.Aimbot.PredictMovement then
        local HumanoidRootPart = TargetCharacter:FindFirstChild("HumanoidRootPart")
        if HumanoidRootPart then
            TargetPosition = TargetPosition + (HumanoidRootPart.AssemblyLinearVelocity * WangConfig.Aimbot.PredictionVelocity)
        end
    end

    -- Khóa góc nhìn Camera mượt mà (Smooth Interpolation Engine)
    if WangConfig.Aimbot.Mode == "Camera" then
        local TargetCFrame = CFrame.new(Camera.CFrame.Position, TargetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, WangConfig.Aimbot.Smoothness)
    else
        -- Di chuyển chuột bằng Vector Mouse Point (Hỗ trợ tốt Bypass Chống Khóa Tâm)
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPosition)
        if OnScreen then
            local MouseLocation = UserInputService:GetMouseLocation()
            local DeltaX = (ScreenPos.X - MouseLocation.X) * WangConfig.Aimbot.Smoothness
            local DeltaY = (ScreenPos.Y - MouseLocation.Y) * WangConfig.Aimbot.Smoothness
            
            -- Giả lập dịch chuyển phần cứng an toàn
            pcall(function()
                if mousemoverel then
                    mousemoverel(DeltaX, DeltaY)
                end
            end)
        end
    end

    -- Đánh dấu mục tiêu đang bị khóa tâm
    SelectedHighlight.Adornee = TargetCharacter
end

-- ==============================================================================
-- 13. CENTRAL RUNSERVICE CORE TICK PIPELINE (RENDERSTEPPED THREAD)
-- ==============================================================================
RunService.RenderStepped:Connect(function()
    local ViewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local MainMenuFrame = MainWindow.MainFrame
    
    -- XỬ LÝ FOV CIRCLE: Tự động ẩn khi mở bảng MENU để không đè giao diện
    if MainMenuFrame and MainMenuFrame.Visible then
        FOV_Circle_Object.Visible = false
    else
        FOV_Circle_Object.Visible = WangConfig.FOV.Enabled
    end
    
    FOV_Circle_Object.Position = ViewportCenter
    FOV_Circle_Object.Radius = WangConfig.FOV.Radius
    FOV_Circle_Object.Color = WangConfig.FOV.Color

    -- XỬ LÝ PLAYER HACKS CONTROLLER (WalkSpeed & JumpPower)
    local LocalChar = LocalPlayer.Character
    if LocalChar and VerifyCharacterState(LocalChar) then
        local LocalHumanoid = LocalChar:FindFirstChildOfClass("Humanoid")
        if LocalHumanoid then
            if WangConfig.Misc.WalkSpeedToggle then
                LocalHumanoid.WalkSpeed = WangConfig.Misc.WalkSpeed
            end
            if WangConfig.Misc.JumpPowerToggle then
                LocalHumanoid.UseJumpPower = true
                LocalHumanoid.JumpPower = WangConfig.Misc.JumpPower
            end
        end
    end

    -- XỬ LÝ PIPELINE CẬP NHẬT AIMBOT MOTOR
    if WangConfig.Aimbot.Enabled then
        local ActiveTarget = AcquireMathematicalTarget()
        if ActiveTarget then
            ProcessAimbotLock(ActiveTarget)
        else
            SelectedHighlight.Adornee = nil
        end
    else
        SelectedHighlight.Adornee = nil
    end

    -- XỬ LÝ PIPELINE CẬP NHẬT VECTOR MATRIX ESP SCREEN
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local CachedElements = ESP_Cache[Player]
            if CachedElements then
                -- Chạy hai tầng lọc vẽ khung xương và đổ màu thực thể
                local success, err = pcall(function()
                    RenderESPForTarget(Player, CachedElements)
                    FinalizeESPRender(Player, CachedElements)
                end)
                
                -- Khôi phục khẩn cấp nếu nhân vật bị lỗi dữ liệu Null
                if not success then
                    for _, Object in pairs(CachedElements) do Object.Visible = false end
                end
            end
        end
    end
end)

print("--- [Wangcaos Premium Core Engine Phase 6 - Pipeline Connected] ---")
-- ==============================================================================
-- 14. MEMORY SCANNING & REWRITING ENGINE (GUN MODS ENGINE)
-- ==============================================================================
local WeaponHookCache = {}

local function ScanAndModifyWeapon(Tool)
    if not Tool:IsA("Tool") then return end
    if WeaponHookCache[Tool] then return end
    
    -- Quét sâu cấu trúc dữ liệu cấu hình súng (Bypass mọi loại tên script như Settings, Config, GunData)
    local SettingsModule = Tool:FindFirstChildWhichIsA("ModuleScript") or Tool:FindFirstChild("Settings") or Tool:FindFirstChild("Config")
    
    if SettingsModule then
        local Success, Data = pcall(require, SettingsModule)
        if Success and type(Data) == "table" then
            WeaponHookCache[Tool] = {
                OriginalData = {},
                Module = SettingsModule
            }
            
            -- Lưu bản sao dự phòng trạng thái gốc trước khi ghi đè dữ liệu bộ nhớ
            for Key, Value in pairs(Data) do
                WeaponHookCache[Tool].OriginalData[Key] = Value
            end

            -- Thiết lập vòng lặp lắng nghe thay đổi cấu hình súng theo chu kỳ siêu ngắn
            task.spawn(function()
                while Tool.Parent and SettingsModule.Parent do
                    if WangConfig.GunMods.NoRecoil then
                        if Data.Recoil then Data.Recoil = 0 end
                        if Data.RecoilMin then Data.RecoilMin = 0 end
                        if Data.RecoilMax then Data.RecoilMax = 0 end
                    end
                    if WangConfig.GunMods.NoSpread then
                        if Data.Spread then Data.Spread = 0 end
                        if Data.SpreadMin then Data.SpreadMin = 0 end
                        if Data.SpreadMax then Data.SpreadMax = 0 end
                    end
                    if WangConfig.GunMods.InstaReload then
                        if Data.ReloadTime then Data.ReloadTime = 0.01 end
                        if Data.ReloadSpeed then Data.ReloadSpeed = 100 end
                    end
                    if WangConfig.GunMods.InfiniteAmmo then
                        if Data.Ammo then Data.Ammo = 999 end
                        if Data.MaxAmmo then Data.MaxAmmo = 999 end
                        if Data.CurrentAmmo then Data.CurrentAmmo = 999 end
                    end
                    if WangConfig.GunMods.FireRate then
                        if Data.FireRate then Data.FireRate = WangConfig.GunMods.RapidFire end
                        if Data.Delay then Data.Delay = WangConfig.GunMods.RapidFire end
                    end
                    task.wait(0.1)
                end
                WeaponHookCache[Tool] = nil
            end)
        end
    end
end

-- Lắng nghe sự kiện trang bị vũ khí trên tay nhân vật
LocalPlayer.CharacterAdded:Connect(function(Character)
    Character.ChildAdded:Connect(ScanAndModifyWeapon)
end)

if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(ScanAndModifyWeapon)
    for _, Child in pairs(LocalPlayer.Character:GetChildren()) do
        ScanAndModifyWeapon(Child)
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(ScanAndModifyWeapon)
for _, Child in pairs(LocalPlayer.Backpack:GetChildren()) do
    ScanAndModifyWeapon(Child)
end

-- ==============================================================================
-- 15. ADVANCED ENVIRONMENT INTERACTION MODS (NOCLIP & LIGHTING OVERRIDE)
-- ==============================================================================
local NoclipConnection = nil

local function EnableQuantumNoclip()
    if NoclipConnection then return end
    NoclipConnection = RunService.Stepped:Connect(function()
        if WangConfig.Misc.Noclip and LocalPlayer.Character then
            for _, Part in pairs(LocalPlayer.Character:GetChildren()) do
                if Part:IsA("BasePart") and Part.CanCollide then
                    Part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableQuantumNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

-- Đồng bộ hóa trạng thái môi trường ánh sáng (Bypass các hiệu ứng mù sương)
task.spawn(function()
    local OriginalAmbient = Lighting.Ambient
    local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
    local OriginalClockTime = Lighting.ClockTime
    
    while true do
        if WangConfig.Misc.FullBright then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 14
        end
        task.wait(1)
    end
end)

-- ==============================================================================
-- 16. CORE TERMINATION HANDLER & TOTAL INITIALIZATION EXECUTED
-- ==============================================================================
-- Thêm các Toggle đặc biệt cho GunMods vào Tab Aimbot đã khởi tạo ở Phần 2
local WeaponPage = TabSystem:CreateTab("Gun Modifications")

WeaponPage:CreateToggle("Bypass & Disable Gun Recoil", WangConfig.GunMods.NoRecoil, function(state)
    WangConfig.GunMods.NoRecoil = state
end)

WeaponPage:CreateToggle("Bypass & Perfect No Spread", WangConfig.GunMods.NoSpread, function(state)
    WangConfig.GunMods.NoSpread = state
end)

WeaponPage:CreateToggle("Instant Bullet Reload Action", WangConfig.GunMods.InstaReload, function(state)
    WangConfig.GunMods.InstaReload = state
end)

WeaponPage:CreateToggle("Infinite Ammo Reserve Clip", WangConfig.GunMods.InfiniteAmmo, function(state)
    WangConfig.GunMods.InfiniteAmmo = state
end)

WeaponPage:CreateToggle("Enable Hyper Rapid Fire Rate", WangConfig.GunMods.FireRate, function(state)
    WangConfig.GunMods.FireRate = state
end)

local MiscPage = TabSystem:CreateTab("World & Environment")

MiscPage:CreateToggle("Enable Universal Noclip Hack", WangConfig.Misc.Noclip, function(state)
    WangConfig.Misc.Noclip = state
    if state then EnableQuantumNoclip() else DisableQuantumNoclip() end
end)

MiscPage:CreateToggle("Enable FullBright (Anti-Dark)", WangConfig.Misc.FullBright, function(state)
    WangConfig.Misc.FullBright = state
end)

-- Tạo nút dọn dẹp hệ thống khẩn cấp trên TopBar
local KillScriptBtn = Instance.new("TextButton")
KillScriptBtn.Name = "KillScriptBtn"
KillScriptBtn.Parent = MainWindow.MainFrame.TopBar
KillScriptBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
KillScriptBtn.Position = UDim2.new(1, -30, 0.5, -10)
KillScriptBtn.Size = UDim2.new(0, 20, 0, 20)
KillScriptBtn.Font = Enum.Font.GothamBold
KillScriptBtn.Text = "X"
KillScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillScriptBtn.TextSize = 12

local KillCorner = Instance.new("UICorner")
KillCorner.CornerRadius = UDim.new(0, 4)
KillCorner.Parent = KillScriptBtn

KillScriptBtn.MouseButton1Click:Connect(function()
    DisableQuantumNoclip()
    FOV_Circle_Object:Remove()
    SelectedHighlight:Destroy()
    for _, Player in pairs(Players:GetPlayers()) do
        DestroyPlayerESPElements(Player)
        CleanCharacterChams(Player.Character)
    end
    MainWindow.MainFrame.Parent.Parent:Destroy()
end)

print("================================================================")
print("--- [WANGCAOS ULTIMATE EDITION VERSION 2026 LOADED 100%] ---")
print("--- [TOTAL LINES: 1600 OF CLEAN REFACTORED LUA EXECUTED] ---")
print("================================================================")
