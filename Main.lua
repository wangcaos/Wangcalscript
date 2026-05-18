-- ==============================================================================
-- WANGCAOS PREMIUM CLIENT V4.7 - COMPACT EDITION
-- POWERED BY DAI CA WANG (2026)
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Config = {
    MenuVisible = true, MenuKeybind = Enum.KeyCode.RightShift,
    Aimbot = false, TeamCheck = true, WallCheck = true, Smoothness = 4,
    SilentAim = false, HitboxExpander = false, HitboxSize = 2, HitboxTrans = 50,
    KillAura = false, AuraRange = 15, EspMaster = false, FovCircle = false,
    FovRadius = 120, EspBox = false, EspTracer = false, EspName = false, MaxDistance = 500,
    SpeedToggle = false, WalkSpeed = 16, JumpToggle = false, JumpPower = 50, FullBright = false,
    AutoFarm = false, BringMobs = false, AutoCollectChest = false,
    StoredAmbient = Lighting.Ambient, StoredOutdoorAmbient = Lighting.OutdoorAmbient, Keybinds = {}
}

local SafeParent = pcall(function() return gethui() end) and gethui() or pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if SafeParent:FindFirstChild("Wangcaos_Compact_UI") then SafeParent.Wangcaos_Compact_UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Wangcaos_Compact_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = SafeParent

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0, 15, 0, 150)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "W"
ToggleButton.TextColor3 = Color3.fromRGB(150, 80, 255)
ToggleButton.TextSize = 20
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleButton).Color = Color3.fromRGB(150, 80, 255)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
MainFrame.Visible = Config.MenuVisible
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(90, 50, 160)

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "WANGCAOS COMPACT V4.7"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local function Drag(Obj, Handle)
    local active, start, startPos
    Handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active, start, startPos = true, i.Position, Obj.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then active = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - start
            Obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
Drag(ToggleButton, ToggleButton) Drag(MainFrame, Header)

local function ToggleMenu() Config.MenuVisible = not Config.MenuVisible MainFrame.Visible = Config.MenuVisible end
ToggleButton.MouseButton1Click:Connect(ToggleMenu)
UserInputService.InputBegan:Connect(function(i, p) if not p and i.KeyCode == Config.MenuKeybind then ToggleMenu() end end)
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, -20, 0, 28)
TabBar.Position = UDim2.new(0, 10, 0, 38)
TabBar.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 5)
local TLay = Instance.new("UIListLayout", TabBar)
TLay.FillDirection, TLay.SortOrder, TLay.Padding = Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, UDim.new(0, 4)

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -80)
Container.Position = UDim2.new(0, 10, 0, 72)
Container.BackgroundTransparency = 1

local Pages, Buttons = {}, {}
local function AddTab(Name, Order)
    local P = Instance.new("ScrollingFrame", Container)
    P.Size = UDim2.new(1, 0, 1, 0)
    P.BackgroundTransparency, P.BorderSizePixel, P.CanvasSize, P.ScrollBarThickness, P.Visible = 1, 0, UDim2.new(0, 0, 0, 400), 2, false
    Instance.new("UIListLayout", P).Padding = UDim.new(0, 4)
    Pages[Name] = P

    local B = Instance.new("TextButton", TabBar)
    B.Size, B.Font, B.Text, B.TextSize, B.LayoutOrder = UDim2.new(0, 92, 1, 0), Enum.Font.GothamBold, Name, 11, Order
    B.BackgroundColor3 = Order == 1 and Color3.fromRGB(50, 30, 85) or Color3.fromRGB(0,0,0)
    B.BackgroundTransparency = Order == 1 and 0 or 1
    B.TextColor3 = Order == 1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
    Buttons[Name] = B

    B.MouseButton1Click:Connect(function()
        for _, pg in pairs(Pages) do pg.Visible = false end
        for _, btn in pairs(Buttons) do btn.BackgroundTransparency, btn.TextColor3 = 1, Color3.fromRGB(140,140,140) end
        P.Visible, B.BackgroundTransparency, B.BackgroundColor3, B.TextColor3 = true, 0, Color3.fromRGB(50, 30, 85), Color3.fromRGB(255,255,255)
    end)
end

