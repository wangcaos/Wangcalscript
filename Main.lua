-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V6.9.6 - SUPER FIXED
-- ALL RIGHTS RESERVED BY DAI CA WANG (2026)
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

local IntroScreen = Instance.new("ScreenGui")
IntroScreen.Name = "WangcaosIntro"
IntroScreen.Parent = SafeParent
IntroScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local IntroFrame = Instance.new("Frame", IntroScreen)
IntroFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 17)
IntroFrame.BackgroundTransparency = 0.1
IntroFrame.BorderSizePixel = 0
IntroFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
IntroFrame.Size = UDim2.new(0, 350, 0, 150)
Instance.new("UICorner", IntroFrame).CornerRadius = UDim.new(0, 10)
local IntroStroke = Instance.new("UIStroke", IntroFrame)
IntroStroke.Color = Color3.fromRGB(0, 255, 255)
IntroStroke.Thickness = 2

local IntroTitle = Instance.new("TextLabel", IntroFrame)
IntroTitle.BackgroundTransparency = 1
IntroTitle.Size = UDim2.new(1, 0, 0, 50)
IntroTitle.Position = UDim2.new(0, 0, 0, 15)
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.Text = "WANGCAOS PREMIUM V6.9.6"
IntroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroTitle.TextSize = 18

local IntroDisc = Instance.new("TextLabel", IntroFrame)
IntroDisc.BackgroundTransparency = 1
IntroDisc.Size = UDim2.new(1, 0, 0, 30)
IntroDisc.Position = UDim2.new(0, 0, 0, 60)
IntroDisc.Font = Enum.Font.GothamBold
IntroDisc.Text = "Discord: Https://discord.gg/GkAKn4zzH"
IntroDisc.TextColor3 = Color3.fromRGB(0, 255, 255)
IntroDisc.TextSize = 14

local IntroSub = Instance.new("TextLabel", IntroFrame)
IntroSub.BackgroundTransparency = 1
IntroSub.Size = UDim2.new(1, 0, 0, 30)
IntroSub.Position = UDim2.new(0, 0, 0, 95)
IntroSub.Font = Enum.Font.Gotham
IntroSub.Text = "Loading Framework Modules..."
IntroSub.TextColor3 = Color3.fromRGB(150, 150, 150)
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
FOV_Drawing.Color = Config.FovColor; FOV_Drawing.Thickness = Config.FovThickness; FOV_Drawing.NumSides = Config.FovSides
FOV_Drawing.Filled = Config.FovFilled; FOV_Drawing.Transparency = Config.FovTransparency; FOV_Drawing.Visible = false

local Dot_Drawing = Drawing.new("Circle")
Dot_Drawing.Color = Color3.fromRGB(255, 255, 255); Dot_Drawing.Thickness = 1; Dot_Drawing.Radius = 3
Dot_Drawing.NumSides = 16; Dot_Drawing.Filled = true; Dot_Drawing.Transparency = 1; Dot_Drawing.Visible = false

local AuraVisual = Instance.new("CylinderHandleAdornment")
AuraVisual.Name = "WangAuraCircle"; AuraVisual.AlwaysOnTop = false; AuraVisual.ZIndex = 5

local Tracer_Cache = {}
local Character_Cache = {}
local NeckCache = {}

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
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
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
    local EnemyRoot = ActiveTargetData.Root; local EnemyHead = ActiveTargetData.Head
    
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
    local dragging = false; local dragInput, mousePos, framePos

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
    
    if not Config["MobilePos_"..Key.."_XS"] then Config["MobilePos_"..Key.."_XS"] = xs; Config["MobilePos_"..Key.."_XO"] = xo; Config["MobilePos_"..Key.."_YS"] = ys; Config["MobilePos_"..Key.."_YO"] = yo end

    local ShortcutBtn = Instance.new("TextButton")
    ShortcutBtn.Name = "IndependentMobile_" .. Key
    ShortcutBtn.Parent = ScreenGui; ShortcutBtn.BackgroundColor3 = DefaultColor; ShortcutBtn.BackgroundTransparency = 0.2
    ShortcutBtn.Position = UDim2.new(xs, xo, ys, yo); ShortcutBtn.Size = UDim2.new(0, 52, 0, 52)
    ShortcutBtn.Font = Enum.Font.GothamBold; ShortcutBtn.Text = TextOff; ShortcutBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ShortcutBtn.TextSize = 9
    ShortcutBtn.Visible = (Config[ShowKey] and IsMobile)
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn)
    Stroke.Color = Color3.fromRGB(255, 255, 255); Stroke.Thickness = 1.5
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

local lxs = Config["MobilePos_MainLogo_XS"] or 0
local lxo = Config["MobilePos_MainLogo_XO"] or 20
local lys = Config["MobilePos_MainLogo_YS"] or 0
local lyo = Config["MobilePos_MainLogo_YO"] or 20
if not Config["MobilePos_MainLogo_XS"] then Config["MobilePos_MainLogo_XS"] = lxs Config["MobilePos_MainLogo_XO"] = lxo Config["MobilePos_MainLogo_YS"] = lys Config["MobilePos_MainLogo_YO"] = lyo end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "PremiumToggleLogo"
ToggleButton.Parent = ScreenGui; ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Position = UDim2.new(lxs, lxo, lys, lyo); ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold; ToggleButton.Text = "W"; ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(60, 60, 60); Instance.new("UIStroke", ToggleButton).Thickness = 1.5

