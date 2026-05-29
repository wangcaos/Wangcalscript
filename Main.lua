-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V6.9.0 - MINIMAL PE-INSPIRED UI (HOTFIX)
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
    LockMobileButtons = false, 
    
    CustomBackground = true,
    BackgroundAssetId = "rbxassetid://118670919014080",
    StoredAmbient = Lighting.Ambient,
    StoredOutdoorAmbient = Lighting.OutdoorAmbient
}

local CurrentSpinAngle = 0
-- Đã sửa lại lỗi nhận diện bàn phím ảo trên điện thoại Android
local IsMobile = UserInputService.TouchEnabled 
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
local NewMainPanel = Instance.new("Frame")
NewMainPanel.Name = "NewMainPanel"
NewMainPanel.Parent = ScreenGui
NewMainPanel.BackgroundColor3 = Color3.fromRGB(20, 21, 23)
NewMainPanel.BackgroundTransparency = 0.2
NewMainPanel.Position = UDim2.new(1, -290, 1, -370)
NewMainPanel.Size = UDim2.new(0, 280, 0, 360)
NewMainPanel.Visible = Config.MenuVisible
Instance.new("UICorner", NewMainPanel).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", NewMainPanel).Color = Color3.fromRGB(50, 52, 56)
NewMainPanel.UIStroke.Thickness = 1

local CustomBackgroundImage = Instance.new("ImageLabel")
CustomBackgroundImage.Name = "MenuCustomWallpaper"
CustomBackgroundImage.Parent = NewMainPanel
CustomBackgroundImage.BackgroundTransparency = 1
CustomBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
CustomBackgroundImage.Image = Config.BackgroundAssetId
CustomBackgroundImage.ImageTransparency = 0.75
CustomBackgroundImage.ScaleType = Enum.ScaleType.Crop
CustomBackgroundImage.ZIndex = 0
CustomBackgroundImage.Visible = Config.CustomBackground
Instance.new("UICorner", CustomBackgroundImage).CornerRadius = UDim.new(0, 10)

local Header = Instance.new("Frame")
Header.Parent = NewMainPanel
Header.BackgroundTransparency = 1
Header.Position = UDim2.new(0, 0, 0, 0)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.ZIndex = 2
MakeDraggable(NewMainPanel, Header, nil) 

local AppIcon = Instance.new("TextLabel")
AppIcon.Parent = Header
AppIcon.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
AppIcon.Position = UDim2.new(0, 10, 0, 5)
AppIcon.Size = UDim2.new(0, 20, 0, 20)
AppIcon.Font = Enum.Font.GothamBold
AppIcon.Text = "W"
AppIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
AppIcon.TextSize = 12
Instance.new("UICorner", AppIcon).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Header
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -25, 0.5, -10)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 153, 158)
CloseBtn.TextSize = 18
RegisterTouchFriendlyClick(CloseBtn, function() Config.MenuVisible = false NewMainPanel.Visible = false end)
RegisterTouchFriendlyClick(ToggleButton, function() Config.MenuVisible = not Config.MenuVisible NewMainPanel.Visible = Config.MenuVisible end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Parent = NewMainPanel
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 0, 0, 30)
ContentContainer.Size = UDim2.new(1, 0, 1, -30)
ContentContainer.ZIndex = 2

local MenuVọcArea = Instance.new("Frame")
MenuVọcArea.Parent = ContentContainer
MenuVọcArea.BackgroundTransparency = 1
MenuVọcArea.Position = UDim2.new(0, 0, 0, 0)
MenuVọcArea.Size = UDim2.new(0, 80, 1, 0)

local TabMenuContainer = Instance.new("ScrollingFrame")
TabMenuContainer.Parent = MenuVọcArea
TabMenuContainer.BackgroundTransparency = 1
TabMenuContainer.BorderSizePixel = 0
TabMenuContainer.Position = UDim2.new(0, 0, 0, 0)
TabMenuContainer.Size = UDim2.new(1, 0, 1, 0)
TabMenuContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
-- Tớ đã thêm AutomaticCanvasSize ở đây để cậu vuốt được rồi này!
TabMenuContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabMenuContainer.ScrollBarThickness = 0
local TabLayout = Instance.new("UIListLayout", TabMenuContainer)
TabLayout.FillDirection = Enum.FillDirection.Vertical
TabLayout.Padding = UDim.new(0, 2)
local TabPad = Instance.new("UIPadding", TabMenuContainer)
TabPad.PaddingLeft = UDim.new(0, 5)
TabPad.PaddingTop = UDim.new(0, 5)

