--////////////////////////////////////////////////////////////
--  Tackle Hız Ölçer v2  •  bildirim + chat fallback
--////////////////////////////////////////////////////////////
local INPUT_KEY      = Enum.KeyCode.F     -- tackle tuşu
local SAMPLE_WINDOW  = 0.25               -- s, hız ölçüm süresi
local TARGET_SAMPLES = 10                 -- kaç ölçümde ortalama?
local SPEEDS         = {}                 -- tepe hızlar

local Players  = game:GetService("Players")
local RunSvc   = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local GUI      = game:GetService("StarterGui")
local lp       = Players.LocalPlayer

-- Bildirim helper (fallback’li)
local function say(txt, good)
    local ok = pcall(GUI.SetCore, GUI, "SendNotification", {
        Title    = good and "✓ Speed" or "✗ Speed",
        Text     = txt,
        Duration = 3
    })
    if not ok then
        GUI:SetCore("ChatMakeSystemMessage", {
            Text  = "[Speed] "..txt,
            Color = good and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,60,60)
        })
    end
end

-- Tek ölçüm
local function measure()
    local char = lp.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local peak, t = 0, 0
    local con; con = RunSvc.Heartbeat:Connect(function(dt)
        t += dt
        local v = hrp.Velocity
        local horiz = Vector3.new(v.X,0,v.Z).Magnitude
        if horiz > peak then peak = horiz end
        if t >= SAMPLE_WINDOW then
            con:Disconnect()
            table.insert(SPEEDS, peak)
            say(string.format("Ölçüm %d  •  %.1f stud/s", #SPEEDS, peak), false)

            if #SPEEDS >= TARGET_SAMPLES then
                local sum = 0
                for _,s in ipairs(SPEEDS) do sum += s end
                local avg = sum/#SPEEDS
                say(string.format("≈ Önerilen eşik: %.1f stud/s", avg*0.9), true)
                SPEEDS = {}  -- istersen yeniden ölçmek için sıfırla
            end
        end
    end)
end

-- Tuş dinle
UIS.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == INPUT_KEY then
        measure()
    end
end)

-- Başlangıç bildirimi (chat’e de düşecek)
say("Ölçer yüklendi • F tuşuna bas, hız ölçülsün", true)
