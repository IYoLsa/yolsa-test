--============================================================
--  Neo Soccer League • Exploit GUI + Hitbox + Cooldowns + Rage
--  Tam LocalScript — 2025-07-12
--============================================================

----------------------------------------------------------------
--  A) SABİTLER
----------------------------------------------------------------
local DEFAULT_RANGE      = 10.22
local RAGE_RANGE         = 9999      -- INF REACH
local DEFAULT_RING_COLOR = Color3.fromRGB(0,128,255)
local ACCENT_COLOR       = Color3.fromRGB(0,170,255)
local SOUND_ID           = "rbxassetid://541909867"

local SEGMENTS           = 48
local BAR_W, BAR_H       = 0.2, 0.05
local BALL_MODEL, BALL_PART = "PLAIN_BALL", "HITBOX_BALL"

local COOLDOWN_LIFT      = 3   -- s  (rage dışında)
local COOLDOWN_TACKLE    = 4   -- s
local KEY_LIFT           = Enum.KeyCode.R
local KEY_TACKLE         = Enum.KeyCode.F

----------------------------------------------------------------
--  B) SERVİSLER & GLOBAL DURUM
----------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer

local ringEnabled  = true
local currentRange = DEFAULT_RANGE
local ringColor    = DEFAULT_RING_COLOR
local soundEnabled = true
local rageEnabled  = false   -- ◀◀◀  yeni

----------------------------------------------------------------
--  C) BAŞ ÜSTÜ COOLDOWN ETİKETİ
----------------------------------------------------------------
local tagGui, liftLbl, tackleLbl
local cdLift, cdTackle = 0, 0

local function createSkillTag(char)
    local head = char:FindFirstChild("Head") or char:WaitForChild("HumanoidRootPart")
    if tagGui then tagGui:Destroy() end
    tagGui = Instance.new("BillboardGui", head)
    tagGui.Name, tagGui.Adornee, tagGui.AlwaysOnTop =
        "SkillCD_Tag", head, true
    tagGui.Size          = UDim2.fromOffset(200,42)
    tagGui.StudsOffset   = Vector3.new(0,2.8,0)
    local function newLine(order, txt)
        local l = Instance.new("TextLabel", tagGui)
        l.Size, l.Position = UDim2.fromScale(1,0.5), UDim2.fromScale(0,(order-1)*0.5)
        l.BackgroundTransparency = 1
        l.Font, l.TextScaled     = Enum.Font.GothamBold, true
        l.TextColor3             = Color3.fromRGB(0,255,0)
        l.Text = txt
        return l
    end
    liftLbl   = newLine(1,"Lift   •   Ready!")
    tackleLbl = newLine(2,"Tackle •   Ready!")
end

local function charAdded(char)
    cdLift, cdTackle = 0,0
    createSkillTag(char)
end
if lp.Character then charAdded(lp.Character) end
lp.CharacterAdded:Connect(charAdded)

-- Sayaç güncelle (rage’de CD == 0 kalır)
RunService.RenderStepped:Connect(function(dt)
    if not rageEnabled then
        if cdLift > 0 then
            cdLift -= dt
            if cdLift <= 0 then
                cdLift = 0
                liftLbl.Text, liftLbl.TextColor3 = "Lift   •   Ready!", Color3.fromRGB(0,255,0)
            else
                liftLbl.Text = ("Lift   •   %.1f s"):format(cdLift)
                liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
            end
        end
        if cdTackle > 0 then
            cdTackle -= dt
            if cdTackle <= 0 then
                cdTackle = 0
                tackleLbl.Text, tackleLbl.TextColor3 = "Tackle •   Ready!", Color3.fromRGB(0,255,0)
            else
                tackleLbl.Text = ("Tackle •   %.1f s"):format(cdTackle)
                tackleLbl.TextColor3 = Color3.fromRGB(255,60,60)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(inp,gp)
    if gp or rageEnabled then return end
    if inp.KeyCode == KEY_LIFT and cdLift==0 then
        cdLift = COOLDOWN_LIFT
        liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
    elseif inp.KeyCode == KEY_TACKLE and cdTackle==0 then
        cdTackle = COOLDOWN_TACKLE
        tackleLbl.TextColor3 = Color3.fromRGB(255,60,60)
    end
end)