local SubPanelArea = Instance.new("Frame")
SubPanelArea.Parent = ContentContainer
SubPanelArea.BackgroundTransparency = 1
SubPanelArea.Position = UDim2.new(0, 80, 0, 0)
SubPanelArea.Size = UDim2.new(1, -80, 1, 0)

local NewCombatPage = Instance.new("ScrollingFrame", SubPanelArea)
local NewPlayerPage = Instance.new("ScrollingFrame", SubPanelArea)
local NewMovementPage = Instance.new("ScrollingFrame", SubPanelArea)
local NewVisualPage = Instance.new("ScrollingFrame", SubPanelArea)
local NewMiscPage = Instance.new("ScrollingFrame", SubPanelArea)
local NewCreditsPage = Instance.new("ScrollingFrame", SubPanelArea)

for _, page in pairs({NewCombatPage, NewPlayerPage, NewMovementPage, NewVisualPage, NewMiscPage, NewCreditsPage}) do
    page.Size = UDim2.new(0, 190, 0, 330)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0) 
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 62, 65)
    page.Visible = false
    local grid = Instance.new("UIGridLayout", page)
    grid.CellSize = UDim2.new(0, 175, 0, 38)
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", page).PaddingLeft = UDim.new(0, 5)
end
NewCombatPage.Visible = true
local function CreatePremiumTab(Name, IconText, Order, TargetPage)
    local TabBtn = Instance.new("TextButton", TabMenuContainer)
    TabBtn.BackgroundColor3 = Order == 1 and Color3.fromRGB(28, 30, 32) or Color3.fromRGB(0, 0, 0)
    TabBtn.BackgroundTransparency = Order == 1 and 0 or 1
    TabBtn.Size = UDim2.new(1, -10, 0, 30)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = Order
    TabBtn.Text = Name
    TabBtn.TextColor3 = Order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 143, 148)
    TabBtn.TextSize = 10
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", TabBtn).PaddingLeft = UDim.new(0, 10)
    local TStroke = Instance.new("UIStroke", TabBtn)
    TStroke.Color = Color3.fromRGB(50, 52, 56)
    TStroke.Enabled = Order == 1
    RegisterTouchFriendlyClick(TabBtn, function()
        for _, p in pairs({NewCombatPage, NewPlayerPage, NewMovementPage, NewVisualPage, NewMiscPage, NewCreditsPage}) do p.Visible = false end
        for _, btn in pairs(TabMenuContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(140, 143, 148)
                btn.UIStroke.Enabled = false
            end
        end
        TabBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 32)
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
    TweenService:Create(Ball, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)}):Play()
    TweenService:Create(SwitchBg, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(35, 37, 40)}):Play()
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
    TFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    TFrame.BackgroundTransparency = 0
    TFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(45, 47, 50)
    
    local Lbl = Instance.new("TextLabel", TFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -95, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local SwitchBg = Instance.new("Frame", TFrame)
    SwitchBg.BackgroundColor3 = Config[Key] and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(35, 37, 40)
    SwitchBg.Position = UDim2.new(1, -40, 0.5, -7)
    SwitchBg.Size = UDim2.new(0, 28, 0, 14)
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

    local Ball = Instance.new("Frame", SwitchBg)
    Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ball.Position = Config[Key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    Ball.Size = UDim2.new(0, 10, 0, 10)
    Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", TFrame)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 0, 1, 0)
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
        BindBtn.Position = UDim2.new(1, -90, 0.5, -9)
        BindBtn.Size = UDim2.new(0, 45, 0, 18)
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE"
        BindBtn.TextColor3 = Color3.fromRGB(180, 185, 190)
        BindBtn.TextSize = 9
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", BindBtn).Color = Color3.fromRGB(50, 52, 55)

        local Listening = false
        local ListenConnection
        local function EndListening(NewKey)
            Listening = false
            if ListenConnection then ListenConnection:Disconnect() end
            if NewKey then Config[BindKey] = NewKey BindBtn.Text = NewKey.Name:upper() else BindBtn.Text = Config[BindKey] and Config[BindKey].Name or "NONE" end
            BindBtn.TextColor3 = Color3.fromRGB(180, 185, 190)
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
        Lbl.Size = UDim2.new(1, -140, 1, 0)
    end
    table.insert(UI_Refresh_Functions, function() UpdateToggleVisual(Key) end)
end
local function AddPremiumSlider(Page, LabelText, Min, Max, Key, Callback)
    local SFrame = Instance.new("Frame", Page)
    SFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    SFrame.BackgroundTransparency = 0
    SFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", SFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", SFrame).Color = Color3.fromRGB(45, 47, 50)

    local Lbl = Instance.new("TextLabel", SFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 3)
    Lbl.Size = UDim2.new(1, -60, 0, 14)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(170, 173, 178)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValTxt = Instance.new("TextLabel", SFrame)
    ValTxt.BackgroundTransparency = 1
    ValTxt.Position = UDim2.new(1, -55, 0, 3)
    ValTxt.Size = UDim2.new(0, 45, 0, 14)
    ValTxt.Font = Enum.Font.GothamBold
    ValTxt.Text = tostring(Config[Key])
    ValTxt.TextColor3 = Color3.fromRGB(230, 230, 230)
    ValTxt.TextSize = 10
    ValTxt.TextXAlignment = Enum.TextXAlignment.Right

    local Bar = Instance.new("Frame", SFrame)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 42, 45)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.new(0, 10, 0, 22)
    Bar.Size = UDim2.new(1, -20, 0, 3)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Bar)
    Fill.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local SliderBall = Instance.new("Frame", Fill)
    SliderBall.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    SliderBall.Position = UDim2.new(1, -3, 0.5, -3)
    SliderBall.Size = UDim2.new(0, 6, 0, 6)
    Instance.new("UICorner", SliderBall).CornerRadius = UDim.new(1, 0)

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
    BFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    BFrame.BackgroundTransparency = 0
    BFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", BFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", BFrame).Color = Color3.fromRGB(45, 47, 50)
    
    local Lbl = Instance.new("TextLabel", BFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -100, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = LabelText
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ActionBtn = Instance.new("TextButton", BFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ActionBtn.Position = UDim2.new(1, -90, 0.5, -11)
    ActionBtn.Size = UDim2.new(0, 80, 0, 22)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = ButtonText
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 4)
    RegisterTouchFriendlyClick(ActionBtn, Callback)
end
local function AddHitboxSelector(Page)
    local HFrame = Instance.new("Frame", Page)
    HFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    HFrame.BackgroundTransparency = 0
    HFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", HFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", HFrame).Color = Color3.fromRGB(45, 47, 50)

    local Lbl = Instance.new("TextLabel", HFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -100, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Aimbot Target Hitbox"
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local HitboxBtn = Instance.new("TextButton", HFrame)
    HitboxBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    HitboxBtn.Position = UDim2.new(1, -90, 0.5, -11)
    HitboxBtn.Size = UDim2.new(0, 80, 0, 22)
    HitboxBtn.Font = Enum.Font.GothamBold
    HitboxBtn.Text = Config.TargetPart:upper()
    HitboxBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    HitboxBtn.TextSize = 10
    Instance.new("UICorner", HitboxBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", HitboxBtn).Color = Color3.fromRGB(55, 57, 60)

    RegisterTouchFriendlyClick(HitboxBtn, function()
        if Config.TargetPart == "Head" then Config.TargetPart = "Torso" HitboxBtn.Text = "TORSO"
        elseif Config.TargetPart == "Torso" then Config.TargetPart = "Legs" HitboxBtn.Text = "LEGS"
        else Config.TargetPart = "Head" HitboxBtn.Text = "HEAD" end
    end)
    table.insert(UI_Refresh_Functions, function() HitboxBtn.Text = Config.TargetPart:upper() end)
end

local function AddSyncedEspColorSelector(Page)
    local CFrame = Instance.new("Frame", Page)
    CFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    CFrame.BackgroundTransparency = 0
    CFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(45, 47, 50)

    local Lbl = Instance.new("TextLabel", CFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -100, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "ESP & Tracer Color"
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ColorBtn = Instance.new("TextButton", CFrame)
    ColorBtn.BackgroundColor3 = Config.EspColor
    ColorBtn.Position = UDim2.new(1, -90, 0.5, -11)
    ColorBtn.Size = UDim2.new(0, 80, 0, 22)
    ColorBtn.Font = Enum.Font.GothamBold
    ColorBtn.Text = "SWAP COLOR"
    ColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ColorBtn.TextSize = 9
    Instance.new("UICorner", ColorBtn).CornerRadius = UDim.new(0, 4)

    local palette = {Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 200, 0), Color3.fromRGB(230, 30, 230), Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 255)}
    local colorIdx = 1
    RegisterTouchFriendlyClick(ColorBtn, function()
        colorIdx = (colorIdx % #palette) + 1
        Config.EspColor = palette[colorIdx]
        ColorBtn.BackgroundColor3 = Config.EspColor
    end)
    table.insert(UI_Refresh_Functions, function() ColorBtn.BackgroundColor3 = Config.EspColor end)
end

local function AddAuraColorSelector(Page)
    local CFrame = Instance.new("Frame", Page)
    CFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    CFrame.BackgroundTransparency = 0
    CFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(45, 47, 50)

    local Lbl = Instance.new("TextLabel", CFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -100, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Aura Circle Color"
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ColorBtn = Instance.new("TextButton", CFrame)
    ColorBtn.BackgroundColor3 = Config.AuraColor
    ColorBtn.Position = UDim2.new(1, -90, 0.5, -11)
    ColorBtn.Size = UDim2.new(0, 80, 0, 22)
    ColorBtn.Font = Enum.Font.GothamBold
    ColorBtn.Text = "SWAP COLOR"
    ColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ColorBtn.TextSize = 10
    Instance.new("UICorner", ColorBtn).CornerRadius = UDim.new(0, 4)

    local palette = {Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 255, 100), Color3.fromRGB(255, 200, 0), Color3.fromRGB(230, 30, 230)}
    local colorIdx = 1
    RegisterTouchFriendlyClick(ColorBtn, function()
        colorIdx = (colorIdx % #palette) + 1
        Config.AuraColor = palette[colorIdx]
        ColorBtn.BackgroundColor3 = Config.AuraColor
    end)
    table.insert(UI_Refresh_Functions, function() ColorBtn.BackgroundColor3 = Config.AuraColor end)
end

local function AddTracerModeSelector(Page)
    local MFrame = Instance.new("Frame", Page)
    MFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    MFrame.BackgroundTransparency = 0
    MFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", MFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", MFrame).Color = Color3.fromRGB(45, 47, 50)

    local Lbl = Instance.new("TextLabel", MFrame)
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Size = UDim2.new(1, -100, 1, 0)
    Lbl.Font = Enum.Font.Gotham
    Lbl.Text = "Tracer Origin Mode"
    Lbl.TextColor3 = Color3.fromRGB(200, 203, 208)
    Lbl.TextSize = 10
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ModeBtn = Instance.new("TextButton", MFrame)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
    ModeBtn.Position = UDim2.new(1, -90, 0.5, -11)
    ModeBtn.Size = UDim2.new(0, 80, 0, 22)
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.Text = Config.TracerMode:upper()
    ModeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
    ModeBtn.TextSize = 10
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", ModeBtn).Color = Color3.fromRGB(55, 57, 60)

    RegisterTouchFriendlyClick(ModeBtn, function()
        Config.TracerMode = Config.TracerMode == "Bottom" and "Center" or "Bottom"
        ModeBtn.Text = Config.TracerMode:upper()
    end)
    table.insert(UI_Refresh_Functions, function() ModeBtn.Text = Config.TracerMode:upper() end)
end
local function AddExportBox(Page)
    local TFrame = Instance.new("Frame", Page)
    TFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    TFrame.BackgroundTransparency = 0
    TFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(45, 47, 50)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -11)
    Box.Size = UDim2.new(1, -90, 0, 22)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Exported Code Here"
    Box.TextColor3 = Color3.fromRGB(180, 180, 180)
    Box.TextSize = 9
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(50, 52, 55)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 230)
    ActionBtn.Position = UDim2.new(1, -75, 0.5, -11)
    ActionBtn.Size = UDim2.new(0, 65, 0, 22)
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
    TFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    TFrame.BackgroundTransparency = 0
    TFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", TFrame).Color = Color3.fromRGB(45, 47, 50)

    local Box = Instance.new("TextBox", TFrame)
    Box.BackgroundTransparency = 0.2
    Box.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
    Box.Position = UDim2.new(0, 10, 0.5, -11)
    Box.Size = UDim2.new(1, -90, 0, 22)
    Box.Font = Enum.Font.Gotham
    Box.Text = ""
    Box.PlaceholderText = "Paste Code Here"
    Box.TextColor3 = Color3.fromRGB(230, 230, 230)
    Box.TextSize = 9
    Box.ClearTextOnFocus = false
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", Box).Color = Color3.fromRGB(50, 52, 55)

    local ActionBtn = Instance.new("TextButton", TFrame)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 75)
    ActionBtn.Position = UDim2.new(1, -75, 0.5, -11)
    ActionBtn.Size = UDim2.new(0, 65, 0, 22)
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
    CFrame.BackgroundColor3 = Color3.fromRGB(25, 26, 28)
    CFrame.BackgroundTransparency = 0
    CFrame.Size = UDim2.new(1, -10, 0, 38)
    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", CFrame).Color = Color3.fromRGB(45, 47, 50)

    local TitleLbl = Instance.new("TextLabel", CFrame)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 10, 0, 3)
    TitleLbl.Size = UDim2.new(1, -20, 0, 14)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = Title
    TitleLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    TitleLbl.TextSize = 10
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local DescLbl = Instance.new("TextLabel", CFrame)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Position = UDim2.new(0, 10, 0, 17)
    DescLbl.Size = UDim2.new(1, -20, 0, 14)
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = Description
    DescLbl.TextColor3 = Color3.fromRGB(160, 165, 170)
    DescLbl.TextSize = 10
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
end

