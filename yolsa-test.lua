--============================================================
--  Neo Soccer League • Exploit-Tarzı GUI + Kick-Hitbox + Lift CD
--  Tam LocalScript – 2025-07-12  (güncel)
--============================================================

--▼ AYARLAR ---------------------------------------------------
local DEFAULT_RANGE      = 10.22
local DEFAULT_RING_COLOR = Color3.fromRGB(0,128,255)
local ACCENT_COLOR       = Color3.fromRGB(0,170,255)
local SOUND_ID           = "rbxassetid://541909867"

local SEGMENTS           = 48
local BAR_W, BAR_H       = 0.2, 0.05
local BALL_MODEL, BALL_PART = "PLAIN_BALL", "HITBOX_BALL"

local LIFT_COOLDOWN      = 3            -- saniye: kendi lift CD süren

--▼ SERVİSLER -------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("ReplicatedStorage")
local lp           = Players.LocalPlayer
local CoreGui      = game:GetService("CoreGui")
local StarterGui   = game:GetService("StarterGui")

--▼ DURUM -----------------------------------------------------
local ringEnabled  = true
local currentRange = DEFAULT_RANGE
local ringColor    = DEFAULT_RING_COLOR
local soundEnabled = true

--////////////////////////////////////////////////////////////
--  Lift Cool-down • yalnızca R tuşu • etiket baş üstünde
--////////////////////////////////////////////////////////////
local COOLDOWN = 3
local KEY      = Enum.KeyCode.R

local Players  = game:GetService("Players")
local Run      = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local lp       = Players.LocalPlayer

----------------------------------------------------------------
--  Etiket kurucu
----------------------------------------------------------------
local function createTag(char)
    local head = char:FindFirstChild("Head") or char:WaitForChild("HumanoidRootPart")
    -- Mevcut etiket varsa sil
    local old = head:FindFirstChild("LiftTag")
    if old then old:Destroy() end

    local tag = Instance.new("BillboardGui", head)
    tag.Name, tag.Adornee = "LiftTag", head
    tag.Size, tag.AlwaysOnTop = UDim2.fromOffset(200,30), true
    tag.StudsOffset = Vector3.new(0, 2.5, 0)

    local lbl = Instance.new("TextLabel", tag)
    lbl.Name, lbl.Size, lbl.BackgroundTransparency = "Lbl", UDim2.fromScale(1,1), 1
    lbl.Font, lbl.TextScaled, lbl.TextColor3 = Enum.Font.GothamBold, true, Color3.new(1,1,1)
    lbl.Text = "Lift   •   Ready!"

    return lbl
end

----------------------------------------------------------------
--  Karakter yüklenince etiket hazırla
----------------------------------------------------------------
local label          -- TextLabel referansı
local cd, active = 0, false

local function onCharacter(char)
    label = createTag(char)
    cd, active = 0, false
end
if lp.Character then onCharacter(lp.Character) end
lp.CharacterAdded:Connect(onCharacter)

----------------------------------------------------------------
--  Geri sayım
----------------------------------------------------------------
Run.RenderStepped:Connect(function(dt)
    if active and cd > 0 then
        cd -= dt
        if cd <= 0 then
            active = false
            cd     = 0
            if label then
                label.Text = "Lift   •   Ready!"
                label.TextColor3 = Color3.fromRGB(0,255,0)
            end
        else
            if label then
                label.Text = string.format("Lift   •   %.1f s", cd)
                label.TextColor3 = Color3.fromRGB(255,60,60)
            end
        end
    end
end)

----------------------------------------------------------------
--  R tuşu → CD başlat
----------------------------------------------------------------
UIS.InputBegan:Connect(function(inp, gp)
    if gp or inp.KeyCode ~= KEY or active == true then return end
    active = true
    cd     = COOLDOWN
    if label then
        label.Text = string.format("Lift   •   %.1f s", cd)
        label.TextColor3 = Color3.fromRGB(255,60,60)   -- kırmızı
    end
end)

-- Dribble Remote hook (Lift tetikleyicisi)
local DribbleRemote = RS:WaitForChild("Remotes"):WaitForChild("Ball"):WaitForChild("Dribble")
do
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt,false)
    mt.__namecall = newcclosure(function(self,...)
        local method = getnamecallmethod()
        if self == DribbleRemote and method == "FireServer" then
            -- Vektör argümanı y>0 ve bool true ise Lift hareketi
            local args = {...}
            local dir  = args[2]
            local flag = args[3]
            if typeof(dir)=="Vector3" and dir.Y > 0.5 and flag == true then
                cdLeft = LIFT_COOLDOWN
                cdLabel.BackgroundColor3 = Color3.fromRGB(120,40,40)
                cdLabel.Text = string.format("Lift   •   %.1f s", cdLeft)
            end
        end
        return old(self,...)
    end)
    setreadonly(mt,true)
