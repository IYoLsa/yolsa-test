--============================================================
--  Neo Soccer League • Hitbox GUI + Lift/Tackle Cool-downs
--  + Rage Mode (INF REACH • NO CD)
--  Fully tested – 2025-07-12
--============================================================

--▼ CONFIG ----------------------------------------------------
local DEFAULT_RANGE      = 10.22
local RAGE_RANGE         = 9_999           -- infinite reach
local RING_COLOR_DEFAULT = Color3.fromRGB(0,128,255)
local ACCENT             = Color3.fromRGB(0,170,255)
local SOUND_ID           = "rbxassetid://541909867"

local SEGMENTS   = 48
local BAR_W,BAR_H= 0.2,0.05
local BALL_MODEL = "PLAIN_BALL"
local BALL_PART  = "HITBOX_BALL"

local CD_LIFT    = 3        -- R
local CD_TACKLE  = 4        -- F
local KEY_LIFT   = Enum.KeyCode.R
local KEY_TACKLE = Enum.KeyCode.F
----------------------------------------------------------------
local Players,RunS,UIS =
      game:GetService("Players"), game:GetService("RunService"),
      game:GetService("UserInputService")
local lp = Players.LocalPlayer

--▼ STATE -----------------------------------------------------
local ringEnabled  = true
local currentRange = DEFAULT_RANGE
local ringColor    = RING_COLOR_DEFAULT
local soundEnabled = true
local rageOn       = false

----------------------------------------------------------------
-- 1)  HEAD-TAG COOLDOWN LABEL
----------------------------------------------------------------
local tagGui,liftLbl,tackleLbl
local cdLift,cdTac = 0,0
local function newLine(parent,order,text)
    local l=Instance.new("TextLabel",parent)
    l.Size, l.Position = UDim2.fromScale(1,0.5), UDim2.fromScale(0,(order-1)*0.5)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; l.TextScaled=true
    l.TextColor3=Color3.fromRGB(0,255,0); l.Text=text
    return l
end
local function makeTag(char)
    local head = char:WaitForChild("Head",3) or char:WaitForChild("HumanoidRootPart")
    if not head then return end
    if tagGui then tagGui:Destroy() end
    tagGui = Instance.new("BillboardGui",head)
    tagGui.Name, tagGui.Size, tagGui.AlwaysOnTop = "SkillTag",UDim2.fromOffset(200,42),true
    tagGui.StudsOffset = Vector3.new(0,2.8,0)
    liftLbl   = newLine(tagGui,1,"Lift   •   Ready!")
    tackleLbl = newLine(tagGui,2,"Tackle •   Ready!")
end
local function onChar(c) makeTag(c); cdLift,cdTac=0,0 end
if lp.Character then onChar(lp.Character) end
lp.CharacterAdded:Connect(onChar)

RunS.RenderStepped:Connect(function(dt)
    if rageOn then return end
    if cdLift>0 then
        cdLift-=dt
        if cdLift<=0 then
            cdLift=0; liftLbl.Text="Lift   •   Ready!"; liftLbl.TextColor3=Color3.fromRGB(0,255,0)
        else
            liftLbl.Text=("Lift   •   %.1f s"):format(cdLift); liftLbl.TextColor3=Color3.fromRGB(255,60,60)
        end
    end
    if cdTac>0 then
        cdTac-=dt
        if cdTac<=0 then
            cdTac=0; tackleLbl.Text="Tackle •   Ready!"; tackleLbl.TextColor3=Color3.fromRGB(0,255,0)
        else
            tackleLbl.Text=("Tackle •   %.1f s"):format(cdTac); tackleLbl.TextColor3=Color3.fromRGB(255,60,60)
        end
    end
end)
UIS.InputBegan:Connect(function(i,gp)
    if gp or rageOn then return end
    if i.KeyCode==KEY_LIFT   and cdLift==0 then cdLift=CD_LIFT; liftLbl.TextColor3=Color3.fromRGB(255,60,60) end
    if i.KeyCode==KEY_TACKLE and cdTac ==0 then cdTac =CD_TACKLE; tackleLbl.TextColor3=Color3.fromRGB(255,60,60) end
end)

----------------------------------------------------------------
-- 2)  RING  (kick-hitbox)
----------------------------------------------------------------
local function clearRing(hrp) for _,p in ipairs(hrp:GetChildren()) do if p.Name=="KickSeg" then p:Destroy() end end end
local function buildRing(hrp)
    clearRing(hrp); if not ringEnabled then return end
    local r,y=currentRange,-hrp.Size.Y/2+BAR_H/2+0.05
    local step,ch= (2*math.pi)/SEGMENTS, 2*r*math.sin(math.pi/SEGMENTS)
    for i=0,SEGMENTS-1 do
        local t=i*step+step/2
        local p=Instance.new("Part")
        p.Name="KickSeg"; p.Size=Vector3.new(ch,BAR_H,BAR_W)
        p.Color, p.Transparency, p.Material = ringColor,0.25,Enum.Material.Neon
        p.Anchored,p.CanCollide,p.Massless=false,false,true
        p.CFrame = hrp.CFrame*CFrame.new(math.cos(t)*r,y,math.sin(t)*r)*CFrame.Angles(0,-t,0)
        p.Parent=hrp
        local w=Instance.new("WeldConstraint",p); w.Part0,w.Part1=hrp,p
    end