local AimbotHeader = Instance.new("TextLabel", NewCombatPage)
AimbotHeader.BackgroundTransparency = 1
AimbotHeader.Size = UDim2.new(0, 175, 0, 20)
AimbotHeader.Font = Enum.Font.GothamBold
AimbotHeader.Text = "ii AIMBOT"
AimbotHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
AimbotHeader.TextSize = 10
AimbotHeader.TextXAlignment = Enum.TextXAlignment.Left
local AimbotPad = Instance.new("UIPadding", AimbotHeader)
AimbotPad.PaddingLeft = UDim.new(0, 5)

AddPremiumToggle(NewCombatPage, "Enable Aimbot Lock", "Aimbot", nil, Color3.fromRGB(255, 50, 50), "AimbotKeybind")
AddPremiumToggle(NewCombatPage, "Aimbot Team Guard", "TeamCheck")
AddPremiumToggle(NewCombatPage, "Aimbot Wall Occlusion", "WallCheck")
AddPremiumSlider(NewCombatPage, "Aimbot Smoothness Factor", 0, 10, "Smoothness")
AddHitboxSelector(NewCombatPage)

local AuraHeader = Instance.new("TextLabel", NewCombatPage)
AuraHeader.BackgroundTransparency = 1
AuraHeader.Size = UDim2.new(0, 175, 0, 20)
AuraHeader.Font = Enum.Font.GothamBold
AuraHeader.Text = "AURA"
AuraHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
AuraHeader.TextSize = 10
AuraHeader.TextXAlignment = Enum.TextXAlignment.Left
local AuraPad = Instance.new("UIPadding", AuraHeader)
AuraPad.PaddingLeft = UDim.new(0, 5)

