-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V6.9.4 - VERTICAL MODERN EDITION
-- ALL RIGHTS RESERVED BY DAI CA WANG (2026)
-- UI Design: Left Vertical Sidebar, Minimalism, Dark Theme, Pill Toggles
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local MasterLoop

-- Modern Theme Colors (Dark/Minimalism)
local Style_Bg = Color3.fromRGB(15, 16, 17)
local Style_SubBg = Color3.fromRGB(22, 24, 27)
local Style_Accent = Color3.fromRGB(210, 80, 50) -- Warm reddish-orange
local Style_Inactive = Color3.fromRGB(40, 42, 45)
local Style_Text_Primary = Color3.fromRGB(255, 255, 255)
local Style_Text_Secondary = Color3.fromRGB(150, 150, 150)
local Style_CornerRadius = UDim.new(0, 5)
local Style_Font = Enum.Font.Gotham
local Style_Padding = UDim.new(0, 10)
local Style_ElementHeight = 32

local Config = {
    MenuVisible = true, MenuKeybind = Enum.KeyCode.RightShift,
    Aimbot = false, AimbotKeybind = Enum.KeyCode.E, TeamCheck = true, WallCheck = true, Smoothness = 5, TargetPart = "Head",
    Aura = false, AuraKeybind = Enum.KeyCode.H, TeamCheckAura = true, AuraWallCheck = true, AuraSmoothness = 5, AuraRadius = 30, AuraColor = Color3.fromRGB(0, 170, 255), AuraTransparency = 50, PriorityLowestHealth = false,
    Triggerbot = false, TriggerbotKeybind = Enum.KeyCode.T, TriggerWallCheck = true,
    Spinbot = false, SpinbotKeybind = Enum.KeyCode.K, SpinSpeed = 25,
    AutoFarmPlayer = false, AutoFarmDelay = 0.05,
    BowDown = false, BowAngle = 45, ThirdPerson = false, ThirdPersonDist = 15, AntiAFK = false,
    EspMaster = false, EspMasterKeybind = Enum.KeyCode.O, EspTeamCheck = false, FovCircle = false, FovRadius = 120, FovThickness = 1.5, FovSides = 64, FovColor = Color3.fromRGB(255, 255, 255), FovTransparency = 0.8, FovFilled = false,
    CrosshairDot = false, EspBox = false, EspTracer = false, TracerMode = "Bottom", EspColor = Color3.fromRGB(255, 50, 50),
    EspName = false, EspHealth = false, EspTransparency = 80, MaxDistance = 5000,
    SpeedToggle = false, SpeedKeybind = Enum.KeyCode.Q, WalkSpeed = 16, JumpToggle = false, JumpKeybind = Enum.KeyCode.G, JumpPower = 50,
    Fly = false, FlyKeybind = Enum.KeyCode.F, FlySpeed = 50, FullBright = false,
    ShowMobileAim = false, ShowMobileTrig = false, ShowMobileSpeed = false, ShowMobileFarm = false, ShowMobileAura = false, ShowMobileTP = false, ShowMobileFly = false, LockMobileButtons = false,
    CustomBackground = true, BackgroundAssetId = "rbxassetid://118670919014080", StoredAmbient = Lighting.Ambient, StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

local CurrentSpinAngle = 0
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local LastFarmTime = 0
local CurrentFarmIndex = 1

local UI_Refresh_Functions = {}
local GlobalMobileButtons = {}
local GlobalSyncToggles = {}

local flyBodyGyro
local flyBodyVelocity

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
    if old.Name == "Wangcaos_Premium_Figma_UI" or old.Name == "WangcaosIntro" then old:Destroy() end
end

local IntroScreen = Instance.new("ScreenGui")
IntroScreen.Name = "WangcaosIntro"
IntroScreen.Parent = SafeParent
IntroScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local IntroFrame = Instance.new("Frame", IntroScreen)
IntroFrame.BackgroundColor3 = Style_Bg
IntroFrame.BackgroundTransparency = 0.05
IntroFrame.BorderSizePixel = 0
IntroFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
IntroFrame.Size = UDim2.new(0, 350, 0, 150)
Instance.new("UICorner", IntroFrame).CornerRadius = Style_CornerRadius
local IntroStroke = Instance.new("UIStroke", IntroFrame)
IntroStroke.Color = Style_Accent
IntroStroke.Thickness = 1.5

local IntroTitle = Instance.new("TextLabel", IntroFrame)
IntroTitle.BackgroundTransparency = 1
IntroTitle.Size = UDim2.new(1, 0, 0, 40)
IntroTitle.Position = UDim2.new(0, 0, 0, 15)
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.Text = "WANGCAOS PREMIUM V6.9.4"
IntroTitle.TextColor3 = Style_Text_Primary
IntroTitle.TextSize = 18

local IntroDisc = Instance.new("TextLabel", IntroFrame)
IntroDisc.BackgroundTransparency = 1
IntroDisc.Size = UDim2.new(1, 0, 0, 20)
IntroDisc.Position = UDim2.new(0, 0, 0, 50)
IntroDisc.Font = Enum.Font.GothamBold
IntroDisc.Text = "Discord: Https://discord.gg/GkAKn4zzH"
IntroDisc.TextColor3 = Style_Accent
IntroDisc.TextSize = 12

local IntroSub = Instance.new("TextLabel", IntroFrame)
IntroSub.BackgroundTransparency = 1
IntroSub.Size = UDim2.new(1, 0, 0, 20)
IntroSub.Position = UDim2.new(0, 0, 0, 85)
IntroSub.Font = Style_Font
IntroSub.Text = "Initializing..."
IntroSub.TextColor3 = Style_Text_Secondary
IntroSub.TextSize = 12

local LoadingBg = Instance.new("Frame", IntroFrame)
LoadingBg.Position = UDim2.new(0, 25, 1, -25)
LoadingBg.Size = UDim2.new(1, -50, 0, 4)
LoadingBg.BackgroundColor3 = Style_Inactive
Instance.new("UICorner", LoadingBg).CornerRadius = UDim.new(1, 0)

local LoadingFill = Instance.new("Frame", LoadingBg)
LoadingFill.Size = UDim2.new(0, 0, 1, 0)
LoadingFill.BackgroundColor3 = Style_Accent
Instance.new("UICorner", LoadingFill).CornerRadius = UDim.new(1, 0)

pcall(function()
    if setclipboard then setclipboard("Https://discord.gg/GkAKn4zzH")
    elseif toclipboard then toclipboard("Https://discord.gg/GkAKn4zzH") end
end)

task.spawn(function()
    IntroSub.Text = "Loading Core Modules..."
    TweenService:Create(LoadingFill, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {Size = UDim2.new(0.35, 0, 1, 0)}):Play()
    task.wait(0.4)
    IntroSub.Text = "Bypassing Security Protocols..."
    TweenService:Create(LoadingFill, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = UDim2.new(0.75, 0, 1, 0)}):Play()
    task.wait(0.5)
    IntroSub.Text = "Injecting Interface..."
    TweenService:Create(LoadingFill, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(0.3)
    IntroSub.Text = "Framework successfully loaded!"
    task.wait(0.5)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(IntroFrame, tweenInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(IntroTitle, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroDisc, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroSub, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroStroke, tweenInfo, {Transparency = 1}):Play()
    TweenService:Create(LoadingBg, tweenInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadingFill, tweenInfo, {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    if IntroScreen then IntroScreen:Destroy() end
end)

local function ExportSettings()
    local exportTable = {}
    for k, v in pairs(Config) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then exportTable[k] = v
        elseif typeof(v) == "EnumItem" then exportTable[k] = {__type = "EnumItem", EnumType = tostring(v.EnumType), Name = v.Name}
        elseif typeof(v) == "Color3" then exportTable[k] = {__type = "Color3", R = v.R, G = v.G, B = v.B} end
    end
    local success, json = pcall(function() return HttpService:JSONEncode(exportTable) end)
    if not success then return "" end
    local hex = ""
    for i = 1, #json do hex = hex .. string.format("%02X", string.byte(json, i)) end
    return hex
end

local function ImportSettings(hexStr)
    local success, err = pcall(function()
        local json = ""
        for i = 1, #hexStr, 2 do
            local hexByte = string.sub(hexStr, i, i+1)
            if not hexByte or #hexByte < 2 then break end
            json = json .. string.char(tonumber(hexByte, 16))
        end
        local importTable = HttpService:JSONDecode(json)
        for k, v in pairs(importTable) do
            if type(v) == "table" and v.__type then
                if v.__type == "EnumItem" then
                    local enumType = string.split(v.EnumType, ".")[3] or v.EnumType
                    pcall(function() Config[k] = Enum[enumType][v.Name] end)
                elseif v.__type == "Color3" then Config[k] = Color3.new(v.R, v.G, v.B) end
            else Config[k] = v end
        end
        for _, refresh in pairs(UI_Refresh_Functions) do pcall(refresh) end
        for key, mData in pairs(GlobalMobileButtons) do
            local xs, xo, ys, yo = Config["MobilePos_"..key.."_XS"], Config["MobilePos_"..key.."_XO"], Config["MobilePos_"..key.."_YS"], Config["MobilePos_"..key.."_YO"]
            if xs and xo and ys and yo and mData.Btn then pcall(function() mData.Btn.Position = UDim2.new(xs, xo, ys, yo) end) end
        end
    end)
    return success
end
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

local AuraVisual = Instance.new("CylinderHandleAdornment")
AuraVisual.Name = "WangAuraCircle"
AuraVisual.AlwaysOnTop = false
AuraVisual.ZIndex = 5

local Tracer_Cache = {}
local Character_Cache = {}
local NeckCache = {}

local function CreateTracerObject(Player)
    if Tracer_Cache[Player] then return end
    local Line = Drawing.new("Line")
    Line.Thickness = 1.2
    Line.Color = Config.EspColor
    Line.Transparency = 1
    Line.Visible = false
    Tracer_Cache[Player] = Line
end

local function ClearTracerObject(Player)
    if Tracer_Cache[Player] then pcall(function() Tracer_Cache[Player].Visible = false Tracer_Cache[Player]:Remove() end) Tracer_Cache[Player] = nil end
end

local function CleanCharacterVisuals(Character)
    if not Character then return end
    if Character_Cache[Character] then
        pcall(function() Character_Cache[Character].Box.Visible = false Character_Cache[Character].Box:Remove() end)
        pcall(function() Character_Cache[Character].Gui:Destroy() end)
        Character_Cache[Character] = nil
    end
    local OldTag = Character:FindFirstChild("WangInfoTag", true)
    if OldTag then OldTag:Destroy() end
    local OldBox = Character:FindFirstChild("WangBoxFill", true)
    if OldBox then OldBox:Destroy() end
end

local function IsAlive(Character)
    if not Character or not Character.Parent then return false end
    local Hum = Character:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    return true
end

local function IsTeammate(Player)
    if Player == LocalPlayer then return true end
    if Player.Team and LocalPlayer.Team and Player.Team == LocalPlayer.Team then return true end
    if Player.TeamColor and LocalPlayer.TeamColor then
        if Player.TeamColor == LocalPlayer.TeamColor and Player.TeamColor.Name ~= "White" and Player.TeamColor.Name ~= "Medium stone grey" then return true end
    end
    local teamKeywords = {"Team", "Faction", "Gang", "Role", "Group", "Side"}
    for _, attr in pairs(teamKeywords) do
        local myAttr = LocalPlayer:GetAttribute(attr)
        local targetAttr = Player:GetAttribute(attr)
        if myAttr and targetAttr and myAttr == targetAttr then return true end
        if LocalPlayer.Character and Player.Character then
            local myCharAttr = LocalPlayer.Character:GetAttribute(attr)
            local targetCharAttr = Player.Character:GetAttribute(attr)
            if myCharAttr and targetCharAttr and myCharAttr == targetCharAttr then return true end
        end
    end
    local function CheckHiddenValues(parent1, parent2)
        if not parent1 or not parent2 then return false end
        for _, val in pairs(parent1:GetChildren()) do
            if val:IsA("StringValue") or val:IsA("IntValue") or val:IsA("ObjectValue") then
                for _, key in pairs(teamKeywords) do
                    if string.find(string.lower(val.Name), string.lower(key)) then
                        local targetVal = parent2:FindFirstChild(val.Name)
                        if targetVal and val.Value == targetVal.Value and val.Value ~= "" and val.Value ~= 0 then return true end
                    end
                end
            end
        end
        return false
    end
    if CheckHiddenValues(LocalPlayer, Player) then return true end
    if CheckHiddenValues(LocalPlayer.Character, Player.Character) then return true end
    return false
end

local function CheckWallOcclusion(TargetPart, Character)
    if not Config.WallCheck and not Config.AuraWallCheck then return true end
    local Origin = Camera.CFrame.Position
    local Direction = TargetPart.Position - Origin
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Character, Camera}
    return workspace:Raycast(Origin, Direction, Params) == nil
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

local function GetDesiredHitbox(Character)
    if Config.TargetPart == "Head" then return Character:FindFirstChild("Head")
    elseif Config.TargetPart == "Torso" then return Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
    elseif Config.TargetPart == "Legs" then return Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightLowerLeg") or Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftLowerLeg") or Character:FindFirstChild("HumanoidRootPart") end
    return Character:FindFirstChild("Head")
end

local function ToggleFlyState(state)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local hum = character:FindFirstChildOfClass("Humanoid")
    if state then
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = root.CFrame
        flyBodyGyro.Parent = root
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = root
        if hum then hum.PlatformStand = true end
    else
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if hum then hum.PlatformStand = false end
    end
end
local function GetClosestPlayerToCrosshair()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ClosestTarget = nil
    local MaxDist = Config.FovRadius
    local LowestHealth = math.huge
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and IsAlive(Player.Character) then
            if Config.TeamCheck and IsTeammate(Player) then continue end
            local TargetPartInstance = GetDesiredHitbox(Player.Character)
            local Hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if TargetPartInstance and Hum then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPartInstance.Position)
                if OnScreen and CheckWallOcclusion(TargetPartInstance, Player.Character) then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Center).Magnitude
                    if Dist < Config.FovRadius then
                        if Config.PriorityLowestHealth then
                            if Hum.Health < LowestHealth then LowestHealth = Hum.Health ClosestTarget = TargetPartInstance end
                        else
                            if Dist < MaxDist then MaxDist = Dist ClosestTarget = TargetPartInstance end
                        end
                    end
                end
            end
        end
    end
    return ClosestTarget