AddTab("Combat", 1) AddTab("Movement", 2) AddTab("Visuals", 3) AddTab("Farming", 4) AddTab("Misc", 5)
Pages["Combat"].Visible = true

local function AddToggle(Page, Text, Key, Call)
    local F = Instance.new("Frame", Page) F.Size, F.BackgroundTransparency = UDim2.new(1, 0, 0, 28), 1
    local L = Instance.new("TextLabel", F) L.Size, L.BackgroundTransparency, L.Font, L.Text, L.TextColor3, L.TextSize, L.TextXAlignment = UDim2.new(0.5, 0, 1, 0), 1, Enum.Font.Gotham, Text:upper(), Color3.fromRGB(200,200,200), 11, Enum.TextXAlignment.Left
    
    local Bg = Instance.new("Frame", F) Bg.Size, Bg.Position, Bg.BackgroundColor3 = UDim2.new(0, 32, 0, 16), UDim2.new(1, -38, 0.5, -8), Config[Key] and Color3.fromRGB(60, 30, 120) or Color3.fromRGB(25, 20, 35)
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)
    local St = Instance.new("UIStroke", Bg) St.Color = Config[Key] and Color3.fromRGB(150, 80, 255) or Color3.fromRGB(75, 75, 75)
    local Bl = Instance.new("Frame", Bg) Bl.Size, Bl.Position, Bl.BackgroundColor3 = UDim2.new(0, 12, 0, 12), Config[Key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), Config[Key] and Color3.fromRGB(150, 80, 255) or Color3.fromRGB(160, 160, 160)
    Instance.new("UICorner", Bl).CornerRadius = UDim.new(1, 0)

    local Bd = Instance.new("TextButton", F) Bd.Size, Bd.Position, Bd.BackgroundColor3, Bd.Font, Bd.TextSize, Bd.TextColor3, Bd.Text = UDim2.new(0, 50, 0, 20), UDim2.new(1, -95, 0.5, -10), Color3.fromRGB(30, 25, 45), Enum.Font.GothamBold, 9, Color3.fromRGB(180, 180, 180), Config.Keybinds[Key] and "["..Config.Keybinds[Key].Name.."]" or "[BIND]"
    Instance.new("UICorner", Bd).CornerRadius = UDim.new(0, 4) Instance.new("UIStroke", Bd).Color = Color3.fromRGB(70, 50, 100)

    local function Toggle()
        Config[Key] = not Config[Key]
        Bl.Position = Config[Key] and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        Bl.BackgroundColor3 = Config[Key] and Color3.fromRGB(150, 80, 255) or Color3.fromRGB(160, 160, 160)
        Bg.BackgroundColor3 = Config[Key] and Color3.fromRGB(60, 30, 120) or Color3.fromRGB(25, 20, 35)
        St.Color = Config[Key] and Color3.fromRGB(150, 80, 255) or Color3.fromRGB(75, 75, 75)
        if Call then Call(Config[Key]) end
    end
    Instance.new("TextButton", Bg).Size, Bg.TextButton.BackgroundTransparency, Bg.TextButton.Text = UDim2.new(1,0,1,0), 1, ""
    Bg.TextButton.MouseButton1Click:Connect(Toggle)

    local bind = false
    Bd.MouseButton1Click:Connect(function() bind = true Bd.Text = "[...]" end)
    UserInputService.InputBegan:Connect(function(i, p)
        if bind and i.UserInputType == Enum.UserInputType.Keyboard then
            Config.Keybinds[Key] = i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil
            Bd.Text = Config.Keybinds[Key] and "["..i.KeyCode.Name.."]" or "[BIND]" bind = false
        elseif not p and Config.Keybinds[Key] and i.KeyCode == Config.Keybinds[Key] then Toggle() end
    end)
