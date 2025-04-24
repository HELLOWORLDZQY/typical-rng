local OrionLib = loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Server Data Management
local ServerDefaults = {
    WalkSpeed = 16,
    JumpPower = 50
}

-- Configuration System
local Config = {
    AutoClick = { Enabled = false, Interval = 0.1 },
    Movement = {
        WalkSpeed = 16,
        JumpPower = 50,
        EnableSpeed = false,
        EnableJump = false
    },
    AntiAFK = { Enabled = true },
    GodMode = { Enabled = false },
    NoClip = { Enabled = false },
    AutoCTI = { Enabled = false }
}

-- Initialize Server Data
local function InitializeServerData()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            ServerDefaults.WalkSpeed = humanoid.WalkSpeed
            ServerDefaults.JumpPower = humanoid.JumpPower
            -- Sync config with server data if features disabled
            if not Config.Movement.EnableSpeed then
                Config.Movement.WalkSpeed = humanoid.WalkSpeed
            end
            if not Config.Movement.EnableJump then
                Config.Movement.JumpPower = humanoid.JumpPower
            end
        end
    end
end

-- UI Window
local Window = OrionLib:MakeWindow({
    Name = "Typical RNG",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "TypicalRNG_Config",
    IntroEnabled = true,
    IntroText = "idk XD"
})

-- Core Functions
local function SafeSetHumanoidProperty(humanoid, property, value)
    pcall(function()
        if humanoid and humanoid:IsA("Humanoid") then
            humanoid[property] = value
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

local function ValidateInput(input, min, max, default)
    local num = tonumber(input)
    return num and math.clamp(num, min, max) or default
end

-- God Mode
local GodModeConnection, NoClipConnection

local function ToggleGodMode(state)
    Config.GodMode.Enabled = state
    if GodModeConnection then GodModeConnection:Disconnect() end
    
    if state then
        GodModeConnection = RunService.Stepped:Connect(function()
            pcall(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanTouch = false
                            part.CanQuery = false
                        end
                    end
                end
            end)
        end)
    end
end

-- NoClip Mode
local function ToggleNoClip(state)
    Config.NoClip.Enabled = state
    if NoClipConnection then NoClipConnection:Disconnect() end
    
    if state then
        NoClipConnection = RunService.Stepped:Connect(function()
            pcall(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end)
    end
end

-- UI Control Builder
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
                SafeSetHumanoidProperty(LocalPlayer.Character and LocalPlayer.Character.Humanoid, params.property, value)
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

-- UI Initialization
local function InitUI()
    InitializeServerData()  -- Load initial server data

    local MainTab = Window:MakeTab({ Name = "Main Controls" })
    
    -- Auto Clicker
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
        inputName = "Set Interval"
    })

    -- Auto CTI Activation
    MainTab:AddToggle({
        Name = "Auto Activate CTI",
        Default = false,
        Callback = function(state) 
            Config.AutoCTI.Enabled = state 
        end
    })

    -- Player Settings
    local PlayerTab = Window:MakeTab({ Name = "Player Settings" })
    
    local movementControls = {
        { 
            name = "Speed", 
            field = "WalkSpeed", 
            property = "WalkSpeed",
            min = 16,
            max = 200,
            default = ServerDefaults.WalkSpeed,
            increment = 1
        },
        { 
            name = "Jump", 
            field = "JumpPower", 
            property = "JumpPower",
            min = 50,
            max = 500,
            default = ServerDefaults.JumpPower,
            increment = 5
        }
    }

    for _, control in ipairs(movementControls) do
        PlayerTab:AddToggle({
            Name = "Enable "..control.name,
            Default = false,
            Callback = function(state)
                Config.Movement["Enable"..control.name] = state
                local humanoid = LocalPlayer.Character and LocalPlayer.Character.Humanoid
                if humanoid then
                    if state then
                        SafeSetHumanoidProperty(humanoid, control.property, Config.Movement[control.field])
                    else
                        SafeSetHumanoidProperty(humanoid, control.property, ServerDefaults[control.property])
                    end
                end
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
            inputName = control.name.." Value",
            property = control.property
        })
    end

    -- System Features
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

    -- Status Display
    local statusLabels = {
        SystemTab:AddLabel("Auto Clicker: OFF (0.1s)"),
        SystemTab:AddLabel("Speed Mod: OFF ("..ServerDefaults.WalkSpeed..")"),
        SystemTab:AddLabel("Jump Mod: OFF ("..ServerDefaults.JumpPower..")"),
        SystemTab:AddLabel("God Mode: OFF"),
        SystemTab:AddLabel("NoClip: OFF"),
        SystemTab:AddLabel("Auto CTI: OFF")
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
                statusLabels[6]:Set("Auto CTI: "..(Config.AutoCTI.Enabled and "ON" or "OFF"))
            end)
        end
    end)
end

-- Character Event Handling
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    pcall(function()
        local humanoid = character:WaitForChild("Humanoid")
        -- Update server defaults
        ServerDefaults.WalkSpeed = humanoid.WalkSpeed
        ServerDefaults.JumpPower = humanoid.JumpPower
        
        -- Sync configuration
        if not Config.Movement.EnableSpeed then
            Config.Movement.WalkSpeed = humanoid.WalkSpeed
        end
        if not Config.Movement.EnableJump then
            Config.Movement.JumpPower = humanoid.JumpPower
        end
        
        -- Apply active modifications
        if Config.Movement.EnableSpeed then
            SafeSetHumanoidProperty(humanoid, "WalkSpeed", Config.Movement.WalkSpeed)
        end
        if Config.Movement.EnableJump then
            SafeSetHumanoidProperty(humanoid, "JumpPower", Config.Movement.JumpPower)
        end
        
        if Config.GodMode.Enabled then ToggleGodMode(true) end
        if Config.NoClip.Enabled then ToggleNoClip(true) end
    end)
end)

-- Window Focus Handling
UserInputService.WindowFocusReleased:Connect(function()
    pcall(function()
        if Config.GodMode.Enabled then ToggleGodMode(false) end
        if Config.NoClip.Enabled then ToggleNoClip(false) end
    end)
end)

-- Main Initialization
local function Initialize()
    InitUI()
    
    -- Auto Clicker
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
    
    -- Anti-AFK
    task.spawn(function()
        while task.wait(30) do
            if Config.AntiAFK.Enabled then
                pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
            end
        end
    end)
    
    -- Auto CTI Activation
    task.spawn(function()
        while task.wait(1) do
            if Config.AutoCTI.Enabled then
                pcall(function()
                    for _, model in ipairs(workspace:GetChildren()) do
                        if model.Name == "purple" then
                            for _, part in ipairs(model:GetDescendants()) do
                                if part.Name == "purple" and part:IsA("BasePart") then
                                    local detector = part:FindFirstChildOfClass("ClickDetector")
                                    if detector then
                                        fireclickdetector(detector)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
    
    OrionLib:Init()
end

-- Error Handling
local success, err = pcall(Initialize)
if not success then
    OrionLib:MakeNotification({
        Name = "Initialization Failed",
        Content = "Error: "..tostring(err),
        Time = 5
    })
end