ToggleButton.Visible = IsMobile
GlobalMobileButtons["MainLogo"] = { Btn = ToggleButton }
MakeDraggable(ToggleButton, ToggleButton, "MainLogo")
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 17)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -120)
MainFrame.Size = UDim2.new(0, 380, 0, 240) 
MainFrame.ClipsDescendants = true
MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
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
Instance.new("UICorner", CustomBackgroundImage).CornerRadius = UDim.new(0, 8)

local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Parent = MainFrame
SettingsPanel.Position = UDim2.new(0, 0, 0, 0)
SettingsPanel.Size = UDim2.new(1, 0, 1, 0)
SettingsPanel.BackgroundTransparency = 1

local TopNavBar = Instance.new("Frame")
TopNavBar.Parent = SettingsPanel
TopNavBar.BackgroundColor3 = Color3.fromRGB(23, 24, 26)
TopNavBar.BackgroundTransparency = 0.3
TopNavBar.Position = UDim2.new(0, 6, 0, 6)
TopNavBar.Size = UDim2.new(1, -12, 0, 36)
TopNavBar.ZIndex = 2
Instance.new("UICorner", TopNavBar).CornerRadius = UDim.new(0, 6)

local TabMenuContainer = Instance.new("Frame")
TabMenuContainer.Parent = TopNavBar
TabMenuContainer.BackgroundTransparency = 1
TabMenuContainer.Size = UDim2.new(1, -35, 1, 0)
local TabLayout = Instance.new("UIListLayout", TabMenuContainer)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
local TabPad = Instance.new("UIPadding", TabMenuContainer)
TabPad.PaddingLeft = UDim.new(0, 4)
TabPad.PaddingTop = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopNavBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 153, 158)
CloseBtn.TextSize = 20

MakeDraggable(MainFrame, TopNavBar, nil) 
RegisterTouchFriendlyClick(CloseBtn, function() Config.MenuVisible = false MainFrame.Visible = false end)
RegisterTouchFriendlyClick(ToggleButton, function() Config.MenuVisible = not Config.MenuVisible MainFrame.Visible = Config.MenuVisible end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = SettingsPanel
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 6, 0, 48)
ContentContainer.Size = UDim2.new(1, -12, 1, -54)
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
    page.CanvasSize = UDim2.new(0, 0, 0, 650)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 62, 65)
    page.Visible = false
    local grid = Instance.new("UIGridLayout", page)
    grid.CellSize = UDim2.new(1, -6, 0, 36)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
end
CombatPage.Visible = true

local function CreatePremiumTab(Name, IconText, Order, TargetPage)
    local TabBtn = Instance.new("TextButton", TabMenuContainer)
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(32, 34, 37) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(0, 50, 0, 26)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = IconText
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 143, 148)
    TabBtn.TextSize = 12
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 5)
    local TStroke = Instance.new("UIStroke", TabBtn)
    TStroke.Color = Color3.fromRGB(55, 57, 61)
    TStroke.Enabled = Order == 1
    RegisterTouchFriendlyClick(TabBtn, function()
        for _, p in pairs({CombatPage, PlayerPage, MovementPage, VisualPage, MiscPage, CreditsPage}) do p.Visible = false end
        for _, btn in pairs(TabMenuContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0); btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(140, 143, 148); btn.UIStroke.Enabled = false
            end
        end
        TabBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37); TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255); TStroke.Enabled = true
        TargetPage.Visible = true
    end)
end

local function UpdateToggleVisual(Key)
    local TargetData = GlobalSyncToggles[Key]
    if not TargetData then return end
    local state = Config[Key]
    local Ball = TargetData.Ball; local SwitchBg = TargetData.SwitchBg
    TweenService:Create(Ball, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
    TweenService:Create(SwitchBg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(40, 42, 45)}):Play()
    if GlobalMobileButtons[Key] then
        local MData = GlobalMobileButtons[Key]
        MData.Btn.BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or TargetData.DefMobColor
        if Key == "Aimbot" then MData.Btn.Text = state and "AIM\nON" or "AIM\nOFF"
        elseif Key == "Triggerbot" then MData.Btn.Text = state and "TRIG\nON" or "TRIG\nOFF"
        elseif Key == "SpeedToggle" then MData.Btn.Text = state and "SPD\nON" or "SPD\nOFF"
        elseif Key == "AutoFarmPlayer" then MData.Btn.Text = state and "FRM\nON" or "FRM\nOFF"
        elseif Key == "Aura" then MData.Btn.Text = state and "AUR\nON" or "AUR\nOFF"
        elseif Key == "ThirdPerson" then MData.Btn.Text = state and "3RD\nON" or "3RD\nOFF"
        elseif Key == "Fly" then MData.Btn.Text = state and "FLY\nON" or "FLY\nOFF" end
    end
end
local RestrictedKeys = { ShowMobileTP = true, ShowMobileAura = true, ShowMobileAim = true, ShowMobileTrig = true, ShowMobileSpeed = true, ShowMobileFarm = true, ShowMobileFly = true }

