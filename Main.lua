local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================================
-- HỆ THỐNG CẤU HÌNH & ENGINE ĐỊNH VỊ (CONFIG)
-- ==========================================================
local Config = {
    Aimbot_Enabled = false,
    AimbotMode = "Mọi người", 
    FOV_Enabled = true,       
    FOV_Radius = 140,         
    ESP_Box_Enabled = false,    
    ESP_Chams_Enabled = false,  
    SnapSpeed = 0.85,         
    SwitchDelay = 0.05        
}

local CurrentTarget = nil
local TargetStartTime = 0
local ESP_Data = {}

-- Khởi tạo Highlight màu đỏ cho mục tiêu Aimbot
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "Wangcaos_TargetHighlight"
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.FillTransparency = 0.5
TargetHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineTransparency = 0
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.Adornee = nil

-- Thư mục gốc chứa GUI bảo mật
local ParentGui = game:GetService("CoreGui")
pcall(function() if gethui then ParentGui = gethui() end end)

TargetHighlight.Parent = ParentGui

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "Wangcaos_ChamsFolder"
ChamsFolder.Parent = ParentGui

-- Dọn dẹp bản chạy cũ nếu trùng lặp
if ParentGui:FindFirstChild("Wangcaos_SplitMenu") then
    ParentGui["Wangcaos_SplitMenu"]:Destroy()
end

-- ==========================================================
-- HÀM XỬ LÝ KÉO THẢ NGHIÊM NGẶT (STRICT DRAGGING)
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
-- BỘ LỌC ĐỐI TƯỢNG VÀ KIỂM TRA ĐỘ KHẢ DỤNG (LOGIC ENGINE)
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
                local isAllowed = (Config.AimbotMode == "Mọi người") or (Config.AimbotMode == "Khác team" and p.Team ~= LocalPlayer.Team)
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

local function UpdateChams()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if Config.ESP_Chams_Enabled and char and LogicEngine.IsAlive(char) then
                local hl = ChamsFolder:FindFirstChild(p.Name)
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = p.Name
                    hl.Parent = ChamsFolder
                    hl.FillColor = Color3.fromRGB(0, 255, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
                hl.Adornee = char
            else
                local hl = ChamsFolder:FindFirstChild(p.Name)
                if hl then hl:Destroy() end
            end
        end
    end
end

-- ==========================================================
-- THIẾT KẾ GIAO DIỆN HÌNH KHỐI PHONG CÁCH CŨ (GUI)
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui", ParentGui)
ScreenGui.Name = "Wangcaos_SplitMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Nút tròn thu phóng di động "GH"
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

-- Khung hiển thị trung tâm bo góc
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

-- Thanh Header Tiêu Đề - Vùng duy nhất để điều hướng vị trí bảng
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TitleBar.BorderSizePixel = 0
local BarCorner = Instance.new("UICorner", TitleBar)
BarCorner.CornerRadius = UDim.new(0, 6)

MakeDraggable(TitleBar, MainFrame)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Text = "  wangcaos script (Full Legacy Build)"
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
    TargetHighlight:Destroy() ChamsFolder:Destroy() ScreenGui:Destroy() 
end)

-- Vùng đệm các nút bấm tương tác
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -24, 1, -42)
ContentFrame.Position = UDim2.new(0, 12, 0, 36)
ContentFrame.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, 7)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Trình khởi tạo Checkbox vuông bo cạnh
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
-- ĐỒNG BỘ LOGIC HOẠT ĐỘNG VÀ VÒNG LẶP HỆ THỐNG
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

local AimBtn, AimLabel, AimStroke = CreateMenuRow("Aimbot + Kéo Tâm Siêu Tốc", 1)
ToggleVisual(AimBtn, AimStroke, Config.Aimbot_Enabled)
AimBtn.MouseButton1Click:Connect(function()
    Config.Aimbot_Enabled = not Config.Aimbot_Enabled
    ToggleVisual(AimBtn, AimStroke, Config.Aimbot_Enabled)
end)

