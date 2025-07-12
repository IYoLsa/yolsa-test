--============================================================
--  Neo Soccer League • Exploit-Tarzı GUI + Kick-Hitbox + Cooldowns
--  Tam LocalScript – 2025-07-12
--============================================================

-- ▼ Ayarlar
local DEFAULT_RANGE      = 10.22
local DEFAULT_RING_COLOR = Color3.fromRGB(0,128,255)
local ACCENT_COLOR       = Color3.fromRGB(0,170,255)
local SOUND_ID           = "rbxassetid://541909867"

local SEGMENTS           = 48
local BAR_W, BAR_H       = 0.2, 0.05
local BALL_MODEL, BALL_PART = "PLAIN_BALL", "HITBOX_BALL"

local COOLDOWN_LIFT      = 3        -- R tuşu
local COOLDOWN_TACKLE    = 4        -- F tuşu
local KEY_LIFT           = Enum.KeyCode.R
local KEY_TACKLE         = Enum.KeyCode.F

-- ▼ Servisler
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local lp           = Players.LocalPlayer

-- ▼ Durum
local ringEnabled  = true
local currentRange = DEFAULT_RANGE
local ringColor    = DEFAULT_RING_COLOR
local soundEnabled = true

--============================================================
-- 0) Lift & Tackle Cooldown Etiketi (Baş üstü)
--============================================================
local tagGui, liftLbl, tackleLbl
local cdLift, cdTackle = 0, 0

local function createCooldownTag(char)
    local head = char:FindFirstChild("Head") or char:WaitForChild("HumanoidRootPart")
    if tagGui then tagGui:Destroy() end

    tagGui = Instance.new("BillboardGui", head)
    tagGui.Name, tagGui.Adornee, tagGui.AlwaysOnTop = "SkillCD_Tag", head, true
    tagGui.Size = UDim2.fromOffset(200,42)
    tagGui.StudsOffset = Vector3.new(0,2.8,0)

    local function makeLine(order, text)
        local l = Instance.new("TextLabel", tagGui)
        l.Size = UDim2.fromScale(1,0.5)
        l.Position = UDim2.fromScale(0,(order-1)*0.5)
        l.BackgroundTransparency = 1
        l.Font, l.TextScaled = Enum.Font.GothamBold, true
        l.TextColor3 = Color3.fromRGB(0,255,0)
        l.Text = text
        return l
    end

    liftLbl = makeLine(1, "Lift   •   Ready!")
    tackleLbl = makeLine(2, "Tackle •   Ready!")
end

local function onCharacterCooldown(char)
    createCooldownTag(char)
    cdLift, cdTackle = 0, 0
end

if lp.Character then onCharacterCooldown(lp.Character) end
lp.CharacterAdded:Connect(onCharacterCooldown)

RunService.RenderStepped:Connect(function(dt)
    if cdLift > 0 then
        cdLift -= dt
        if cdLift <= 0 then
            cdLift = 0
            liftLbl.Text, liftLbl.TextColor3 = "Lift   •   Ready!", Color3.fromRGB(0,255,0)
        else
            liftLbl.Text = string.format("Lift   •   %.1f s", cdLift)
            liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
        end
    end
    if cdTackle > 0 then
        cdTackle -= dt
        if cdTackle <= 0 then
            cdTackle = 0
            tackleLbl.Text, tackleLbl.TextColor3 = "Tackle •   Ready!", Color3.fromRGB(0,255,0)
        else
            tackleLbl.Text = string.format("Tackle •   %.1f s", cdTackle)
            tackleLbl.TextColor3 = Color3.fromRGB(255,60,60)
        end
    end
end)

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == KEY_LIFT and cdLift == 0 then
        cdLift = COOLDOWN_LIFT
        liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
    elseif inp.KeyCode == KEY_TACKLE and cdTackle == 0 then
        cdTackle = COOLDOWN_TACKLE
        tackleLbl.TextColor3 = Color3.fromRGB(255,60,60)
    end
end)

--============================================================
-- 1) Exploit-Tarzı Sekmeli UI + Kick-Hitbox
--============================================================
local gui = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "HitboxUI", false, Enum.ZIndexBehavior.Global

-- • Ana Pencere
local window = Instance.new("Frame", gui)
window.Size, window.Position = UDim2.fromOffset(420,280), UDim2.fromOffset(60,120)
window.BackgroundColor3, window.BackgroundTransparency = Color3.fromRGB(25,25,25), 0.08
window.BorderSizePixel = 0
Instance.new("UICorner", window).CornerRadius = UDim.new(0,8)

-- • Gölge
local shadow = Instance.new("ImageLabel", window)
shadow.Size, shadow.Position = UDim2.new(1,14,1,14), UDim2.fromOffset(-7,-7)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency, shadow.BackgroundTransparency = 0.7, 1
shadow.ScaleType, shadow.SliceCenter, shadow.ZIndex =
    Enum.ScaleType.Slice, Rect.new(10,10,118,118), -1