end

----------------------------------------------------------------
-- 3)  GUI  (tabs)
----------------------------------------------------------------
local function mkBtn(txt,h)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(220,h or 30)
    b.Text=txt; b.Font=Enum.Font.GothamMedium; b.TextSize=16
    b.TextColor3, b.BackgroundColor3=Color3.new(1,1,1),Color3.fromRGB(40,40,40)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(60,60,60)
    return b
end
local function mkInput(def)
    local t=Instance.new("TextBox")
    t.Size=UDim2.fromOffset(220,28); t.Text=def; t.Font=Enum.Font.Gotham; t.TextSize=15
    t.BackgroundColor3, t.TextColor3=Color3.fromRGB(40,40,40),Color3.new(1,1,1); t.ClearTextOnFocus=false
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",t).Color=Color3.fromRGB(60,60,60)
    return t
end

local gui=Instance.new("ScreenGui",lp.PlayerGui) gui.Name="HitboxUI"; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
local win=Instance.new("Frame",gui) win.Size,win.Position=UDim2.fromOffset(420,280),UDim2.fromOffset(60,120)
win.BackgroundColor3=Color3.fromRGB(25,25,25); win.BackgroundTransparency=0.08; Instance.new("UICorner",win).CornerRadius=UDim.new(0,8)
local shadow=Instance.new("ImageLabel",win)
shadow.Size,shadow.Position=UDim2.new(1,14,1,14),UDim2.fromOffset(-7,-7)
shadow.Image="rbxassetid://1316045217"; shadow.ImageTransparency=0.7; shadow.BackgroundTransparency=1; shadow.ZIndex=-1
shadow.ScaleType,shadow.SliceCenter=Enum.ScaleType.Slice,Rect.new(10,10,118,118)
-- title
local bar=Instance.new("Frame",win) bar.Size=UDim2.new(1,0,0,30); bar.BackgroundColor3=Color3.fromRGB(20,20,20); Instance.new("UICorner",bar).CornerRadius=UDim.new(0,8)
local t=Instance.new("TextLabel",bar)
t.Size, t.Position=UDim2.new(1,-60,1,0),UDim2.fromOffset(10,0)
t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=18; t.TextXAlignment=Enum.TextXAlignment.Left
t.TextColor3=ACCENT; t.Text="Neo Soccer • Hitbox GUI"
local X=Instance.new("TextButton",bar)
X.Size,X.Position=UDim2.fromOffset(24,24),UDim2.fromScale(1,0)+UDim2.fromOffset(-32,3)
X.Text="×"; X.Font=Enum.Font.GothamBlack; X.TextSize=22; X.BackgroundTransparency=1; X.TextColor3=Color3.new(1,1,1)
X.MouseButton1Click:Connect(function() win.Visible=not win.Visible end)
-- drag
do local drag,st,pos
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; st=i.Position; pos=win.Position end end)
    bar.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-st; win.Position=UDim2.fromOffset(pos.X.Offset+d.X,pos.Y.Offset+d.Y) end end)
    bar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end
-- tabs
local side=Instance.new("Frame",win) side.Size,side.Position=UDim2.new(0,90,1,-30),UDim2.fromOffset(0,30)
side.BackgroundColor3=Color3.fromRGB(20,20,20); Instance.new("UICorner",side).CornerRadius=UDim.new(0,8)
local list=Instance.new("UIListLayout",side)
list.Padding=UDim.new(0,6); list.FillDirection=Enum.FillDirection.Vertical
list.HorizontalAlignment=Enum.HorizontalAlignment.Center; list.VerticalAlignment=Enum.VerticalAlignment.Top
local tabs={},nil
local pages,current=nil,nil
local function tab(name,icon,order)
    local b=Instance.new("TextButton",side); b.LayoutOrder, b.Size = order,UDim2.fromOffset(70,30)
    b.Text=icon.."  "..name; b.Font=Enum.Font.GothamMedium; b.TextSize=15
    b.TextColor3, b.BackgroundColor3 = Color3.new(1,1,1), Color3.fromRGB(35,35,35)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local pg=Instance.new("Frame",win); pg.Size,pg.Position=UDim2.new(1,-100,1,-40),UDim2.fromOffset(100,40); pg.BackgroundTransparency=1; pg.Visible=false
    pages[name]=pg
    b.MouseButton1Click:Connect(function()
        if current then current.Visible=false end
        current=pg; pg.Visible=true
        for _,x in ipairs(side:GetChildren()) do if x:IsA("TextButton") then x.BackgroundColor3=Color3.fromRGB(35,35,35) end end
        b.BackgroundColor3=ACCENT
    end)
    return pg
