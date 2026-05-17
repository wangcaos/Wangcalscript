local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================================
-- SYSTEM CONFIGURATION (ENGLISH CENTRAL ENGINE)
-- ==========================================================
local Config = {
    Aimbot_Enabled = false,
    AimbotMode = "Everyone", -- "None", "Enemy", "Everyone", "Bot"
    FOV_Enabled = true,       
    FOV_Radius = 140,         
    ESP_Box_Enabled = false,   -- Toggle for Corner Box + Tracer + Health Line
    ESP_Chams_Enabled = false, -- Toggle for Information Head Tags
    SnapSpeed = 0.85,         
    SwitchDelay = 0.05,
    
    -- Chams Config Parameters
    FillTransparency = 0.8,
    DefaultColor = Color3.fromRGB(0, 255, 0),
    MaxDistance = 2000
}

local CurrentTarget = nil
local TargetStartTime = 0
local ESP_Lines_Data = {}

-- Visual Target Marker for Aimbot Target Focus
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "Wangcaos_TargetHighlight"
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.FillTransparency = 0.5
TargetHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineTransparency = 0
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.Adornee = nil

local ParentGui = game:GetService("CoreGui")
pcall(function() if gethui then ParentGui = gethui() end end)
TargetHighlight.Parent = ParentGui

if ParentGui:FindFirstChild("Wangcaos_SplitMenu") then
    ParentGui["Wangcaos_SplitMenu"]:Destroy()
end

-- ==========================================================
-- DRAG-DROP CONTROLLER FOR TITLEBAR ONLY
-- ==========================================================
local function MakeDraggable(dragHandle, targetObject)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==========================================================
-- CORE UTILITIES & TARGET CLOSEST-TO-CROSSHAIR FILTER
-- ==========================================================
local LogicEngine = {}

function LogicEngine.IsVisible(targetPart, targetChar)
    if not targetPart or not targetChar then return false end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar, Camera}
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

function LogicEngine.IsAlive(char)
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if not humanoid or not rootPart or not head then return false end
    if humanoid.Health <= 0 then return false end
    if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    
    return true
end

-- Target algorithm focusing target closest to crosshair center position
function LogicEngine.GetClosestTarget()
    if Config.AimbotMode == "None" then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local selectedTarget, closest = nil, Config.FOV_Radius

    if Config.AimbotMode == "Bot" then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and LogicEngine.IsAlive(obj) and not Players:GetPlayerFromCharacter(obj) then
                local head = obj.Head
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen and LogicEngine.IsVisible(head, obj) then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < closest then closest = dist selectedTarget = head end
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and LogicEngine.IsAlive(p.Character) then
                local isAllowed = (Config.AimbotMode == "Everyone") or (Config.AimbotMode == "Enemy" and p.Team ~= LocalPlayer.Team)
                if isAllowed then
                    local head = p.Character.Head
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and LogicEngine.IsVisible(head, p.Character) then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < closest then closest = dist selectedTarget = head end
                    end
                end
            end
        end
    end
    return selectedTarget
end

-- ==========================================================
-- BILLBOARD CHAMS TAG CONTEXT LOGIC
-- ==========================================================
local function GetPlayerColor(Player)
    if Player.Team then return Player.TeamColor.Color end
    if Player.TeamColor ~= BrickColor.new("White") and Player.TeamColor ~= BrickColor.new("Medium stone grey") then
        return Player.TeamColor.Color
    end
    return Config.DefaultColor
end

local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then return Tool.Name end
    return "None"
end

local function CleanUpChams(character)
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        if root and root:FindFirstChild("BéBoxFill") then root["BéBoxFill"]:Destroy() end
        if head and head:FindFirstChild("BéInfoTag") then head["BéInfoTag"]:Destroy() end
    end
end