-- • Başlık Bar
local titleBar = Instance.new("Frame", window)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,8)

local tLabel = Instance.new("TextLabel", titleBar)
tLabel.Size, tLabel.Position = UDim2.new(1,-60,1,0), UDim2.fromOffset(10,0)
tLabel.BackgroundTransparency = 1
tLabel.Font, tLabel.TextSize, tLabel.TextColor3 =
    Enum.Font.GothamBold, 18, ACCENT_COLOR
tLabel.TextXAlignment = Enum.TextXAlignment.Left
tLabel.Text = "Neo Soccer • Hitbox Settings"

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size, closeBtn.Position = UDim2.fromOffset(24,24), UDim2.fromScale(1,0)+UDim2.fromOffset(-32,3)
closeBtn.Text, closeBtn.Font, closeBtn.TextSize = "×", Enum.Font.GothamBlack, 22
closeBtn.BackgroundTransparency, closeBtn.TextColor3 = 1, Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function() window.Visible = not window.Visible end)

-- • Sürükle
do
    local dragging, startPos, dragStart
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, i.Position, window.Position
        end
    end)
    titleBar.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local diff = i.Position - dragStart
            window.Position = UDim2.fromOffset(startPos.X.Offset+diff.X, startPos.Y.Offset+diff.Y)
        end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- • Yan Sekme Çubuğu
local side = Instance.new("Frame", window)
side.Size, side.Position = UDim2.new(0,90,1,-30), UDim2.fromOffset(0,30)
side.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", side).CornerRadius = UDim.new(0,8)

local tabList = Instance.new("UIListLayout", side)
tabList.Padding = UDim.new(0,6)
tabList.FillDirection = Enum.FillDirection.Vertical
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Top
tabList.SortOrder = Enum.SortOrder.LayoutOrder

local pages, currentPage = {}, nil
local function makeTab(name, icon, order)
    local btn = Instance.new("TextButton", side)
    btn.LayoutOrder, btn.Size = order, UDim2.fromOffset(70,30)
    btn.Text, btn.Font, btn.TextSize = icon.."  "..name, Enum.Font.GothamMedium, 15
    btn.TextColor3, btn.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(35,35,35)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local page = Instance.new("Frame", window)
    page.Visible, page.BackgroundTransparency = false, 1
    page.Size, page.Position = UDim2.new(1,-100,1,-40), UDim2.fromOffset(100,40)
    pages[name] = page

    btn.MouseButton1Click:Connect(function()
        if currentPage then currentPage.Visible = false end
        currentPage = page; page.Visible = true
        for _,b in ipairs(side:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35,35,35) end
        end
        btn.BackgroundColor3 = ACCENT_COLOR
    end)
    return page
end

local generalPage = makeTab("General","⚙",1)
local colorPage   = makeTab("Colors","🎨",2)
local audioPage   = makeTab("Audio","🔊",3)
task.defer(function() side:GetChildren()[1]:FindFirstChildOfClass("TextButton"):Activate() end)

-- ▼ Yardımcı Oluşturucular
local function mkButton(text,h)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(220,h or 30)
    b.Text, b.Font, b.TextSize = text, Enum.Font.GothamMedium, 16
    b.TextColor3, b.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(40,40,40)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(60,60,60)
    return b
end

local function mkInput(def)
    local i = Instance.new("TextBox")
    i.Size, i.Text = UDim2.fromOffset(220,28), def
    i.Font, i.TextSize = Enum.Font.Gotham, 15
    i.BackgroundColor3, i.TextColor3 = Color3.fromRGB(40,40,40), Color3.new(1,1,1)
    i.ClearTextOnFocus = false
    Instance.new("UICorner", i).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", i).Color = Color3.fromRGB(60,60,60)
    return i
end

-- ■ General Page
local genList = Instance.new("UIListLayout", generalPage)
genList.Padding, genList.HorizontalAlignment = UDim.new(0,4), Enum.HorizontalAlignment.Center

local ringToggle = mkButton("Ring: ON"); ringToggle.Parent = generalPage
local rangeInput = mkInput(tostring(currentRange)); rangeInput.Parent = generalPage
local applyBtn   = mkButton("Apply",24); applyBtn.Parent = generalPage
local resetBtn   = mkButton("Reset",24); resetBtn.Parent = generalPage

