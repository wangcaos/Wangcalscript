-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V7.1 - PE POSITION SAVER & BUTTON LOCK
-- ALL RIGHTS RESERVED BY WANGCAOS (2026)
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
    MenuVisible = true,
    MenuKeybind = Enum.KeyCode.RightShift,
    
    Aimbot = false,
    AimbotKeybind = Enum.KeyCode.E,
    TeamCheck = true,
    WallCheck = true,
    Smoothness = 5,
    TargetPart = "Head",
    
    Aura = false,
    AuraKeybind = Enum.KeyCode.H,
    TeamCheckAura = true,
    AuraWallCheck = true,
    AuraSmoothness = 5,
    AuraRadius = 30,
    AuraColor = Color3.fromRGB(0, 170, 255),
    AuraTransparency = 50,
    PriorityLowestHealth = false,
    
    Triggerbot = false,
    TriggerbotKeybind = Enum.KeyCode.T,
    TriggerWallCheck = true,
    
    Spinbot = false,
    SpinbotKeybind = Enum.KeyCode.K,
    SpinSpeed = 25,
    
    AutoFarmPlayer = false,
    AutoFarmDelay = 0.05,
    
    BowDown = false,
    BowAngle = 45,
    ThirdPerson = false,
    ThirdPersonDist = 15,
    AntiAFK = false,
    
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
    EspColor = Color3.fromRGB(255, 50, 50),
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
    ShowMobileAura = false,
    ShowMobileTP = false,
    LockMobileButtons = false, -- TÍNH NĂNG KHOÁ NÚT MOBILE
    
    CustomBackground = true,
    BackgroundAssetId = "rbxassetid://118670919014080",
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

local CurrentSpinAngle = 0
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local LastFarmTime = 0
local CurrentFarmIndex = 1

local UI_Refresh_Functions = {}
local GlobalMobileButtons = {} 
local GlobalSyncToggles = {}

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

local function ExportSettings()
    local exportTable = {}
    for k, v in pairs(Config) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            exportTable[k] = v
        elseif typeof(v) == "EnumItem" then
            exportTable[k] = {__type = "EnumItem", EnumType = tostring(v.EnumType), Name = v.Name}
        elseif typeof(v) == "Color3" then
            exportTable[k] = {__type = "Color3", R = v.R, G = v.G, B = v.B}
        end
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
                elseif v.__type == "Color3" then
                    Config[k] = Color3.new(v.R, v.G, v.B)
                end
            else
                Config[k] = v
            end
        end
        for _, refresh in pairs(UI_Refresh_Functions) do pcall(refresh) end
        
        for key, mData in pairs(GlobalMobileButtons) do
            local xs = Config["MobilePos_"..key.."_XS"]
            local xo = Config["MobilePos_"..key.."_XO"]
            local ys = Config["MobilePos_"..key.."_YS"]
            local yo = Config["MobilePos_"..key.."_YO"]
            if xs and xo and ys and yo and mData.Btn then
                pcall(function() mData.Btn.Position = UDim2.new(xs, xo, ys, yo) end)
            end
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
    if Tracer_Cache[Player] then
        pcall(function() Tracer_Cache[Player].Visible = false Tracer_Cache[Player]:Remove() end)
        Tracer_Cache[Player] = nil
    end
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

local function GetDesiredHitbox(Character)
    if Config.TargetPart == "Head" then
        return Character:FindFirstChild("Head")
    elseif Config.TargetPart == "Torso" then
        return Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
    elseif Config.TargetPart == "Legs" then
        return Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightLowerLeg") or Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftLowerLeg") or Character:FindFirstChild("HumanoidRootPart")
    end
    return Character:FindFirstChild("Head")
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
                            if Hum.Health < LowestHealth then
                                LowestHealth = Hum.Health
                                ClosestTarget = TargetPartInstance
                            end
                        else
                            if Dist < MaxDist then
                                MaxDist = Dist
                                ClosestTarget = TargetPartInstance
                            end
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
                        if Hum.Health < LowestHealth then
                            LowestHealth = Hum.Health
                            BestTarget = TargetPartInstance
                        end
                    else
                        if DistFlat < ClosestDist then
                            ClosestDist = DistFlat
                            BestTarget = TargetPartInstance
                        end
                    end
                end
            end
        end
    end
    return BestTarget
end