end

local function GetAuraTarget()
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    local BestTarget = nil
    local LowestHealth = math.huge
    local ClosestDist = Config.AuraRadius
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and IsAlive(Player.Character) then
            if Config.TeamCheckAura and IsTeammate(Player) then continue end
            local TargetPartInstance = GetDesiredHitbox(Player.Character)
            local EnemyRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            local Hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if TargetPartInstance and EnemyRoot and Hum then
                if Config.AuraWallCheck and not CheckWallOcclusion(TargetPartInstance, Player.Character) then continue end
                local MyPosFlat = Vector3.new(MyRoot.Position.X, 0, MyRoot.Position.Z)
                local EnemyPosFlat = Vector3.new(EnemyRoot.Position.X, 0, EnemyRoot.Position.Z)
                local DistFlat = (EnemyPosFlat - MyPosFlat).Magnitude
                if DistFlat <= Config.AuraRadius then
                    if Config.PriorityLowestHealth then
                        if Hum.Health < LowestHealth then LowestHealth = Hum.Health BestTarget = TargetPartInstance end
                    else
                        if DistFlat < ClosestDist then ClosestDist = DistFlat BestTarget = TargetPartInstance end
                    end
                end
            end
        end
    end
    return BestTarget
end

local function GetPlayerColor(Player)
    if Config.EspTeamCheck and IsTeammate(Player) then return Color3.fromRGB(0, 255, 0) end
    return Config.EspColor