end
pages={};    -- initialise table BEFORE calling tab
local general = tab("General","⚙",1)
local colours = tab("Colors","🎨",2)
local audio   = tab("Audio","🔊",3)
task.defer(function() side:GetChildren()[1]:FindFirstChildOfClass("TextButton"):Activate() end)

-- General content
local gList=Instance.new("UIListLayout",general)
gList.Padding=UDim.new(0,4); gList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local ringBtn  = mkBtn("Ring: ON"); ringBtn.Parent = general
local rangeInp = mkInput(tostring(currentRange)); rangeInp.Parent = general
local applyBtn = mkBtn("Apply",24); applyBtn.Parent = general
local rageBtn  = mkBtn("Rage: OFF",24); rageBtn.Parent = general
local resetBtn = mkBtn("Reset",24); resetBtn.Parent = general

-- Color content
local cg=Instance.new("UIGridLayout",colours)
cg.CellPadding,cg.CellSize=UDim2.fromOffset(6,6),UDim2.fromOffset(60,28)
for _,v in ipairs({{"Blue",Color3.fromRGB(0,128,255)},{"Green",Color3.fromRGB(0,255,0)},{"Red",Color3.fromRGB(255,70,70)}}) do
    local b=mkBtn(v[1],24); b.BackgroundColor3=v[2]; b.Parent=colours
    b.MouseButton1Click:Connect(function()
        ringColor=v[2]; local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
    end)
end
-- Audio tab
local audBtn = mkBtn("Sound: ON"); audBtn.Parent=audio

-- General callbacks
ringBtn.MouseButton1Click:Connect(function()
    ringEnabled = not ringEnabled; ringBtn.Text="Ring: "..(ringEnabled and "ON" or "OFF")
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then (ringEnabled and buildRing or clearRing)(hrp) end
end)
applyBtn.MouseButton1Click:Connect(function()
    local v=tonumber(rangeInp.Text); if v and v>0 then currentRange=v end
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end)
audBtn.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled; audBtn.Text="Sound: "..(soundEnabled and "ON" or "OFF")
end)
resetBtn.MouseButton1Click:Connect(function()
    rageOn=false; ringEnabled=true; currentRange=DEFAULT_RANGE; ringColor=RING_COLOR_DEFAULT; soundEnabled=true
    ringBtn.Text="Ring: ON"; rangeInp.Text=tostring(currentRange); audBtn.Text="Sound: ON"; rageBtn.Text="Rage: OFF"
    cdLift,cdTac=0,0; liftLbl.Text="Lift   •   Ready!"; tackleLbl.Text="Tackle •   Ready!"; liftLbl.TextColor3=tackleLbl.TextColor3=Color3.fromRGB(0,255,0)
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end)

local function setRage(on)
    rageOn=on; rageBtn.Text="Rage: "..(on and "ON" or "OFF")
    currentRange = on and RAGE_RANGE or DEFAULT_RANGE
    cdLift,cdTac=0,0; liftLbl.Text="Lift   •   Ready!"; tackleLbl.Text="Tackle •   Ready!"
    liftLbl.TextColor3=tackleLbl.TextColor3=Color3.fromRGB(0,255,0)
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"); if hrp then buildRing(hrp) end
end
rageBtn.MouseButton1Click:Connect(function() setRage(not rageOn) end)

----------------------------------------------------------------
-- 4)  TOP reach & SOUND  (unchanged)
----------------------------------------------------------------
local function reachLbl(ball)
    local gui=ball:FindFirstChild("ReachGui") or Instance.new("BillboardGui",ball)
    gui.Name,gui.Size,gui.AlwaysOnTop="ReachGui",UDim2.fromOffset(130,34),true; gui.StudsOffset=Vector3.new(0,ball.Size.Y/2+1.8,0)
    local lbl=gui:FindFirstChild("Lbl") or Instance.new("TextLabel",gui)
    lbl.Name,lbl.Size,lbl.BackgroundTransparency="Lbl",UDim2.fromScale(1,1),1
    lbl.Font,lbl.TextScaled,lbl.TextStrokeTransparency=Enum.Font.GothamBold,true,0.7; return lbl
end
local function charInit(c)
    local hrp=c:WaitForChild("HumanoidRootPart"); buildRing(hrp)
    local snd=hrp:FindFirstChild("KickSnd") or Instance.new("Sound",hrp); snd.Name,snd.SoundId,snd.Volume="KickSnd",SOUND_ID,1
    task.spawn(function()
        local ball repeat
            local m=workspace:FindFirstChild(BALL_MODEL,true); ball=m and m:FindFirstChild(BALL_PART,true); task.wait(0.25)
        until ball and ball:IsA("BasePart")
        local lbl=reachLbl(ball); local was=false
        RunService.Heartbeat:Connect(function()
            local inside=(ball.Position-hrp.Position).Magnitude<=currentRange
            if inside and not was and soundEnabled then snd:Play() end; was=inside
            lbl.Text=inside and "Reachable" or "Unreachable!"; lbl.TextColor3=inside and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
        end)
    end)
end
if lp.Character then charInit(lp.Character) end
lp.CharacterAdded:Connect(charInit)
