--============================================================
--  Neo Soccer League • Hitbox GUI + Cool-downs + Rage Mode
--  Tested 2025-07-12
--============================================================

-- ▲ CONSTANTS -----------------------------------------------
local DEFAULT_RANGE      = 10.22
local RAGE_RANGE         = 9_999
local RING_COLOR_DEFAULT = Color3.fromRGB(0,128,255)
local ACCENT             = Color3.fromRGB(0,170,255)
local SOUND_ID           = "rbxassetid://541909867"

local SEGMENTS      = 48
local BAR_W, BAR_H  = 0.2, 0.05
local BALL_MODEL    = "PLAIN_BALL"
local BALL_PART     = "HITBOX_BALL"

local CD_LIFT, CD_TAC = 3, 4          -- seconds
local KEY_LIFT, KEY_TAC = Enum.KeyCode.R, Enum.KeyCode.F

-- ▲ SERVICES -------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer

-- ▲ STATE ----------------------------------------------------
local ringOn   = true
local curRange = DEFAULT_RANGE
local ringCol  = RING_COLOR_DEFAULT
local sndOn    = true
local rageOn   = false

----------------------------------------------------------------
-- 1)  HEAD-TAG COOLDOWN LABEL
----------------------------------------------------------------
local tagGui, liftLbl, tacLbl
local cdLift, cdTac = 0, 0

local function newLine(parent, order, text)
    local l = Instance.new("TextLabel", parent)
    l.Size, l.Position = UDim2.fromScale(1,0.5), UDim2.fromScale(0,(order-1)*0.5)
    l.BackgroundTransparency = 1
    l.Font, l.TextScaled     = Enum.Font.GothamBold, true
    l.TextColor3, l.Text     = Color3.fromRGB(0,255,0), text
    return l
end

local function makeTag(char)
    local head = char:FindFirstChild("Head") or char:WaitForChild("HumanoidRootPart")
    if tagGui then tagGui:Destroy() end
    tagGui = Instance.new("BillboardGui", head)
    tagGui.Name, tagGui.AlwaysOnTop = "SkillTag", true
    tagGui.Size, tagGui.StudsOffset = UDim2.fromOffset(200,42), Vector3.new(0,2.8,0)
    liftLbl = newLine(tagGui,1,"Lift   •   Ready!")
    tacLbl  = newLine(tagGui,2,"Tackle •   Ready!")
end

local function onCharacter(char)
    cdLift, cdTac = 0, 0
    makeTag(char)
end
if lp.Character then onCharacter(lp.Character) end
lp.CharacterAdded:Connect(onCharacter)

RunService.RenderStepped:Connect(function(dt)
    if rageOn then return end
    if cdLift>0 then
        cdLift -= dt
        if cdLift<=0 then
            cdLift = 0
            liftLbl.Text, liftLbl.TextColor3 = "Lift   •   Ready!", Color3.fromRGB(0,255,0)
        else
            liftLbl.Text = ("Lift   •   %.1f s"):format(cdLift)
            liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
        end
    end
    if cdTac>0 then
        cdTac -= dt
        if cdTac<=0 then
            cdTac = 0
            tacLbl.Text, tacLbl.TextColor3 = "Tackle •   Ready!", Color3.fromRGB(0,255,0)
        else
            tacLbl.Text = ("Tackle •   %.1f s"):format(cdTac)
            tacLbl.TextColor3 = Color3.fromRGB(255,60,60)
        end
    end
end)

UIS.InputBegan:Connect(function(inp,gp)
    if gp or rageOn then return end
    if inp.KeyCode==KEY_LIFT and cdLift==0 then
        cdLift = CD_LIFT; liftLbl.TextColor3 = Color3.fromRGB(255,60,60)
    elseif inp.KeyCode==KEY_TAC and cdTac==0 then
        cdTac  = CD_TAC;  tacLbl.TextColor3  = Color3.fromRGB(255,60,60)
    end
end)

----------------------------------------------------------------
-- 2)  KICK-HITBOX RING
----------------------------------------------------------------
local function clearRing(hrp)
    for _,p in ipairs(hrp:GetChildren()) do
        if p.Name=="KickSeg" then p:Destroy() end
    end
end

local function buildRing(hrp)
    clearRing(hrp)
    if not ringOn then return end
    local r,y = curRange, -hrp.Size.Y/2+BAR_H/2+0.05
    local step,ch = (2*math.pi)/SEGMENTS, 2*r*math.sin(math.pi/SEGMENTS)
    for i=0,SEGMENTS-1 do
        local t = i*step+step/2
        local s = Instance.new("Part")
        s.Name="KickSeg"; s.Size=Vector3.new(ch,BAR_H,BAR_W)
        s.Color, s.Transparency, s.Material = ringCol,0.25,Enum.Material.Neon
        s.Anchored, s.CanCollide, s.Massless = false,false,true
        s.CFrame = hrp.CFrame*CFrame.new(math.cos(t)*r,y,math.sin(t)*r)*CFrame.Angles(0,-t,0)
        s.Parent=hrp
        local w=Instance.new("WeldConstraint",s); w.Part0,w.Part1=hrp,s
    end