----------------------------------------------------------------
--  D) HITBOX HALKASI
----------------------------------------------------------------
local function clearRing(hrp)
    for _,p in ipairs(hrp:GetChildren()) do
        if p.Name=="KickSeg" then p:Destroy() end
    end
end

function buildRing(hrp)
    clearRing(hrp)
    if not ringEnabled then return end
    local y = -hrp.Size.Y/2 + BAR_H/2 + 0.05
    local r = currentRange
    local step, chord = (2*math.pi)/SEGMENTS, 2*r*math.sin(math.pi/SEGMENTS)
    for i=0,SEGMENTS-1 do
        local th=i*step+step/2
        local seg=Instance.new("Part")
        seg.Name,seg.Size="KickSeg",Vector3.new(chord,BAR_H,BAR_W)
        seg.Color,seg.Transparency,seg.Material = ringColor,0.25,Enum.Material.Neon
        seg.Anchored,seg.CanCollide,seg.Massless=false,false,true
        seg.CFrame = hrp.CFrame
                 * CFrame.new(math.cos(th)*r,y,math.sin(th)*r)
                 * CFrame.Angles(0,-th,0)
        seg.Parent=hrp
        local w=Instance.new("WeldConstraint",seg); w.Part0,w.Part1=hrp,seg
    end
end

----------------------------------------------------------------
--  E) SEKME GUI
----------------------------------------------------------------
local function mkButton(txt,h)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(220,h or 30)
    b.Text, b.Font, b.TextSize = txt, Enum.Font.GothamMedium, 16
    b.TextColor3, b.BackgroundColor3=Color3.new(1,1,1),Color3.fromRGB(40,40,40)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(60,60,60)
    return b
end
local function mkInput(def)
    local box=Instance.new("TextBox")
    box.Size, box.Text = UDim2.fromOffset(220,28),def
    box.Font, box.TextSize = Enum.Font.Gotham,15
    box.BackgroundColor3, box.TextColor3 = Color3.fromRGB(40,40,40),Color3.new(1,1,1)
    box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",box).Color=Color3.fromRGB(60,60,60)
    return box
end

local gui=Instance.new("ScreenGui",lp:WaitForChild("PlayerGui"))
gui.Name,gui.ResetOnSpawn,gui.ZIndexBehavior="HitboxUI",false,Enum.ZIndexBehavior.Global
local win=Instance.new("Frame",gui)
win.Size,win.Position=UDim2.fromOffset(420,280),UDim2.fromOffset(60,120)
win.BackgroundColor3,win.BackgroundTransparency=Color3.fromRGB(25,25,25),0.08
win.BorderSizePixel=0;Instance.new("UICorner",win).CornerRadius=UDim.new(0,8)
-- gölge
local sh=Instance.new("ImageLabel",win)
sh.Size,sh.Position=UDim2.new(1,14,1,14),UDim2.fromOffset(-7,-7)
sh.Image,sh.ImageTransparency="rbxassetid://1316045217",0.7
sh.BackgroundTransparency,sh.ZIndex=1,-1
sh.ScaleType,sh.SliceCenter=Enum.ScaleType.Slice,Rect.new(10,10,118,118)
-- başlık
local bar=Instance.new("Frame",win)
bar.Size=UDim2.new(1,0,0,30);bar.BackgroundColor3=Color3.fromRGB(20,20,20)
Instance.new("UICorner",bar).CornerRadius=UDim.new(0,8)
local ttl=Instance.new("TextLabel",bar)
ttl.Size,ttl.Position=UDim2.new(1,-60,1,0),UDim2.fromOffset(10,0)
ttl.BackgroundTransparency=1;ttl.Font=Enum.Font.GothamBold;ttl.TextSize=18
ttl.TextColor3,ttl.TextXAlignment=ACCENT_COLOR,Enum.TextXAlignment.Left
ttl.Text="Neo Soccer • Hitbox GUI"
local close=Instance.new("TextButton",bar)
close.Size,close.Position=UDim2.fromOffset(24,24),
    UDim2.fromScale(1,0)+UDim2.fromOffset(-32,3)