AddPremiumToggle(NewCombatPage, "Enable Kill Aura", "Aura", nil, Color3.fromRGB(0, 150, 255), "AuraKeybind")
AddPremiumToggle(NewCombatPage, "Aura Team Guard", "TeamCheckAura")
AddPremiumToggle(NewCombatPage, "Aura Wall Occlusion", "AuraWallCheck")
AddPremiumSlider(NewCombatPage, "Aura Field Radius", 5, 150, "AuraRadius")
AddPremiumSlider(NewCombatPage, "Aura Smoothness Factor", 0, 10, "AuraSmoothness")
AddPremiumSlider(NewCombatPage, "Aura Transparency (%)", 0, 100, "AuraTransparency")
AddAuraColorSelector(NewCombatPage)
AddPremiumToggle(NewCombatPage, "Priority Lowest Health", "PriorityLowestHealth")

local TriggerHeader = Instance.new("TextLabel", NewCombatPage)
TriggerHeader.BackgroundTransparency = 1
TriggerHeader.Size = UDim2.new(0, 175, 0, 20)
TriggerHeader.Font = Enum.Font.GothamBold
TriggerHeader.Text = "TRIGGERBOT"
TriggerHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
TriggerHeader.TextSize = 10
TriggerHeader.TextXAlignment = Enum.TextXAlignment.Left
local TriggerPad = Instance.new("UIPadding", TriggerHeader)
TriggerPad.PaddingLeft = UDim.new(0, 5)

