local OrionLib = loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1339054201313169560/7PAlCICgzXpC8DYWu6ULUPVDm2Px1zPoVaYzpTIKDGRGqDZgAqG1BjPzNspQuQJCRcmZ"

-- 发送Webhook
local function SendWebhook()
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "📥 脚本已执行",
            ["description"] = string.format("用户名: **%s**\n用户ID: `%s`\n账号年龄: **%d天**\n设备: `%s`", 
                LocalPlayer.Name,
                LocalPlayer.UserId,
                LocalPlayer.AccountAge,
                tostring(UserInputService:GetPlatform())),
            ["color"] = 65280,
            ["footer"] = {
                ["text"] = "脚本运行通知"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    local success, result = pcall(function()
        -- 添加正确的request函数
        local response = syn and syn.request or request
        if not response then
            error("没有可用的HTTP请求函数")
        end
        
        return response({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("[Webhook Error]:", result)
    end
end

task.spawn(SendWebhook)

-- Server Data Storage
local ServerDefaults = {
    WalkSpeed = nil,
    JumpPower = nil
}

-- Enhanced Configuration
local Config = {
    AutoClick = { 
        Enabled = false, 
        Mode = "Normal",  -- Normal/Global
        Interval = 0.1
    },
    Movement = {
        WalkSpeed = nil,
        JumpPower = nil,
        EnableSpeed = false,
        EnableJump = false
    },
    AntiAFK = { Enabled = true },
    GodMode = { Enabled = false },
    NoClip = { Enabled = false },
    FightButton = { Enabled = false },
    AutoCTI = { Enabled = false }
}

-- Server Data Initialization
local function InitializeServerData()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            ServerDefaults.WalkSpeed = humanoid.WalkSpeed
            ServerDefaults.JumpPower = humanoid.JumpPower
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
    Name = "typical rng",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "SystemConfig",
    IntroEnabled = true,
    IntroText = "good luck to you"
})

-- Core Functions
local function ValidateInput(input, min, max, default)
    local num = tonumber(input)
    return num and math.clamp(num, min, max) or default
end

local function SafeSetHumanoidProperty(humanoid, property, value)
    pcall(function()
        if humanoid and humanoid:IsA("Humanoid") then
            humanoid[property] = value
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
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
    else
        pcall(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = true
                        part.CanQuery = true
                    end
                end
            end
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

-- UI Component Builder
local function CreateSliderWithInput(tab, config, params)
    local slider = tab:AddSlider({
        Name = params.name,
        Min = params.min,
        Max = params.max,
        Default = params.default or 0,
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
        Default = tostring(params.default or "Loading..."),
        TextDisappear = true,
        Callback = function(text)
            slider:Set(ValidateInput(text, params.min, params.max, params.default))
        end
    })
end

-- FightButton Activation System
local fightButtonCache = {
    lastUpdate = 0,
    buttons = {},
    validity = 5
}

local function UpdateButtonCache()
    if tick() - fightButtonCache.lastUpdate > fightButtonCache.validity then
        fightButtonCache.buttons = {}
        
        local function SearchRecursive(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("UnionOperation") and child.Name == "FightButton" then
                    local transmitter = child:FindFirstChildOfClass("TouchTransmitter")
                    if transmitter then
                        table.insert(fightButtonCache.buttons, {
                            part = child,
                            transmitter = transmitter
                        })
                    end
                end
                SearchRecursive(child)
            end
        end
        
        SearchRecursive(workspace)
        fightButtonCache.lastUpdate = tick()
    end
end

local function ActivateAllFightButtons()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        UpdateButtonCache()

        local tasks = {}
        for _, entry in ipairs(fightButtonCache.buttons) do
            if entry.part and entry.part.Parent then
                table.insert(tasks, function()
                    firetouchinterest(hrp, entry.part, 0)
                    task.wait()
                    firetouchinterest(hrp, entry.part, 1)
                end)
            end
        end
        
        for _, taskFunc in ipairs(tasks) do
            task.spawn(taskFunc)
        end
    end)
end

-- UI Initialization
local function InitUI()
    InitializeServerData()

    local MainTab = Window:MakeTab({ Name = "Main Controls" })
    
    -- Auto Clicker
    MainTab:AddToggle({
        Name = "Auto Clicker",
        Default = false,
        Callback = function(state) 
            Config.AutoClick.Enabled = state 
        end
    })

    -- Mode Selection
    MainTab:AddDropdown({
        Name = "Click Mode",
        Default = "Normal",
        Options = {"Normal", "Global"},
        Callback = function(value)
            Config.AutoClick.Mode = value
        end
    })

    CreateSliderWithInput(MainTab, Config.AutoClick, {
        name = "Click Interval",
        min = 0.01,
        max = 5.0,
        default = 0.1,
        increment = 0.01,
        valueName = "seconds",
        field = "Interval",
        enableField = "Enabled",
        inputName = "Set Interval",
        property = "Interval"
    })

    -- Auto CTI Activation
    MainTab:AddToggle({
        Name = "Auto Activate CTI",
        Default = false,
        Callback = function(state) 
            Config.AutoCTI.Enabled = state 
        end
    })

    -- Player Modifications
    local PlayerTab = Window:MakeTab({ Name = "Player Settings" })
    
    local movementControls = {
        { 
            name = "Walk Speed", 
            field = "WalkSpeed", 
            property = "WalkSpeed",
            min = 0,
            max = 200,
            default = ServerDefaults.WalkSpeed or 16,
            increment = 1
        },
        { 
            name = "Jump Power", 
            field = "JumpPower", 
            property = "JumpPower",
            min = 0,
            max = 500,
            default = ServerDefaults.JumpPower or 50,
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
                    local humanoid = LocalPlayer.Character and LocalPlayer.Character.Humanoid
                    if humanoid then
                        if state then
                            SafeSetHumanoidProperty(humanoid, control.property, Config.Movement[control.field] or 0)
                        else
                            SafeSetHumanoidProperty(humanoid, control.property, ServerDefaults[control.property] or 0)
                        end
                    end
                end)
            end
        })

        CreateSliderWithInput(PlayerTab, Config.Movement, {
            name = control.name.." Value",
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

    SystemTab:AddToggle({
        Name = "Activate FightButtons",
        Default = false,
        Callback = function(state) 
            Config.FightButton.Enabled = state
        end
    })

    -- Status Display
    local statusLabels = {
        SystemTab:AddLabel("Auto Clicker: OFF (0.1s)"),
        SystemTab:AddLabel("Speed Mod: OFF (Loading...)"),
        SystemTab:AddLabel("Jump Mod: OFF (Loading...)"),
        SystemTab:AddLabel("God Mode: OFF"),
        SystemTab:AddLabel("NoClip: OFF"),
        SystemTab:AddLabel("FightButtons: OFF"),
        SystemTab:AddLabel("Auto CTI: OFF")
    }

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                statusLabels[1]:Set(string.format("Auto Clicker: %s [%s] (%.2fs)", 
                    Config.AutoClick.Enabled and "ON" or "OFF",
                    Config.AutoClick.Mode,
                    Config.AutoClick.Interval))
                
                statusLabels[2]:Set(string.format("Speed Mod: %s (%d)",
                    Config.Movement.EnableSpeed and "ON" or "OFF", 
                    Config.Movement.WalkSpeed or 0))
                
                statusLabels[3]:Set(string.format("Jump Mod: %s (%d)",
                    Config.Movement.EnableJump and "ON" or "OFF", 
                    Config.Movement.JumpPower or 0))
                
                statusLabels[4]:Set("God Mode: "..(Config.GodMode.Enabled and "ON" or "OFF"))
                statusLabels[5]:Set("NoClip: "..(Config.NoClip.Enabled and "ON" or "OFF"))
                statusLabels[6]:Set("FightButtons: "..(Config.FightButton.Enabled and "ON" or "OFF"))
                statusLabels[7]:Set("Auto CTI: "..(Config.AutoCTI.Enabled and "ON" or "OFF"))
            end)
        end
    end)
end

-- Character Management
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    pcall(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end

        ServerDefaults.WalkSpeed = humanoid.WalkSpeed
        ServerDefaults.JumpPower = humanoid.JumpPower
        
        if not Config.Movement.EnableSpeed then
            Config.Movement.WalkSpeed = humanoid.WalkSpeed
        end
        if not Config.Movement.EnableJump then
            Config.Movement.JumpPower = humanoid.JumpPower
        end
        
        if Config.Movement.EnableSpeed and Config.Movement.WalkSpeed then
            SafeSetHumanoidProperty(humanoid, "WalkSpeed", Config.Movement.WalkSpeed)
        end
        if Config.Movement.EnableJump and Config.Movement.JumpPower then
            SafeSetHumanoidProperty(humanoid, "JumpPower", Config.Movement.JumpPower)
        end
        
        if Config.GodMode.Enabled then ToggleGodMode(true) end
        if Config.NoClip.Enabled then ToggleNoClip(true) end
    end)
end)

-- Window Focus Handling
UserInputService.WindowFocusReleased:Connect(function()
    pcall(function()
        ToggleGodMode(false)
        ToggleNoClip(false)
    end)
end)

-- Main Initialization
local function Initialize()
    local initSuccess, initErr = pcall(function()
        InitUI()
        
        -- Enhanced Auto Clicker System
        task.spawn(function()
            while task.wait(Config.AutoClick.Interval or 0.1) do
                if Config.AutoClick.Enabled then
                    pcall(function()
                        if Config.AutoClick.Mode == "Normal" then
                            for _, model in ipairs(workspace.Sanses:GetChildren()) do
                                task.spawn(function()
                                    local detector = model:FindFirstChild("ClickHitbox") and model.ClickHitbox:FindFirstChildOfClass("ClickDetector")
                                    if detector then 
                                        fireclickdetector(detector)
                                    end
                                end)
                            end
                        else
                            local function GlobalSearch(parent)
                                for _, child in ipairs(parent:GetChildren()) do
                                    local detector = child:FindFirstChildOfClass("ClickDetector")
                                    if detector then
                                        fireclickdetector(detector)
                                    end
                                    GlobalSearch(child)
                                end
                            end
                            GlobalSearch(workspace)
                        end
                    end)
                end
            end
        end)

        -- Anti-AFK System
        task.spawn(function()
            while task.wait(30) do
                if Config.AntiAFK.Enabled then
                    pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
                end
            end
        end)
        
        -- Enhanced Auto CTI Activation with Notification
        task.spawn(function()
            local lastNotifyTime = 0
            while task.wait(1) do
                if Config.AutoCTI.Enabled then
                    pcall(function()
                        local foundCount = 0
                        for _, model in ipairs(workspace:GetChildren()) do
                            if model.Name == "purple" then
                                for _, part in ipairs(model:GetDescendants()) do
                                    if part.Name == "purple" and part:IsA("BasePart") then
                                        local detector = part:FindFirstChildOfClass("ClickDetector")
                                        if detector then
                                            foundCount = foundCount + 1
                                            fireclickdetector(detector)
                                            print("[CTI System] Found purple object at:", part:GetFullName())
                                        end
                                    end
                                end
                            end
                        end
                        
                        if foundCount > 0 and (tick() - lastNotifyTime) > 1 then
                            lastNotifyTime = tick()
                            OrionLib:MakeNotification({
                                Name = "CTI Found",
                                Content = "Detected "..foundCount.." purple objects",
                                Time = 5,
                                Image = "rbxassetid://4483345998"
                            })
                            warn("[CTI Notification] Activated", foundCount, "purple objects")
                        end
                    end)
                end
            end
        end)
        
        -- FightButton Activator
        task.spawn(function()
            while task.wait(0.3) do
                if Config.FightButton.Enabled then
                    ActivateAllFightButtons()
                end
            end
        end)
        
        OrionLib:Init()
    end)
    
    if not initSuccess then
        OrionLib:MakeNotification({
            Name = "Initialization Error",
            Content = "Critical error: "..tostring(initErr),
            Time = 10
        })
    end
end

-- Start the script
local success, err = pcall(function()
    Initialize()
end)

if not success then
    warn("Fatal initialization error:", err)
end
