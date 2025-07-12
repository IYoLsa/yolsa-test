--///////////////////////////////////////////////////////////
--  Neo Soccer League • Cooldown Spy v3
--  SendNotification tabanlı – çalıştırıldığında MUTLAKA bildirir
--///////////////////////////////////////////////////////////

local KEYWORDS  = {"tackle","kick","cooldown","cd"}        -- aranacak ad parçaları
local Players   = game:GetService("Players")
local Gui       = game:GetService("StarterGui")

------------------------------------------------------------
--  Bildirim yardımcı
------------------------------------------------------------
local function notify(text, good)
    Gui:SetCore("SendNotification",{
        Title    = good and "✓ Cooldown" or "✗ Cooldown",
        Text     = text,
        Duration = 3,
    })
end

------------------------------------------------------------
--  Eşleşme + tarama
------------------------------------------------------------
local function matches(n)
    n = n:lower()
    for _,k in ipairs(KEYWORDS) do
        if n:find(k) then return true end
    end
end

local function hookValue(val, plr)
    if not val:IsA("ValueBase") or not matches(val.Name) then return end

    local function report(v)
        if tonumber(v) and v > 0 then
            notify(plr.Name.."  •  "..string.format("%.1f s", v), false)
        else
            notify(plr.Name.."  •  Ready!", true)
        end
    end
    report(val.Value)
    val.Changed:Connect(report)
end

local function scanChar(char, plr)
    -- Attributes
    for n,_ in pairs(char:GetAttributes()) do
        if matches(n) then
            local function attrRpt()
                local v = char:GetAttribute(n)
                notify(plr.Name.."  •  "..((tonumber(v) and v>0) and v.." s" or "Ready!"), v<=0)
            end
            attrRpt()
            char:GetAttributeChangedSignal(n):Connect(attrRpt)
        end
    end
    -- ValueBase
    for _,d in ipairs(char:GetDescendants()) do hookValue(d, plr) end
    char.DescendantAdded:Connect(function(d) hookValue(d, plr) end)
end

local function trackPlayer(plr)
    if plr.Character then scanChar(plr.Character, plr) end
    plr.CharacterAdded:Connect(function(c) scanChar(c, plr) end)
end
for _,p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
Players.PlayerAdded:Connect(trackPlayer)

notify("Cooldown Spy ✓ Loaded", true)