AddPremiumToggle(NewCombatPage, "Triggerbot Click Engine", "Triggerbot", nil, Color3.fromRGB(230, 125, 30), "TriggerbotKeybind")
AddPremiumToggle(NewCombatPage, "Triggerbot Wall Check", "TriggerWallCheck")

AddPremiumToggle(NewPlayerPage, "Enable Character Head Bow", "BowDown", nil, nil, nil)
AddPremiumSlider(NewPlayerPage, "Head Bow Angle Degree", 0, 90, "BowAngle")
AddPremiumToggle(NewPlayerPage, "Auto Farm Player (Behind)", "AutoFarmPlayer", nil, Color3.fromRGB(45, 140, 75))
AddPremiumSlider(NewPlayerPage, "Farm TP Intervallic Delay", 0.01, 5, "AutoFarmDelay")
AddPremiumToggle(NewPlayerPage, "FullBright Atmosphere", "FullBright", function(state)
    if state then Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else Lighting.Ambient = Config.StoredAmbient Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient end
end)
AddPremiumToggle(NewPlayerPage, "Enable Spinbot Axis", "Spinbot", nil, nil, "SpinbotKeybind")
AddPremiumSlider(NewPlayerPage, "Spinbot Rotate Velocity", 5, 100, "SpinSpeed")

