return function()
    -- Load UI library (with fallback handling)
    local OrionLib, uiLoaded = pcall(function()
        return loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()
    end)
    
    if not OrionLib or not uiLoaded then
        warn("Failed to load UI library. Please check internet connection.")
        return
    end

    -- Configuration system
    local Config = {
        AutoClick = { Enabled = false, Interval = 0.1 },
        Movement = { WalkSpeed = 16, JumpPower = 50 },
        AntiAFK = { Enabled = false }
    }

    -- Enhanced input validation
    local function ValidateInput(input, min, max, defaultValue)
        local num = tonumber(input)
        return num and math.clamp(num, min, max) or defaultValue
    end

    -- Auto-click module
    local function AutoClicker()
        while task.wait(Config.AutoClick.Interval) do
            if not Config.AutoClick.Enabled then continue end
            
            local success, err = pcall(function()
                local targets = workspace.Sanses:GetChildren()
                if #targets == 0 then
                    warn("No clickable targets found")
                    return
                end
                
                for _, model in ipairs(targets) do
                    local hitbox = model:FindFirstChild("ClickHitbox")
                    if hitbox then
                        local detector = hitbox:FindFirstChildOfClass("ClickDetector")
                        if detector then
                            fireclickdetector(detector)
                            task.wait(0.05) -- Click cooldown
                        end
                    end
                end
            end)
            
            if not success then
                warn("Auto-click error:", err)
            end
        end
    end

    -- Anti-AFK system
    local function AntiAFKSystem()
        while task.wait(math.random(25, 35)) do
            if Config.AntiAFK.Enabled then
                pcall(function()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                    print("Anti-AFK heartbeat sent")
                end)
            end
        end
    end

    -- Player properties sync
    local function SyncPlayerProperties()
        game:GetService("RunService").Heartbeat:Connect(function()
            pcall(function()
                local character = game.Players.LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = Config.Movement.WalkSpeed
                        humanoid.JumpPower = Config.Movement.JumpPower
                    end
                end
            end)
        end)
    end

    -- GUI initialization
    local function InitGUI()
        local Window = OrionLib:MakeWindow({
            Name = "Typical RNG",
            HidePremium = false,
            SaveConfig = true,
            ConfigFolder = "TypicalRNG_Config"
        })

        -- Main Controls Tab
        local MainTab = Window:MakeTab({Name = "Main Controls"})
        
        MainTab:AddToggle({
            Name = "Auto Click Toggle",
            Default = false,
            Callback = function(v) 
                Config.AutoClick.Enabled = v
                print("Auto-click status:", v and "ENABLED" or "DISABLED")
            end
        })

        local ClickSlider = MainTab:AddSlider({
            Name = "Click Interval (seconds)",
            Min = 0.05,
            Max = 1.0,
            Default = 0.1,
            Increment = 0.05,
            Callback = function(v) 
                Config.AutoClick.Interval = v
            end
        })

        MainTab:AddTextbox({
            Name = "Manual Interval Input",
            Default = "0.1",
            Callback = function(text)
                local value = ValidateInput(text, 0.05, 1.0, 0.1)
                ClickSlider:Set(value)
                Config.AutoClick.Interval = value
            end
        })

        -- Player Settings Tab
        local PlayerTab = Window:MakeTab({Name = "Player Settings"})
        
        local WalkSlider = PlayerTab:AddSlider({
            Name = "Movement Speed",
            Min = 16,
            Max = 250,
            Default = 16,
            Increment = 1,
            Callback = function(v)
                Config.Movement.WalkSpeed = v
                pcall(function()
                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
                end)
            end
        })

        PlayerTab:AddTextbox({
            Name = "Speed Input",
            Default = "16",
            Callback = function(text)
                local value = ValidateInput(text, 16, 250, 16)
                WalkSlider:Set(value)
            end
        })

        local JumpSlider = PlayerTab:AddSlider({
            Name = "Jump Height",
            Min = 50,
            Max = 500,
            Default = 50,
            Increment = 5,
            Callback = function(v)
                Config.Movement.JumpPower = v
                pcall(function()
                    game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
                end)
            end
        })

        PlayerTab:AddTextbox({
            Name = "Jump Height Input",
            Default = "50",
            Callback = function(text)
                local value = ValidateInput(text, 50, 500, 50)
                JumpSlider:Set(value)
            end
        })

        -- System Features Tab
        local SystemTab = Window:MakeTab({Name = "System Features"})
        SystemTab:AddToggle({
            Name = "Anti-AFK System",
            Default = false,
            Callback = function(v) 
                Config.AntiAFK.Enabled = v
                print("Anti-AFK status:", v and "ENABLED" or "DISABLED")
            end
        })

        -- Initialization complete notification
        Window:MakeNotification({
            Name = "Initialization Complete",
            Content = "Script loaded successfully!",
            Time = 5
        })
    end

    -- Main execution flow
    local function Main()
        InitGUI()
        task.spawn(AutoClicker)
        task.spawn(AntiAFKSystem)
        task.spawn(SyncPlayerProperties)
        OrionLib:Init()
    end

    -- Error handling
    local success, err = pcall(Main)
    if not success then
        OrionLib:MakeNotification({
            Name = "Critical Error",
            Content = "Initialization failed: "..tostring(err),
            Time = 10
        })
    end
end