end

local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or "None"
end

local function PerformTriggerbotClick()
    local TargetInstance = Mouse.Target
    if TargetInstance and TargetInstance.Parent then
        local Char = TargetInstance.Parent
        if Char:IsA("Accessory") then Char = Char.Parent end
        local Plr = Players:GetPlayerFromCharacter(Char)
        if Plr and Plr ~= LocalPlayer and IsAlive(Char) then
            if Config.TeamCheck and IsTeammate(Plr) then return end
            local TargetPart = GetDesiredHitbox(Char)
            if TargetPart and CheckTriggerWall(TargetPart.Position) then pcall(function() mouse1click() end) end
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
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            if Config.TeamCheck and IsTeammate(p) then continue end
            local TRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local THead = p.Character:FindFirstChild("Head")
            if TRoot and THead then table.insert(Targets, {Root = TRoot, Head = THead}) end
        end
    end
    if #Targets == 0 then if IsFiring then IsFiring = false pcall(function() mouse1release() end) end return end
    if CurrentFarmIndex > #Targets then CurrentFarmIndex = 1 end
    local ActiveTargetData = Targets[CurrentFarmIndex]
    local EnemyRoot = ActiveTargetData.Root
    local EnemyHead = ActiveTargetData.Head
    if EnemyRoot and EnemyHead then
        local BehindPosition = EnemyRoot.Position - (EnemyRoot.CFrame.LookVector * 3)
        MyRoot.CFrame = CFrame.new(BehindPosition, EnemyRoot.Position)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, EnemyHead.Position)
        if not IsFiring then IsFiring = true pcall(function() mouse1press() end) end
        if tick() - LastFarmTime >= Config.AutoFarmDelay then LastFarmTime = tick() CurrentFarmIndex = CurrentFarmIndex + 1 end
    end
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Premium_Figma_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

