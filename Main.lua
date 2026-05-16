local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================================
-- PHẦN 1: HỆ THỐNG CẤU HÌNH (CONFIG) - SIÊU NHẠY & CHUẨN FOV
-- ==========================================================
local Config = {
    Aimbot_Enabled = false,
    AimbotMode = "Mọi người", 
    FOV_Enabled = true,       
    FOV_Radius = 140,         
    ESP_Enabled = false,
    SnapSpeed = 0.85,         -- Giữ độ nhạy cao để dính mục tiêu cực bốc
    SwitchDelay = 0.05        -- Giảm tối đa độ trễ để chuyển mục tiêu sống khác ngay khi thằng cũ chết
}

local CurrentTarget = nil
local TargetStartTime = 0
local ESP_Data = {}

-- Khởi tạo hiệu ứng Highlights Đỏ bao quanh mục tiêu khi bị Aim
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "Wangcaos_TargetHighlight"
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.FillTransparency = 0.5
TargetHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineTransparency = 0
TargetHighlight.Adornee = nil
TargetHighlight.Parent = game:GetService("CoreGui")

-- Kiểm tra phân vùng hiển thị UI an toàn
local ParentGui = game:GetService("CoreGui")
pcall(function()
    if gethui then ParentGui = gethui() end
end)

if ParentGui:FindFirstChild("Wangcaos_SplitMenu") then
    ParentGui["Wangcaos_SplitMenu"]:Destroy()
end

-- Thuật toán kéo thả giao diện mượt mà cho cả PC và Mobile
local function ApplyDragging(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
-- ==========================================================
-- PHẦN 2: LÕI XỬ LÝ CHỨC NĂNG - LOẠI BỎ THẰNG CHẾT NGAY LẬP TỨC
-- ==========================================================
local LogicEngine = {}

-- Kiểm tra tường chắn vật cản Raycast
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

-- [HÀM KIỂM TRA MỤC TIÊU CÒN SỐNG THỰC SỰ KHÔNG] - Bộ lọc chống khựng tối ưu
function LogicEngine.IsAlive(char)
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    -- Nếu thiếu các bộ phận cốt lõi, hoặc máu <= 0, hoặc đã vào trạng thái Dead -> Loại luôn
    if not humanoid or not rootPart or not head then return false end
    if humanoid.Health <= 0 then return false end
    if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    
    return true
end

-- Thuật toán quét tìm mục tiêu nằm trong vòng tròn FOV (Chỉ quét người sống)
function LogicEngine.GetClosestTarget()
    if Config.AimbotMode == "None" then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local selectedTarget, closest = nil, Config.FOV_Radius

    if Config.AimbotMode == "Bot" then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and LogicEngine.IsAlive(obj) then
                if not Players:GetPlayerFromCharacter(obj) then
                    local head = obj.Head
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and LogicEngine.IsVisible(head, obj) then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < closest then closest = dist selectedTarget = head end
                    end
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

-- Khởi tạo vòng tròn FOV trắng định vị giữa màn hình
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

-- Vòng lặp Render cập nhật vị trí khóa tâm mượt mà không khựng
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV_Radius
    FOVCircle.Visible = Config.FOV_Enabled 

    if Config.Aimbot_Enabled then
        -- Kiểm tra liên tục: Nếu thằng cũ vừa chết, hủy ghim ngay lập tức không chờ vòng lặp quét mới
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

        -- Khi đã khóa được mục tiêu còn sống chuẩn đét
        if CurrentTarget and CurrentTarget.Parent and LogicEngine.IsAlive(CurrentTarget.Parent) then
            -- Dí tâm mượt mà siêu tốc
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, CurrentTarget.Position), Config.SnapSpeed)
            -- Bật Highlights đỏ rực quấn quanh người kẻ địch còn sống đó
            TargetHighlight.Adornee = CurrentTarget.Parent
        else
            TargetHighlight.Adornee = nil
        end
    else
        TargetHighlight.Adornee = nil
    end
end)
-- ==========================================================
-- PHẦN 3: TRỤC KẾT NỐI GIAO DIỆN (GUI) - CHIA THEO TỪNG NÚT BẤM
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui", ParentGui)
ScreenGui.Name = "Wangcaos_SplitMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Nút tròn mở menu nhanh trên Mobile
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
ApplyDragging(MobileToggleBtn)

-- Khung Menu Chính màu đen giống ảnh của đại ca
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 260)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Color = Color3.fromRGB(50, 50, 50)
ApplyDragging(MainFrame)

MobileToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Thanh Tiêu Đề
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 26)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Text = "  wangcaos script (Anti-Lag Alive)"
TitleText.TextColor3 = Color3.new(1, 1, 1)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Size = UDim2.new(1, -30, 1, 0)
TitleText.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -23, 0, 3)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Khung chứa danh sách các dòng tùy chọn
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -20, 1, -36)
ContentFrame.Position = UDim2.new(0, 10, 0, 31)
ContentFrame.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Hàm mẫu tạo dòng Checkbox cơ sở
local function CreateMenuRow(labelText, layoutOrder)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder

    local box = Instance.new("TextButton", row)
    box.Size = UDim2.new(0, 16, 0, 16)
    box.Position = UDim2.new(0, 0, 0.5, -8)
    box.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    box.BorderSizePixel = 0
    box.Text = ""
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.BackgroundTransparency = 0.8

    local label = Instance.new("TextLabel", row)
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 24, 0, 0)
    label.BackgroundTransparency = 1

    return box, label