local function AddPremiumToggle(Page, LabelText, Key, Callback, DefMobColor, BindKey)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)
    
    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
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
        if RestrictedKeys[Key] and not IsMobile then
            pcall(function() StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Button enable only for PE!", Duration = 3}) end)
            return
        end
        Config[Key] = not Config[Key] 
        UpdateToggleVisual(Key) 
        if Callback then Callback(Config[Key]) end 
    end)

    if BindKey then
        local BindBtn = Instance.new("TextButton", TFrame)
        BindBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
        BindBtn.Position = UDim2.new(1, -100, 0.5, -10)
        BindBtn.Size = UDim2.new(0, 45, 0, 20)
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE"
        BindBtn.TextColor3 = Color3.fromRGB(200, 205, 210)
        BindBtn.TextSize = 10
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", BindBtn).Color = Color3.fromRGB(55, 57, 60)

        local Listening = false; local ListenConnection
        local function EndListening(NewKey)
            Listening = false
            if ListenConnection then ListenConnection:Disconnect() end
            if NewKey then Config[BindKey] = NewKey BindBtn.Text = NewKey.Name:upper() else BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE" end
            BindBtn.TextColor3 = Color3.fromRGB(200, 205, 210)
        end
        RegisterTouchFriendlyClick(BindBtn, function()
            if Listening then return end
            Listening = true; BindBtn.Text = "..."; BindBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
            task.delay(5, function() if Listening then EndListening(nil) end end)
            ListenConnection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then EndListening(input.KeyCode) end
            end)
        end)
    end
    table.insert(UI_Refresh_Functions, function() UpdateToggleVisual(Key) end)
end

local function AddPremiumSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    SFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", SFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", SFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", SFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0.4, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(180, 183, 188)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Bar = Instance.new("Frame", SFrame)
    Bar.BackgroundColor3 = Color3.fromRGB(45, 47, 50)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.new(1, -160, 0.5, -2)
    Bar.Size = UDim2.new(0, 100, 0, 4)
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

    local ValTxt = Instance.new("TextLabel", SFrame)
    ValTxt.BackgroundTransparency = 1
    ValTxt.Position = UDim2.new(1, -50, 0, 0)
    ValTxt.Size = UDim2.new(0, 40, 1, 0)
    ValTxt.Font = Enum.Font.GothamBold
    ValTxt.Text = tostring(Config[Key])
    ValTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValTxt.TextSize = 11
    ValTxt.TextXAlignment = Enum.TextXAlignment.Right

    local Btn = Instance.new("TextButton", Bar)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.Text = ""

    local Dragging = false
    local function Update(inputPos)
        local mouseX = (inputPos and inputPos.X) or Mouse.X
        local ratio = math.clamp((mouseX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = Min + (Max - Min) * ratio
        if Max - Min > 10 then val = math.floor(val) else val = math.floor(val * 10) / 10 end
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        ValTxt.Text = tostring(val)
        Config[Key] = val
        if Callback then Callback(val) end
    end
    Btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true Update(input.Position) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input.Position) end end)
    
    table.insert(UI_Refresh_Functions, function()
        ValTxt.Text = tostring(Config[Key])
        Fill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
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
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ActionBtn = Instance.new("TextButton", BFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    ActionBtn.Position = UDim2.new(1, -95, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 85, 0, 24)
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
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Aimbot Target Hitbox"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local HitboxBtn = Instance.new("TextButton", HFrame)
    HitboxBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    HitboxBtn.Position = UDim2.new(1, -95, 0.5, -12)
    HitboxBtn.Size = UDim2.new(0, 85, 0, 24)
    HitboxBtn.Font = Enum.Font.GothamBold
    HitboxBtn.Text = Config.TargetPart:upper()
    HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    HitboxBtn.TextSize = 11
    Instance.new("UICorner", HitboxBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", HitboxBtn).Color = Color3.fromRGB(60, 62, 65)

    RegisterTouchFriendlyClick(HitboxBtn, function()
        if Config.TargetPart == "Head" then Config.TargetPart = "Torso" HitboxBtn.Text = "TORSO"
        elseif Config.TargetPart == "Torso" then Config.TargetPart = "Legs" HitboxBtn.Text = "LEGS"
        else Config.TargetPart = "Head" HitboxBtn.Text = "HEAD" end
    end)
    table.insert(UI_Refresh_Functions, function() HitboxBtn.Text = Config.TargetPart:upper() end)
end

local function AddSyncedEspColorSelector(Page)
    local CFrame = Instance.new("Frame", Page)
    CFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    CFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", CFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0.6, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "ESP & Tracer Color"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ColorBox = Instance.new("TextButton", CFrame)
    ColorBox.Name = "ColorBox"
    ColorBox.Position = UDim2.new(1, -35, 0.5, -9) 
    ColorBox.Size = UDim2.new(0, 25, 0, 18)
    ColorBox.BackgroundColor3 = Config.EspColor
    ColorBox.Text = ""
    Instance.new("UICorner", ColorBox).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", ColorBox).Color = Color3.fromRGB(55, 57, 60)

    local palette = {Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 200, 0), Color3.fromRGB(230, 30, 230), Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 255)}
    local colorIdx = 1
    RegisterTouchFriendlyClick(ColorBox, function()
        colorIdx = (colorIdx % #palette) + 1
        Config.EspColor = palette[colorIdx]
        ColorBox.BackgroundColor3 = Config.EspColor
    end)
    table.insert(UI_Refresh_Functions, function() ColorBox.BackgroundColor3 = Config.EspColor end)
end

local function AddAuraColorSelector(Page)
    local CFrame = Instance.new("Frame", Page)
    CFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    CFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", CFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(0.6, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Aura Circle Color"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ColorBox = Instance.new("TextButton", CFrame)
    ColorBox.Name = "ColorBox"
    ColorBox.Position = UDim2.new(1, -35, 0.5, -9)
    ColorBox.Size = UDim2.new(0, 25, 0, 18)
    ColorBox.BackgroundColor3 = Config.AuraColor
    ColorBox.Text = ""
    Instance.new("UICorner", ColorBox).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", ColorBox).Color = Color3.fromRGB(55, 57, 60)

    local palette = {Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 200, 0), Color3.fromRGB(230, 30, 230)}
    local colorIdx = 1
    RegisterTouchFriendlyClick(ColorBox, function()
        colorIdx = (colorIdx % #palette) + 1
        Config.AuraColor = palette[colorIdx]
        ColorBox.BackgroundColor3 = Config.AuraColor
    end)
    table.insert(UI_Refresh_Functions, function() ColorBox.BackgroundColor3 = Config.AuraColor end)
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
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Tracer Origin Mode"
    Lbl.TextColor3 = Color3.fromRGB(220, 223, 228)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ModeBtn = Instance.new("TextButton", MFrame)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    ModeBtn.Position = UDim2.new(1, -95, 0.5, -12)
    ModeBtn.Size = UDim2.new(0, 85, 0, 24)
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
    table.insert(UI_Refresh_Functions, function() ModeBtn.Text = Config.TracerMode:upper() end)
end
local function AddExportBox(Page)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -12)
    Box.Size = UDim2.new(1, -85, 0, 24)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Exported Code Here"
    Box.TextColor3 = Color3.fromRGB(200, 200, 200)
    Box.TextSize = 10
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(55, 57, 60)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 230)
    ActionBtn.Position = UDim2.new(1, -70, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 60, 0, 24)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = "EXPORT"
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

    RegisterTouchFriendlyClick(ActionBtn, function()
        local code = ExportSettings()
        Box.Text = code
        if setclipboard then
            setclipboard(code)
            StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Code copied to clipboard!", Duration = 3})
        else
            StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Please copy from the text box!", Duration = 3})
        end
    end)