AddPremiumToggle(NewMovementPage, "WalkSpeed Safe Bypass", "SpeedToggle", nil, Color3.fromRGB(140, 30, 230), "SpeedKeybind")
AddPremiumSlider(NewMovementPage, "Speed Core Value", 16, 200, "WalkSpeed")
AddPremiumToggle(NewMovementPage, "JumpPower Boost Axis", "JumpToggle", nil, nil, "JumpKeybind")
AddPremiumSlider(NewMovementPage, "Jump Force Magnitude", 50, 350, "JumpPower")

AddPremiumToggle(NewVisualPage, "Master ESP Overlay Control", "EspMaster", nil, Color3.fromRGB(30, 140, 230), "EspMasterKeybind")
AddPremiumToggle(NewVisualPage, "Render 3D Chams Box", "EspBox")
AddPremiumSlider(NewVisualPage, "Chams Opacity Multiplier", 0, 100, "EspTransparency")
AddPremiumToggle(NewVisualPage, "Snapline Tracers Vector", "EspTracer")
AddTracerModeSelector(NewVisualPage)
AddSyncedEspColorSelector(NewVisualPage)
AddPremiumToggle(NewVisualPage, "Informative Character Tags", "EspName")
AddPremiumToggle(NewVisualPage, "Show Character Health Meter", "EspHealth") 
AddPremiumSlider(NewVisualPage, "Max Rendering Vector Range", 100, 5000, "MaxDistance")

