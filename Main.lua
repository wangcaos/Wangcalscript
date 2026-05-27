-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V6.9.4 - MODERN VERTICAL SIDEBAR EDITION
-- ALL RIGHTS RESERVED BY DAI CA WANG (2026)
-- UI Design: Minimalism / Dark Modern / Blur / Vertical Sidebar / Pill Toggles
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

-- Modern Theme Configuration (Dark/Minimalism)
local Style_Bg = Color3.fromRGB(15, 16, 17)
local Style_SubBg = Color3.fromRGB(22, 24, 27)
local Style_Accent = Color3.fromRGB(210, 80, 50) -- Warm reddish-orange for active elements
local Style_Inactive = Color3.fromRGB(40, 42, 45)
local Style_Text_Primary = Color3.fromRGB(255, 255, 255)
local Style_Text_Secondary = Color3.fromRGB(150, 150, 150)
local Style_CornerRadius = UDim.new(0, 6)

local Config = {
    MenuVisible = true, MenuKeybind = Enum.KeyCode.RightShift,
    Aimbot = false, AimbotKeybind = Enum.KeyCode.E, TeamCheck = true, WallCheck = true, Smoothness = 5, TargetPart = "Head",
    Aura = false, AuraKeybind = Enum.KeyCode.H, TeamCheckAura = true, AuraWallCheck = true, AuraSmoothness = 5, AuraRadius = 30, AuraColor = Color3.fromRGB(0, 170, 255), AuraTransparency = 50, PriorityLowestHealth = false,
    Triggerbot = false, TriggerbotKeybind = Enum.KeyCode.T, TriggerWallCheck = true,
    Spinbot = false, SpinbotKeybind = Enum.KeyCode.K, SpinSpeed = 25,
    AutoFarmPlayer = false, AutoFarmDelay = 0.05,
    BowDown = false, BowAngle = 45, ThirdPerson = false, ThirdPersonDist = 15, AntiAFK = false,
    EspMaster = false, EspMasterKeybind = Enum.KeyCode.O, EspTeamCheck = false, FovCircle = false, FovRadius = 120, FovThickness = 1.5, FovSides = 64, FovColor = Color3.fromRGB(255, 255, 255), FovTransparency = 0.8, FovFilled = false,
    CrosshairDot = false, EspBox = false, EspTracer = false, TracerMode = "Bottom", EspColor = Color3.fromRGB(255, 50, 50), EspName = false, EspHealth = false, EspTransparency = 80, MaxDistance = 5000,
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

-- ==============================================================================
-- INTRO SYSTEM
-- ==============================================================================
local IntroScreen = Instance.new("ScreenGui")
IntroScreen.Name = "WangcaosIntro"
IntroScreen.Parent = SafeParent
IntroScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local IntroFrame = Instance.new("Frame", IntroScreen)
IntroFrame.BackgroundColor3 = Style_Bg
IntroFrame.BackgroundTransparency = 0.1
IntroFrame.BorderSizePixel = 0
IntroFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
IntroFrame.Size = UDim2.new(0, 350, 0, 150)
Instance.new("UICorner", IntroFrame).CornerRadius = UDim.new(0, 10)
local IntroStroke = Instance.new("UIStroke", IntroFrame)
IntroStroke.Color = Style_Accent
IntroStroke.Thickness = 2

local IntroTitle = Instance.new("TextLabel", IntroFrame)
IntroTitle.BackgroundTransparency = 1
IntroTitle.Size = UDim2.new(1, 0, 0, 50)
IntroTitle.Position = UDim2.new(0, 0, 0, 15)
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.Text = "WANGCAOS PREMIUM V6.9.4"
IntroTitle.TextColor3 = Style_Text_Primary
IntroTitle.TextSize = 18

local IntroDisc = Instance.new("TextLabel", IntroFrame)
IntroDisc.BackgroundTransparency = 1
IntroDisc.Size = UDim2.new(1, 0, 0, 30)
IntroDisc.Position = UDim2.new(0, 0, 0, 60)
IntroDisc.Font = Enum.Font.GothamBold
IntroDisc.Text = "Discord: Https://discord.gg/GkAKn4zzH"
IntroDisc.TextColor3 = Style_Accent
IntroDisc.TextSize = 14

local IntroSub = Instance.new("TextLabel", IntroFrame)
IntroSub.BackgroundTransparency = 1
IntroSub.Size = UDim2.new(1, 0, 0, 30)
IntroSub.Position = UDim2.new(0, 0, 0, 95)
IntroSub.Font = Enum.Font.Gotham
IntroSub.Text = "Loading Framework Modules..."
IntroSub.TextColor3 = Style_Text_Secondary
IntroSub.TextSize = 12

pcall(function()
    if setclipboard then setclipboard("Https://discord.gg/GkAKn4zzH")
    elseif toclipboard then toclipboard("Https://discord.gg/GkAKn4zzH") end
end)

task.spawn(function()
    task.wait(1.5)
    IntroSub.Text = "Framework successfully loaded!"
    task.wait(2.5)
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(IntroFrame, tweenInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(IntroTitle, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroDisc, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroSub, tweenInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroStroke, tweenInfo, {Transparency = 1}):Play()
    task.wait(1.5)
    if IntroScreen then IntroScreen:Destroy() end
end)

-- ==============================================================================
-- CORE UTILITIES & SETTINGS HANDLERS
-- ==============================================================================
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

-- ==============================================================================
-- DRAWING OBJECTS INITIALIZATION
-- ==============================================================================
local FOV_Drawing = Drawing.new("Circle")
FOV_Drawing.Color = Config.FovColor; FOV_Drawing.Thickness = Config.FovThickness; FOV_Drawing.NumSides = Config.FovSides
FOV_Drawing.Filled = Config.FovFilled; FOV_Drawing.Transparency = Config.FovTransparency; FOV_Drawing.Visible = false

local Dot_Drawing = Drawing.new("Circle")
Dot_Drawing.Color = Color3.fromRGB(255, 255, 255); Dot_Drawing.Thickness = 1; Dot_Drawing.Radius = 3
Dot_Drawing.NumSides = 16; Dot_Drawing.Filled = true; Dot_Drawing.Transparency = 1; Dot_Drawing.Visible = false

local AuraVisual = Instance.new("CylinderHandleAdornment")
AuraVisual.Name = "WangAuraCircle"; AuraVisual.AlwaysOnTop = false; AuraVisual.ZIndex = 5

local Tracer_Cache = {}
local Character_Cache = {}

local function CreateTracerObject(Player)
    if Tracer_Cache[Player] then return end
    local Line = Drawing.new("Line")
    Line.Thickness = 1.2; Line.Color = Config.EspColor; Line.Transparency = 1; Line.Visible = false
    Tracer_Cache[Player] = Line
end

local function ClearTracerObject(Player)
    if Tracer_Cache[Player] then pcall(function() Tracer_Cache[Player].Visible = false Tracer_Cache[Player]:Remove() end) Tracer_Cache[Player] = nil end
end

local function CleanCharacterVisuals(Character)
    if not Character then return end
    local OldBox = Character:FindFirstChild("WangBoxFill", true)
    if OldBox then OldBox:Destroy() end
    local OldTag = Character:FindFirstChild("WangInfoTag", true)
    if OldTag then OldTag:Destroy() end
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
        local myAttr = LocalPlayer:GetAttribute(attr); local targetAttr = Player:GetAttribute(attr)
        if myAttr and targetAttr and myAttr == targetAttr then return true end
        if LocalPlayer.Character and Player.Character then
            local myCharAttr = LocalPlayer.Character:GetAttribute(attr); local targetCharAttr = Player.Character:GetAttribute(attr)
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
    local Origin = Camera.CFrame.Position; local Direction = TargetPart.Position - Origin
    local Params = RaycastParams.new(); Params.FilterType = Enum.RaycastFilterType.Exclude; Params.FilterDescendantsInstances = {LocalPlayer.Character, Character, Camera}
    return workspace:Raycast(Origin, Direction, Params) == nil
end

local function CheckTriggerWall(Position)
    if not Config.TriggerWallCheck then return true end
    local Origin = Camera.CFrame.Position; local Direction = Position - Origin
    local Params = RaycastParams.new(); Params.FilterType = Enum.RaycastFilterType.Exclude; Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
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
    local root = character.HumanoidRootPart; local hum = character:FindFirstChildOfClass("Humanoid")
    if state then
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyGyro = Instance.new("BodyGyro"); flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyBodyGyro.CFrame = root.CFrame; flyBodyGyro.Parent = root
        flyBodyVelocity = Instance.new("BodyVelocity"); flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyBodyVelocity.Parent = root
        if hum then hum.PlatformStand = true end
    else
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if hum then hum.PlatformStand = false end
    end
end

local function GetClosestPlayerToCrosshair()
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ClosestTarget = nil; local MaxDist = Config.FovRadius; local LowestHealth = math.huge
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
    local MyChar = LocalPlayer.Character; local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    local BestTarget = nil; local LowestHealth = math.huge; local ClosestDist = Config.AuraRadius
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
    local MyChar = LocalPlayer.Character; local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
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
    local EnemyRoot = ActiveTargetData.Root; local EnemyHead = ActiveTargetData.Head
    if EnemyRoot and EnemyHead then
        local BehindPosition = EnemyRoot.Position - (EnemyRoot.CFrame.LookVector * 3)
        MyRoot.CFrame = CFrame.new(BehindPosition, EnemyRoot.Position)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, EnemyHead.Position)
        if not IsFiring then IsFiring = true pcall(function() mouse1press() end) end
        if tick() - LastFarmTime >= Config.AutoFarmDelay then LastFarmTime = tick() CurrentFarmIndex = CurrentFarmIndex + 1 end
    end
end

-- ==============================================================================
-- GUI BUILDING - EXPLICIT VERTICAL SIDEBAR LAYOUT
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Premium_Figma_UI"
ScreenGui.ResetOnSpawn = false; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = SafeParent

local function MakeDraggable(UIElement, DragHandle, PosKey)
    local dragging = false; local dragInput, mousePos, framePos
    DragHandle.InputBegan:Connect(function(input)
        if Config.LockMobileButtons and PosKey then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = UIElement.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if PosKey then
                        Config["MobilePos_"..PosKey.."_XS"] = UIElement.Position.X.Scale; Config["MobilePos_"..PosKey.."_XO"] = UIElement.Position.X.Offset
                        Config["MobilePos_"..PosKey.."_YS"] = UIElement.Position.Y.Scale; Config["MobilePos_"..PosKey.."_YO"] = UIElement.Position.Y.Offset
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
    local xs = Config["MobilePos_"..Key.."_XS"] or InitPos.X.Scale; local xo = Config["MobilePos_"..Key.."_XO"] or InitPos.X.Offset
    local ys = Config["MobilePos_"..Key.."_YS"] or InitPos.Y.Scale; local yo = Config["MobilePos_"..Key.."_YO"] or InitPos.Y.Offset
    if not Config["MobilePos_"..Key.."_XS"] then Config["MobilePos_"..Key.."_XS"] = xs; Config["MobilePos_"..Key.."_XO"] = xo; Config["MobilePos_"..Key.."_YS"] = ys; Config["MobilePos_"..Key.."_YO"] = yo end

    local ShortcutBtn = Instance.new("TextButton")
    ShortcutBtn.Name = "IndependentMobile_" .. Key; ShortcutBtn.Parent = ScreenGui
    ShortcutBtn.BackgroundColor3 = DefaultColor; ShortcutBtn.BackgroundTransparency = 0.2
    ShortcutBtn.Position = UDim2.new(xs, xo, ys, yo); ShortcutBtn.Size = UDim2.new(0, 52, 0, 52)
    ShortcutBtn.Font = Enum.Font.GothamBold; ShortcutBtn.Text = TextOff; ShortcutBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ShortcutBtn.TextSize = 9
    ShortcutBtn.Visible = (Config[ShowKey] and IsMobile)
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn); Stroke.Color = Color3.fromRGB(255, 255, 255); Stroke.Thickness = 1.5
    MakeDraggable(ShortcutBtn, ShortcutBtn, Key)
    GlobalMobileButtons[Key] = { Btn = ShortcutBtn, ShowKey = ShowKey }
    return ShortcutBtn
end

local MobAim = CreateIndependentMobileButton("Aimbot", "AIM\nON", "AIM\nOFF", "Aimbot", "ShowMobileAim", Color3.fromRGB(255, 50, 50), UDim2.new(0.85, 0, 0.15, 0))
local MobTrig = CreateIndependentMobileButton("Triggerbot", "TRIG\nON", "TRIG\nOFF", "Triggerbot", "ShowMobileTrig", Color3.fromRGB(230, 125, 30), UDim2.new(0.85, 0, 0.26, 0))
local MobSpeed = CreateIndependentMobileButton("Speed", "SPD\nON", "SPD\nOFF", "SpeedToggle", "ShowMobileSpeed", Color3.fromRGB(140, 30, 230), UDim2.new(0.85, 0, 0.37, 0))
local MobFarm = CreateIndependentMobileButton("AutoFarm", "FRM\nON", "FRM\nOFF", "AutoFarmPlayer", "ShowMobileFarm", Color3.fromRGB(45, 140, 75), UDim2.new(0.85, 0, 0.48, 0))
local MobAura = CreateIndependentMobileButton("Aura", "AUR\nON", "AUR\nOFF", "Aura", "ShowMobileAura", Color3.fromRGB(0, 150, 255), UDim2.new(0.85, 0, 0.59, 0))
local MobTP = CreateIndependentMobileButton("ThirdPerson", "3RD\nON", "3RD\nOFF", "ThirdPerson", "ShowMobileTP", Color3.fromRGB(150, 150, 150), UDim2.new(0.85, 0, 0.70, 0))
local MobFly = CreateIndependentMobileButton("Fly", "FLY\nON", "FLY\nOFF", "Fly", "ShowMobileFly", Color3.fromRGB(0, 255, 255), UDim2.new(0.85, 0, 0.81, 0))

local lxs = Config["MobilePos_MainLogo_XS"] or 0; local lxo = Config["MobilePos_MainLogo_XO"] or 20
local lys = Config["MobilePos_MainLogo_YS"] or 0; local lyo = Config["MobilePos_MainLogo_YO"] or 20
if not Config["MobilePos_MainLogo_XS"] then Config["MobilePos_MainLogo_XS"] = lxs; Config["MobilePos_MainLogo_XO"] = lxo; Config["MobilePos_MainLogo_YS"] = lys; Config["MobilePos_MainLogo_YO"] = lyo end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "PremiumToggleLogo"; ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Position = UDim2.new(lxs, lxo, lys, lyo); ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold; ToggleButton.Text = "W"; ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(60, 60, 60); ToggleButton.UIStroke.Thickness = 1.5
ToggleButton.Visible = IsMobile
GlobalMobileButtons["MainLogo"] = { Btn = ToggleButton }
MakeDraggable(ToggleButton, ToggleButton, "MainLogo")

-- Main Menu Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Style_Bg; MainFrame.Position = UDim2.new(0.5, -240, 0.5, -165)
MainFrame.Size = UDim2.new(0, 480, 0, 330); MainFrame.ClipsDescendants = true; MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(45, 47, 50); MainFrame.UIStroke.Thickness = 1.5
MakeDraggable(MainFrame, MainFrame, nil)

local CustomBackgroundImage = Instance.new("ImageLabel")
CustomBackgroundImage.Name = "MenuCustomWallpaper"; CustomBackgroundImage.Parent = MainFrame
CustomBackgroundImage.BackgroundTransparency = 1; CustomBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
CustomBackgroundImage.Image = Config.BackgroundAssetId; CustomBackgroundImage.ImageTransparency = 0.75
CustomBackgroundImage.ScaleType = Enum.ScaleType.Crop; CustomBackgroundImage.ZIndex = 0; CustomBackgroundImage.Visible = Config.CustomBackground
Instance.new("UICorner", CustomBackgroundImage).CornerRadius = UDim.new(0, 8)

-- Left Sidebar Container Frame
local SideBarFrame = Instance.new("Frame", MainFrame)
SideBarFrame.Name = "SideBarFrame"; SideBarFrame.BackgroundColor3 = Style_SubBg; SideBarFrame.BorderSizePixel = 0
SideBarFrame.Size = UDim2.new(0, 120, 1, 0); SideBarFrame.ZIndex = 2
local SideBarLine = Instance.new("Frame", SideBarFrame)
SideBarLine.Size = UDim2.new(0, 1, 1, 0); SideBarLine.Position = UDim2.new(1, -1, 0, 0)
SideBarLine.BackgroundColor3 = Color3.fromRGB(45, 47, 50); SideBarLine.BorderSizePixel = 0

local TitleLabel = Instance.new("TextLabel", SideBarFrame)
TitleLabel.Size = UDim2.new(1, 0, 0, 40); TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.Text = "WANGCAOS"
TitleLabel.TextColor3 = Style_Accent; TitleLabel.TextSize = 15

local TabMenuContainer = Instance.new("ScrollingFrame", SideBarFrame)
TabMenuContainer.Size = UDim2.new(1, 0, 1, -50); TabMenuContainer.Position = UDim2.new(0, 0, 0, 45)
TabMenuContainer.BackgroundTransparency = 1; TabMenuContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
TabMenuContainer.ScrollBarThickness = 0
local SidebarLayout = Instance.new("UIListLayout", TabMenuContainer)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder; SidebarLayout.Padding = UDim.new(0, 4)
Instance.new("UIPadding", TabMenuContainer).PaddingLeft = UDim.new(0, 6)
TabMenuContainer.UIPadding.PaddingRight = UDim.new(0, 6)

-- Pages Panel (Right side)
local PagesContainer = Instance.new("Frame", MainFrame)
PagesContainer.Size = UDim2.new(1, -130, 1, -10); PagesContainer.Position = UDim2.new(0, 125, 0, 5)
PagesContainer.BackgroundTransparency = 1; PagesContainer.ZIndex = 2

local function CreatePage(Name)
    local Page = Instance.new("ScrollingFrame", PagesContainer)
    Page.Name = Name .. "Page"; Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Style_Accent; Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local List = Instance.new("UIListLayout", Page)
    List.SortOrder = Enum.SortOrder.LayoutOrder; List.Padding = UDim.new(0, 5)
    Instance.new("UIPadding", Page).PaddingRight = UDim.new(0, 4)
    return Page
end

local CombatPage = CreatePage("Combat")
local PlayerPage = CreatePage("Player")
local MovementPage = CreatePage("Movement")
local VisualPage = CreatePage("Visual")
local MiscPage = CreatePage("Misc")
local CreditsPage = CreatePage("Credits")

local function AddTab(Name, Order, targetPage)
    local TabBtn = Instance.new("TextButton", TabMenuContainer)
    TabBtn.Size = UDim2.new(1, 0, 0, 32); TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.BackgroundColor3 = Style_Inactive; TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.Text = Name; TabBtn.TextColor3 = Order == 1 and Style_Text_Primary or Style_Text_Secondary; TabBtn.TextSize = 13
    Instance.new("UICorner", TabBtn).CornerRadius = Style_CornerRadius
    local TStroke = Instance.new("UIStroke", TabBtn); TStroke.Color = Color3.fromRGB(55, 57, 61); TStroke.Enabled = Order == 1

    RegisterTouchFriendlyClick(TabBtn, function()
        for _, p in pairs({CombatPage, PlayerPage, MovementPage, VisualPage, MiscPage, CreditsPage}) do p.Visible = false end
        for _, btn in pairs(TabMenuContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 1; btn.TextColor3 = Style_Text_Secondary
                if btn:FindFirstChild("UIStroke") then btn.UIStroke.Enabled = false end
            end
        end
        targetPage.Visible = true; TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Style_Text_Primary; TStroke.Enabled = true
    end)
    if Order == 1 then targetPage.Visible = true end
end

AddTab("⚔️ Combat", 1, CombatPage)
AddTab("👤 Player Target", 2, PlayerPage)
AddTab("👟 Movement", 3, MovementPage)
AddTab("👁️ Visuals / ESP", 4, VisualPage)
AddTab("⚙️ System Config", 5, MiscPage)
AddTab("📜 Credits Info", 6, CreditsPage)

local function UpdateToggleVisual(Key)
    local state = Config[Key]
    if GlobalSyncToggles[Key] then
        for _, tData in pairs(GlobalSyncToggles[Key]) do
            TweenService:Create(tData.Pill, TweenInfo.new(0.2), {BackgroundColor3 = state and Style_Accent or Style_Inactive}):Play()
            TweenService:Create(tData.Ball, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -17, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)}):Play()
        end
    end
    if GlobalMobileButtons[Key] then
        local MData = GlobalMobileButtons[Key]
        if MData.Btn then
            MData.Btn.BackgroundColor3 = state and Style_Accent or Color3.fromRGB(40, 42, 45)
            if Key == "Aimbot" then MData.Btn.Text = state and "AIM\nON" or "AIM\nOFF"
            elseif Key == "Triggerbot" then MData.Btn.Text = state and "TRIG\nON" or "TRIG\nOFF"
            elseif Key == "SpeedToggle" then MData.Btn.Text = state and "SPD\nON" or "SPD\nOFF"
            elseif Key == "AutoFarmPlayer" then MData.Btn.Text = state and "FRM\nON" or "FRM\nOFF"
            elseif Key == "Aura" then MData.Btn.Text = state and "AUR\nON" or "AUR\nOFF"
            elseif Key == "ThirdPerson" then MData.Btn.Text = state and "3RD\nON" or "3RD\nOFF"
            elseif Key == "Fly" then MData.Btn.Text = state and "FLY\nON" or "FLY\nOFF" end
        end
    end
