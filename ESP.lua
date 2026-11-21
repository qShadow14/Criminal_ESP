-- ========================================================
-- 🥷 CRIMINAL HUB - Visuals only (English)
-- Loot ESP / Police ESP / Guard ESP / Civilian ESP
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local COLORS = {
    Loot = Color3.fromRGB(255, 215, 0), Safe = Color3.fromRGB(255, 50, 50),
    Police = Color3.fromRGB(0, 100, 255), Guard = Color3.fromRGB(255, 0, 0),
    Civilian = Color3.fromRGB(0, 255, 0), ArmoredTruck = Color3.fromRGB(255, 140, 0), Bg = Color3.fromRGB(20, 20, 25),
    Panel = Color3.fromRGB(30, 30, 35), Button = Color3.fromRGB(45, 45, 55),
}
local ACCENT = Color3.fromRGB(255, 215, 0)
local FOLDERS = { Police = "Police", Guard = "Guards", ArmoredTruck = "ArmoredTruck", Civilian = "Npcs" }
local enabled = { Loot = false, Police = false, Guard = false, Civilian = false, ArmoredTruck = false, Tracers = false }
local active = {}
local lootMarks = {}

local LOOT_NAMES = {
    ["CashBag"] = true, ["GoldBar"] = true, ["DiamondNecklace"] = true, ["Handbag"] = true,
    ["SeizedCash"] = true, ["TaserItem"] = true, ["CashBox"] = true, ["PoliceRadio"] = true,
    ["PoliceBadge"] = true, ["Ring"] = true, ["RingBox"] = true, ["Wallet"] = true,
    ["Watch"] = true, ["Necklace"] = true, ["Valuables"] = true, ["WaterLilies"] = true,
    ["Masterpiece"] = true, ["FabergeEgg"] = true, ["Item"] = true
}

-- Cleanup of previous runs
if getgenv().CrimHubStop then pcall(getgenv().CrimHubStop) end
local running = true
local pg = LP:WaitForChild("PlayerGui")
for _, name in ipairs({"CrimHubV34", "CrimHubV35", "CrimHubV36", "CrimHubV37", "CrimHubLoot", "CrimHubVisuals", "CrimHubTracers"}) do
    if pg:FindFirstChild(name) then pg[name]:Destroy() end
end
for _, v in ipairs(Workspace:GetDescendants()) do
    if v.Name == "CrimESP" or v.Name == "CrimMark" then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "CrimHubVisuals"
sg.ResetOnSpawn = false
sg.Parent = pg

local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "CrimHubTracers"
tracerGui.ResetOnSpawn = false
tracerGui.IgnoreGuiInset = true
tracerGui.Parent = pg
local tracerConn = nil

-- ========================================================
-- NPC ESP (Police / Guard / Civilian / Armored Truck)
-- ========================================================
local function addHL(obj, kind)
    local hl = obj:FindFirstChild("CrimESP")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "CrimESP"
        hl.Adornee = obj
        hl.FillTransparency = 0.5
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj
    end
    hl.FillColor = COLORS[kind]
    hl.OutlineColor = COLORS[kind]
    active[obj] = { hl = hl, kind = kind }
end

local function removeKind(kind)
    for obj, rec in pairs(active) do
        if rec.kind == kind then
            if rec.hl then rec.hl:Destroy() end
            active[obj] = nil
        end
    end
end