end

local function AddImportBox(Page)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -12)
    Box.Size = UDim2.new(1, -85, 0, 24)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Paste Code Here"
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.TextSize = 10
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(55, 57, 60)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 75)
    ActionBtn.Position = UDim2.new(1, -70, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 60, 0, 24)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = "IMPORT"
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

    RegisterTouchFriendlyClick(ActionBtn, function()
        local code = Box.Text
        if code and code ~= "" then
            local success = ImportSettings(code)
            if success then
                StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Import Success! Interface updated.", Duration = 3})
                Box.Text = ""
            else
                StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Invalid Code!", Duration = 3})
            end
        end
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
    TitleLbl.TextSize = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local DescLbl = Instance.new("TextLabel", CFrame)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Position = UDim2.new(0, 10, 0, 20)
    DescLbl.Size = UDim2.new(1, -20, 0, 16)
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = Description
    DescLbl.TextColor3 = Color3.fromRGB(170, 175, 180)
    DescLbl.TextSize = 10
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
end
local function AddExportBox(Page)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -12)
    Box.Size = UDim2.new(1, -85, 0, 24)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Exported Code Here"
    Box.TextColor3 = Color3.fromRGB(200, 200, 200)
    Box.TextSize = 10
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(55, 57, 60)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 230)
    ActionBtn.Position = UDim2.new(1, -70, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 60, 0, 24)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = "EXPORT"
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

    RegisterTouchFriendlyClick(ActionBtn, function()
        local code = ExportSettings()
        Box.Text = code
        if setclipboard then
            setclipboard(code)
            StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Code copied to clipboard!", Duration = 3})
        else
            StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Please copy from the text box!", Duration = 3})
        end
    end)
end