end

----------------------------------------------------------------
-- 3)  GUI (tabs)
----------------------------------------------------------------
local function mkBtn(text,h)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(220,h or 30)
    b.Text, b.Font, b.TextSize = text, Enum.Font.GothamMedium, 16
    b.TextColor3, b.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(40,40,40)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(60,60,60); return b
end
local function mkInput(def)
    local t=Instance.new("TextBox")
    t.Size, t.Text = UDim2.fromOffset(220,28), def
    t.Font, t.TextSize = Enum.Font.Gotham, 15
    t.BackgroundColor3, t.TextColor3 = Color3.fromRGB(40,40,40), Color3.new(1,1,1)
    t.ClearTextOnFocus=false
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",t).Color=Color3.fromRGB(60,60,60); return t
end

local gui=Instance.new("ScreenGui",lp.PlayerGui)
gui.Name="HitboxUI"; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global

local win=Instance.new("Frame",gui)
win.Size, win.Position = UDim2.fromOffset(420,280), UDim2.fromOffset(60,120)
win.BackgroundColor3, win.BackgroundTransparency = Color3.fromRGB(25,25,25),0.08
win.BorderSizePixel=0; Instance.new("UICorner",win).CornerRadius=UDim.new(0,8)

-- shadow
local sh=Instance.new("ImageLabel",win)
sh.Size,sh.Position=UDim2.new(1,14,1,14),UDim2.fromOffset(-7,-7)
sh.Image="rbxassetid://1316045217"; sh.ImageTransparency=0.7
sh.BackgroundTransparency, sh.ZIndex = 1, -1
sh.ScaleType, sh.SliceCenter = Enum.ScaleType.Slice, Rect.new(10,10,118,118)

-- title
local bar=Instance.new("Frame",win)
bar.Size=UDim2.new(1,0,0,30); bar.BackgroundColor3=Color3.fromRGB(20,20,20)
Instance.new("UICorner",bar).CornerRadius=UDim.new(0,8)
local title=Instance.new("TextLabel",bar)
title.Size, title.Position = UDim2.new(1,-60,1,0), UDim2.fromOffset(10,0)
title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBold; title.TextSize=18
title.TextXAlignment, title.TextColor3 = Enum.TextXAlignment.Left, ACCENT
title.Text="Neo Soccer • Hitbox GUI"
local close=Instance.new("TextButton",bar)
close.Size,close.Position=UDim2.fromOffset(24,24),UDim2.fromScale(1,0)+UDim2.fromOffset(-32,3)
close.Text="×"; close.Font=Enum.Font.GothamBlack; close.TextSize=22
close.BackgroundTransparency,close.TextColor3=1,Color3.new(1,1,1)
close.MouseButton1Click:Connect(function() win.Visible=not win.Visible end)
-- drag
do local drag,st,pos
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; st=i.Position; pos=win.Position end end)
    bar.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-st; win.Position=UDim2.fromOffset(pos.X.Offset+d.X,pos.Y.Offset+d.Y) end end)
    bar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end

-- side tab bar
local side=Instance.new("Frame",win)
side.Size, side.Position = UDim2.new(0,90,1,-30), UDim2.fromOffset(0,30)
side.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner",side).CornerRadius=UDim.new(0,8)
local list=Instance.new("UIListLayout",side)
list.Padding=UDim.new(0,6); list.FillDirection=Enum.FillDirection.Vertical
list.HorizontalAlignment, list.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top

local pages = {}          -- <- initialised before use
local currentPage = nil
local function addTab(name, icon, order)
    local b=Instance.new("TextButton",side)
    b.LayoutOrder, b.Size = order, UDim2.fromOffset(70,30)
    b.Text=icon.."  "..name; b.Font=Enum.Font.GothamMedium; b.TextSize=15
    b.TextColor3, b.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(35,35,35)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)

    local pg=Instance.new("Frame",win)
    pg.Size, pg.Position = UDim2.new(1,-100,1,-40), UDim2.fromOffset(100,40)
    pg.BackgroundTransparency, pg.Visible = 1, false
    pages[name] = pg

    b.MouseButton1Click:Connect(function()
        if currentPage then currentPage.Visible=false end
        currentPage = pg; pg.Visible=true
        for _,x in ipairs(side:GetChildren()) do
            if x:IsA("TextButton") then x.BackgroundColor3=Color3.fromRGB(35,35,35) end
        end
        b.BackgroundColor3 = ACCENT
    end)
    return pg
end

local general = addTab("General","⚙",1)
local colours = addTab("Colors" ,"🎨",2)
local audio   = addTab("Audio"  ,"🔊",3)
task.defer(function() side:GetChildren()[1]:FindFirstChildOfClass("TextButton"):Activate() end)