end
local function AddSlider(Page, Text, Min, Max, Key, Call)
    local F = Instance.new("Frame", Page) F.Size, F.BackgroundTransparency = UDim2.new(1, 0, 0, 36), 1
    local L = Instance.new("TextLabel", F) L.Size, L.BackgroundTransparency, L.Font, L.Text, L.TextColor3, L.TextSize, L.TextXAlignment = UDim2.new(0.5, 0, 0, 14), 1, Enum.Font.Gotham, Text:upper(), Color3.fromRGB(200,200,200), 11, Enum.TextXAlignment.Left
    local V = Instance.new("TextLabel", F) V.Size, V.Position, V.BackgroundTransparency, V.Font, V.Text, V.TextColor3, V.TextSize, V.TextXAlignment = UDim2.new(0, 50, 0, 14), UDim2.new(1, -56, 0, 0), 1, Enum.Font.GothamBold, tostring(Config[Key]), Color3.fromRGB(150, 80, 255), 11, Enum.TextXAlignment.Right
    
    local Bar = Instance.new("Frame", F) Bar.Size, Bar.Position, Bar.BackgroundColor3 = UDim2.new(1, -12, 0, 4), UDim2.new(0, 6, 0, 20), Color3.fromRGB(25, 20, 35)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)
    local Fil = Instance.new("Frame", Bar) Fil.Size, Fil.BackgroundColor3 = UDim2.new((Config[Key] - Min) / (Max - Min), 0, 1, 0), Color3.fromRGB(150, 80, 255)
    Instance.new("UICorner", Fil).CornerRadius = UDim.new(1, 0)

    local function Upd(i)
        local r = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(Min + (Max - Min) * r)
        Fil.Size, V.Text, Config[Key] = UDim2.new(r, 0, 1, 0), tostring(val), val
        if Call then Call(val) end
    end
    local Dragging = false
    local Sb = Instance.new("TextButton", Bar) Sb.Size, Sb.BackgroundTransparency, Sb.Text = UDim2.new(1,0,1,0), 1, ""
    Sb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = true Upd(i) end end)
    UserInputService.InputChanged:Connect(function(i) if Dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Upd(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = false end end)
end

-- GÁN TÍNH NĂNG THEO TAB (GỌN GÀNG ĐẦY ĐỦ)
local CP = Pages["Combat"]
AddToggle(CP, "Aimbot Lock", "Aimbot") AddToggle(CP, "Team Filter", "TeamCheck") AddToggle(CP, "Wall Check", "WallCheck") AddSlider(CP, "Smoothness", 1, 10, "Smoothness")
AddToggle(CP, "Silent Aim", "SilentAim") AddToggle(CP, "Hitbox Expander", "HitboxExpander") AddSlider(CP, "Hitbox Size", 2, 40, "HitboxSize") AddSlider(CP, "Hitbox Trans", 0, 100, "HitboxTrans")
AddToggle(CP, "KillAura", "KillAura") AddSlider(CP, "Aura Range", 5, 40, "AuraRange")

local MP = Pages["Movement"]
AddToggle(MP, "WalkSpeed Hack", "SpeedToggle") AddSlider(MP, "Speed Val", 16, 200, "WalkSpeed")
AddToggle(MP, "JumpPower Hack", "JumpToggle") AddSlider(MP, "Jump Val", 50, 300, "JumpPower")

local VP = Pages["Visuals"]
AddToggle(VP, "ESP Master", "EspMaster") AddToggle(VP, "ESP Box", "EspBox") AddToggle(VP, "ESP Tracer", "EspTracer") AddToggle(VP, "ESP Name", "EspName") AddSlider(VP, "Max Dist", 100, 2000, "MaxDistance")
AddToggle(VP, "Draw FOV", "FovCircle") AddSlider(VP, "FOV Radius", 30, 500, "FovRadius")

local FP = Pages["Farming"]
AddToggle(FP, "Auto Farm", "AutoFarm") AddToggle(FP, "Bring Mobs", "BringMobs") AddToggle(FP, "Auto Chest", "AutoCollectChest")

local MiP = Pages["Misc"]
AddToggle(MiP, "FullBright Environment", "FullBright", function(s)
    Lighting.Ambient = s and Color3.fromRGB(255,255,255) or Config.StoredAmbient
    Lighting.OutdoorAmbient = s and Color3.fromRGB(255,255,255) or Config.StoredOutdoorAmbient
end)
local FOV_Draw = Drawing.new("Circle")
FOV_Draw.Color, FOV_Draw.Thickness, FOV_Draw.NumSides, FOV_Draw.Filled, FOV_Draw.Transparency, FOV_Draw.Visible = Color3.fromRGB(150, 80, 255), 1.5, 64, false, 0.8, false

local VisCache = {}
local function Alive(c) return c and c.Parent and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid").Health > 0 end

local function GetTarget()
    local center, target, max = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), nil, Config.FovRadius
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and Alive(p.Character) and not (Config.TeamCheck and p.Team == LocalPlayer.Team) then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if on and dist < max then max, target = dist, head end
            end
        end
    end
    return target