AddPremiumToggle(NewMiscPage, "Force Third Person View", "ThirdPerson", nil, nil, nil)
AddPremiumSlider(NewMiscPage, "Third Person Distance", 5, 100, "ThirdPersonDist")
AddPremiumToggle(NewMiscPage, "Draw Dynamic FOV Circle", "FovCircle")
AddPremiumSlider(NewMiscPage, "FOV Perimeter Range", 30, 500, "FovRadius")
AddPremiumToggle(NewMiscPage, "Crosshair Center Alignment Dot", "CrosshairDot")
AddPremiumToggle(NewMiscPage, "Anti-AFK Auto Interactor", "AntiAFK", nil, Color3.fromRGB(210, 50, 140))

AddPremiumToggle(NewMiscPage, "Lock Mobile Buttons Position", "LockMobileButtons", nil, Color3.fromRGB(200, 50, 50))

AddExportBox(NewMiscPage)
AddImportBox(NewMiscPage)

AddPremiumToggle(NewMiscPage, "Display Mobile 3RD Button", "ShowMobileTP", function(state) GlobalMobileButtons["ThirdPerson"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Display Mobile Aura Trigger", "ShowMobileAura", function(state) GlobalMobileButtons["Aura"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Display Mobile Aim Trigger", "ShowMobileAim", function(state) GlobalMobileButtons["Aimbot"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Display Mobile Trigger Clicker", "ShowMobileTrig", function(state) GlobalMobileButtons["Triggerbot"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Display Mobile Speed Toggle", "ShowMobileSpeed", function(state) GlobalMobileButtons["SpeedToggle"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Display Mobile Farm Toggle", "ShowMobileFarm", function(state) GlobalMobileButtons["AutoFarmPlayer"].Btn.Visible = (state and IsMobile) end)
AddPremiumToggle(NewMiscPage, "Menu Modular Wallpaper", "CustomBackground", function(state) CustomBackgroundImage.Visible = state end)
AddPremiumButton(NewMiscPage, "Uninject Execution Process", "UNINJECT NOW", function()
    MasterLoop:Disconnect()
    pcall(function() FOV_Drawing:Remove() end)
    pcall(function() Dot_Drawing:Remove() end)
    pcall(function() AuraVisual:Remove() end)
    pcall(function() mouse1release() end)
    for _, L in pairs(Tracer_Cache) do pcall(function() L:Remove() end) end
    for C, _ in pairs(Character_Cache) do CleanCharacterVisuals(C) end
    for neck, origC0 in pairs(NeckCache) do if neck and neck.Parent then pcall(function() neck.C0 = origC0 end) end end
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = 400
    Lighting.Ambient = Config.StoredAmbient
    Lighting.OutdoorAmbient = Config.StoredOutdoorAmbient
    ScreenGui:Destroy()
end)

AddPremiumCreditBox(NewCreditsPage, "Lead Architecture Designer", "Dai Ca Wang")
AddPremiumCreditBox(NewCreditsPage, "Framework Integrity Status", "Premium V6.9.0 - PE Control Matrix")

CreatePremiumTab("Combat", "⚔", 1, NewCombatPage)
CreatePremiumTab("Player", "👤", 2, NewPlayerPage)
CreatePremiumTab("Movement", "🏃", 3, NewMovementPage)
CreatePremiumTab("Visuals", "👁", 4, NewVisualPage)
CreatePremiumTab("Misc", "⚙", 5, NewMiscPage)
CreatePremiumTab("Credits", "👑", 6, NewCreditsPage)

local function RegisterMobileClick(Btn, Key)
    RegisterTouchFriendlyClick(Btn, function() Config[Key] = not Config[Key] UpdateToggleVisual(Key) end)
end
RegisterMobileClick(MobAim, "Aimbot")
RegisterMobileClick(MobTrig, "Triggerbot")
RegisterMobileClick(MobSpeed, "SpeedToggle")
RegisterMobileClick(MobFarm, "AutoFarmPlayer")
RegisterMobileClick(MobAura, "Aura")
RegisterMobileClick(MobTP, "ThirdPerson")
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.MenuKeybind then Config.MenuVisible = not Config.MenuVisible NewMainPanel.Visible = Config.MenuVisible
    elseif input.KeyCode == Config.AimbotKeybind and Config.AimbotKeybind ~= Enum.KeyCode.Unknown then Config.Aimbot = not Config.Aimbot UpdateToggleVisual("Aimbot")
    elseif input.KeyCode == Config.AuraKeybind and Config.AuraKeybind ~= Enum.KeyCode.Unknown then Config.Aura = not Config.Aura UpdateToggleVisual("Aura")
    elseif input.KeyCode == Config.TriggerbotKeybind and Config.TriggerbotKeybind ~= Enum.KeyCode.Unknown then Config.Triggerbot = not Config.Triggerbot UpdateToggleVisual("Triggerbot")
    elseif input.KeyCode == Config.SpinbotKeybind and Config.SpinbotKeybind ~= Enum.KeyCode.Unknown then Config.Spinbot = not Config.Spinbot UpdateToggleVisual("Spinbot")
    elseif input.KeyCode == Config.EspMasterKeybind and Config.EspMasterKeybind ~= Enum.KeyCode.Unknown then Config.EspMaster = not Config.EspMaster UpdateToggleVisual("EspMaster")
    elseif input.KeyCode == Config.SpeedKeybind and Config.SpeedKeybind ~= Enum.KeyCode.Unknown then Config.SpeedToggle = not Config.SpeedToggle UpdateToggleVisual("SpeedToggle")
    elseif input.KeyCode == Config.JumpKeybind and Config.JumpKeybind ~= Enum.KeyCode.Unknown then Config.JumpToggle = not Config.JumpToggle UpdateToggleVisual("JumpToggle")
    end
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
    local Root = Character:WaitForChild("HumanoidRootPart", 5)
    local Head = Character:WaitForChild("Head", 5)
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
        
        local headInstance = MyChar:FindFirstChild("Head")
        local torsoInstance = MyChar:FindFirstChild("UpperTorso") or MyChar:FindFirstChild("Torso")
        local neckJoint = (headInstance and headInstance:FindFirstChild("Neck")) or (torsoInstance and torsoInstance:FindFirstChild("Neck"))
        if neckJoint and neckJoint:IsA("Motor6D") then
            if not NeckCache[neckJoint] then NeckCache[neckJoint] = neckJoint.C0 end
            if Config.BowDown then neckJoint.C0 = NeckCache[neckJoint] * CFrame.Angles(math.rad(-Config.BowAngle), 0, 0)
            else neckJoint.C0 = NeckCache[neckJoint] end
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
            if Config.EspMaster and Root and MyChar and MyChar:FindFirstChild("HumanoidRootPart") and Hum then
                local PColor = GetPlayerColor(Data.Player)
                local Dist = math.floor((Root.Position - MyChar.HumanoidRootPart.Position).Magnitude)

                if Config.EspBox and Dist <= Config.MaxDistance then Data.Box.Visible = true Data.Box.Color3 = PColor Data.Box.Transparency = Config.EspTransparency / 100 else Data.Box.Visible = false end
                if Config.EspName and Dist <= Config.MaxDistance then Data.Gui.Enabled = true Data.Label.Visible = true Data.Label.TextColor3 = PColor Data.Label.Text = string.format("%s (%dm)\\n[%s] [%s]", Data.Player.Name, Dist, Data.Player.Team and Data.Player.Team.Name or "No Team", GetEquippedTool(Char)) else Data.Label.Visible = false end
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
    StarterGui:SetCore("SendNotification", {
        Title = "WANGCAOS CLIENT V6.9.0",
        Text = "Successfully hotfixed Mobile detection & Scrolling issues!",
        Duration = 7
    })
end)
-- ==============================================================================
-- END OF SCRIPT - HOTFIXED
-- ==============================================================================