end

--============================================================
-- 1) GUI OLUŞUMU (sekmeli) ----------------------------------
--================================================------------
local gui = Instance.new("ScreenGui", lp.PlayerGui)
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior =
    "HitboxUI", false, Enum.ZIndexBehavior.Global

--— PENCERE
local window = Instance.new("Frame", gui)
window.Size, window.Position = UDim2.fromOffset(420,280), UDim2.fromOffset(60,120)
window.BackgroundColor3, window.BackgroundTransparency = Color3.fromRGB(25,25,25), 0.08
window.BorderSizePixel = 0
Instance.new("UICorner", window).CornerRadius = UDim.new(0,8)
local shadow = Instance.new("ImageLabel", window)
shadow.Size, shadow.Position = UDim2.new(1,14,1,14), UDim2.fromOffset(-7,-7)
shadow.Image               = "rbxassetid://1316045217"
shadow.BackgroundTransparency = 1
shadow.ImageTransparency   = 0.7
shadow.ScaleType, shadow.SliceCenter, shadow.ZIndex =
    Enum.ScaleType.Slice, Rect.new(10,10,118,118), -1

--— BAŞLIK BAR
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
tLabel.Text = "Neo Soccer • Hitbox GUI"
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size, closeBtn.Position = UDim2.fromOffset(24,24), UDim2.fromScale(1,0)+UDim2.fromOffset(-32,3)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 22
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function() window.Visible = not window.Visible end)
-- sürükle
do
    local drag, startPos, dragStart
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; dragStart=i.Position; startPos=window.Position
        end
    end)
    titleBar.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local diff=i.Position-dragStart
            window.Position = UDim2.fromOffset(startPos.X.Offset+diff.X,startPos.Y.Offset+diff.Y)
        end
    end)
    titleBar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

--— YAN SEKME ÇUBUĞU
local side = Instance.new("Frame", window)
side.Size, side.Position = UDim2.new(0,90,1,-30), UDim2.fromOffset(0,30)
side.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", side).CornerRadius = UDim.new(0,8)
local tabList = Instance.new("UIListLayout", side)
tabList.Padding = UDim.new(0,6)
tabList.FillDirection = Enum.FillDirection.Vertical
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Top

local pages, currentPage = {}, nil
local function makeTab(name, icon, order)
    local btn = Instance.new("TextButton", side)
    btn.LayoutOrder, btn.Size = order, UDim2.fromOffset(70,30)
    btn.Text, btn.Font, btn.TextSize = icon.."  "..name, Enum.Font.GothamMedium, 15
    btn.TextColor3, btn.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(35,35,35)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local page = Instance.new("Frame", window)
    page.Visible, page.BackgroundTransparency = false,1
    page.Size, page.Position = UDim2.new(1,-100,1,-40), UDim2.fromOffset(100,40)
    pages[name]=page
    btn.MouseButton1Click:Connect(function()
        if currentPage then currentPage.Visible=false end
        currentPage=page; page.Visible=true
        for _,b in ipairs(side:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(35,35,35) end
        end
        btn.BackgroundColor3 = ACCENT_COLOR
    end)
    return page
end

local generalPage = makeTab("General","⚙",1)
local colorPage   = makeTab("Colors","🎨",2)
local audioPage   = makeTab("Audio","🔊",3)
task.defer(function() side:GetChildren()[1]:FindFirstChildOfClass("TextButton"):Activate() end)

--▼ Yardımcı UI oluşturucular
local function mkButton(text,h)
    local b = Instance.new("TextButton")
    b.Size, b.Text = UDim2.fromOffset(220,h or 30), text
    b.Font, b.TextSize = Enum.Font.GothamMedium, 16
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

-- Genel sekme
local gList = Instance.new("UIListLayout", generalPage)
gList.Padding = UDim.new(0,4); gList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local ringToggle = mkButton("Ring: ON"); ringToggle.Parent = generalPage
local rangeInput = mkInput(tostring(currentRange)); rangeInput.Parent = generalPage
local applyBtn   = mkButton("Apply",24); applyBtn.Parent = generalPage
local resetBtn   = mkButton("Reset",24); resetBtn.Parent = generalPage

-- Colors sekmesi
local colors = {
    {"Blue",  Color3.fromRGB(0,128,255)},
    {"Green", Color3.fromRGB(0,255,0)},
    {"Red",   Color3.fromRGB(255,70,70)},
}
local colGrid = Instance.new("UIGridLayout", colorPage)
colGrid.CellPadding, colGrid.CellSize = UDim2.fromOffset(6,6), UDim2.fromOffset(60,28)
for _,c in ipairs(colors) do
    local but = mkButton(c[1],24); but.BackgroundColor3=c[2]; but.Parent=colorPage
    but.MouseButton1Click:Connect(function()
        ringColor=c[2]; local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then buildRing(hrp) end
    end)
end

-- Audio sekmesi
local audToggle = mkButton("Sound: ON"); audToggle.Parent = audioPage

--============================================================
-- 2) Halka Fonksiyonları
--============================================================
local function clearRing(hrp)
    for _,p in ipairs(hrp:GetChildren()) do if p.Name=="KickSeg" then p:Destroy() end end