local function AddImportBox(Page)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    TFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(35, 37, 40)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -12)
    Box.Size = UDim2.new(1, -85, 0, 24)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Paste Code Here"
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.TextSize = 10
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(55, 57, 60)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 75)
    ActionBtn.Position = UDim2.new(1, -70, 0.5, -12)
    ActionBtn.Size = UDim2.new(0, 60, 0, 24)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = "IMPORT"
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)

    RegisterTouchFriendlyClick(ActionBtn, function()
        local code = Box.Text
        if code and code ~= "" then
            local success = ImportSettings(code)
            if success then
                StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Import Success! Interface updated.", Duration = 3})
                Box.Text = ""
            else
                StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Invalid Code!", Duration = 3})
            end
        end
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
    TitleLbl.TextSize = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local DescLbl = Instance.new("TextLabel", CFrame)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Position = UDim2.new(0, 10, 0, 20)
    DescLbl.Size = UDim2.new(1, -20, 0, 16)
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = Description
    DescLbl.TextColor3 = Color3.fromRGB(170, 175, 180)
    DescLbl.TextSize = 10
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
end
AddPremiumToggle(CombatPage, "Enable Kill Aura", "Aura", nil, Color3.fromRGB(0, 150, 255), "AuraKeybind")
AddPremiumToggle(CombatPage, "Aura Team Guard", "TeamCheckAura")
AddPremiumToggle(CombatPage, "Aura Wall Occlusion", "AuraWallCheck")
AddPremiumSlider(CombatPage, "Aura Field Radius", 5, 150, "AuraRadius")
AddPremiumSlider(CombatPage, "Aura Smoothness Factor", 0, 10, "AuraSmoothness")
AddPremiumSlider(CombatPage, "Aura Transparency (%)", 0, 100, "AuraTransparency")
AddAuraColorSelector(CombatPage)
AddPremiumToggle(CombatPage, "Priority Lowest Health", "PriorityLowestHealth")

AddPremiumToggle(CombatPage, "Enable Aimbot Lock", "Aimbot", nil, Color3.fromRGB(255, 50, 50), "AimbotKeybind")
AddPremiumToggle(CombatPage, "Aimbot Team Guard", "TeamCheck")
AddPremiumToggle(CombatPage, "Aimbot Wall Occlusion", "WallCheck")
AddPremiumSlider(CombatPage, "Aimbot Smoothness Factor", 0, 10, "Smoothness")
AddHitboxSelector(CombatPage)
AddPremiumToggle(CombatPage, "Triggerbot Click Engine", "Triggerbot", nil, Color3.fromRGB(230, 125, 30), "TriggerbotKeybind")
AddPremiumToggle(CombatPage, "Triggerbot Wall Check", "TriggerWallCheck")

AddPremiumToggle(PlayerPage, "Enable Character Head Bow", "BowDown", nil, nil, nil)
AddPremiumSlider(PlayerPage, "Head Bow Angle Degree", 0, 90, "BowAngle")
AddPremiumToggle(PlayerPage, "Auto Farm Player (Behind)", "AutoFarmPlayer", nil, Color3.fromRGB(45, 140, 75))
AddPremiumSlider(PlayerPage, "Farm TP Intervallic Delay", 0.01, 5, "AutoFarmDelay")
AddPremiumToggle(PlayerPage, "FullBright Atmosphere", "FullBright", function(state)
    if state then Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else Lighting.Ambient = Config.StoredAmbient Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient end
end)
AddPremiumToggle(PlayerPage, "Enable Spinbot Axis", "Spinbot", nil, nil, "SpinbotKeybind")
AddPremiumSlider(PlayerPage, "Spinbot Rotate Velocity", 5, 100, "SpinSpeed")

AddPremiumToggle(MovementPage, "Enable Flight Hack", "Fly", ToggleFlyState, Color3.fromRGB(0, 255, 255), "FlyKeybind")
AddPremiumSlider(MovementPage, "Flight Speed Velocity", 10, 300, "FlySpeed")
AddPremiumToggle(MovementPage, "WalkSpeed Safe Bypass", "SpeedToggle", nil, Color3.fromRGB(140, 30, 230), "SpeedKeybind")
AddPremiumSlider(MovementPage, "Speed Core Value", 16, 200, "WalkSpeed")
AddPremiumToggle(MovementPage, "JumpPower Boost Axis", "JumpToggle", nil, nil, "JumpKeybind")
AddPremiumSlider(MovementPage, "Jump Force Magnitude", 50, 350, "JumpPower")

AddPremiumToggle(VisualPage, "Master ESP Overlay Control", "EspMaster", nil, Color3.fromRGB(30, 140, 230), "EspMasterKeybind")
AddPremiumToggle(VisualPage, "Highlight Team (Green)", "EspTeamCheck")
AddPremiumToggle(VisualPage, "Render 3D Chams Box", "EspBox")
AddPremiumSlider(VisualPage, "Chams Opacity Multiplier", 0, 100, "EspTransparency")
AddPremiumToggle(VisualPage, "Snapline Tracers Vector", "EspTracer")
AddTracerModeSelector(VisualPage)
AddSyncedEspColorSelector(VisualPage)
AddPremiumToggle(VisualPage, "Informative Character Tags", "EspName")
AddPremiumToggle(VisualPage, "Show Character Health Meter", "EspHealth") 
AddPremiumSlider(VisualPage, "Max Rendering Vector Range", 100, 5000, "MaxDistance")
AddPremiumToggle(MiscPage, "Force Third Person View", "ThirdPerson", nil, nil, nil)
AddPremiumSlider(MiscPage, "Third Person Distance", 5, 100, "ThirdPersonDist")
AddPremiumToggle(MiscPage, "Draw Dynamic FOV Circle", "FovCircle")
AddPremiumSlider(MiscPage, "FOV Perimeter Range", 30, 500, "FovRadius")
AddPremiumToggle(MiscPage, "Crosshair Center Alignment Dot", "CrosshairDot")
AddPremiumToggle(MiscPage, "Anti-AFK Auto Interactor", "AntiAFK", nil, Color3.fromRGB(210, 50, 140))
AddPremiumToggle(MiscPage, "Lock Mobile Buttons Position", "LockMobileButtons", nil, Color3.fromRGB(200, 50, 50))

AddExportBox(MiscPage)
AddImportBox(MiscPage)

AddPremiumToggle(MiscPage, "Display Mobile 3RD Button", "ShowMobileTP", function(state) GlobalMobileButtons["ThirdPerson"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Aura Trigger", "ShowMobileAura", function(state) GlobalMobileButtons["Aura"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Aim Trigger", "ShowMobileAim", function(state) GlobalMobileButtons["Aimbot"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Trigger Clicker", "ShowMobileTrig", function(state) GlobalMobileButtons["Triggerbot"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Speed Toggle", "ShowMobileSpeed", function(state) GlobalMobileButtons["SpeedToggle"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Farm Toggle", "ShowMobileFarm", function(state) GlobalMobileButtons["AutoFarmPlayer"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(MiscPage, "Display Mobile Fly Toggle", "ShowMobileFly", function(state) GlobalMobileButtons["Fly"].Btn.Visible = (state and IsMobile) end)

AddPremiumToggle(MiscPage, "Menu Modular Wallpaper", "CustomBackground", function(state) CustomBackgroundImage.Visible = state end)

AddPremiumButton(MiscPage, "Uninject Execution Process", "UNINJECT NOW", function()
    MasterLoop:Disconnect()
    pcall(function() FOV_Drawing:Remove() end)
    pcall(function() Dot_Drawing:Remove() end)
    pcall(function() AuraVisual:Remove() end)
    pcall(function() mouse1release() end)
    ToggleFlyState(false)
    for _, L in pairs(Tracer_Cache) do pcall(function() L:Remove() end) end
    for C, _ in pairs(Character_Cache) do CleanCharacterVisuals(C) end
    for neck, origC0 in pairs(NeckCache) do if neck and neck.Parent then pcall(function() neck.C0 = origC0 end) end end
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = 400
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

AddPremiumButton(MiscPage, "Join Community", "DISCORD", function()
    if setclipboard then setclipboard("Https://discord.gg/GkAKn4zzH") StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Copied Discord Link!", Duration = 3})
    else StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Https://discord.gg/GkAKn4zzH", Duration = 5}) end
end)

AddPremiumCreditBox(CreditsPage, "Lead Architecture Designer", "Dai Ca Wang (Wangcaos Client Proprietor)")
AddPremiumCreditBox(CreditsPage, "Framework Integrity Status", "Premium V6.9.6 - Mobile Fixed Edition")
AddPremiumCreditBox(CreditsPage, "Official Discord Community", "Https://discord.gg/GkAKn4zzH")

CreatePremiumTab("⚔", "Combat", 1, CombatPage)
CreatePremiumTab("👤", "Player", 2, PlayerPage)
CreatePremiumTab("🏃", "Move", 3, MovementPage)
CreatePremiumTab("👁", "Visual", 4, VisualPage)
CreatePremiumTab("⚙", "Misc", 5, MiscPage)
CreatePremiumTab("👑", "Credit", 6, CreditsPage)

local function RegisterMobileClick(Btn, Key)
    RegisterTouchFriendlyClick(Btn, function() Config[Key] = not Config[Key] UpdateToggleVisual(Key) if Key == "Fly" then ToggleFlyState(Config.Fly) end end)
end
RegisterMobileClick(MobAim, "Aimbot"); RegisterMobileClick(MobTrig, "Triggerbot"); RegisterMobileClick(MobSpeed, "SpeedToggle")
RegisterMobileClick(MobFarm, "AutoFarmPlayer"); RegisterMobileClick(MobAura, "Aura"); RegisterMobileClick(MobTP, "ThirdPerson"); RegisterMobileClick(MobFly, "Fly")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.MenuKeybind then Config.MenuVisible = not Config.MenuVisible MainFrame.Visible = Config.MenuVisible
    elseif input.KeyCode == Config.AimbotKeybind and Config.AimbotKeybind ~= Enum.KeyCode.Unknown then Config.Aimbot = not Config.Aimbot UpdateToggleVisual("Aimbot")
    elseif input.KeyCode == Config.AuraKeybind and Config.AuraKeybind ~= Enum.KeyCode.Unknown then Config.Aura = not Config.Aura UpdateToggleVisual("Aura")
    elseif input.KeyCode == Config.TriggerbotKeybind and Config.TriggerbotKeybind ~= Enum.KeyCode.Unknown then Config.Triggerbot = not Config.Triggerbot UpdateToggleVisual("Triggerbot")
    elseif input.KeyCode == Config.SpinbotKeybind and Config.SpinbotKeybind ~= Enum.KeyCode.Unknown then Config.Spinbot = not Config.Spinbot UpdateToggleVisual("Spinbot")
    elseif input.KeyCode == Config.EspMasterKeybind and Config.EspMasterKeybind ~= Enum.KeyCode.Unknown then Config.EspMaster = not Config.EspMaster UpdateToggleVisual("EspMaster")
    elseif input.KeyCode == Config.SpeedKeybind and Config.SpeedKeybind ~= Enum.KeyCode.Unknown then Config.SpeedToggle = not Config.SpeedToggle UpdateToggleVisual("SpeedToggle")
    elseif input.KeyCode == Config.JumpKeybind and Config.JumpKeybind ~= Enum.KeyCode.Unknown then Config.JumpToggle = not Config.JumpToggle UpdateToggleVisual("JumpToggle")
    elseif input.KeyCode == Config.FlyKeybind and Config.FlyKeybind ~= Enum.KeyCode.Unknown then Config.Fly = not Config.Fly UpdateToggleVisual("Fly") ToggleFlyState(Config.Fly) end
end)
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end
    end)
end)

local function RenderVisuals(Player, Character)
    if not Character or not Character.Parent then return end
    local Root = Character:WaitForChild("HumanoidRootPart", 5); local Head = Character:WaitForChild("Head", 5)
    if not Root or not Head then return end
    
    CleanCharacterVisuals(Character)
    local Box = Instance.new("BoxHandleAdornment")
    Box.Name = "WangBoxFill" Box.Parent = Root Box.Adornee = Root Box.AlwaysOnTop = true Box.ZIndex = 10 Box.Size = Vector3.new(4, 6, 4) Box.Visible = false

    local Gui = Instance.new("BillboardGui")
    Gui.Name = "WangInfoTag" Gui.Adornee = Head Gui.Size = UDim2.new(0, 200, 0, 100) Gui.StudsOffset = Vector3.new(0, 4, 0) Gui.AlwaysOnTop = true

    local Label = Instance.new("TextLabel", Gui)
    Label.Size = UDim2.new(1, 0, 0, 40) Label.BackgroundTransparency = 1 Label.Font = Enum.Font.Code Label.TextSize = 13 Label.TextColor3 = Config.EspColor
    
    local HealthBG = Instance.new("Frame", Gui)
    HealthBG.Name = "HealthBG" HealthBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0) HealthBG.BorderSizePixel = 1 HealthBG.Position = UDim2.new(0.25, 0, 0, 45) HealthBG.Size = UDim2.new(0.5, 0, 0, 5) HealthBG.Visible = false
    
    local HealthBar = Instance.new("Frame", HealthBG)
    HealthBar.Name = "HealthBar" HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100) HealthBar.BorderSizePixel = 0 HealthBar.Size = UDim2.new(1, 0, 1, 0)

    Gui.Parent = Head
    Character_Cache[Character] = { Box = Box, Gui = Gui, Label = Label, HealthBG = HealthBG, HealthBar = HealthBar, Player = Player }
end

local function MonitorPlayer(Player)
    if Player == LocalPlayer then return end
    Player.CharacterAdded:Connect(function(Char) task.spawn(RenderVisuals, Player, Char) end)
    if Player.Character then task.spawn(RenderVisuals, Player, Player.Character) end
end

MasterLoop = RunService.RenderStepped:Connect(function()
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    if Config.FovCircle then FOV_Drawing.Position = ScreenCenter FOV_Drawing.Radius = Config.FovRadius FOV_Drawing.Visible = true else FOV_Drawing.Visible = false end
    if Config.CrosshairDot then Dot_Drawing.Position = ScreenCenter Dot_Drawing.Visible = true else Dot_Drawing.Visible = false end

    if Config.ThirdPerson then LocalPlayer.CameraMinZoomDistance = Config.ThirdPersonDist LocalPlayer.CameraMaxZoomDistance = Config.ThirdPersonDist
    else LocalPlayer.CameraMinZoomDistance = 0.5 LocalPlayer.CameraMaxZoomDistance = 400 end

    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    
    if IsAlive(MyChar) and MyRoot then
        local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
        if MyHum then
            if Config.SpeedToggle then MyHum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpToggle then MyHum.UseJumpPower = true MyHum.JumpPower = Config.JumpPower end
        end
        if Config.Spinbot then
            CurrentSpinAngle = (CurrentSpinAngle + Config.SpinSpeed) % 360
            MyRoot.CFrame = CFrame.new(MyRoot.CFrame.Position) * CFrame.Angles(0, math.rad(CurrentSpinAngle), 0)
        end
        
        if Config.Fly and flyBodyGyro and flyBodyVelocity then
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            
            if MyHum and MyHum.MoveDirection.Magnitude > 0 then
                local look = Camera.CFrame.LookVector; local right = Camera.CFrame.RightVector
                local flatLook = Vector3.new(look.X, 0, look.Z); local flatRight = Vector3.new(right.X, 0, right.Z)
                if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
                local forwardIntent = MyHum.MoveDirection:Dot(flatLook)
                local rightIntent = MyHum.MoveDirection:Dot(flatRight)
                if moveDir.Magnitude == 0 then moveDir = (look * forwardIntent) + (right * rightIntent) end
            end
            
            if moveDir.Magnitude > 0 then flyBodyVelocity.Velocity = moveDir.Unit * Config.FlySpeed else flyBodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            flyBodyGyro.CFrame = Camera.CFrame
        end
        
        local headInstance = MyChar:FindFirstChild("Head")
        local torsoInstance = MyChar:FindFirstChild("UpperTorso") or MyChar:FindFirstChild("Torso")
        local neckJoint = (headInstance and headInstance:FindFirstChild("Neck")) or (torsoInstance and torsoInstance:FindFirstChild("Neck"))
        if neckJoint and neckJoint:IsA("Motor6D") then
            if not NeckCache[neckJoint] then NeckCache[neckJoint] = neckJoint.C0 end
            if Config.BowDown then neckJoint.C0 = NeckCache[neckJoint] * CFrame.Angles(math.rad(-Config.BowAngle), 0, 0) else neckJoint.C0 = NeckCache[neckJoint] end
        end
        
        if Config.Aura then
            if AuraVisual.Parent ~= MyRoot then AuraVisual.Parent = MyRoot AuraVisual.Adornee = MyRoot end
            AuraVisual.Height = 0.08 AuraVisual.Radius = Config.AuraRadius AuraVisual.Color3 = Config.AuraColor
            AuraVisual.Transparency = Config.AuraTransparency / 100 AuraVisual.CFrame = CFrame.new(0, -3.1, 0) * CFrame.Angles(math.rad(90), 0, 0) AuraVisual.Visible = true
        else AuraVisual.Visible = false end
    else AuraVisual.Visible = false end

    task.spawn(ProcessAutoFarmPlayer)
    if Config.Triggerbot then task.spawn(PerformTriggerbotClick) end

    local AuraActiveTarget = nil
    if Config.Aura then
        AuraActiveTarget = GetAuraTarget()
        if AuraActiveTarget then
            local LerpFactor = 1
            if Config.AuraSmoothness > 0 then LerpFactor = math.clamp(1 / (Config.AuraSmoothness * 3 + 1), 0.01, 1) end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, AuraActiveTarget.Position), LerpFactor)
        end
    end

    if Config.Aimbot and not Config.AutoFarmPlayer and not AuraActiveTarget then
        local Target = GetClosestPlayerToCrosshair()
        if Target then
            local LerpFactor = 1
            if Config.Smoothness > 0 then LerpFactor = math.clamp(1 / (Config.Smoothness * 3 + 1), 0.01, 1) end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), LerpFactor)
        end
    end

    for Char, Data in pairs(Character_Cache) do
        if Char and Char.Parent and IsAlive(Char) then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            
            local isTarget = true 
            
            if Config.EspMaster and Root and MyChar and MyChar:FindFirstChild("HumanoidRootPart") and Hum and isTarget then
                local PColor = GetPlayerColor(Data.Player)
                local Dist = math.floor((Root.Position - MyChar.HumanoidRootPart.Position).Magnitude)

                if Config.EspBox and Dist <= Config.MaxDistance then Data.Box.Visible = true Data.Box.Color3 = PColor Data.Box.Transparency = Config.EspTransparency / 100 else Data.Box.Visible = false end
                if Config.EspName and Dist <= Config.MaxDistance then Data.Gui.Enabled = true Data.Label.Visible = true Data.Label.TextColor3 = PColor Data.Label.Text = string.format("%s (%dm)\n[%s] [%s]", Data.Player.Name, Dist, Data.Player.Team and Data.Player.Team.Name or "No Team", GetEquippedTool(Char)) else Data.Label.Visible = false end
                if Config.EspHealth and Dist <= Config.MaxDistance then Data.Gui.Enabled = true Data.HealthBG.Visible = true local HealthPercent = math.clamp(Hum.Health / Hum.MaxHealth, 0, 1) Data.HealthBar.Size = UDim2.new(HealthPercent, 0, 1, 0) Data.HealthBar.BackgroundColor3 = Color3.fromHSV(HealthPercent * 0.35, 1, 1) else Data.HealthBG.Visible = false end

                local Tracer = Tracer_Cache[Data.Player]
                if Tracer and Config.EspTracer and Dist <= Config.MaxDistance then
                    local Leg, OnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    if OnScreen then Tracer.From = Config.TracerMode == "Center" and ScreenCenter or ScreenBottom Tracer.To = Vector2.new(Leg.X, Leg.Y) Tracer.Color = PColor Tracer.Visible = true else Tracer.Visible = false end
                elseif Tracer then Tracer.Visible = false end
            else Data.Box.Visible = false Data.Label.Visible = false Data.HealthBG.Visible = false if Tracer_Cache[Data.Player] then Tracer_Cache[Data.Player].Visible = false end end
        else CleanCharacterVisuals(Char) Character_Cache[Char] = nil end
    end
end)

Players.PlayerAdded:Connect(function(Player) CreateTracerObject(Player) MonitorPlayer(Player) end)
Players.PlayerRemoving:Connect(function(Player) ClearTracerObject(Player) end)

for _, P in pairs(Players:GetPlayers()) do CreateTracerObject(P) MonitorPlayer(P) end
for K, _ in pairs(GlobalSyncToggles) do UpdateToggleVisual(K) end

pcall(function()
    StarterGui:SetCore("SendNotification", {Title = "WANGCAOS CLIENT V6.9.6", Text = "Loaded Super Fixed Edition successfully!", Duration = 5})
end)
-- ==============================================================================
-- END OF SCRIPT - POWERED BY BE FOR DAI CA WANG (2026)
-- ==============================================================================