-- ========================================================
-- LOOT ESP
-- ========================================================
local function inCharacter(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return true end
    end
    return false
end

local function hasMark(obj)
    if lootMarks[obj] then return true end
    local parent = obj.Parent
    while parent and parent ~= Workspace do
        if lootMarks[parent] then return true end
        if (parent:IsA("Model") or parent:IsA("BasePart")) and LOOT_NAMES[parent.Name] then return true end
        parent = parent.Parent
    end
    return false
end

local function markLoot(obj, isSafe)
    if not obj.Parent or inCharacter(obj) or hasMark(obj) then return end
    local color = isSafe and COLORS.Safe or COLORS.Loot
    local hl = obj:FindFirstChild("CrimESP")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "CrimESP"
        hl.Adornee = obj
        hl.FillTransparency = 0.4
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj
    end
    hl.OutlineColor = color
    hl.FillColor = color

    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    local bb
    if part then
        bb = Instance.new("BillboardGui")
        bb.Name = "CrimMark"
        bb.Adornee = part
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.Parent = sg
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 1, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.TextColor3 = color
        t.TextStrokeTransparency = 0.5
        t.Text = "◆ " .. obj.Name
        t.Parent = bb
    end
    lootMarks[obj] = {hl = hl, bb = bb, part = part, color = color}
end

local function isLoot(d)
    if not (d:IsA("Model") or d:IsA("BasePart")) then return false, false end
    local name = d.Name
    if name == "SafeDialing" or name:find("Safe") then return true, true end
    if LOOT_NAMES[name] then return true, false end
    return false, false
end

local function scanLoot()
    for _, d in ipairs(Workspace:GetDescendants()) do
        local isL, isSafe = isLoot(d)
        if isL then markLoot(d, isSafe) end
    end
end

local lootConn = nil
local function setLoot(on)
    if lootConn then lootConn:Disconnect(); lootConn = nil end
    if on then
        scanLoot()
        lootConn = Workspace.DescendantAdded:Connect(function(d)
            if enabled.Loot then
                local isL, isSafe = isLoot(d)
                if isL then task.delay(0.2, function() markLoot(d, isSafe) end) end
            end
        end)
    else
        for obj, rec in pairs(lootMarks) do
            if rec.hl then rec.hl:Destroy() end
            if rec.bb then rec.bb:Destroy() end
            lootMarks[obj] = nil
        end
    end
end

local function clearAll()
    for obj, rec in pairs(active) do
        if rec.hl then rec.hl:Destroy() end
        active[obj] = nil
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CrimESP" then v:Destroy() end
    end
    setLoot(false)
end

getgenv().CrimHubStop = function()
    running = false
    pcall(clearAll)
    pcall(function() if tracerConn then tracerConn:Disconnect() end end)
    pcall(function() tracerGui:Destroy() end)
    pcall(function() sg:Destroy() end)
end

-- Update loop: refresh NPC highlights, drop stale loot marks
task.spawn(function()
    while running and task.wait(0.5) do
        pcall(function()
            for obj, rec in pairs(lootMarks) do
                if not obj:IsDescendantOf(Workspace) or inCharacter(obj) then
                    if rec.hl then rec.hl:Destroy() end
                    if rec.bb then rec.bb:Destroy() end
                    lootMarks[obj] = nil
                end
            end
            for kind, fname in pairs(FOLDERS) do
                if enabled[kind] then
                    local f = Workspace:FindFirstChild(fname)
                    if f then
                        if kind == "ArmoredTruck" then
                            -- trucks have no Humanoid: highlight the folder itself if it is a model, else each model inside
                            if f:IsA("Model") then
                                addHL(f, kind)
                            else
                                for _, truck in ipairs(f:GetChildren()) do
                                    if truck:IsA("Model") then addHL(truck, kind) end
                                end
                            end
                        else
                            for _, npc in ipairs(f:GetChildren()) do
                                if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then addHL(npc, kind) end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ========================================================
-- TRACERS (drawn for whichever ESP toggles are on, when Tracers is enabled)
-- ========================================================
local tracerLines = {}

local function drawTracer(key, worldPos, color, used)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local v = cam:WorldToViewportPoint(worldPos)
    if v.Z <= 0 then return end -- behind the camera

    local vs = cam.ViewportSize
    local from = Vector2.new(vs.X / 2, vs.Y)
    local to = Vector2.new(v.X, v.Y)
    local delta = to - from
    local mid = (from + to) / 2

    local line = tracerLines[key]
    if not line then
        line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BorderSizePixel = 0
        line.Parent = tracerGui
        tracerLines[key] = line
    end
    line.BackgroundColor3 = color
    line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
    line.Position = UDim2.fromOffset(mid.X, mid.Y)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    used[key] = true
end

tracerConn = RunService.RenderStepped:Connect(function()
    local used = {}
    pcall(function()
        if not enabled.Tracers then return end
        if enabled.Loot then
            for obj, rec in pairs(lootMarks) do
                if rec.part and rec.part.Parent then
                    drawTracer(obj, rec.part.Position, rec.color, used)
                end
            end
        end
        for obj, rec in pairs(active) do
            if enabled[rec.kind] and obj.Parent then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if root then drawTracer(obj, root.Position, COLORS[rec.kind], used) end
            end
        end
    end)
    for key, line in pairs(tracerLines) do
        if not used[key] then
            line:Destroy()
            tracerLines[key] = nil
        end
    end
end)

-- ========================================================
-- UI
-- ========================================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 0)
MainFrame.AutomaticSize = Enum.AutomaticSize.Y
MainFrame.Position = UDim2.new(0, 30, 0, 100)
MainFrame.BackgroundColor3 = COLORS.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = sg
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Dragging
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = COLORS.Panel
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
local fixCorner = Instance.new("Frame")
fixCorner.Size = UDim2.new(1, 0, 0.5, 0)
fixCorner.Position = UDim2.new(0, 0, 0.5, 0)
fixCorner.BackgroundColor3 = COLORS.Panel
fixCorner.BorderSizePixel = 0
fixCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0.6, 0)
Title.Position = UDim2.new(0, 10, 0, 2)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = ACCENT
Title.Text = "LOOT ESP"
Title.Parent = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -60, 0.4, 0)
SubTitle.Position = UDim2.new(0, 10, 0.6, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 10
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Text = "by Shadow"
SubTitle.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 10)
MinimizeBtn.BackgroundColor3 = COLORS.Button
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TopBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 5)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 0, 0)
Content.AutomaticSize = Enum.AutomaticSize.Y
Content.Position = UDim2.new(0, 0, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)
layout.Parent = Content

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = Content

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 0, 20)
Label.BackgroundTransparency = 1
Label.Font = Enum.Font.GothamBold
Label.TextSize = 11
Label.TextColor3 = Color3.fromRGB(120, 120, 130)
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Text = "VISUALS"
Label.Parent = Content