local function MakeDraggable(UIElement, DragHandle, PosKey)
    local dragging = false
    local dragInput, mousePos, framePos
    DragHandle.InputBegan:Connect(function(input)
        if Config.LockMobileButtons and PosKey then return end 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = UIElement.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    if PosKey then
                        Config["MobilePos_"..PosKey.."_XS"] = UIElement.Position.X.Scale
                        Config["MobilePos_"..PosKey.."_XO"] = UIElement.Position.X.Offset
                        Config["MobilePos_"..PosKey.."_YS"] = UIElement.Position.Y.Scale
                        Config["MobilePos_"..PosKey.."_YO"] = UIElement.Position.Y.Offset
                    end
                end
            end)
        end
    end)
    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
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
    TextButton.MouseButton1Click:Connect(function() if not HoldingTouch then Callback() end end)
    TextButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then HoldingTouch = true end end)
    TextButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then if HoldingTouch then HoldingTouch = false Callback() end end end)
end

local function CreateIndependentMobileButton(Name, TextOn, TextOff, Key, ShowKey, DefaultColor, InitPos)
    local xs = Config["MobilePos_"..Key.."_XS"] or InitPos.X.Scale
    local xo = Config["MobilePos_"..Key.."_XO"] or InitPos.X.Offset
    local ys = Config["MobilePos_"..Key.."_YS"] or InitPos.Y.Scale
    local yo = Config["MobilePos_"..Key.."_YO"] or InitPos.Y.Offset
    if not Config["MobilePos_"..Key.."_XS"] then 
        Config["MobilePos_"..Key.."_XS"] = xs; Config["MobilePos_"..Key.."_XO"] = xo; Config["MobilePos_"..Key.."_YS"] = ys; Config["MobilePos_"..Key.."_YO"] = yo 
    end
    local ShortcutBtn = Instance.new("TextButton")
    ShortcutBtn.Name = "IndependentMobile_" .. Key
    ShortcutBtn.Parent = ScreenGui
    ShortcutBtn.BackgroundColor3 = DefaultColor
    ShortcutBtn.BackgroundTransparency = 0.2
    ShortcutBtn.Position = UDim2.new(xs, xo, ys, yo)
    ShortcutBtn.Size = UDim2.new(0, 52, 0, 52)
    ShortcutBtn.Font = Enum.Font.GothamBold
    ShortcutBtn.Text = TextOff
    ShortcutBtn.TextColor3 = Style_Text_Primary
    ShortcutBtn.TextSize = 9
    ShortcutBtn.Visible = (Config[ShowKey] and IsMobile)
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn)
    Stroke.Color = Style_Text_Primary
    Stroke.Thickness = 1
    MakeDraggable(ShortcutBtn, ShortcutBtn, Key)
    GlobalMobileButtons[Key] = { Btn = ShortcutBtn, ShowKey = ShowKey }
    return ShortcutBtn
end

local MobAim = CreateIndependentMobileButton("Aimbot", "AIM\nON", "AIM\nOFF", "Aimbot", "ShowMobileAim", Color3.fromRGB(255, 50, 50), UDim2.new(0.85, 0, 0.15, 0))
local MobTrig = CreateIndependentMobileButton("Triggerbot", "TRIG\nON", "TRIG\nOFF", "Triggerbot", "ShowMobileTrig", Color3.fromRGB(230, 125, 30), UDim2.new(0.85, 0, 0.26, 0))
local MobSpeed = CreateIndependentMobileButton("Speed", "SPD\nON", "SPD\nOFF", "SpeedToggle", "ShowMobileSpeed", Color3.fromRGB(140, 30, 230), UDim2.new(0.85, 0, 0.37, 0))
local MobFarm = CreateIndependentMobileButton("AutoFarm", "FRM\nON", "FRM\nOFF", "AutoFarmPlayer", "ShowMobileFarm", Color3.fromRGB(45, 140, 75), UDim2.new(0.85, 0, 0.48, 0))
local MobAura = CreateIndependentMobileButton("Aura", "AUR\nON", "AUR\nOFF", "Aura", "ShowMobileAura", Color3.fromRGB(0, 150, 255), UDim2.new(0.85, 0, 0.59, 0))
local MobTP = CreateIndependentMobileButton("ThirdPerson", "3RD\nON", "3RD\nOFF", "ThirdPerson", "ShowMobileTP", Style_Text_Secondary, UDim2.new(0.85, 0, 0.70, 0))
local MobFly = CreateIndependentMobileButton("Fly", "FLY\nON", "FLY\nOFF", "Fly", "ShowMobileFly", Color3.fromRGB(0, 255, 255), UDim2.new(0.85, 0, 0.81, 0))