end

local RestrictedKeys = { ShowMobileTP = true, ShowMobileAura = true, ShowMobileAim = true, ShowMobileTrig = true, ShowMobileSpeed = true, ShowMobileFarm = true, ShowMobileFly = true }
local function AddPremiumToggle(Page, LabelText, Key, Callback, DefMobColor, BindKey)
    local TFrame = Instance.new("Frame", Page)
    TFrame.Size = UDim2.new(1, -5, 0, 38); TFrame.BackgroundColor3 = Style_SubBg
    Instance.new("UICorner", TFrame).CornerRadius = Style_CornerRadius
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.Position = UDim2.new(0, 10, 0, 0); Lbl.Size = UDim2.new(1, -120, 1, 0)
    Lbl.Font = Enum.Font.GothamMedium; Lbl.Text = LabelText; Lbl.TextColor3 = Style_Text_Primary; Lbl.TextSize = 13; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    if BindKey then
        local KBKey = Key .. "Keybind"
        local BindBtn = Instance.new("TextButton", TFrame)
        BindBtn.Position = UDim2.new(1, -115, 0.5, -11); BindBtn.Size = UDim2.new(0, 55, 0, 22)
        BindBtn.BackgroundColor3 = Style_Inactive; BindBtn.Font = Enum.Font.Gotham; BindBtn.Text = "[" .. Config[KBKey].Name .. "]"; BindBtn.TextColor3 = Style_Text_Secondary; BindBtn.TextSize = 11
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
        RegisterTouchFriendlyClick(BindBtn, function()
            BindBtn.Text = "[...]"
            local conn; conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Config[KBKey] = input.KeyCode; BindBtn.Text = "[" .. input.KeyCode.Name .. "]"; conn:Disconnect()
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Config[KBKey] = Enum.KeyCode.Unknown; BindBtn.Text = "[None]"; conn:Disconnect()
                end
            end)
        end)
    end

    local Pill = Instance.new("TextButton", TFrame)
    Pill.Position = UDim2.new(1, -50, 0.5, -10); Pill.Size = UDim2.new(0, 40, 0, 20); Pill.Text = ""
    Pill.BackgroundColor3 = Config[Key] and Style_Accent or Style_Inactive
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Ball = Instance.new("Frame", Pill)
    Ball.Size = UDim2.new(0, 14, 0, 14); Ball.Position = Config[Key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    if not GlobalSyncToggles[Key] then GlobalSyncToggles[Key] = {} end
    table.insert(GlobalSyncToggles[Key], {Pill = Pill, Ball = Ball})

    RegisterTouchFriendlyClick(Pill, function()
        Config[Key] = not Config[Key]
        UpdateToggleVisual(Key)
        if Callback then Callback(Config[Key]) end
        if RestrictedKeys[Key] and IsMobile then
            local targetMobKey = string.sub(Key, 11)
            if targetMobKey == "TP" then targetMobKey = "ThirdPerson"
            elseif targetMobKey == "Speed" then targetMobKey = "SpeedToggle"
            elseif targetMobKey == "Farm" then targetMobKey = "AutoFarmPlayer" end
            if GlobalMobileButtons[targetMobKey] then GlobalMobileButtons[targetMobKey].Btn.Visible = Config[Key] end
        end
    end)

    local function ExternalUIRefresh()
        Pill.BackgroundColor3 = Config[Key] and Style_Accent or Style_Inactive
        Ball.Position = Config[Key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        if BindKey then BindBtn.Text = "[" .. Config[Key .. "Keybind"].Name .. "]" end
    end
    table.insert(UI_Refresh_Functions, ExternalUIRefresh)
    Page.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 40)
end

local function AddPremiumSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.Size = UDim2.new(1, -5, 0, 45); SFrame.BackgroundColor3 = Style_SubBg
    Instance.new("UICorner", SFrame).CornerRadius = Style_CornerRadius
    Instance.new("UIStroke", SFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", SFrame)
    Lbl.Position = UDim2.new(0, 10, 0, 3); Lbl.Size = UDim2.new(1, -80, 0, 20)
    Lbl.Font = Enum.Font.GothamMedium; Lbl.Text = LabelText; Lbl.TextColor3 = Style_Text_Primary; Lbl.TextSize = 13; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", SFrame)
    ValLbl.Position = UDim2.new(1, -75, 0, 3); ValLbl.Size = UDim2.new(0, 65, 0, 20)
    ValLbl.Font = Enum.Font.GothamBold; ValLbl.Text = tostring(Config[Key]); ValLbl.TextColor3 = Style_Accent; ValLbl.TextSize = 13; ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBar = Instance.new("TextButton", SFrame)
    SliderBar.Position = UDim2.new(0, 10, 0, 26); SliderBar.Size = UDim2.new(1, -20, 0, 6); SliderBar.Text = ""
    SliderBar.BackgroundColor3 = Style_Inactive
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local SliderFill = Instance.new("Frame", SliderBar)
    SliderFill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0); SliderFill.BackgroundColor3 = Style_Accent
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

    local function UpdateSliderInput(input)
        local pct = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(pct, 0, 1, 0)
        local val = math.floor(Min + (pct * (Max - Min)))
        Config[Key] = val; ValLbl.Text = tostring(val)
        if Callback then Callback(val) end
    end

    local SlideActive = false
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SlideActive = true UpdateSliderInput(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if SlideActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSliderInput(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SlideActive = false end
    end)

    local function SliderRefresh()
        ValLbl.Text = tostring(Config[Key])
        SliderFill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
    end
    table.insert(UI_Refresh_Functions, SliderRefresh)
end

local function AddPremiumDropdown(Page, LabelText, Options, Key, Callback)
    local DFrame = Instance.new("Frame", Page)
    DFrame.Size = UDim2.new(1, -5, 0, 38); DFrame.BackgroundColor3 = Style_SubBg; DFrame.ClipsDescendants = true
    Instance.new("UICorner", DFrame).CornerRadius = Style_CornerRadius
    local DStroke = Instance.new("UIStroke", DFrame); DStroke.Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", DFrame)
    Lbl.Position = UDim2.new(0, 10, 0, 0); Lbl.Size = UDim2.new(1, -150, 0, 38)
    Lbl.Font = Enum.Font.GothamMedium; Lbl.Text = LabelText; Lbl.TextColor3 = Style_Text_Primary; Lbl.TextSize = 13; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local MainBtn = Instance.new("TextButton", DFrame)
    MainBtn.Position = UDim2.new(1, -135, 0, 8); MainBtn.Size = UDim2.new(0, 125, 0, 22)
    MainBtn.BackgroundColor3 = Style_Inactive; MainBtn.Font = Enum.Font.GothamMedium; MainBtn.Text = tostring(Config[Key]) .. "  ▼"; MainBtn.TextColor3 = Style_Text_Primary; MainBtn.TextSize = 11
    Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 4)

    local OptContainer = Instance.new("Frame", DFrame)
    OptContainer.Position = UDim2.new(0, 0, 0, 38); OptContainer.Size = UDim2.new(1, 0, 0, #Options * 24); OptContainer.BackgroundTransparency = 1
    local OList = Instance.new("UIListLayout", OptContainer); OList.SortOrder = Enum.SortOrder.LayoutOrder

    local Expanded = false
    for idx, opt in pairs(Options) do
        local OBtn = Instance.new("TextButton", OptContainer)
        OBtn.Size = UDim2.new(1, 0, 0, 24); OBtn.BackgroundTransparency = 1; OBtn.Font = Enum.Font.Gotham; OBtn.Text = tostring(opt); OBtn.TextColor3 = Style_Text_Secondary; OBtn.TextSize = 12
        RegisterTouchFriendlyClick(OBtn, function()
            Config[Key] = opt; MainBtn.Text = tostring(opt) .. "  ▼"; Expanded = false
            DFrame.Size = UDim2.new(1, -5, 0, 38); DStroke.Color = Color3.fromRGB(35, 37, 40)
            if Callback then Callback(opt) end
        end)
    end

    RegisterTouchFriendlyClick(MainBtn, function()
        Expanded = not Expanded
        if Expanded then
            DFrame.Size = UDim2.new(1, -5, 0, 38 + (#Options * 24)); DStroke.Color = Style_Accent
        else
            DFrame.Size = UDim2.new(1, -5, 0, 38); DStroke.Color = Color3.fromRGB(35, 37, 40)
        end
    end)

    local function DropdownRefresh() MainBtn.Text = tostring(Config[Key]) .. "  ▼" end
    table.insert(UI_Refresh_Functions, DropdownRefresh)
end

-- ==============================================================================
-- ADD PAGE CONTENT ITEMS
-- ==============================================================================
-- Combat Page Toggles
AddPremiumToggle(CombatPage, "Enable Engine Aimbot", "Aimbot", nil, nil, true)
AddPremiumToggle(CombatPage, "Active Engine Kill Aura", "Aura", nil, nil, true)
AddPremiumToggle(CombatPage, "Instant Triggerbot Fire", "Triggerbot", nil, nil, true)
AddPremiumToggle(CombatPage, "Enable Spinbot Rotation", "Spinbot", nil, nil, true)
AddPremiumSlider(CombatPage, "Spinbot Rotation Velocity Speed", 5, 100, "SpinSpeed", nil)

-- Player Target Page Controls
AddPremiumDropdown(PlayerPage, "Selected Hitbox Frame Target", {"Head", "Torso", "Legs"}, "TargetPart", nil)
AddPremiumToggle(PlayerPage, "Enforce Strict Team Check Filtering", "TeamCheck", nil, nil, false)
AddPremiumToggle(PlayerPage, "Enforce Raycast Wall Occlusion", "WallCheck", nil, nil, false)
AddPremiumToggle(PlayerPage, "Prioritize Minimum Health Targets", "PriorityLowestHealth", nil, nil, false)
AddPremiumSlider(PlayerPage, "Smooth Interpolation Friction", 1, 30, "Smoothness", nil)
AddPremiumSlider(PlayerPage, "Kill Aura Physical Radius Zone", 10, 150, "AuraRadius", function(v) AuraVisual.Radius = v end)

-- Movement Page Controls
AddPremiumToggle(MovementPage, "Modify Default WalkSpeed Asset", "SpeedToggle", nil, nil, true)
AddPremiumSlider(MovementPage, "Custom Configuration WalkSpeed", 16, 250, "WalkSpeed", nil)
AddPremiumToggle(MovementPage, "Modify Default JumpPower Asset", "JumpToggle", nil, nil, true)
AddPremiumSlider(MovementPage, "Custom Configuration JumpPower", 50, 500, "JumpPower", nil)
AddPremiumToggle(MovementPage, "Enable Flight Engine Simulator", "Fly", function(state) ToggleFlyState(state) end, nil, true)
AddPremiumSlider(MovementPage, "Flight Vector Movement Velocity Speed", 10, 300, "FlySpeed", nil)

-- Visual / ESP Page Controls
AddPremiumToggle(VisualPage, "Master Diagnostic Overlay", "EspMaster", nil, nil, true)
AddPremiumToggle(VisualPage, "Filter Teammate Vector Visuals", "EspTeamCheck", nil, nil, false)
AddPremiumToggle(VisualPage, "Draw Precise 2D Alignment Box", "EspBox", nil, nil, false)
AddPremiumToggle(VisualPage, "Draw Vector Direction Tracer Line", "EspTracer", nil, nil, false)
AddPremiumDropdown(VisualPage, "Tracer Root Position Anchor", {"Bottom", "Center"}, "TracerMode", nil)
AddPremiumToggle(VisualPage, "Display Identity Strings Label", "EspName", nil, nil, false)
AddPremiumToggle(VisualPage, "Display Realtime Numerical Health", "EspHealth", nil, nil, false)
AddPremiumToggle(VisualPage, "Draw Aimbot Dynamic FOV Circle", "FovCircle", nil, nil, false)
AddPremiumSlider(VisualPage, "Aimbot FOV Boundary Radius Scale", 30, 800, "FovRadius", function(v) FOV_Drawing.Radius = v end)
AddPremiumToggle(VisualPage, "Draw Desktop Crosshair Dot", "CrosshairDot", nil, nil, false)
AddPremiumToggle(VisualPage, "Force Atmospheric Maximum Brightness", "FullBright", nil, nil, false)

-- Misc / System Management Page
AddPremiumToggle(MiscPage, "Loop Automatic Backup Farm Core", "AutoFarmPlayer", nil, nil, false)
AddPremiumToggle(MiscPage, "Active Character AntiAFK Heartbeat", "AntiAFK", nil, nil, false)
AddPremiumToggle(MiscPage, "Force Permanent ThirdPerson Camera", "ThirdPerson", nil, nil, false)
AddPremiumToggle(MiscPage, "Lock Overlay Touch Button Drag", "LockMobileButtons", nil, nil, false)

local MobileLayoutSubFrame = Instance.new("Frame", MiscPage)
MobileLayoutSubFrame.Size = UDim2.new(1, -5, 0, 180); MobileLayoutSubFrame.BackgroundColor3 = Style_SubBg
Instance.new("UICorner", MobileLayoutSubFrame).CornerRadius = Style_CornerRadius
local MobileLayoutSubFrameList = Instance.new("UIListLayout", MobileLayoutSubFrame); MobileLayoutSubFrameList.SortOrder = Enum.SortOrder.LayoutOrder

AddPremiumToggle(MobileLayoutSubFrame, "Display Touch Overlay Aimbot Trigger", "ShowMobileAim", nil, nil, false)
AddPremiumToggle(MobileLayoutSubFrame, "Display Touch Overlay Triggerbot Trigger", "ShowMobileTrig", nil, nil, false)
AddPremiumToggle(MobileLayoutSubFrame, "Display Touch Overlay Walkspeed Trigger", "ShowMobileSpeed", nil, nil, false)
AddPremiumToggle(MobileLayoutSubFrame, "Display Touch Overlay Autofarm Trigger", "ShowMobileFarm", nil, nil, false)
AddPremiumToggle(MobileLayoutSubFrame, "Display Touch Overlay KillAura Trigger", "ShowMobileAura", nil, nil, false)

-- Save/Load Config Section Frame Container
local HexConfigBoxFrame = Instance.new("Frame", MiscPage)
HexConfigBoxFrame.Size = UDim2.new(1, -5, 0, 70); HexConfigBoxFrame.BackgroundColor3 = Style_SubBg
Instance.new("UICorner", HexConfigBoxFrame).CornerRadius = Style_CornerRadius

local HexBoxTextBox = Instance.new("TextBox", HexConfigBoxFrame)
HexBoxTextBox.Position = UDim2.new(0, 10, 0, 10); HexBoxTextBox.Size = UDim2.new(1, -20, 0, 24)
HexBoxTextBox.BackgroundColor3 = Style_Inactive; HexBoxTextBox.Font = Enum.Font.Gotham; HexBoxTextBox.Text = ""
HexBoxTextBox.PlaceholderText = "Paste configuration Hex string token key here..."; HexBoxTextBox.TextColor3 = Style_Text_Primary; HexBoxTextBox.TextSize = 11; HexBoxTextBox.ClearTextOnFocus = false
Instance.new("UICorner", HexBoxTextBox).CornerRadius = UDim.new(0, 4)

local ExportBtn = Instance.new("TextButton", HexConfigBoxFrame)
ExportBtn.Position = UDim2.new(0, 10, 0, 40); ExportBtn.Size = UDim2.new(0.5, -15, 0, 24)
ExportBtn.BackgroundColor3 = Style_Accent; ExportBtn.Font = Enum.Font.GothamBold; ExportBtn.Text = "EXPORT CODE"; ExportBtn.TextColor3 = Style_Text_Primary; ExportBtn.TextSize = 11
Instance.new("UICorner", ExportBtn).CornerRadius = UDim.new(0, 4)

local ImportBtn = Instance.new("TextButton", HexConfigBoxFrame)
ImportBtn.Position = UDim2.new(0.5, 5, 0, 40); ImportBtn.Size = UDim2.new(0.5, -15, 0, 24)
ImportBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 75); ImportBtn.Font = Enum.Font.GothamBold; ImportBtn.Text = "IMPORT CODE"; ImportBtn.TextColor3 = Style_Text_Primary; ImportBtn.TextSize = 11
Instance.new("UICorner", ImportBtn).CornerRadius = UDim.new(0, 4)

RegisterTouchFriendlyClick(ExportBtn, function()
    local token = ExportSettings()
    HexBoxTextBox.Text = token
    pcall(function()
        if setclipboard then setclipboard(token)
        elseif toclipboard then toclipboard(token) end
        StarterGui:SetCore("SendNotification", {Title = "WANGCAOS FRAMEWORK", Text = "Configuration token copied successfully!", Duration = 3})
    end)
end)

RegisterTouchFriendlyClick(ImportBtn, function()
    local str = HexBoxTextBox.Text
    if #str > 0 then
        local ok = ImportSettings(str)
        if ok then StarterGui:SetCore("SendNotification", {Title = "WANGCAOS FRAMEWORK", Text = "Configuration token applied successfully!", Duration = 3})
        else StarterGui:SetCore("SendNotification", {Title = "WANGCAOS FRAMEWORK", Text = "Invalid hex string token pattern verification failed!", Duration = 3}) end
    end
end)

-- Credits Information Panel Page
local function AddCreditsRow(Text, ColorValue)
    local CLabel = Instance.new("TextLabel", CreditsPage)
    CLabel.Size = UDim2.new(1, 0, 0, 22); CLabel.BackgroundTransparency = 1
    CLabel.Font = Enum.Font.GothamBold; CLabel.Text = Text; CLabel.TextColor3 = ColorValue; CLabel.TextSize = 13; CLabel.TextXAlignment = Enum.TextXAlignment.Left
end
AddCreditsRow("WANGCAOS PREMIUM ENGINE MODULE FRAMEWORK", Style_Text_Primary)
AddCreditsRow("Core Developer Author: BE CREATED FOR DAI CA WANG (2026)", Style_Text_Secondary)
AddCreditsRow("UI Architecture Theme: Minimalism / Matte Dark / Figma Blur", Style_Text_Secondary)
AddCreditsRow("Target System: Cross-Platform Universal Architecture Optimization", Style_Text_Secondary)
AddCreditsRow("Active License Verification: Premium VIP Corporate Access Granted", Style_Accent)

-- ==============================================================================
-- MOBILE TOUCH LOGIC FUNCTION SYNCS
-- ==============================================================================
local function RegisterMobileClick(Btn, Key)
    RegisterTouchFriendlyClick(Btn, function()
        Config[Key] = not Config[Key]
        UpdateToggleVisual(Key)
        if Key == "Fly" then ToggleFlyState(Config.Fly) end
    end)
end
RegisterMobileClick(MobAim, "Aimbot"); RegisterMobileClick(MobTrig, "Triggerbot"); RegisterMobileClick(MobSpeed, "SpeedToggle")
RegisterMobileClick(MobFarm, "AutoFarmPlayer"); RegisterMobileClick(MobAura, "Aura"); RegisterMobileClick(MobTP, "ThirdPerson"); RegisterMobileClick(MobFly, "Fly")

RegisterTouchFriendlyClick(ToggleButton, function()
    Config.MenuVisible = not Config.MenuVisible; MainFrame.Visible = Config.MenuVisible
end)

-- ==============================================================================
-- RUNTIME TICK ENGINE CORE LOOPS
-- ==============================================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.MenuKeybind then
        Config.MenuVisible = not Config.MenuVisible; MainFrame.Visible = Config.MenuVisible
    elseif input.KeyCode == Config.AimbotKeybind and Config.AimbotKeybind ~= Enum.KeyCode.Unknown then
        Config.Aimbot = not Config.Aimbot; UpdateToggleVisual("Aimbot")
    elseif input.KeyCode == Config.AuraKeybind and Config.AuraKeybind ~= Enum.KeyCode.Unknown then
        Config.Aura = not Config.Aura; UpdateToggleVisual("Aura")
    elseif input.KeyCode == Config.TriggerbotKeybind and Config.TriggerbotKeybind ~= Enum.KeyCode.Unknown then
        Config.Triggerbot = not Config.Triggerbot; UpdateToggleVisual("Triggerbot")
    elseif input.KeyCode == Config.SpinbotKeybind and Config.SpinbotKeybind ~= Enum.KeyCode.Unknown then
        Config.Spinbot = not Config.Spinbot; UpdateToggleVisual("Spinbot")
    elseif input.KeyCode == Config.SpeedKeybind and Config.SpeedKeybind ~= Enum.KeyCode.Unknown then
        Config.SpeedToggle = not Config.SpeedToggle; UpdateToggleVisual("SpeedToggle")
    elseif input.KeyCode == Config.JumpKeybind and Config.JumpKeybind ~= Enum.KeyCode.Unknown then
        Config.JumpToggle = not Config.JumpToggle; UpdateToggleVisual("JumpToggle")
    elseif input.KeyCode == Config.FlyKeybind and Config.FlyKeybind ~= Enum.KeyCode.Unknown then
        Config.Fly = not Config.Fly; UpdateToggleVisual("Fly"); ToggleFlyState(Config.Fly)
    elseif input.KeyCode == Config.EspMasterKeybind and Config.EspMasterKeybind ~= Enum.KeyCode.Unknown then
        Config.EspMaster = not Config.EspMaster; UpdateToggleVisual("EspMaster")
    end
end)

MasterLoop = RunService.RenderStepped:Connect(function()
    -- Crosshair Dot Drawing Logic
    if Config.CrosshairDot then
        Dot_Drawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); Dot_Drawing.Visible = true
    else Dot_Drawing.Visible = false end

    -- FOV Drawing Logic
    if Config.FovCircle then
        FOV_Drawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOV_Drawing.Radius = Config.FovRadius; FOV_Drawing.Color = Config.FovColor; FOV_Drawing.Visible = true
    else FOV_Drawing.Visible = false end

    -- Kill Aura Visual Positioning Zone Logic
    local MyChar = LocalPlayer.Character; local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if Config.Aura and MyRoot and IsAlive(MyChar) then
        AuraVisual.Parent = MyRoot; AuraVisual.Radius = Config.AuraRadius; AuraVisual.CFrame = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
        AuraVisual.Color3 = Config.AuraColor; AuraVisual.Transparency = Config.AuraTransparency / 100; AuraVisual.Visible = true
    else AuraVisual.Visible = false end

    -- FullBright Logic Control Sync
    if Config.FullBright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Config.StoredAmbient; Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    end

    -- ThirdPerson Logic Camera Control Override
    if Config.ThirdPerson then LocalPlayer.CameraMaxZoomDistance = Config.ThirdPersonDist; LocalPlayer.CameraMinZoomDistance = Config.ThirdPersonDist
    else LocalPlayer.CameraMaxZoomDistance = 400; LocalPlayer.CameraMinZoomDistance = 0.5 end

    -- Core ESP Graphics Render Loop Matrix
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    for _, Player in pairs(Players:GetPlayers()) do
        local Char = Player.Character
        if Player ~= LocalPlayer and Char and Config.EspMaster and IsAlive(Char) then
            if Config.EspTeamCheck and IsTeammate(Player) then
                CleanCharacterVisuals(Char); local Tracer = Tracer_Cache[Player]; if Tracer then Tracer.Visible = false end continue
            end
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            if Root and Hum then
                local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                local Dist = (Camera.CFrame.Position - Root.Position).Magnitude
                if OnScreen and Dist <= Config.MaxDistance then
                    local PColor = GetPlayerColor(Player)
                    
                    -- Dynamic Dimensions Setup for 2D Box
                    local SizeY = (Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3.5, 0)).Y - Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 4.5, 0)).Y)
                    local SizeX = SizeY * 0.55
                    local BPosX = Pos.X - (SizeX / 2)
                    local BPosY = Pos.Y - (SizeY / 2)

                    -- 2D Box Visual Logic Integration
                    local BoxFill = Char:FindFirstChild("WangBoxFill")
                    if Config.EspBox then
                        if not BoxFill then
                            local BF = Instance.new("ScreenGui"); BF.Name = "WangBoxFill"; BF.Parent = SafeParent; Instance.new("Frame", BF).Name = "BoxFrame"
                            local Strk = Instance.new("UIStroke", BF.BoxFrame); Strk.Thickness = 1.5; BF.BoxFrame.BackgroundTransparency = 1
                            BoxFill = BF
                        end
                        local Frame = BoxFill:FindFirstChild("BoxFrame")
                        if Frame then
                            Frame.Position = UDim2.new(0, BPosX, 0, BPosY); Frame.Size = UDim2.new(0, SizeX, 0, SizeY)
                            Frame.UIStroke.Color = PColor; Frame.UIStroke.Transparency = (100 - Config.EspTransparency) / 100; BoxFill.Enabled = true
                        end
                    else if BoxFill then BoxFill:Destroy() end end

                    -- Text & Tag Metadata Rendering
                    local InfoTag = Char:FindFirstChild("WangInfoTag")
                    if Config.EspName or Config.EspHealth then
                        if not InfoTag then
                            local IT = Instance.new("ScreenGui"); IT.Name = "WangInfoTag"; IT.Parent = SafeParent
                            local TL = Instance.new("TextLabel", IT); TL.Name = "TagLabel"; TL.BackgroundTransparency = 1
                            TL.Font = Enum.Font.GothamBold; TL.TextColor3 = Color3.fromRGB(255, 255, 255); TL.TextSize = 11
                            local TS = Instance.new("UIStroke", TL); TS.Color = Color3.fromRGB(0, 0, 0); TS.Thickness = 1.5
                            InfoTag = IT
                        end
                        local Label = InfoTag:FindFirstChild("TagLabel")
                        if Label then
                            local buildStr = ""
                            if Config.EspName then buildStr = Player.Name .. " [" .. math.floor(Dist) .. "m]" end
                            if Config.EspHealth then
                                local healthSuffix = " [HP: " .. math.floor(Hum.Health) .. "/" .. math.floor(Hum.MaxHealth) .. "]"
                                buildStr = buildStr .. healthSuffix
                            end
                            Label.Text = buildStr; Label.TextColor3 = PColor
                            Label.Position = UDim2.new(0, BPosX, 0, BPosY - 16); Label.Size = UDim2.new(0, SizeX, 0, 14); InfoTag.Enabled = true
                        end
                    else if InfoTag then InfoTag:Destroy() end end

                    -- Directional Tracer Rendering
                    local Tracer = Tracer_Cache[Player]
                    if Tracer and Config.EspTracer then
                        local Leg, IsTracerOnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                        if IsTracerOnScreen then
                            Tracer.From = Config.TracerMode == "Center" and ScreenCenter or ScreenBottom
                            Tracer.To = Vector2.new(Leg.X, Leg.Y); Tracer.Color = PColor; Tracer.Visible = true
                        else Tracer.Visible = false end
                    elseif Tracer then Tracer.Visible = false end
                else
                    CleanCharacterVisuals(Char); local Tracer = Tracer_Cache[Player]; if Tracer then Tracer.Visible = false end
                end
            else
                CleanCharacterVisuals(Char); local Tracer = Tracer_Cache[Player]; if Tracer then Tracer.Visible = false end
            end
        else
            CleanCharacterVisuals(Char); if Character_Cache[Char] then Character_Cache[Char] = nil end
            local Tracer = Tracer_Cache[Player]; if Tracer then Tracer.Visible = false end
        end
    end