local function makeToggle(text, kind)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = COLORS.Button
    b.TextColor3 = Color3.fromRGB(200, 200, 200)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = "○ " .. text
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 10)
    p.Parent = b

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 75)}):Play()
    end)
    b.MouseLeave:Connect(function()
        local target = enabled[kind] and COLORS.Panel or COLORS.Button
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = target}):Play()
    end)

    b.MouseButton1Click:Connect(function()
        enabled[kind] = not enabled[kind]
        if enabled[kind] then
            b.Text = "● " .. text
            b.TextColor3 = ACCENT
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Panel}):Play()
        else
            b.Text = "○ " .. text
            b.TextColor3 = Color3.fromRGB(200, 200, 200)
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Button}):Play()
        end
        if kind == "Loot" then
            setLoot(enabled[kind])
        elseif not enabled[kind] then
            removeKind(kind)
        end
    end)
    return b
end

makeToggle("Loot ESP", "Loot")
makeToggle("Police ESP", "Police")
makeToggle("Guard ESP", "Guard")
makeToggle("Civilian ESP", "Civilian")
makeToggle("Armored Truck ESP", "ArmoredTruck")
makeToggle("Tracers", "Tracers")

-- Minimize
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Content.Visible = not isMinimized
    MinimizeBtn.Text = isMinimized and "+" or "—"
end)