local function ApplyChamsTag(Player)
    if Player == LocalPlayer then return end

    local function Setup(Character)
        Character:WaitForChild("HumanoidRootPart", 15)
        Character:WaitForChild("Head", 15)
        
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Head = Character:FindFirstChild("Head")
        if not Root or not Head then return end

        CleanUpChams(Character)

        local Box = Instance.new("BoxHandleAdornment")
        Box.Name = "BéBoxFill"
        Box.Parent = Root
        Box.Adornee = Root
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Size = Vector3.new(4, 6, 4)
        Box.Transparency = Config.FillTransparency
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
        Label.TextScaled = false
        Label.TextSize = 13
        Label.TextStrokeTransparency = 0
        Label.TextColor3 = Color3.new(1, 1, 1)
        Gui.Parent = Head

        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            if not Character.Parent or not Root.Parent or not Head.Parent then
                Connection:Disconnect()
                Gui:Destroy()
                return
            end

            local Hum = Character:FindFirstChild("Humanoid")
            if Config.ESP_Chams_Enabled and Hum and Hum.Health > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local color = GetPlayerColor(Player)
                local dist = math.floor((Root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                local teamName = Player.Team and Player.Team.Name or "No Team"
                local toolName = GetEquippedTool(Character)

                if dist <= Config.MaxDistance then
                    Box.Visible = true
                    Box.Color3 = color
                    Label.Visible = true
                    Label.TextColor3 = color
                    Label.Text = string.format("%s (%dm)\n(%s)(%s)", Player.Name, dist, teamName, toolName)
                    Gui.Enabled = true
                else
                    Box.Visible = false
                    Gui.Enabled = false
                end
            else
                Box.Visible = false
                Gui.Enabled = false
            end
        end)
    end

    Player.CharacterAdded:Connect(Setup)
    if Player.Character then task.spawn(Setup, Player.Character) end
end

-- ==========================================================
-- SOLID CIRLCE FOV & CORNER ESP OVERLAY ENGINE
-- ==========================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.9
FOVCircle.NumSides = 64

local function createESP(player)
    if player == LocalPlayer or ESP_Lines_Data[player] then return end
    
    -- 8 Lines for 4 Corners (TopLeft, TopRight, BottomLeft, BottomRight)
    local data = {
        TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"),
        TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
        BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"),
        BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line"),
        Health = Drawing.new("Line"),
        Tracer = Drawing.new("Line")
    }

    for _, line in pairs(data) do
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(0, 255, 150) -- Default clean sleek light-green/cyan color
        line.Transparency = 1
        line.Visible = false
    end
    data.Health.Thickness = 2 

    ESP_Lines_Data[player] = data
end

-- ==========================================================
-- CLASSIC UI FRAME BUILD (ENGLISH TRANSLATED)
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui", ParentGui)
ScreenGui.Name = "Wangcaos_SplitMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local MobileToggleBtn = Instance.new("TextButton", ScreenGui)
MobileToggleBtn.Size = UDim2.new(0, 45, 0, 45)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MobileToggleBtn.Text = "GH"
MobileToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
MobileToggleBtn.Font = Enum.Font.SourceSansBold
MobileToggleBtn.TextSize = 18
Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", MobileToggleBtn)
BtnStroke.Color = Color3.fromRGB(100, 255, 100)
BtnStroke.Thickness = 1.5
MakeDraggable(MobileToggleBtn, MobileToggleBtn)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 310, 0, 255)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -127)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
local FrameCorner = Instance.new("UICorner", MainFrame)
FrameCorner.CornerRadius = UDim.new(0, 6)
local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(45, 45, 45)
FrameStroke.Thickness = 1.5

MobileToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TitleBar.BorderSizePixel = 0
local BarCorner = Instance.new("UICorner", TitleBar)
BarCorner.CornerRadius = UDim.new(0, 6)

MakeDraggable(TitleBar, MainFrame)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Text = "  wangcaos script (Corner ESP & Circle FOV)"
TitleText.TextColor3 = Color3.fromRGB(235, 235, 235)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Size = UDim2.new(1, -35, 1, 0)
TitleText.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 13
CloseBtn.Size = UDim2.new(0, 22, 0, 20)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -10)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function() 
    TargetHighlight:Destroy()
    FOVCircle:Remove()
    for _, p in pairs(Players:GetPlayers()) do CleanUpChams(p.Character) end
    for _, data in pairs(ESP_Lines_Data) do
        for _, line in pairs(data) do line:Remove() end
    end
    ScreenGui:Destroy() 
end)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -24, 1, -42)
ContentFrame.Position = UDim2.new(0, 12, 0, 36)
ContentFrame.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, 7)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateMenuRow(labelText, layoutOrder)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder

    local box = Instance.new("TextButton", row)
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 2, 0.5, -9)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.BorderSizePixel = 0
    box.Text = ""
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 4)
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = Color3.fromRGB(60, 60, 60)
    boxStroke.Thickness = 1

    local label = Instance.new("TextLabel", row)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -35, 1, 0)
    label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1

    return box, label, boxStroke
end

-- ==========================================================
-- INTERACTION CONFIG BUTTON HOOKS
-- ==========================================================
local function ToggleVisual(btn, stroke, state)
    if state then
        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        stroke.Color = Color3.fromRGB(100, 255, 100)
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        stroke.Color = Color3.fromRGB(60, 60, 60)
    end
end

local AimBtn, AimLabel, AimStroke = CreateMenuRow("Aimbot Closest Crosshair", 1)
ToggleVisual(AimBtn, AimStroke, Config.Aimbot_Enabled)
AimBtn.MouseButton1Click:Connect(function()
    Config.Aimbot_Enabled = not Config.Aimbot_Enabled
    ToggleVisual(AimBtn, AimStroke, Config.Aimbot_Enabled)
end)