end)

-- Gameplay Framework Processing Execution Heartbeat Loop
RunService.Heartbeat:Connect(function()
    local MyChar = LocalPlayer.Character; local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    local Hum = MyChar and MyChar:FindFirstChildOfClass("Humanoid")

    -- Humanoid State Asset Modifications Sync
    if IsAlive(MyChar) and Hum then
        if Config.SpeedToggle then Hum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpToggle then Hum.JumpPower = Config.JumpPower end
    end

    -- Flight Control Handling Positioning Logic Vector Mapping
    if Config.Fly and MyRoot and IsAlive(MyChar) then
        local targetVelocity = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then targetVelocity = targetVelocity + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then targetVelocity = targetVelocity - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then targetVelocity = targetVelocity - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then targetVelocity = targetVelocity + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then targetVelocity = targetVelocity + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then targetVelocity = targetVelocity - Vector3.new(0, 1, 0) end
        
        if flyBodyVelocity and flyBodyGyro then
            flyBodyVelocity.Velocity = targetVelocity.Unit * Config.FlySpeed
            if targetVelocity == Vector3.new(0, 0, 0) then flyBodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            flyBodyGyro.CFrame = Camera.CFrame
        end
    end

    -- Spinbot Angle Rotation Tracking Logic
    if Config.Spinbot and MyRoot and IsAlive(MyChar) then
        CurrentSpinAngle = (CurrentSpinAngle + Config.SpinSpeed) % 360
        MyRoot.CFrame = MyRoot.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
    end

    -- Engine Aimbot Framework Core Lock Focus Target Mapping Execution
    if Config.Aimbot then
        local TargetPart = GetClosestPlayerToCrosshair()
        if TargetPart then
            local NextFrameCFrame = CFrame.new(Camera.CFrame.Position, TargetPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(NextFrameCFrame, 1 / Config.Smoothness)
        end
    end

    -- Kill Aura Core Execution Event Processing Connection Trigger
    if Config.Aura then
        local AuraTargetPart = GetAuraTarget()
        if AuraTargetPart then pcall(function() mouse1click() end) end
    end

    -- Triggerbot Validation Trigger Loop execution
    if Config.Triggerbot then PerformTriggerbotClick() end

    -- Autofarm Heartbeat Loop Thread Handler
    ProcessAutoFarmPlayer()
end)

-- AntiAFK Engine Core Signal Simulator Prevent Disconnect
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame) end
    end)
end)

-- Connect Runtime Global System Listeners Management
Players.PlayerAdded:Connect(function(Player) CreateTracerObject(Player) end)
Players.PlayerRemoving:Connect(function(Player) ClearTracerObject(Player) end)
for _, P in pairs(Players:GetPlayers()) do CreateTracerObject(P) end
for K, _ in pairs(GlobalSyncToggles) do UpdateToggleVisual(K) end

pcall(function()
    StarterGui:SetCore("SendNotification", {Title = "WANGCAOS CLIENT V6.9.4", Text = "Loaded Modern Vertical Sidebar UI Framework successfully!", Duration = 5})
end)
-- ==============================================================================
-- END OF SCRIPT - MODERN CONSOLIDATED VERSION (100% COMPLETE NO MISSING SEMICOLON)
-- ==============================================================================