end

function buildRing(hrp)
    clearRing(hrp); if not ringEnabled then return end
    local y = -hrp.Size.Y/2 + BAR_H/2 + 0.05
    local step, chord = (2*math.pi)/SEGMENTS, 2*currentRange*math.sin(math.pi/SEGMENTS)
    for i=0, SEGMENTS-1 do
        local theta = i*step + step/2
        local seg = Instance.new("Part")
        seg.Name, seg.Size = "KickSeg", Vector3.new(chord,BAR_H,BAR_W)
        seg.Color, seg.Transparency, seg.Material = ringColor,0.25,Enum.Material.Neon
        seg.Anchored, seg.CanCollide, seg.Massless = false,false,true
        seg.CFrame = hrp.CFrame * CFrame.new(math.cos(theta)*currentRange, y, math.sin(theta)*currentRange)
                     * CFrame.Angles(0,-theta,0)
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
    gui.Name, gui.Size, gui.AlwaysOnTop =
        "ReachGui", UDim2.fromOffset(130,34), true
    gui.StudsOffset = Vector3.new(0, ball.Size.Y/2 + 1.8, 0)
    local lbl = gui:FindFirstChild("Lbl") or Instance.new("TextLabel", gui)
    lbl.Name, lbl.Size, lbl.BackgroundTransparency = "Lbl", UDim2.fromScale(1,1),1
    lbl.Font, lbl.TextScaled, lbl.TextStrokeTransparency =
        Enum.Font.GothamBold, true,0.7
    return lbl
end

--============================================================
-- 3) UI BUTON OLAYLARI
--============================================================
ringToggle.MouseButton1Click:Connect(function()
    ringEnabled = not ringEnabled
    ringToggle.Text = "Ring: "..(ringEnabled and "ON" or "OFF")
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then (ringEnabled and buildRing or clearRing)(hrp) end
end)

applyBtn.MouseButton1Click:Connect(function()
    local v=tonumber(rangeInput.Text); if v and v>0 then currentRange=v end
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)

audToggle.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    audToggle.Text = "Sound: "..(soundEnabled and "ON" or "OFF")
end)

resetBtn.MouseButton1Click:Connect(function()
    ringEnabled, currentRange, ringColor, soundEnabled =
        true, DEFAULT_RANGE, DEFAULT_RING_COLOR, true
    ringToggle.Text, audToggle.Text, rangeInput.Text =
        "Ring: ON", "Sound: ON", tostring(currentRange)
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)

--============================================================
-- 4) KARAKTER & TOP TAKİBİ
--============================================================
local function onChar(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    buildRing(hrp)
    local beep, prev = getSound(hrp), false

    task.spawn(function()
        local ball
        repeat
            local m = workspace:FindFirstChild(BALL_MODEL,true)
            ball = m and m:FindFirstChild(BALL_PART,true)
            task.wait(0.2)
        until ball and ball:IsA("BasePart")

        local lbl = getLabel(ball)
        RunService.Heartbeat:Connect(function()
            local inside = (ball.Position-hrp.Position).Magnitude<=currentRange
            if inside and not prev and soundEnabled then beep:Play() end
            prev = inside
            lbl.Text = inside and "Reachable" or "Unreachable!"
            lbl.TextColor3 = inside and Color3.new(0,1,0) or Color3.new(1,0,0)
        end)
    end)
end
if lp.Character then onChar(lp.Character) end
lp.CharacterAdded:Connect(onChar)