end
-- ==========================================================
-- CHI TIẾT LOGIC KẾT NỐI TỪNG NÚT BẤM (GUI 1 BÊN, CODE VẬN HÀNH 1 BÊN)
-- ==========================================================

-- ----------------------------------------------------------
-- [NÚT 1]: ĐIỀU KHIỂN CHỨC NĂNG AIMBOT + HIGHLIGHTS ĐỎ ĐI KÈM
-- ----------------------------------------------------------
local AimBtn, AimLabel = CreateMenuRow("Aimbot + Highlights Đỏ", 1)
AimBtn.BackgroundTransparency = Config.Aimbot_Enabled and 0 or 0.8

AimBtn.MouseButton1Click:Connect(function()
    Config.Aimbot_Enabled = not Config.Aimbot_Enabled
    AimBtn.BackgroundTransparency = Config.Aimbot_Enabled and 0 or 0.8
    AimLabel.TextColor3 = Config.Aimbot_Enabled and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
end)

-- ----------------------------------------------------------
-- [NÚT 2]: ĐIỀU KHIỂN BẬT/TẮT VÒNG TRÒN FOV TRẮNG TRÊN MÀN HÌNH
-- ----------------------------------------------------------
local FovBtn, FovLabel = CreateMenuRow("Vòng tròn định vị FOV (Trắng)", 2)
FovBtn.BackgroundTransparency = Config.FOV_Enabled and 0 or 0.8

FovBtn.MouseButton1Click:Connect(function()
    Config.FOV_Enabled = not Config.FOV_Enabled
    FovBtn.BackgroundTransparency = Config.FOV_Enabled and 0 or 0.8
    FovLabel.TextColor3 = Config.FOV_Enabled and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
end)

-- ----------------------------------------------------------
-- [NÚT 3]: ĐIỀU KHIỂN HỆ THỐNG ĐỒ HỌA FULL ESP KHUNG VUÔNG KHÔNG LỖI
-- ----------------------------------------------------------
local EspBtn, EspLabel = CreateMenuRow("Kích hoạt Full ESP Khung Đỏ", 3)
EspBtn.BackgroundTransparency = Config.ESP_Enabled and 0 or 0.8

EspBtn.MouseButton1Click:Connect(function()
    Config.ESP_Enabled = not Config.ESP_Enabled
    EspBtn.BackgroundTransparency = Config.ESP_Enabled and 0 or 0.8
    EspLabel.TextColor3 = Config.ESP_Enabled and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
end)

-- ----------------------------------------------------------
-- [MỤC DÀNH CHO MENU CHỌN ĐỐI TƯỢNG (DROPDOWN)]
-- ----------------------------------------------------------
local DropRow = Instance.new("Frame", ContentFrame)
DropRow.Size = UDim2.new(1, 0, 0, 26)
DropRow.BackgroundTransparency = 1
DropRow.LayoutOrder = 4

local DropTitle = Instance.new("TextLabel", DropRow)
DropTitle.Text = "Mục tiêu Aim:"
DropTitle.TextColor3 = Color3.new(1, 1, 1)
DropTitle.Font = Enum.Font.SourceSansBold
DropTitle.TextSize = 14
DropTitle.TextXAlignment = Enum.TextXAlignment.Left
DropTitle.Size = UDim2.new(0, 90, 1, 0)
DropTitle.BackgroundTransparency = 1

local DropMainBtn = Instance.new("TextButton", DropRow)
DropMainBtn.Size = UDim2.new(0, 120, 0, 22)
DropMainBtn.Position = UDim2.new(0, 95, 0.5, -11)
DropMainBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
DropMainBtn.Text = Config.AimbotMode .. "  ▼"
DropMainBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
DropMainBtn.Font = Enum.Font.SourceSansBold
DropMainBtn.TextSize = 13
Instance.new("UICorner", DropMainBtn).CornerRadius = UDim.new(0, 4)

local DropContainer = Instance.new("Frame", ScreenGui)
DropContainer.Size = UDim2.new(0, 120, 0, 90)
DropContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropContainer.Visible = false
DropContainer.ZIndex = 15
Instance.new("UICorner", DropContainer).CornerRadius = UDim.new(0, 4)
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
BuildOption("None")
BuildOption("Khác team")
BuildOption("Mọi người")
BuildOption("Bot")

-- ==========================================================
-- ĐỘNG CƠ RENDER KHUNG ESP ĐỎ ĐỘC LẬP (CHỈ VẼ TRÊN NGƯỜI SỐNG)
-- ==========================================================
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

RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        local lines = ESP_Data[p]
        if not lines then if p ~= LocalPlayer then BuildESP(p) end continue end

        local char = p.Character
        if Config.ESP_Enabled and LogicEngine.IsAlive(char) then
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

Players.PlayerRemoving:Connect(function(p)
    if ESP_Data[p] then
        for _, l in pairs(ESP_Data[p]) do l:Remove() end
        ESP_Data[p] = nil
    end
end)
Players.PlayerAdded:Connect(BuildESP)
for _, v in pairs(Players:GetPlayers()) do BuildESP(v) end

print("--- [Wangcaos Fixed Anti-Dead Target Architecture V10 Loaded!] ---")