-- General content
local gLayout=Instance.new("UIListLayout",general)
gLayout.Padding=UDim.new(0,4); gLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
local ringBtn = mkBtn("Ring: ON");     ringBtn.Parent = general
local rangeBox= mkInput(tostring(curRange)); rangeBox.Parent = general
local applyBtn= mkBtn("Apply",24);     applyBtn.Parent = general
local rageBtn = mkBtn("Rage: OFF",24); rageBtn.Parent = general
local resetBtn= mkBtn("Reset",24);     resetBtn.Parent = general

-- Colour buttons
local colGrid=Instance.new("UIGridLayout",colours)
colGrid.CellPadding,colGrid.CellSize=UDim2.fromOffset(6,6),UDim2.fromOffset(60,28)
for _,v in ipairs({{"Blue",Color3.fromRGB(0,128,255)},{"Green",Color3.fromRGB(0,255,0)},{"Red",Color3.fromRGB(255,70,70)}}) do
    local b=mkBtn(v[1],24); b.BackgroundColor3=v[2]; b.Parent=colours
    b.MouseButton1Click:Connect(function()
        ringCol=v[2]; local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
    end)
end
-- Audio tab
local audBtn = mkBtn("Sound: ON"); audBtn.Parent = audio

-- Button callbacks
ringBtn.MouseButton1Click:Connect(function()
    ringOn = not ringOn; ringBtn.Text="Ring: "..(ringOn and "ON" or "OFF")
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then (ringOn and buildRing or clearRing)(hrp) end
end)
applyBtn.MouseButton1Click:Connect(function()
    local v=tonumber(rangeBox.Text); if v and v>0 then curRange=v end
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end)
audBtn.MouseButton1Click:Connect(function()
    sndOn = not sndOn; audBtn.Text="Sound: "..(sndOn and "ON" or "OFF")
end)
resetBtn.MouseButton1Click:Connect(function()
    rageOn=false; ringOn=true; curRange=DEFAULT_RANGE; ringCol=RING_COLOR_DEFAULT; sndOn=true
    ringBtn.Text="Ring: ON"; audBtn.Text="Sound: ON"; rageBtn.Text="Rage: OFF"; rangeBox.Text=tostring(curRange)
    cdLift,cdTac=0,0; liftLbl.Text="Lift   •   Ready!"; tacLbl.Text="Tackle •   Ready!"; liftLbl.TextColor3=tacLbl.TextColor3=Color3.fromRGB(0,255,0)
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end)

local function setRage(on)
    rageOn=on; rageBtn.Text="Rage: "..(on and "ON" or "OFF")
    curRange = on and RAGE_RANGE or DEFAULT_RANGE
    cdLift,cdTac=0,0; liftLbl.Text="Lift   •   Ready!"; tacLbl.Text="Tackle •   Ready!"; liftLbl.TextColor3=tacLbl.TextColor3=Color3.fromRGB(0,255,0)
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end
rageBtn.MouseButton1Click:Connect(function() setRage(not rageOn) end)

----------------------------------------------------------------
-- 4)  BALL reach + sound ping
----------------------------------------------------------------
local function reachLabel(ball)
    local g=ball:FindFirstChild("ReachGui") or Instance.new("BillboardGui",ball)
    g.Name, g.Size, g.AlwaysOnTop="ReachGui",UDim2.fromOffset(130,34),true
    g.StudsOffset=Vector3.new(0,ball.Size.Y/2+1.8,0)
    local l=g:FindFirstChild("Lbl") or Instance.new("TextLabel",g)
    l.Name,l.Size,l.BackgroundTransparency="Lbl",UDim2.fromScale(1,1),1
    l.Font,l.TextScaled,l.TextStrokeTransparency=Enum.Font.GothamBold,true,0.7; return l
end

local function charInit(c)
    local hrp=c:WaitForChild("HumanoidRootPart"); buildRing(hrp)
    local snd=hrp:FindFirstChild("KickSnd") or Instance.new("Sound",hrp)
    snd.Name,snd.SoundId,snd.Volume="KickSnd",SOUND_ID,1
    task.spawn(function()
        local ball repeat
            local m=workspace:FindFirstChild(BALL_MODEL,true); ball=m and m:FindFirstChild(BALL_PART,true); task.wait(0.25)
        until ball and ball:IsA("BasePart")
        local lbl=reachLabel(ball); local prev=false
        RunService.Heartbeat:Connect(function()
            local inside=(ball.Position-hrp.Position).Magnitude<=curRange
            if inside and not prev and sndOn then snd:Play() end; prev=inside
            lbl.Text=inside and "Reachable" or "Unreachable!"
            lbl.TextColor3=inside and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
        end)
    end)
end
if lp.Character then charInit(lp.Character) end
lp.CharacterAdded:Connect(charInit)