local FovBtn, FovLabel, FovStroke = CreateMenuRow("Display Circle FOV (White)", 2)
ToggleVisual(FovBtn, FovStroke, Config.FOV_Enabled)
FovBtn.MouseButton1Click:Connect(function()
    Config.FOV_Enabled = not Config.FOV_Enabled
    ToggleVisual(FovBtn, FovStroke, Config.FOV_Enabled)
end)

local EspBoxBtn, EspBoxLabel, EspBoxStroke = CreateMenuRow("Corner ESP Box + Health + Tracer", 3)
ToggleVisual(EspBoxBtn, EspBoxStroke, Config.ESP_Box_Enabled)
EspBoxBtn.MouseButton1Click:Connect(function()
    Config.ESP_Box_Enabled = not Config.ESP_Box_Enabled
    ToggleVisual(EspBoxBtn, EspBoxStroke, Config.ESP_Box_Enabled)
end)

local ChamsBtn, ChamsLabel, ChamsStroke = CreateMenuRow("Chams Text Tags Information", 4)
ToggleVisual(ChamsBtn, ChamsStroke, Config.ESP_Chams_Enabled)
ChamsBtn.MouseButton1Click:Connect(function()
    Config.ESP_Chams_Enabled = not Config.ESP_Chams_Enabled
    ToggleVisual(ChamsBtn, ChamsStroke, Config.ESP_Chams_Enabled)
    if not Config.ESP_Chams_Enabled then
        for _, p in pairs(Players:GetPlayers()) do CleanUpChams(p.Character) end
    end
end)

-- Target Mode Configuration Context Row
local DropRow = Instance.new("Frame", ContentFrame)
DropRow.Size = UDim2.new(1, 0, 0, 28)
DropRow.BackgroundTransparency = 1
DropRow.LayoutOrder = 5

local DropTitle = Instance.new("TextLabel", DropRow)
DropTitle.Text = "Target Mode:"
DropTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
DropTitle.Font = Enum.Font.SourceSansBold
DropTitle.TextSize = 14
DropTitle.TextXAlignment = Enum.TextXAlignment.Left
DropTitle.Size = UDim2.new(0, 95, 1, 0)
DropTitle.BackgroundTransparency = 1

local DropMainBtn = Instance.new("TextButton", DropRow)
DropMainBtn.Size = UDim2.new(0, 125, 0, 22)
DropMainBtn.Position = UDim2.new(0, 100, 0.5, -11)
DropMainBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
DropMainBtn.Text = Config.AimbotMode .. "  ▼"
DropMainBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
DropMainBtn.Font = Enum.Font.SourceSansBold
DropMainBtn.TextSize = 13
Instance.new("UICorner", DropMainBtn).CornerRadius = UDim.new(0, 4)
local DropStroke = Instance.new("UIStroke", DropMainBtn)
DropStroke.Color = Color3.fromRGB(50, 50, 50)

local DropContainer = Instance.new("Frame", ScreenGui)
DropContainer.Size = UDim2.new(0, 125, 0, 90)
DropContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropContainer.Visible = false
DropContainer.ZIndex = 15
Instance.new("UICorner", DropContainer).CornerRadius = UDim.new(0, 4)
local DropContainerStroke = Instance.new("UIStroke", DropContainer)
DropContainerStroke.Color = Color3.fromRGB(50, 50, 50)
local DropLayout = Instance.new("UIListLayout", DropContainer)

DropMainBtn.MouseButton1Click:Connect(function()
    DropContainer.Position = UDim2.new(0, DropMainBtn.AbsolutePosition.X, 0, DropMainBtn.AbsolutePosition.Y + DropMainBtn.AbsoluteSize.Y + 4)
    DropContainer.Visible = not DropContainer.Visible
end)

local function BuildOption(modeName)
    local opt = Instance.new("TextButton", DropContainer)
    opt.Size = UDim2.new(1, 0, 0, 22)
    opt.BackgroundTransparency = 1
    opt.Text = "  " .. modeName
    opt.TextColor3 = Color3.fromRGB(220, 220, 220)
    opt.Font = Enum.Font.SourceSans
    opt.TextSize = 13
    opt.TextXAlignment = Enum.TextXAlignment.Left
    opt.ZIndex = 16
    opt.MouseButton1Click:Connect(function()
        Config.AimbotMode = modeName
        DropMainBtn.Text = modeName .. "  ▼"
        DropContainer.Visible = false
    end)
end
BuildOption("None") BuildOption("Enemy") BuildOption("Everyone") BuildOption("Bot")