local lxs, lxo, lys, lyo = 0, 20, 0, 20
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "PremiumToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Style_SubBg
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Position = UDim2.new(lxs, lxo, lys, lyo)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Style_Text_Primary
ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = Style_CornerRadius
local TogStroke = Instance.new("UIStroke", ToggleButton)
TogStroke.Color = Color3.fromRGB(60, 60, 60)
TogStroke.Thickness = 1
ToggleButton.Visible = IsMobile
GlobalMobileButtons["MainLogo"] = { Btn = ToggleButton }
MakeDraggable(ToggleButton, ToggleButton, "MainLogo")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Style_Bg
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.Size = UDim2.new(0, 550, 0, 350) 
MainFrame.ClipsDescendants = true
MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = Style_CornerRadius
local MFrameStroke = Instance.new("UIStroke", MainFrame)
MFrameStroke.Color = Color3.fromRGB(45, 47, 50)
MFrameStroke.Thickness = 1

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
Instance.new("UICorner", CustomBackgroundImage).CornerRadius = Style_CornerRadius
local SidebarFrame = Instance.new("Frame")
SidebarFrame.Name = "SidebarFrame"
SidebarFrame.Parent = MainFrame
SidebarFrame.BackgroundColor3 = Style_SubBg
SidebarFrame.Position = UDim2.new(0, 0, 0, 0)
SidebarFrame.Size = UDim2.new(0, 130, 1, 0)
SidebarFrame.ZIndex = 2

local SidebarStroke = Instance.new("UIStroke", SidebarFrame)
SidebarStroke.Color = Color3.fromRGB(35, 37, 40)
SidebarStroke.Thickness = 1

local BrandLabel = Instance.new("TextLabel", SidebarFrame)
BrandLabel.BackgroundTransparency = 1
BrandLabel.Size = UDim2.new(1, 0, 0, 40)
BrandLabel.Position = UDim2.new(0, 0, 0, 10)
BrandLabel.Font = Enum.Font.GothamBold
BrandLabel.Text = "WANGCAOS v6.9"
BrandLabel.TextColor3 = Style_Accent
BrandLabel.TextSize = 14
BrandLabel.ZIndex = 3

local TabButtonsContainer = Instance.new("Frame", SidebarFrame)
TabButtonsContainer.BackgroundTransparency = 1
TabButtonsContainer.Position = UDim2.new(0, 5, 0, 55)
TabButtonsContainer.Size = UDim2.new(1, -10, 1, -95)
local SidebarLayout = Instance.new("UIListLayout", TabButtonsContainer)
SidebarLayout.FillDirection = Enum.FillDirection.Vertical
SidebarLayout.Padding = UDim.new(0, 5)

local DragHandleZone = Instance.new("Frame", MainFrame)
DragHandleZone.Name = "DragHandleZone"
DragHandleZone.BackgroundTransparency = 1
DragHandleZone.Position = UDim2.new(0, 0, 0, 0)
DragHandleZone.Size = UDim2.new(1, 0, 0, 40)
DragHandleZone.ZIndex = 1
MakeDraggable(MainFrame, DragHandleZone, nil)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Style_Text_Secondary
CloseBtn.TextSize = 22
CloseBtn.ZIndex = 4
RegisterTouchFriendlyClick(CloseBtn, function() Config.MenuVisible = false MainFrame.Visible = false end)
RegisterTouchFriendlyClick(ToggleButton, function() Config.MenuVisible = not Config.MenuVisible MainFrame.Visible = Config.MenuVisible end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 140, 0, 40)
ContentContainer.Size = UDim2.new(1, -150, 1, -50)
ContentContainer.ZIndex = 2

local CombatPage = Instance.new("ScrollingFrame", ContentContainer)
local PlayerPage = Instance.new("ScrollingFrame", ContentContainer)
local MovementPage = Instance.new("ScrollingFrame", ContentContainer)
local VisualPage = Instance.new("ScrollingFrame", ContentContainer)
local MiscPage = Instance.new("ScrollingFrame", ContentContainer)
local CreditsPage = Instance.new("ScrollingFrame", ContentContainer)

local AllPages = {
    Combat = CombatPage,
    Player = PlayerPage,
    Movement = MovementPage,
    Visual = VisualPage,
    Misc = MiscPage,
    Credits = CreditsPage
}

for name, page in pairs(AllPages) do
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 1
    page.ScrollBarImageColor3 = Style_Inactive
    page.Visible = false
    local listLayout = Instance.new("UIListLayout", page)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local pagePadding = Instance.new("UIPadding", page)
    pagePadding.PaddingLeft = UDim.new(0, 5)
    pagePadding.PaddingRight = UDim.new(0, 5)
    pagePadding.PaddingBottom = UDim.new(0, 15)
end
CombatPage.Visible = true

local function CreateSectionTitle(Page, Text)
    local Title = Instance.new("TextLabel", Page)
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.Font = Enum.Font.GothamBold
    Title.Text = Text
    Title.TextColor3 = Style_Accent
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    return Title
end