local function GetPlayerColor(Player)
    return IsTeammate(Player) and Color3.fromRGB(0, 170, 255) or Config.EspColor
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
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            if Config.TeamCheck and IsTeammate(p) then continue end
            local TRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local THead = p.Character:FindFirstChild("Head")
            if TRoot and THead then table.insert(Targets, {Root = TRoot, Head = THead}) end
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
            dragging = true
            mousePos = input.Position
            framePos = UIElement.Position
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
    TextButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if HoldingTouch then HoldingTouch = false Callback() end
        end
    end)
end

local function CreateIndependentMobileButton(Name, TextOn, TextOff, Key, ShowKey, DefaultColor, InitPos)
    local xs = Config["MobilePos_"..Key.."_XS"] or InitPos.X.Scale
    local xo = Config["MobilePos_"..Key.."_XO"] or InitPos.X.Offset
    local ys = Config["MobilePos_"..Key.."_YS"] or InitPos.Y.Scale
    local yo = Config["MobilePos_"..Key.."_YO"] or InitPos.Y.Offset
    
    if not Config["MobilePos_"..Key.."_XS"] then
        Config["MobilePos_"..Key.."_XS"] = xs
        Config["MobilePos_"..Key.."_XO"] = xo
        Config["MobilePos_"..Key.."_YS"] = ys
        Config["MobilePos_"..Key.."_YO"] = yo
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
    ShortcutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShortcutBtn.TextSize = 9
    ShortcutBtn.Visible = (Config[ShowKey] and IsMobile)
    Instance.new("UICorner", ShortcutBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ShortcutBtn)
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.Thickness = 1.5
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

local lxs = Config["MobilePos_MainLogo_XS"] or 0
local lxo = Config["MobilePos_MainLogo_XO"] or 20
local lys = Config["MobilePos_MainLogo_YS"] or 0
local lyo = Config["MobilePos_MainLogo_YO"] or 20
if not Config["MobilePos_MainLogo_XS"] then
    Config["MobilePos_MainLogo_XS"] = lxs Config["MobilePos_MainLogo_XO"] = lxo Config["MobilePos_MainLogo_YS"] = lys Config["MobilePos_MainLogo_YO"] = lyo
end

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "PremiumToggleLogo"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Position = UDim2.new(lxs, lxo, lys, lyo)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(60, 60, 60)
Instance.new("UIStroke", ToggleButton).Thickness = 1.5

ToggleButton.Visible = IsMobile
GlobalMobileButtons["MainLogo"] = { Btn = ToggleButton }
MakeDraggable(ToggleButton, ToggleButton, "MainLogo")

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
TopNavBar.Parent = MainFrame
TopNavBar.BackgroundColor3 = Color3.fromRGB(23, 24, 26)
TopNavBar.BackgroundTransparency = 0.3
TopNavBar.Position = UDim2.new(0, 10, 0, 10)
TopNavBar.Size = UDim2.new(1, -20, 0, 42)
TopNavBar.ZIndex = 2
Instance.new("UICorner", TopNavBar).CornerRadius = UDim.new(0, 8)

local TabMenuContainer = Instance.new("Frame")
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
CloseBtn.Parent = TopNavBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 153, 158)
CloseBtn.TextSize = 22

MakeDraggable(MainFrame, TopNavBar, nil) 
RegisterTouchFriendlyClick(CloseBtn, function() Config.MenuVisible = false MainFrame.Visible = false end)
RegisterTouchFriendlyClick(ToggleButton, function() Config.MenuVisible = not Config.MenuVisible MainFrame.Visible = Config.MenuVisible end)

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
    page.CanvasSize = UDim2.new(0, 0, 0, 650)
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
        for _, page in pairs({CombatPage, PlayerPage, MovementPage, VisualPage, MiscPage, CreditsPage}) do page.Visible = false end
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
        elseif Key == "Aura" then MData.Btn.Text = state and "AUR\nON" or "AUR\nOFF"
        elseif Key == "ThirdPerson" then MData.Btn.Text = state and "3RD\nON" or "3RD\nOFF"
        end
    end
end