-- Left Bracket Toggle Configuration Setup
UserInputService.InputBegan:Connect(function(i, p)
    if not p and i.KeyCode == Enum.KeyCode.LeftBracket then
        Config.ESP_Box_Enabled = not Config.ESP_Box_Enabled
        ToggleVisual(EspBoxBtn, EspBoxStroke, Config.ESP_Box_Enabled)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESP_Lines_Data[player] then
        for _, line in pairs(ESP_Lines_Data[player]) do line:Remove() end
        ESP_Lines_Data[player] = nil
    end
    CleanUpChams(player.Character)
end)

Players.PlayerAdded:Connect(function(p)
    createESP(p)
    ApplyChamsTag(p)
end)

-- ==========================================================
-- STEPPED RENDER PIPELINE CORE LAYER VÒNG LẶP LIÊN TỤC
-- ==========================================================
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Setup Clean Solid Circle Framework
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV_Radius
    FOVCircle.Visible = Config.FOV_Enabled 

    -- Closest-to-Crosshair Aimbot Thread Logic Execution
    if Config.Aimbot_Enabled then
        if CurrentTarget and (not CurrentTarget.Parent or not LogicEngine.IsAlive(CurrentTarget.Parent)) then
            CurrentTarget = nil
            TargetHighlight.Adornee = nil
        end

        local targetHead = LogicEngine.GetClosestTarget()
        if targetHead then
            if CurrentTarget == nil or (targetHead ~= CurrentTarget and os.clock() - TargetStartTime >= Config.SwitchDelay) then
                if targetHead ~= CurrentTarget then TargetStartTime = os.clock() end
                CurrentTarget = targetHead
            end
        else
            CurrentTarget = nil
        end

        if CurrentTarget and CurrentTarget.Parent and LogicEngine.IsAlive(CurrentTarget.Parent) then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, CurrentTarget.Position), Config.SnapSpeed)
            TargetHighlight.Adornee = CurrentTarget.Parent
        else
            TargetHighlight.Adornee = nil
        end
    else
        TargetHighlight.Adornee = nil
    end

    -- Combined Layout Traditional Box Drawing Loop Execution Engine
    for _, player in pairs(Players:GetPlayers()) do
        local data = ESP_Lines_Data[player]
        if not data then if player ~= LocalPlayer then createESP(player) end continue end

        local char = player.Character
        if Config.ESP_Box_Enabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local root = char.HumanoidRootPart
            local hum = char.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local head = char:FindFirstChild("Head")
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local h = math.abs(headPos.Y - legPos.Y)
                local w = h / 2
                local x, y = pos.X - w/2, pos.Y - h/2
                
                -- Dynamic Corner Length calculation based on size
                local lineLength = w / 3

                -- Top-Left Corner Lines
                data.TL1.From = Vector2.new(x, y)
                data.TL1.To = Vector2.new(x + lineLength, y)
                data.TL2.From = Vector2.new(x, y)
                data.TL2.To = Vector2.new(x, y + lineLength)

                -- Top-Right Corner Lines
                data.TR1.From = Vector2.new(x + w, y)
                data.TR1.To = Vector2.new(x + w - lineLength, y)
                data.TR2.From = Vector2.new(x + w, y)
                data.TR2.To = Vector2.new(x + w, y + lineLength)

                -- Bottom-Left Corner Lines
                data.BL1.From = Vector2.new(x, y + h)
                data.BL1.To = Vector2.new(x + lineLength, y + h)
                data.BL2.From = Vector2.new(x, y + h)
                data.BL2.To = Vector2.new(x, y + h - lineLength)

                -- Bottom-Right Corner Lines
                data.BR1.From = Vector2.new(x + w, y + h)
                data.BR1.To = Vector2.new(x + w - lineLength, y + h)
                data.BR2.From = Vector2.new(x + w, y + h)
                data.BR2.To = Vector2.new(x + w, y + h - lineLength)

                -- Dynamic Red Health Line Placement SÁT CẠNH TRÁI CORNER
                local healthX = x - 3 
                data.Health.From = Vector2.new(healthX, y + h)
                data.Health.To = Vector2.new(healthX, y + h - (h * (hum.Health / hum.MaxHealth)))
                data.Health.Color = Color3.fromRGB(255, 0, 0) 

                -- Snap Tracer Alignment to Center Bottom Screen Line
                data.Tracer.From = Vector2.new(x + w/2, y + h)
                data.Tracer.To = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                data.Tracer.Color = Color3.fromRGB(255, 0, 0) -- Tracer color back to requested red

                for _, line in pairs(data) do line.Visible = true end
            else
                for _, line in pairs(data) do line.Visible = false end
            end
        else
            for _, line in pairs(data) do line.Visible = false end
        end
    end
end)

-- Fire Initialization Hooks for Current Session Elements
for _, v in pairs(Players:GetPlayers()) do 
    createESP(v) 
    ApplyChamsTag(v)
end

print("--- [Wangcaos Unified Version V18 - Modern Corner ESP & Circle FOV Loaded] ---")
