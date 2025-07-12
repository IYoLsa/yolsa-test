--  Animation-Spy  –  Tackle animasyonu tespit + 3 s sayaç
local COOLDOWN_TIME = 3       -- saniye, sabit tahmin
local KEY = {"slide","tackle","dive"}

local Gui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local function ping(p, txt, ok)
    Gui:SetCore("SendNotification",{
        Title  = p.Name,
        Text   = txt,
        Duration = 2,
    })
end

local function watchAnimator(char, plr)
    local anim = char:FindFirstChildOfClass("Animator")
    if not anim then return end
    anim.AnimationPlayed:Connect(function(track)
        local id = (track.Name or ""):lower()
        for _,k in ipairs(KEY) do
            if id:find(k) then
                ping(plr, "Tackle!", false)
                task.delay(COOLDOWN_TIME, function() ping(plr,"Ready!",true) end)
                break
            end
        end
    end)
end

local function hook(plr)
    if plr.Character then watchAnimator(plr.Character, plr) end
    plr.CharacterAdded:Connect(function(c) watchAnimator(c, plr) end)
end
for _,p in ipairs(Players:GetPlayers()) do hook(p) end
Players.PlayerAdded:Connect(hook)

Gui:SetCore("SendNotification",{Title="Anim-Spy",Text="✓ Loaded",Duration=3})