local FovBtn, FovLabel, FovStroke = CreateMenuRow("Vòng Tròn Định Vị FOV (Trắng)", 2)
ToggleVisual(FovBtn, FovStroke, Config.FOV_Enabled)
FovBtn.MouseButton1Click:Connect(function()
    Config.FOV_Enabled = not Config.FOV_Enabled
    ToggleVisual(FovBtn, FovStroke, Config.FOV_Enabled)
end)

local EspBoxBtn, EspBoxLabel, EspBoxStroke = CreateMenuRow("ESP Khung Vuông Định Vị", 3)
ToggleVisual(EspBoxBtn, EspBoxStroke, Config.ESP_Box_Enabled)
EspBoxBtn.MouseButton1Click:Connect(function()
    Config.ESP_Box_Enabled = not Config.ESP_Box_Enabled
    ToggleVisual(EspBoxBtn, EspBoxStroke, Config.ESP_Box_Enabled)
end)

local ChamsBtn, ChamsLabel, ChamsStroke = CreateMenuRow("Chams Nhìn Xuyên Vật Cản", 4)
ToggleVisual(ChamsBtn, ChamsStroke, Config.ESP_Chams_Enabled)
ChamsBtn.MouseButton1Click:Connect(function()
    Config.ESP_Chams_Enabled = not Config.ESP_Chams_Enabled
    ToggleVisual(ChamsBtn, ChamsStroke, Config.ESP_Chams_Enabled)
    if not Config.ESP_Chams_Enabled then ChamsFolder:ClearAllChildren() end
end)

-- Tạo cụm menu thả lựa chọn chế độ ngắm
local DropRow = Instance.new("Frame", ContentFrame)
DropRow.Size = UDim2.new(1, 0, 0, 28)
DropRow.BackgroundTransparency = 1
DropRow.LayoutOrder = 5

local DropTitle = Instance.new("TextLabel", DropRow)
DropTitle.Text = "Mục tiêu quét:"
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
BuildOption("None") BuildOption("Khác team") BuildOption("Mọi người") BuildOption("Bot")

-- Thiết lập công cụ vẽ khung vẽ ngoại vi (Drawing API)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

local function BuildESP(player)
    if player == LocalPlayer or ESP_Data[player] then return end
    local parts = {
        Top = Drawing.new("Line"), Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"), Right = Drawing.new("Line")
    }
    for _, line in pairs(parts) do
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 0, 0)
        line.Transparency = 1
        line.Visible = false
    end
    ESP_Data[player] = parts
end

Players.PlayerRemoving:Connect(function(p)
    if ESP_Data[p] then for _, l in pairs(ESP_Data[p]) do l:Remove() end ESP_Data[p] = nil end
    if ChamsFolder:FindFirstChild(p.Name) then ChamsFolder[p.Name]:Destroy() end
end)
Players.PlayerAdded:Connect(BuildESP)
for _, v in pairs(Players:GetPlayers()) do BuildESP(v) end

-- VÒNG LẶP XỬ LÝ FRAME-BY-FRAME KHÔNG KHỰNG TÂM
RunService.RenderStepped:Connect(function()
    UpdateChams()

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV_Radius
    FOVCircle.Visible = Config.FOV_Enabled 

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

    for _, p in pairs(Players:GetPlayers()) do
        local lines = ESP_Data[p]
        if not lines then continue end
        local char = p.Character
        if Config.ESP_Box_Enabled and LogicEngine.IsAlive(char) then
            local root = char.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(char.Head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local h = math.abs(headPos.Y - legPos.Y)
                local w = h / 2
                local x, y = pos.X - w/2, pos.Y - h/2

                lines.Top.From = Vector2.new(x, y) lines.Top.To = Vector2.new(x + w, y)
                lines.Bottom.From = Vector2.new(x, y + h) lines.Bottom.To = Vector2.new(x + w, y + h)
                lines.Left.From = Vector2.new(x, y) lines.Left.To = Vector2.new(x, y + h)
                lines.Right.From = Vector2.new(x + w, y) lines.Right.To = Vector2.new(x + w, y + h)

                for _, l in pairs(lines) do l.Visible = true end
            else
                for _, l in pairs(lines) do l.Visible = false end
            end
        else
            for _, l in pairs(lines) do l.Visible = false end
        end
    end
end)

print("--- [Wangcaos Unified Version V14 - 200+ Lines Checked] ---")