close.Text,close.Font,close.TextSize="×",Enum.Font.GothamBlack,22
close.BackgroundTransparency,close.TextColor3=1,Color3.new(1,1,1)
close.MouseButton1Click:Connect(function() win.Visible=not win.Visible end)
-- drag
do local dr,st,sp
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dr,i.Position,win.Position=true,i.Position,win.Position end
    end)
    bar.InputChanged:Connect(function(i)
        if dr and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-st
            win.Position=UDim2.fromOffset(sp.X.Offset+d.X,sp.Y.Offset+d.Y)
        end
    end)
    bar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
end
-- sekmeler
local side=Instance.new("Frame",win);side.Size,side.Position=UDim2.new(0,90,1,-30),UDim2.fromOffset(0,30)
side.BackgroundColor3=Color3.fromRGB(20,20,20);Instance.new("UICorner",side).CornerRadius=UDim.new(0,8)
local tabList=Instance.new("UIListLayout",side)
tabList.Padding=UDim.new(0,6);tabList.FillDirection=Enum.FillDirection.Vertical
tabList.HorizontalAlignment,tabList.VerticalAlignment=Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Top
tabList.SortOrder=Enum.SortOrder.LayoutOrder
local pages,current=nil,nil
local function addTab(name,icon,order)
    local b=Instance.new("TextButton",side)
    b.LayoutOrder,b.Size=order,UDim2.fromOffset(70,30)
    b.Text=icon.."  "..name;b.Font=Enum.Font.GothamMedium;b.TextSize=15
    b.TextColor3,b.BackgroundColor3=Color3.new(1,1,1),Color3.fromRGB(35,35,35)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local pg=Instance.new("Frame",win);pg.Size,pg.Position=UDim2.new(1,-100,1,-40),UDim2.fromOffset(100,40)
    pg.BackgroundTransparency,pg.Visible=1,false;pages=name;pages[name]=pg
    b.MouseButton1Click:Connect(function()
        if current then current.Visible=false end;current=pg;pg.Visible=true
        for _,x in ipairs(side:GetChildren()) do
            if x:IsA("TextButton") then x.BackgroundColor3=Color3.fromRGB(35,35,35) end
        end;b.BackgroundColor3=ACCENT_COLOR
    end);return pg
end
local generalPage=addTab("General","⚙",1)
local colorPage  =addTab("Colors","🎨",2)
local audioPage  =addTab("Audio","🔊",3)
task.defer(function()side:GetChildren()[1]:FindFirstChildOfClass("TextButton"):Activate()end)

-- General
local gList=Instance.new("UIListLayout",generalPage)
gList.Padding=UDim.new(0,4);gList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local ringBtn=mkButton("Ring: ON"); ringBtn.Parent=generalPage
local rangeBox=mkInput(tostring(currentRange)); rangeBox.Parent=generalPage
local applyBtn=mkButton("Apply",24); applyBtn.Parent=generalPage
local rageBtn =mkButton("Rage: OFF",24); rageBtn.Parent=generalPage  -- ◀◀ Rage düğmesi
local resetBtn=mkButton("Reset",24); resetBtn.Parent=generalPage

-- Colors
local colGrid=Instance.new("UIGridLayout",colorPage)
colGrid.CellPadding,colGrid.CellSize=UDim2.fromOffset(6,6),UDim2.fromOffset(60,28)
for _,opt in ipairs({{"Blue",Color3.fromRGB(0,128,255)},{"Green",Color3.fromRGB(0,255,0)},{"Red",Color3.fromRGB(255,70,70)}}) do
    local b=mkButton(opt[1],24);b.BackgroundColor3=opt[2];b.Parent=colorPage
    b.MouseButton1Click:Connect(function()
        ringColor=opt[2];local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then buildRing(hrp) end
    end)