-- ■ Colors Page
local colors = {
    {"Blue",  Color3.fromRGB(0,128,255)},
    {"Green", Color3.fromRGB(0,255,0)},
    {"Red",   Color3.fromRGB(255,70,70)},
}
local colGrid = Instance.new("UIGridLayout", colorPage)
colGrid.CellPadding, colGrid.CellSize = UDim2.fromOffset(6,6), UDim2.fromOffset(60,28)
for _,c in ipairs(colors) do
    local but = mkButton(c[1],24)
    but.BackgroundColor3 = c[2]; but.Parent = colorPage
    but.MouseButton1Click:Connect(function()
        ringColor = c[2]
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then buildRing(hrp) end
    end)
end

-- ■ Audio Page
local audToggle = mkButton("Sound: ON"); audToggle.Parent = audioPage

--============================================================
-- 2) Halka & Hitbox Fonksiyonları
--============================================================
local function clearRing(hrp)
    for _,p in ipairs(hrp:GetChildren()) do
        if p.Name == "KickSeg" then p:Destroy() end
    end
end

function buildRing(hrp)
    clearRing(hrp)
    if not ringEnabled then return end

    local y = -hrp.Size.Y/2 + BAR_H/2 + 0.05
    local step, chord = (2*math.pi)/SEGMENTS, 2*currentRange*math.sin(math.pi/SEGMENTS)
    for i = 0, SEGMENTS-1 do
        local theta = i*step + step/2
        local seg = Instance.new("Part")
        seg.Name, seg.Size = "KickSeg", Vector3.new(chord, BAR_H, BAR_W)
        seg.Color, seg.Transparency, seg.Material = ringColor, 0.25, Enum.Material.Neon
        seg.Anchored, seg.CanCollide, seg.Massless = false, false, true
        seg.CFrame = hrp.CFrame
            * CFrame.new(math.cos(theta)*currentRange, y, math.sin(theta)*currentRange)
            * CFrame.Angles(0, -theta, 0)
        seg.Parent = hrp
        local weld = Instance.new("WeldConstraint", seg)
        weld.Part0, weld.Part1 = hrp, seg
    end
end

local function getSound(hrp)
    local s = hrp:FindFirstChild("KickSnd") or Instance.new("Sound", hrp)
    s.Name, s.SoundId, s.Volume = "KickSnd", SOUND_ID, 1
    return s
end

local function getLabel(ball)
    local gui = ball:FindFirstChild("ReachGui") or Instance.new("BillboardGui", ball)
    gui.Name, gui.Size, gui.AlwaysOnTop = "ReachGui", UDim2.fromOffset(130,34), true
    gui.StudsOffset = Vector3.new(0, ball.Size.Y/2 + 1.8, 0)

    local lbl = gui:FindFirstChild("Lbl") or Instance.new("TextLabel", gui)
    lbl.Name, lbl.Size, lbl.BackgroundTransparency = "Lbl", UDim2.fromScale(1,1), 1
    lbl.Font, lbl.TextScaled, lbl.TextStrokeTransparency = Enum.Font.GothamBold, true, 0.7
    return lbl
end

--============================================================
-- 3) UI Olayları
--============================================================
ringToggle.MouseButton1Click:Connect(function()
    ringEnabled = not ringEnabled
    ringToggle.Text = "Ring: " .. (ringEnabled and "ON" or "OFF")
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then (ringEnabled and buildRing or clearRing)(hrp) end
end)

applyBtn.MouseButton1Click:Connect(function()
    local v = tonumber(rangeInput.Text)
    if v and v > 0 then currentRange = v end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)

audToggle.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    audToggle.Text = "Sound: " .. (soundEnabled and "ON" or "OFF")
end)

resetBtn.MouseButton1Click:Connect(function()
    ringEnabled, currentRange, ringColor, soundEnabled =
        true, DEFAULT_RANGE, DEFAULT_RING_COLOR, true
    ringToggle.Text, audToggle.Text, rangeInput.Text = 
        "Ring: ON", "Sound: ON", tostring(currentRange)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)

--============================================================
-- 4) Karakter & Top İzleme
--============================================================
local function onCharacter(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    buildRing(hrp)
    local beep = getSound(hrp)
    local prev = false

    -- Top parçasını bekle
    task.spawn(function()
        local ball
        repeat
            local m = workspace:FindFirstChild(BALL_MODEL, true)
            ball = m and m:FindFirstChild(BALL_PART, true)
            task.wait(0.2)
        until ball and ball:IsA("BasePart")

        local lbl = getLabel(ball)
        RunService.Heartbeat:Connect(function()
            local inside = (ball.Position - hrp.Position).Magnitude <= currentRange
            if inside and not prev and soundEnabled then beep:Play() end
            prev = inside
            lbl.Text = inside and "Reachable" or "Unreachable!"
            lbl.TextColor3 = inside and Color3.new(0,1,0) or Color3.new(1,0,0)
        end)
    end)
end

if lp.Character then onCharacter(lp.Character) end
lp.CharacterAdded:Connect(onCharacter)