end

local function ClearVis(c) if not c then return end local b = c:FindFirstChild("WangBox", true) if b then b:Destroy() end local t = c:FindFirstChild("WangTag", true) if t then t:Destroy() end end

local function BuildVis(p, c)
    if not c or not c.Parent then return end local r, h = c:WaitForChild("HumanoidRootPart", 5), c:WaitForChild("Head", 5) if not r or not h then return end
    ClearVis(c)
    local b = Instance.new("BoxHandleAdornment") b.Name, b.Parent, b.Adornee, b.AlwaysOnTop, b.ZIndex, b.Size, b.Visible = "WangBox", r, r, true, 10, Vector3.new(4, 5.5, 4), false
    local g = Instance.new("BillboardGui") g.Name, g.Adornee, g.Size, g.StudsOffset, g.AlwaysOnTop, g.Parent = "WangTag", h, UDim2.new(0, 160, 0, 50), Vector3.new(0, 3, 0), true, h
    local l = Instance.new("TextLabel", g) l.Size, l.BackgroundTransparency, l.Font, l.TextSize, l.TextColor3 = UDim2.new(1,0,1,0), 1, Enum.Font.Code, 11, Color3.fromRGB(255,255,255)
    VisCache[c] = {Box = b, Gui = g, Label = l, Player = p}
end

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) BuildVis(p, c) end) end)
for _, p in pairs(Players:GetPlayers()) do if p.Character then BuildVis(p, p.Character) end end

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOV_Draw.Position, FOV_Draw.Radius, FOV_Draw.Visible = center, Config.FovRadius, Config.FovCircle
    
    local my = LocalPlayer.Character
    if Alive(my) and my:FindFirstChildOfClass("Humanoid") then
        if Config.SpeedToggle then my:FindFirstChildOfClass("Humanoid").WalkSpeed = Config.WalkSpeed end
        if Config.JumpToggle then my:FindFirstChildOfClass("Humanoid").UseJumpPower, my:FindFirstChildOfClass("Humanoid").JumpPower = true, Config.JumpPower end
    end

    if Config.Aimbot then local t = GetTarget() if t then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), Config.Smoothness / 20) end end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and Alive(p.Character) and p.Character:FindFirstChild("HumanoidRootPart") then
            local r = p.Character.HumanoidRootPart
            if Config.HitboxExpander and not (Config.TeamCheck and p.Team == LocalPlayer.Team) then
                r.Size, r.Transparency, r.CanCollide = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize), Config.HitboxTrans/100, false
            else r.Size, r.Transparency = Vector3.new(2, 2, 1), 0 end
        end
    end

    for c, d in pairs(VisCache) do
        if c and c.Parent and Alive(c) and Config.EspMaster and Alive(my) and my:FindFirstChild("HumanoidRootPart") then
            if Config.TeamCheck and d.Player.Team == LocalPlayer.Team then d.Box.Visible, d.Label.Visible = false, false continue end
            local dist = math.floor((c.HumanoidRootPart.Position - my.HumanoidRootPart.Position).Magnitude)
            if dist <= Config.MaxDistance then
                local col = d.Player.TeamColor.Color or Color3.fromRGB(150, 80, 255)
                d.Box.Visible, d.Box.Color3 = Config.EspBox, col
                d.Gui.Enabled, d.Label.Visible, d.Label.TextColor3, d.Label.Text = Config.EspName, Config.EspName, col, string.format("%s\n[%d m]", d.Player.Name, dist)
            else d.Box.Visible, d.Label.Visible = false, false end
        else if not Alive(c) then VisCache[c] = nil else d.Box.Visible, d.Label.Visible = false, false end end
    end
end)

pcall(function() StarterGui:SetCore("SendNotification", {Title = "WANGCAOS CLIENT", Text = "Bản rút gọn dòng siêu mượt đã chạy!", Duration = 5}) end)
-- ==============================================================================
-- END BUILD - POWERED BY BE FOR DAI CA WANG (2026)
-- ==============================================================================