end
-- Audio
local audBtn=mkButton("Sound: ON"); audBtn.Parent=audioPage

----------------------------------------------------------------
--  E) GUI buton callback'leri
----------------------------------------------------------------
ringBtn.MouseButton1Click:Connect(function()
    ringEnabled=not ringEnabled; ringBtn.Text="Ring: "..(ringEnabled and "ON" or "OFF")
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then (ringEnabled and buildRing or clearRing)(hrp) end
end)
applyBtn.MouseButton1Click:Connect(function()
    local v=tonumber(rangeBox.Text); if v and v>0 then currentRange=v end
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)
audBtn.MouseButton1Click:Connect(function()
    soundEnabled=not soundEnabled; audBtn.Text="Sound: "..(soundEnabled and "ON" or "OFF")
end)
resetBtn.MouseButton1Click:Connect(function()
    rageEnabled=false
    ringEnabled,currentRange,ringColor,soundEnabled=
        true,DEFAULT_RANGE,DEFAULT_RING_COLOR,true
    ringBtn.Text="Ring: ON"; audBtn.Text="Sound: ON"; rangeBox.Text=tostring(currentRange)
    rageBtn.Text="Rage: OFF"
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end)
-- Rage Mode toggle
local function setRage(on)
    rageEnabled=on
    rageBtn.Text="Rage: "..(on and "ON" or "OFF")
    if on then
        currentRange=RAGE_RANGE
        cdLift,cdTackle=0,0
        liftLbl.Text,tackleLbl.Text="Lift   •   Ready!","Tackle •   Ready!"
        liftLbl.TextColor3,tackleLbl.TextColor3=Color3.fromRGB(0,255,0),Color3.fromRGB(0,255,0)
    else
        currentRange=DEFAULT_RANGE
    end
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then buildRing(hrp) end
end
rageBtn.MouseButton1Click:Connect(function() setRage(not rageEnabled) end)

----------------------------------------------------------------
--  F) Karakter & Top Hitbox İzleme
----------------------------------------------------------------
local function charHitbox(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    buildRing(hrp)
    local snd = hrp:FindFirstChild("KickSnd") or Instance.new("Sound", hrp)
    snd.Name,snd.SoundId,snd.Volume="KickSnd",SOUND_ID,1
    local last=false
    task.spawn(function()
        local ball repeat
            local m=workspace:FindFirstChild(BALL_MODEL,true)
            ball=m and m:FindFirstChild(BALL_PART,true)
            task.wait(0.25)
        until ball and ball:IsA("BasePart")
        local lbl=ball:FindFirstChild("ReachGui") or Instance.new("BillboardGui",ball)
        lbl.Name,lbl.Size,lbl.AlwaysOnTop="ReachGui",UDim2.fromOffset(130,34),true
        lbl.StudsOffset=Vector3.new(0,ball.Size.Y/2+1.8,0)
        local tx=lbl:FindFirstChild("Lbl") or Instance.new("TextLabel",lbl)
        tx.Name,tx.Size,tx.BackgroundTransparency="Lbl",UDim2.fromScale(1,1),1
        tx.Font,tx.TextScaled,tx.TextStrokeTransparency=Enum.Font.GothamBold,true,0.7

        RunService.Heartbeat:Connect(function()
            local inside=(ball.Position-hrp.Position).Magnitude<=currentRange
            if inside and not last and soundEnabled then snd:Play() end
            last=inside
            tx.Text=inside and "Reachable" or "Unreachable!"
            tx.TextColor3=inside and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
        end)
    end)
end
if lp.Character then charHitbox(lp.Character) end
lp.CharacterAdded:Connect(charHitbox)