local CurrentActiveTabButton = nil
local function CreateTabButton(Name, PageInstance)
    local Btn = Instance.new("TextButton", TabButtonsContainer)
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Style_Bg
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = Name
    Btn.TextColor3 = Style_Text_Secondary
    Btn.TextSize = 12
    Instance.new("UICorner", Btn).CornerRadius = Style_CornerRadius
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = Color3.fromRGB(35, 37, 40)
    Stroke.Thickness = 1

    if CurrentActiveTabButton == nil then
        CurrentActiveTabButton = Btn
        Btn.BackgroundColor3 = Style_Inactive
        Btn.TextColor3 = Style_Text_Primary
        Stroke.Color = Style_Accent
    end

    RegisterTouchFriendlyClick(Btn, function()
        for _, p in pairs(AllPages) do p.Visible = false end
        for _, b in pairs(TabButtonsContainer:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Style_Bg
                b.TextColor3 = Style_Text_Secondary
                local s = b:FindFirstChildOfClass("UIStroke")
                if s then s.Color = Color3.fromRGB(35, 37, 40) end
            end
        end
        PageInstance.Visible = true
        Btn.BackgroundColor3 = Style_Inactive
        Btn.TextColor3 = Style_Text_Primary
        Stroke.Color = Style_Accent
    end)
    return Btn
end

CreateTabButton("Combat", CombatPage)
CreateTabButton("Player", PlayerPage)
CreateTabButton("Movement", MovementPage)
CreateTabButton("Visual", VisualPage)
CreateTabButton("Misc", MiscPage)
CreateTabButton("Credits", CreditsPage)
local function CreateToggleElement(Page, TitleText, ConfigKey, Callback)
    local Row = Instance.new("Frame", Page)
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = Style_SubBg
    Instance.new("UICorner", Row).CornerRadius = Style_CornerRadius
    local Stroke = Instance.new("UIStroke", Row)
    Stroke.Color = Color3.fromRGB(30, 32, 35)
    
    local Label = Instance.new("TextLabel", Row)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Font = Style_Font
    Label.Text = TitleText
    Label.TextColor3 = Style_Text_Primary
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Pill = Instance.new("TextButton", Row)
    Pill.Size = UDim2.new(0, 42, 0, 20)
    Pill.Position = UDim2.new(1, -52, 0.5, -10)
    Pill.BackgroundColor3 = Config[ConfigKey] and Style_Accent or Style_Inactive
    Pill.Text = ""
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = Config[ConfigKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Style_Text_Primary
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function updateVisuals()
        local state = Config[ConfigKey]
        TweenService:Create(Pill, TweenInfo.new(0.2), {BackgroundColor3 = state and Style_Accent or Style_Inactive}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        if GlobalSyncToggles[ConfigKey] then
            GlobalSyncToggles[ConfigKey](state)
        end
    end

    table.insert(UI_Refresh_Functions, function()
        Pill.BackgroundColor3 = Config[ConfigKey] and Style_Accent or Style_Inactive
        Knob.Position = Config[ConfigKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end)

    RegisterTouchFriendlyClick(Pill, function()
        Config[ConfigKey] = not Config[ConfigKey]
        updateVisuals()
        if Callback then Callback(Config[ConfigKey]) end
    end)
    return Row
end

local function CreateSliderElement(Page, TitleText, ConfigKey, Min, Max, Callback)
    local Row = Instance.new("Frame", Page)
    Row.Size = UDim2.new(1, 0, 0, 46)
    Row.BackgroundColor3 = Style_SubBg
    Instance.new("UICorner", Row).CornerRadius = Style_CornerRadius

    local Label = Instance.new("TextLabel", Row)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 4)
    Label.Size = UDim2.new(0.5, 0, 0, 18)
    Label.Font = Style_Font
    Label.Text = TitleText
    Label.TextColor3 = Style_Text_Primary
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValLabel = Instance.new("TextLabel", Row)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Position = UDim2.new(1, -70, 0, 4)
    ValLabel.Size = UDim2.new(0, 60, 0, 18)
    ValLabel.Font = Style_Font
    ValLabel.Text = tostring(Config[ConfigKey])
    ValLabel.TextColor3 = Style_Accent
    ValLabel.TextSize = 12
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("TextButton", Row)
    Track.Size = UDim2.new(1, -20, 0, 4)
    Track.Position = UDim2.new(0, 10, 1, -12)
    Track.BackgroundColor3 = Style_Inactive
    Track.Text = ""
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Track)
    local pct = (Config[ConfigKey] - Min) / (Max - Min)
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Style_Accent
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local function slide(input)
        local x = input.Position.X - Track.AbsolutePosition.X
        local rawPct = math.clamp(x / Track.AbsoluteSize.Width, 0, 1)
        local val = math.floor(Min + (rawPct * (Max - Min)))
        Config[ConfigKey] = val
        ValLabel.Text = tostring(val)
        Fill.Size = UDim2.new(rawPct, 0, 1, 0)
        if Callback then Callback(val) end
    end

    local interaction = false
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            interaction = true; slide(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if interaction and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            slide(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            interaction = false
        end
    end)

    table.insert(UI_Refresh_Functions, function()
        local currentPct = (Config[ConfigKey] - Min) / (Max - Min)
        Fill.Size = UDim2.new(currentPct, 0, 1, 0)
        ValLabel.Text = tostring(Config[ConfigKey])
    end)
    return Row
end
local function CreateDropdownElement(Page, TitleText, ConfigKey, Options, Callback)
    local Row = Instance.new("Frame", Page)
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = Style_SubBg
    Instance.new("UICorner", Row).CornerRadius = Style_CornerRadius
    
    local Label = Instance.new("TextLabel", Row)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Font = Style_Font
    Label.Text = TitleText
    Label.TextColor3 = Style_Text_Primary
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SelectBtn = Instance.new("TextButton", Row)
    SelectBtn.Size = UDim2.new(0, 100, 0, 24)
    SelectBtn.Position = UDim2.new(1, -110, 0.5, -12)
    SelectBtn.BackgroundColor3 = Style_Inactive
    SelectBtn.Font = Style_Font
    SelectBtn.Text = tostring(Config[ConfigKey])
    SelectBtn.TextColor3 = Style_Text_Primary
    SelectBtn.TextSize = 11
    Instance.new("UICorner", SelectBtn).CornerRadius = Style_CornerRadius

    local currentIdx = table.find(Options, Config[ConfigKey]) or 1
    RegisterTouchFriendlyClick(SelectBtn, function()
        currentIdx = currentIdx + 1
        if currentIdx > #Options then currentIdx = 1 end
        Config[ConfigKey] = Options[currentIdx]
        SelectBtn.Text = tostring(Options[currentIdx])
        if Callback then Callback(Options[currentIdx]) end
    end)

    table.insert(UI_Refresh_Functions, function()
        SelectBtn.Text = tostring(Config[ConfigKey])
        currentIdx = table.find(Options, Config[ConfigKey]) or 1
    end)
    return Row
end

-- Điền các Control của Combat Page
CreateSectionTitle(CombatPage, "Aimbot Settings")
CreateToggleElement(CombatPage, "Enable Aimbot", "Aimbot")
CreateToggleElement(CombatPage, "Team Check", "TeamCheck")
CreateToggleElement(CombatPage, "Wall Check", "WallCheck")
CreateSliderElement(CombatPage, "Smoothness", "Smoothness", 1, 20)
CreateDropdownElement(CombatPage, "Target Part", "TargetPart", {"Head", "Torso", "Legs"})

CreateSectionTitle(CombatPage, "Kill Aura Settings")
CreateToggleElement(CombatPage, "Enable Kill Aura", "Aura")
CreateSliderElement(CombatPage, "Aura Radius", "AuraRadius", 10, 100)
CreateToggleElement(CombatPage, "Aura Wall Check", "AuraWallCheck")

CreateSectionTitle(CombatPage, "Triggerbot Settings")
CreateToggleElement(CombatPage, "Enable Triggerbot", "Triggerbot")

CreateSectionTitle(CombatPage, "Auto Farm Settings")
CreateToggleElement(CombatPage, "Auto Farm Players", "AutoFarmPlayer")

-- Điền các Control của Player Page
CreateSectionTitle(PlayerPage, "Character Modifiers")
CreateToggleElement(PlayerPage, "Spinbot", "Spinbot")
CreateSliderElement(PlayerPage, "Spin Speed", "SpinSpeed", 5, 100)
CreateToggleElement(PlayerPage, "Anti-AFK active", "AntiAFK")

-- Điền các Control của Movement Page
CreateSectionTitle(MovementPage, "Speed Control")
CreateToggleElement(MovementPage, "Speed Multiplier", "SpeedToggle")
CreateSliderElement(MovementPage, "WalkSpeed Value", "WalkSpeed", 16, 250)

CreateSectionTitle(MovementPage, "Jump Control")
CreateToggleElement(MovementPage, "Jump Power Multiplier", "JumpToggle")
CreateSliderElement(MovementPage, "JumpPower Value", "JumpPower", 50, 500)

CreateSectionTitle(MovementPage, "Fly Control")
CreateToggleElement(MovementPage, "Fly Hack", "Fly", function(val) ToggleFlyState(val) end)
CreateSliderElement(MovementPage, "Fly Speed", "FlySpeed", 20, 300)

-- Điền các Control của Visual Page
CreateSectionTitle(VisualPage, "ESP Configuration")
CreateToggleElement(VisualPage, "Master Visuals Active", "EspMaster")
CreateToggleElement(VisualPage, "Show 2D Box", "EspBox")
CreateToggleElement(VisualPage, "Show Tracers", "EspTracer")
CreateDropdownElement(VisualPage, "Tracer Origin", "TracerMode", {"Bottom", "Center"})
CreateToggleElement(VisualPage, "Show Name Labels", "EspName")
CreateToggleElement(VisualPage, "Show Health Indicators", "EspHealth")
CreateToggleElement(VisualPage, "Draw FOV Circle", "FovCircle")
CreateSliderElement(VisualPage, "FOV Circle Radius", "FovRadius", 30, 400)
-- Điền các Control của Misc Page
CreateSectionTitle(MiscPage, "Configuration Profiles")
local HexInputText = ""
local TempRow = Instance.new("Frame", MiscPage)
TempRow.Size = UDim2.new(1, 0, 0, 40)
TempRow.BackgroundTransparency = 1

local ExportBtn = Instance.new("TextButton", TempRow)
ExportBtn.Size = UDim2.new(0.45, 0, 1, 0)
ExportBtn.BackgroundColor3 = Style_SubBg
ExportBtn.Font = Style_Font
ExportBtn.Text = "Export Hex Profile"
ExportBtn.TextColor3 = Style_Text_Primary
ExportBtn.TextSize = 12
Instance.new("UICorner", ExportBtn).CornerRadius = Style_CornerRadius
RegisterTouchFriendlyClick(ExportBtn, function()
    local str = ExportSettings()
    if setclipboard then setclipboard(str) end
    ExportBtn.Text = "Copied Data Profile!"
    task.wait(1.5)
    ExportBtn.Text = "Export Hex Profile"
end)

local ImportBtn = Instance.new("TextButton", TempRow)
ImportBtn.Size = UDim2.new(0.45, 0, 1, 0)
ImportBtn.Position = UDim2.new(0.55, 0, 0, 0)
ImportBtn.BackgroundColor3 = Style_SubBg
ImportBtn.Font = Style_Font
ImportBtn.Text = "Import Profile"
ImportBtn.TextColor3 = Style_Text_Primary
ImportBtn.TextSize = 12
Instance.new("UICorner", ImportBtn).CornerRadius = Style_CornerRadius
RegisterTouchFriendlyClick(ImportBtn, function()
    local success = false
    pcall(function()
        if getclipboard then
            local cb = getclipboard()
            success = ImportSettings(cb)
        end
    end)
    if success then
        ImportBtn.Text = "Imported!"
    else
        ImportBtn.Text = "Failed/No Clipboard"
    end
    task.wait(1.5)
    ImportBtn.Text = "Import Profile"
end)

-- Điền các Control của Credits Page
CreateSectionTitle(CreditsPage, "Project Authorization")
local CredLabel = Instance.new("TextLabel", CreditsPage)
CredLabel.BackgroundTransparency = 1
CredLabel.Size = UDim2.new(1, 0, 0, 60)
CredLabel.Font = Style_Font
CredLabel.Text = "OWNER: DAI CA WANG\nDEVELOPER: BE\nVERSION: 6.9.4 UI VERTICAL COMPLETE"
CredLabel.TextColor3 = Style_Text_Secondary
CredLabel.TextSize = 12

local function MonitorPlayer(Player)
    if Player == LocalPlayer then return end
    Player.CharacterAdded:Connect(function(Char)
        CreateTracerObject(Player)
    end)
end

local function HandleMobileShortcutToggle(Key, state)
    if Key == "Aimbot" then MobAim.Text = state and "AIM\nON" or "AIM\nOFF" MobAim.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(255, 50, 50)
    elseif Key == "Triggerbot" then MobTrig.Text = state and "TRIG\nON" or "TRIG\nOFF" MobTrig.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(230, 125, 30)
    elseif Key == "SpeedToggle" then MobSpeed.Text = state and "SPD\nON" or "SPD\nOFF" MobSpeed.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(140, 30, 230)
    elseif Key == "AutoFarmPlayer" then MobFarm.Text = state and "FRM\nON" or "FRM\nOFF" MobFarm.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(45, 140, 75)
    elseif Key == "Aura" then MobAura.Text = state and "AUR\nON" or "AUR\nOFF" MobAura.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(0, 150, 255)
    elseif Key == "ThirdPerson" then MobTP.Text = state and "3RD\nON" or "3RD\nOFF"
    elseif Key == "Fly" then MobFly.Text = state and "FLY\nON" or "FLY\nOFF" MobFly.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(0, 255, 255)
    end
end

for K, _ in pairs(Config) do
    GlobalSyncToggles[K] = function(state) HandleMobileShortcutToggle(K, state) end
end
MasterLoop = RunService.RenderStepped:Connect(function()
    if Config.Aimbot and UserInputService:IsKeyDown(Config.AimbotKeybind) then
        local target = GetClosestPlayerToCrosshair()
        if target then
            local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local mouseMove = (Vector2.new(screenPos.X, screenPos.Y) - Center) / Config.Smoothness
                pcall(function() mousemoverel(mouseMove.X, mouseMove.Y) end)
            end
        end
    end

    if Config.Triggerbot then
        PerformTriggerbotClick()
    end

    if Config.Spinbot then
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
        end
    end

    ProcessAutoFarmPlayer()

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.SpeedToggle then hum.WalkSpeed = Config.WalkSpeed else hum.WalkSpeed = 16 end
        if Config.JumpToggle then hum.JumpPower = Config.JumpPower else hum.JumpPower = 50 end
    end

    if Config.Fly and flyBodyGyro and flyBodyVelocity and char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        flyBodyGyro.CFrame = Camera.CFrame
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        flyBodyVelocity.Velocity = moveDir.Unit * Config.FlySpeed
    end

    if Config.FovCircle then
        FOV_Drawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOV_Drawing.Radius = Config.FovRadius
        FOV_Drawing.Visible = true
    else
        FOV_Drawing.Visible = false
    end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local Char = Player.Character
            local Tracer = Tracer_Cache[Player]
            if Root and Char and IsAlive(Char) and Config.EspMaster then
                local Dist = (Root.Position - Camera.CFrame.Position).Magnitude
                local PColor = GetPlayerColor(Player)
                if Tracer and Config.EspTracer and Dist <= Config.MaxDistance then
                    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local Leg, IsTracerOnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    if IsTracerOnScreen then 
                        Tracer.From = Config.TracerMode == "Center" and ScreenCenter or ScreenBottom 
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
                if Tracer then Tracer.Visible = false end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(Player) CreateTracerObject(Player) MonitorPlayer(Player) end)
Players.PlayerRemoving:Connect(function(Player) ClearTracerObject(Player) end)

for _, P in pairs(Players:GetPlayers()) do CreateTracerObject(P) MonitorPlayer(P) end
if UI_Refresh_Functions then
    for _, refresh in pairs(UI_Refresh_Functions) do pcall(refresh) end
end

pcall(function()
    StarterGui:SetCore("SendNotification", {Title = "WANGCAOS CLIENT V6.9.4", Text = "Loaded Modern Compact Edition successfully!", Duration = 5})
end)
