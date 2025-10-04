if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local queueteleport = missing("function", 
    queue_on_teleport 
    or (syn and syn.queue_on_teleport) 
    or (fluxus and fluxus.queue_on_teleport)
)

local TeleportCheck = false
game.Players.LocalPlayer.OnTeleport:Connect(function()
    if (not TeleportCheck) and queueteleport then
        TeleportCheck = true
    
        queueteleport([[
            if game.PlaceId == 91694942823334 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/HELLOWORLDZQY/typical-rng/refs/heads/main/typical%20rng1.lua", true))()
            else
                loadstring(game:HttpGet("https://raw.githubusercontent.com/HELLOWORLDZQY/typical-rng/refs/heads/main/typical%20rng2.lua", true))()
            end
        ]])
    end
end)

if game.PlaceId == 91694942823334 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HELLOWORLDZQY/typical-rng/refs/heads/main/typical%20rng1.lua", true))()
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HELLOWORLDZQY/typical-rng/refs/heads/main/typical%20rng2.lua", true))()
end
