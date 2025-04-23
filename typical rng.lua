local OrionLib = loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    AutoClick = { Enabled = false, Interval = 0.1 },
    Movement = { WalkSpeed = 16, JumpPower = 50, EnableMovement = false, EnableJump = false },
    AntiAFK = { Enabled = true },
    GodMode = { Enabled = false },
    NoClip = { Enabled = false }
}

local Window = OrionLib:MakeWindow({
    Name = "Typical RNG",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "TypicalRNG_Config",
    IntroEnabled = true,
    IntroText = "Powered by Enhanced System"
})

local function ValidateInput(input, min, max, default)
    local num = tonumber(input)
    return num and math.clamp(num, min, max) or default
end

local GodModeConnection, NoClipConnection

local function ToggleGodMode(state)
    Config.GodMode.Enabled = state
    if GodModeConnection then GodModeConnection:Disconnect() end
    
    if state then
        GodModeConnection = RunService.Stepped:Connect(function()
            pcall(function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = false
                        part.CanQuery = false
                    end
                end
            end)
        end)
    else
        pcall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanTouch = true
                    part.CanQuery = true
                end
            end
        end)
    end
end

local function ToggleNoClip(state)
    Config.NoClip.Enabled = state
    if NoClipConnection then NoClipConnection:Disconnect() end
    
    if state then
        NoClipConnection = RunService.Stepped:Connect(function()
            pcall(function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end)
    end
end

local function CreateSliderWithInput(tab, config, params)
    local slider = tab:AddSlider({
        Name = params.name,
        Min = params.min,
        Max = params.max,
        Default = params.default,
        Increment = params.increment,
        ValueName = params.valueName,
        Callback = function(value)
            config[params.field] = value
            if config[params.enableField] then
                pcall(function()
                    LocalPlayer.Character.Humanoid[params.property] = value
                end)
            end
        end
    })

    tab:AddTextbox({
        Name = params.inputName,
        Default = tostring(params.default),
        TextDisappear = true,
        Callback = function(text)
            slider:Set(ValidateInput(text, params.min, params.max, params.default))
        end
    })
end

local function InitUI()
    local MainTab = Window:MakeTab({ Name = "Main Controls" })
    
    MainTab:AddToggle({
        Name = "Auto Clicker",
        Default = false,
        Callback = function(state) Config.AutoClick.Enabled = state end
    })

    CreateSliderWithInput(MainTab, Config.AutoClick, {
        name = "Click Interval (sec)",
        min = 0.01,
        max = 1.0,
        default = 0.1,
        increment = 0.01,
        valueName = "sec",
        field = "Interval",
        inputName = "Manual Interval"
    })

    local PlayerTab = Window:MakeTab({ Name = "Player Settings" })
    
    local movementControls = {
        { 
            name = "Speed", 
            field = "WalkSpeed", 
            property = "WalkSpeed",
            min = 16,
            max = 200,
            default = 16,
            increment = 1
        },
        { 
            name = "Jump", 
            field = "JumpPower", 
            property = "JumpPower",
            min = 50,
            max = 500,
            default = 50,
            increment = 5
        }
    }

    for _, control in ipairs(movementControls) do
        PlayerTab:AddToggle({
            Name = "Enable "..control.name,
            Default = false,
            Callback = function(state)
                Config.Movement["Enable"..control.name] = state
                pcall(function()
                    LocalPlayer.Character.Humanoid[control.property] = state and Config.Movement[control.field] or control.default
                end)
            end
        })

        CreateSliderWithInput(PlayerTab, Config.Movement, {
            name = control.name.." Power",
            min = control.min,
            max = control.max,
            default = control.default,
            increment = control.increment,
            valueName = "value",
            field = control.field,
            enableField = "Enable"..control.name,
            inputName = control.name.." Input",
            property = control.property
        })
    end

    local SystemTab = Window:MakeTab({ Name = "System Features" })
    
    SystemTab:AddToggle({
        Name = "Anti-AFK System",
        Default = true,
        Callback = function(state) Config.AntiAFK.Enabled = state end
    })

    SystemTab:AddToggle({
        Name = "God Mode",
        Default = false,
        Callback = ToggleGodMode
    })

    SystemTab:AddToggle({
        Name = "NoClip Mode",
        Default = false,
        Callback = ToggleNoClip
    })

    local statusLabels = {
        SystemTab:AddLabel("Auto Clicker: OFF (0.1s)"),
        SystemTab:AddLabel("Speed Mod: OFF (16)"),
        SystemTab:AddLabel("Jump Mod: OFF (50)"),
        SystemTab:AddLabel("God Mode: OFF"),
        SystemTab:AddLabel("NoClip: OFF")
    }

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                statusLabels[1]:Set(string.format("Auto Clicker: %s (%.2fs)", 
                    Config.AutoClick.Enabled and "ON" or "OFF", Config.AutoClick.Interval))
                statusLabels[2]:Set(string.format("Speed Mod: %s (%d)",
                    Config.Movement.EnableSpeed and "ON" or "OFF", Config.Movement.WalkSpeed))
                statusLabels[3]:Set(string.format("Jump Mod: %s (%d)",
                    Config.Movement.EnableJump and "ON" or "OFF", Config.Movement.JumpPower))
                statusLabels[4]:Set("God Mode: "..(Config.GodMode.Enabled and "ON" or "OFF"))
                statusLabels[5]:Set("NoClip: "..(Config.NoClip.Enabled and "ON" or "OFF"))
            end)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    pcall(function()
        if Config.Movement.EnableSpeed then
            character.Humanoid.WalkSpeed = Config.Movement.WalkSpeed
        end
        if Config.Movement.EnableJump then
            character.Humanoid.JumpPower = Config.Movement.JumpPower
        end
        if Config.GodMode.Enabled then ToggleGodMode(true) end
        if Config.NoClip.Enabled then ToggleNoClip(true) end
    end)
end)

UserInputService.WindowFocusReleased:Connect(function()
    pcall(function()
        if Config.GodMode.Enabled then ToggleGodMode(false) end
        if Config.NoClip.Enabled then ToggleNoClip(false) end
    end)
end)

local function Initialize()
    InitUI()
    task.spawn(function()
        while task.wait(Config.AutoClick.Interval) do
            if Config.AutoClick.Enabled then
                pcall(function()
                    for _, model in ipairs(workspace.Sanses:GetChildren()) do
                        task.spawn(function()
                            local detector = model:FindFirstChild("ClickHitbox") and model.ClickHitbox:FindFirstChildOfClass("ClickDetector")
                            if detector then fireclickdetector(detector) end
                        end)
                    end
                end)
            end
        end
    end)
    task.spawn(function()
        while task.wait(math.random(25,35)) do
            if Config.AntiAFK.Enabled then
                pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
            end
        end
    end)
    OrionLib:Init()
end

pcall(Initialize)
