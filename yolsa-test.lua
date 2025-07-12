-- Remote-Spy Lite  –  “Tackle” kelimesi geçen paketleri bildirir
local RS   = game:GetService("ReplicatedStorage")
local Gui  = game:GetService("StarterGui")

local function ping(txt)
    Gui:SetCore("SendNotification",{Title="Remote",Text=txt,Duration=4})
end

for _,r in ipairs(RS:GetDescendants()) do
    if r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            local data = table.concat(
                table.pack(...),
                " | ",
                1,
                select("#", ...)
            )
            if tostring(data):lower():find("tackle") then
                ping("Remote → "..r.Name.." : "..data)
            end
        end)
    end
end
ping("Remote-Spy ✓ Listening")