local RestrictedKeys = {
    ShowMobileTP = true, ShowMobileAura = true, ShowMobileAim = true, 
    ShowMobileTrig = true, ShowMobileSpeed = true, ShowMobileFarm = true
}

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
        if RestrictedKeys[Key] and not IsMobile then
            pcall(function() StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Button enabled only for PE!", Duration = 3}) end)
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
        BindBtn.Size = UDim2.new(0, 50, 0, 20)
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE"
        BindBtn.TextColor3 = Color3.fromRGB(200, 205, 210)
        BindBtn.TextSize = 10
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", BindBtn).Color = Color3.fromRGB(55, 57, 60)

        local Listening = false
        local ListenConnection
        
        local function EndListening(NewKey)
            Listening = false
            if ListenConnection then ListenConnection:Disconnect() end
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
    local function UpdateSliderPosition(inputPos)
        local mouseX = (inputPos and inputPos.X) or Mouse.X
        local ratio = math.clamp((mouseX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = Min + (Max - Min) * ratio
        if Max - Min > 10 then val = math.floor(val) else val = math.floor(val * 10) / 10 end
        Config[Key] = val
        ValTxt.Text = tostring(val)
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        if Callback then Callback(val) end
    end

    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true UpdateSliderPosition(input.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSliderPosition(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)

    table.insert(UI_Refresh_Functions, function()
        ValTxt.Text = tostring(Config[Key])
        Fill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
    end)
end

local function AddPremiumDropdown(Page, LabelText, Items, Key, Callback)
    local DFrame = Instance.new("Frame", Page)
    DFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    DFrame.BackgroundTransparency = 0.4
    Instance.new("UICorner", DFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", DFrame).Color = Color3.fromRGB(35, 37, 40)

    local Lbl = Instance.new("TextLabel", DFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -120, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(180, 183, 188)
    Lbl.TextSize = 11
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local DropBtn = Instance.new("TextButton", DFrame)
    DropBtn.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    DropBtn.Position = UDim2.new(1, -110, 0.5, -11)
    DropBtn.Size = UDim2.new(0, 100, 0, 22)
    DropBtn.Font = Enum.Font.GothamBold
    DropBtn.Text = tostring(Config[Key]) .. " v"
    DropBtn.TextColor3 = Color3.fromRGB(240, 242, 245)
    DropBtn.TextSize = 10
    Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", DropBtn).Color = Color3.fromRGB(55, 57, 60)

    local Expanded = false
    local ListFrame = Instance.new("Frame", ScreenGui)
    ListFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    ListFrame.Size = UDim2.new(0, 100, 0, #Items * 22)
    ListFrame.Visible = false
    ListFrame.ZIndex = 10
    Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 4)
    local LStroke = Instance.new("UIStroke", ListFrame)
    LStroke.Color = Color3.fromRGB(60, 62, 65)

    local Layout = Instance.new("UIListLayout", ListFrame)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    for idx, item in pairs(Items) do
        local ItemBtn = Instance.new("TextButton", ListFrame)
        ItemBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ItemBtn.BackgroundTransparency = 1
        ItemBtn.Size = UDim2.new(1, 0, 0, 22)
        ItemBtn.Font = Enum.Font.Gotham
        ItemBtn.Text = tostring(item)
        ItemBtn.TextColor3 = Color3.fromRGB(200, 202, 205)
        ItemBtn.TextSize = 10
        ItemBtn.LayoutOrder = idx
        
        RegisterTouchFriendlyClick(ItemBtn, function()
            Config[Key] = item
            DropBtn.Text = tostring(item) .. " v"
            Expanded = false
            ListFrame.Visible = false
            if Callback then Callback(item) end
        end)
    end
    
    table.insert(UI_Refresh_Functions, function()
        DropBtn.Text = tostring(Config[Key]) .. " v"
    end)
end

CreatePremiumTab("Combat", "⚔️", 1, CombatPage)
CreatePremiumTab("Player", "👤", 2, PlayerPage)
CreatePremiumTab("Movement", "⚡", 3, MovementPage)
CreatePremiumTab("Visuals", "👁️", 4, VisualPage)
CreatePremiumTab("Misc", "⚙️", 5, MiscPage)
CreatePremiumTab("Credits", "ℹ️", 6, CreditsPage)

-- COMBAT PAGE
AddPremiumToggle(CombatPage, "Enable Aimbot", "Aimbot", function(state) FOV_Drawing.Visible = (state and Config.FovCircle) end, Color3.fromRGB(255, 50, 50), "AimbotKeybind")
AddPremiumDropdown(CombatPage, "Target Hitbox", {"Head", "Torso", "Legs"}, "TargetPart", nil)
AddPremiumSlider(CombatPage, "Aimbot Smoothness", 1, 20, "Smoothness", nil)
AddPremiumToggle(CombatPage, "Aimbot Wall Check", "WallCheck", nil)
AddPremiumToggle(CombatPage, "Aimbot Team Check", "TeamCheck", nil)

AddPremiumToggle(CombatPage, "Enable Kill Aura", "Aura", function(state) AuraVisual.Visible = state end, Color3.fromRGB(0, 150, 255), "AuraKeybind")
AddPremiumSlider(CombatPage, "Aura Radius (Studs)", 5, 100, "AuraRadius", function(val) AuraVisual.Radius = val end)
AddPremiumToggle(CombatPage, "Aura Wall Check", "AuraWallCheck", nil)
AddPremiumToggle(CombatPage, "Aura Team Check", "TeamCheckAura", nil)
AddPremiumToggle(CombatPage, "Priority Lowest Health", "PriorityLowestHealth", nil)

AddPremiumToggle(CombatPage, "Enable Triggerbot", "Triggerbot", nil, Color3.fromRGB(230, 125, 30), "TriggerbotKeybind")
AddPremiumToggle(CombatPage, "Triggerbot Wall Check", "TriggerWallCheck", nil)

-- PLAYER PAGE
AddPremiumToggle(PlayerPage, "Enable Auto Farm Player", "AutoFarmPlayer", nil, Color3.fromRGB(45, 140, 75))
AddPremiumSlider(PlayerPage, "Auto Farm Delay (Sec)", 0, 1, "AutoFarmDelay", nil)
AddPremiumToggle(PlayerPage, "Enable Anti-AFK Loop", "AntiAFK", nil)
AddPremiumToggle(PlayerPage, "Enable Spinbot", "Spinbot", nil, nil, "SpinbotKeybind")
AddPremiumSlider(PlayerPage, "Spinbot Speed", 5, 100, "SpinSpeed", nil)
AddPremiumToggle(PlayerPage, "Bow Down Style", "BowDown", nil)
AddPremiumSlider(PlayerPage, "Bow Custom Angle", 0, 90, "BowAngle", nil)

-- MOVEMENT PAGE
AddPremiumToggle(MovementPage, "Enable Speed Hack", "SpeedToggle", nil, Color3.fromRGB(140, 30, 230), "SpeedKeybind")
AddPremiumSlider(MovementPage, "WalkSpeed Value", 16, 250, "WalkSpeed", function(v) if Config.SpeedToggle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v end end)
AddPremiumToggle(MovementPage, "Enable Jump Hack", "JumpToggle", nil, nil, "JumpKeybind")
AddPremiumSlider(MovementPage, "JumpPower Value", 50, 500, "JumpPower", function(v) if Config.JumpToggle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = v end end)

-- VISUAL PAGE
AddPremiumToggle(VisualPage, "Master ESP Switch", "EspMaster", nil, nil, "EspMasterKeybind")
AddPremiumToggle(VisualPage, "Show 3D ESP Box", "EspBox", nil)
AddPremiumToggle(VisualPage, "Show Name & Item Tags", "EspName", nil)
AddPremiumToggle(VisualPage, "Show Health Bar Tags", "EspHealth", nil)
AddPremiumToggle(VisualPage, "Show Tracer Lines", "EspTracer", nil)
AddPremiumDropdown(VisualPage, "Tracer Source Mode", {"Top", "Center", "Bottom"}, "TracerMode", nil)
AddPremiumSlider(VisualPage, "Max Rendering Dist", 100, 10000, "MaxDistance", nil)

AddPremiumToggle(VisualPage, "Show FOV Circle Radius", "FovCircle", function(state) FOV_Drawing.Visible = (state and Config.Aimbot) end)
AddPremiumSlider(VisualPage, "FOV Circle Radius Size", 30, 600, "FovRadius", function(v) FOV_Drawing.Radius = v end)
AddPremiumToggle(VisualPage, "Show Crosshair Center Dot", "CrosshairDot", function(state) Dot_Drawing.Visible = state end)
AddPremiumToggle(VisualPage, "Enable Ambient FullBright", "FullBright", function(state) if state then Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) else Lighting.Ambient = Config.StoredAmbient Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient end end)

-- MISC PAGE
AddPremiumToggle(MiscPage, "Force Third Person PE", "ThirdPerson", nil, Color3.fromRGB(150, 150, 150))
AddPremiumSlider(MiscPage, "Third Person Distance", 5, 50, "ThirdPersonDist", nil)
AddPremiumToggle(MiscPage, "Menu Custom Wallpaper", "CustomBackground", function(state) CustomBackgroundImage.Visible = state end)

AddPremiumToggle(MiscPage, "Show Mobile Aim Button", "ShowMobileAim", function(s) MobAim.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Show Mobile Trigger Button", "ShowMobileTrig", function(s) MobTrig.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Show Mobile Speed Button", "ShowMobileSpeed", function(s) MobSpeed.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Show Mobile Farm Button", "ShowMobileFarm", function(s) MobFarm.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Show Mobile Aura Button", "ShowMobileAura", function(s) MobAura.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Show Mobile TP Button", "ShowMobileTP", function(s) MobTP.Visible = (s and IsMobile) end)
AddPremiumToggle(MiscPage, "Lock Mobile Buttons Position", "LockMobileButtons", nil)

local ConfigFrame = Instance.new("Frame", MiscPage)
ConfigFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
ConfigFrame.BackgroundTransparency = 0.4
Instance.new("UICorner", ConfigFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", ConfigFrame).Color = Color3.fromRGB(35, 37, 40)

local ExpBtn = Instance.new("TextButton", ConfigFrame)
ExpBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
ExpBtn.Position = UDim2.new(0, 10, 0.5, -11)
ExpBtn.Size = UDim2.new(0, 120, 0, 22)
ExpBtn.Font = Enum.Font.GothamBold
ExpBtn.Text = "EXPORT CONFIG"
ExpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExpBtn.TextSize = 10
Instance.new("UICorner", ExpBtn).CornerRadius = UDim.new(0, 4)

local ImpBtn = Instance.new("TextButton", ConfigFrame)
ImpBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
ImpBtn.Position = UDim2.new(0, 140, 0.5, -11)
ImpBtn.Size = UDim2.new(0, 120, 0, 22)
ImpBtn.Font = Enum.Font.GothamBold
ImpBtn.Text = "IMPORT CONFIG"
ImpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ImpBtn.TextSize = 10
Instance.new("UICorner", ImpBtn).CornerRadius = UDim.new(0, 4)

RegisterTouchFriendlyClick(ExpBtn, function()
    local hexStr = ExportSettings()
    if hexStr ~= "" then
        pcall(function() setclipboard(hexStr) end)
        pcall(function() StarterGui:SetCore("SendNotification", {Title = "WANGCAOS", Text = "Configuration hex copied to clipboard!", Duration = 4}) end)
    end
end)

RegisterTouchFriendlyClick(ImpBtn, function()
    local success = false
    pcall(function()
        local cb = getclipboard()
        if cb and #cb > 0 then success = ImportSettings(cb) end
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WANGCAOS",
            Text = success and "Configuration successfully imported!" or "Failed to read data from clipboard!",
            Duration = 4
        })
    end)
end)

-- CREDITS PAGE
local function AddCreditsText(TextString)
    local FrameStr = Instance.new("Frame", CreditsPage)
    FrameStr.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
    FrameStr.BackgroundTransparency = 0.4
    Instance.new("UICorner", FrameStr).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", FrameStr).Color = Color3.fromRGB(35, 37, 40)
    
    local txt = Instance.new("TextLabel", FrameStr)
    txt.BackgroundTransparency = 1
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Font = Enum.Font.GothamBold
    txt.Text = TextString
    txt.TextColor3 = Color3.fromRGB(200, 205, 210)
    txt.TextSize = 10
end

AddCreditsText("WANGCAOS PREMIUM CLIENT V7.1")
AddCreditsText("GUI Layout & Framework: Figma UI Eng")
AddCreditsText("Optimization & Security Updates: 2026")
AddCreditsText("Status: Fully Operational")

-- CORE LOGIC LOOPS
MasterLoop = RunService.RenderStepped:Connect(function()
    if Config.MenuVisible then
        local targetX = Camera.ViewportSize.X / 2
        local targetY = Camera.ViewportSize.Y / 2
        Dot_Drawing.Position = Vector2.new(targetX, targetY)
    end

    if Config.Aimbot and UserInputService:IsKeyDown(Config.AimbotKeybind) then
        local LockTarget = GetClosestPlayerToCrosshair()
        if LockTarget then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(LockTarget.Position)
            if OnScreen then
                local MousePos = UserInputService:GetMouseLocation()
                local Delta = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos) / Config.Smoothness
                pcall(function() mousemoverel(Delta.X, Delta.Y) end)
            end
        end
    end

    if Config.Aura then
        local TargetPart = GetAuraTarget()
        if TargetPart and MyRoot then
            AuraVisual.Adornment = TargetPart.Parent:FindFirstChild("HumanoidRootPart")
            AuraVisual.Color3 = Config.AuraColor
            AuraVisual.Transparency = Config.AuraTransparency / 100
            
            local currentWeapon = GetEquippedTool(LocalPlayer.Character)
            if currentWeapon ~= "None" then
                pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0)) end)
            end
        else
            AuraVisual.Adornment = nil
        end
    else
        AuraVisual.Adornment = nil
    end

    if Config.Triggerbot and UserInputService:IsKeyDown(Config.TriggerbotKeybind) then
        PerformTriggerbotClick()
    end

    if Config.Spinbot and LocalPlayer.Character and IsAlive(LocalPlayer.Character) then
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if Root then
            CurrentSpinAngle = (CurrentSpinAngle + Config.SpinSpeed) % 360
            Root.CFrame = CFrame.new(Root.Position) * CFrame.Angles(0, math.radians(CurrentSpinAngle), 0)
        end
    end

    if Config.BowDown and LocalPlayer.Character and IsAlive(LocalPlayer.Character) then
        local Torso = LocalPlayer.Character:FindFirstChild("UpperTorso") or LocalPlayer.Character:FindFirstChild("Torso")
        local Neck = Torso and (Torso:FindFirstChild("Neck") or Torso:FindFirstChild("Waist"))
        if Neck then
            if not NeckCache[Neck] then NeckCache[Neck] = Neck.C0 end
            Neck.C0 = NeckCache[Neck] * CFrame.Angles(math.radians(Config.BowAngle), 0, 0)
        end
    else
        for neck, origC0 in pairs(NeckCache) do if neck.Parent then neck.C0 = origC0 end end
    end

    if Config.ThirdPerson and LocalPlayer.Character and Camera then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        Config.ThirdPersonDist = math.clamp(Config.ThirdPersonDist, 5, 50)
    end

    pcall(ProcessAutoFarmPlayer)

    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

    for _, Player in pairs(Players:GetPlayers()) do
        local Char = Player.Character
        local Tracer = Tracer_Cache[Player]
        if Char and IsAlive(Char) and Player ~= LocalPlayer and Config.EspMaster then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            if Root and Hum then
                local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                local Dist = (Camera.CFrame.Position - Root.Position).Magnitude
                
                if OnScreen and Dist <= Config.MaxDistance then
                    CleanCharacterVisuals(Char)
                    local PColor = GetPlayerColor(Player)

                    if Config.EspBox then
                        local BoxFill = Instance.new("BoxHandleAdornment", Char)
                        BoxFill.Name = "WangBoxFill"
                        BoxFill.Size = Char:GetExtentsSize() + Vector3.new(0.2, 0.2, 0.2)
                        BoxFill.CFrame = Root.CFrame
                        BoxFill.Color3 = PColor
                        BoxFill.Transparency = 0.85
                        BoxFill.AlwaysOnTop = true
                        BoxFill.ZIndex = 1
                        BoxFill.Adornment = Root
                        end

                    if Config.EspName or Config.EspHealth then
                        local InfoTag = Instance.new("BillboardGui", Char)
                        InfoTag.Name = "WangInfoTag"
                        InfoTag.AlwaysOnTop = true
                        InfoTag.Size = UDim2.new(0, 200, 0, 50)
                        InfoTag.ExtentsOffset = Vector3.new(0, 3, 0)
                        InfoTag.Adornment = Root

                        local Label = Instance.new("TextLabel", InfoTag)
                        Label.Size = UDim2.new(1, 0, 1, 0)
                        Label.BackgroundTransparency = 1
                        Label.Font = Enum.Font.GothamBold
                        Label.TextSize = 12
                        Label.TextColor3 = PColor
                        Label.TextStrokeTransparency = 0.2

                        local tText = ""
                        if Config.EspName then tText = tText .. Player.Name .. " [" .. math.floor(Dist) .. "m]\n" end
                        if Config.EspHealth then tText = tText .. "HP: " .. math.floor(Hum.Health) .. "/" .. math.floor(Hum.MaxHealth) .. " (" .. GetEquippedTool(Char) .. ")" end
                        Label.Text = tText
                    end

                    if Config.EspTracer and Tracer then
                        local Leg, LOnScreen = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                        if LOnScreen then
                            if Config.TracerMode == "Center" then Tracer.From = ScreenCenter
                            elseif Config.TracerMode == "Top" then Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                            else Tracer.From = ScreenBottom end
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
        Title = "WANGCAOS CLIENT V7.1",
        Text = "Successfully implemented V7.1 Framework & Core Updates!",
        Duration = 7
    })
end)
-- ==============================================================================
-- END OF SCRIPT - WANGCAOS CLIENT (2026)
-- ==============================================================================
