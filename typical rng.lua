return function()
    local OrionLib = loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()
    
    -- 配置系统
    local Config = {
        AutoClick = { Enabled = false, Interval = 0.1 },
        Movement = { WalkSpeed = 16, JumpPower = 50 },
        AntiAFK = { Enabled = false }
    }

    -- 输入验证
    local function ValidateInput(input, min, max)
        local num = tonumber(input)
        return num and math.clamp(num, min, max) or min
    end

    -- 核心功能模块
    local function AutoClicker()
        while task.wait(Config.AutoClick.Interval) do
            if not Config.AutoClick.Enabled then continue end
            pcall(function()
                for _, model in pairs(workspace.Sanses:GetChildren()) do
                    local hitbox = model:FindFirstChild("ClickHitbox")
                    if hitbox and hitbox:FindFirstChildOfClass("ClickDetector") then
                        fireclickdetector(hitbox:FindFirstChildOfClass("ClickDetector"))
                    end
                end
            end)
        end
    end

    local function AntiAFKSystem()
        while task.wait(30) do
            if Config.AntiAFK.Enabled then
                pcall(function()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end)
            end
        end
    end

    -- GUI初始化
    local function Init()
        local Window = OrionLib:MakeWindow({
            Name = "Typical RNG",
            HidePremium = false,
            SaveConfig = true,
            ConfigFolder = "TypicalRNG_Config"
        })

        -- 主控制标签页
        local MainTab = Window:MakeTab({Name = "Main Controls"})
        MainTab:AddToggle({
            Name = "Auto Click Toggle",
            Default = false,
            Callback = function(v) 
                Config.AutoClick.Enabled = v 
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
            Name = "Manual Input Interval",
            Default = "0.1",
            Callback = function(text)
                local value = ValidateInput(text, 0.05, 1.0)
                ClickSlider:Set(value)
            end
        })

        -- 玩家属性标签页
        local PlayerTab = Window:MakeTab({Name = "Player Properties"})
        local WalkSlider = PlayerTab:AddSlider({
            Name = "Walk Speed",
            Min = 16,
            Max = 250,
            Default = 16,
            Increment = 1,
            Callback = function(v)
                pcall(function()
                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
                end)
            end
        })

        PlayerTab:AddTextbox({
            Name = "Input Walk Speed",
            Default = "16",
            Callback = function(text)
                local value = ValidateInput(text, 16, 250)
                WalkSlider:Set(value)
            end
        })

        local JumpSlider = PlayerTab:AddSlider({
            Name = "Jump Power",
            Min = 50,
            Max = 500,
            Default = 50,
            Increment = 5,
            Callback = function(v)
                pcall(function()
                    game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
                end)
            end
        })

        PlayerTab:AddTextbox({
            Name = "Input Jump Power",
            Default = "50",
            Callback = function(text)
                local value = ValidateInput(text, 50, 500)
                JumpSlider:Set(value)
            end
        })

        -- 系统功能标签页
        local SystemTab = Window:MakeTab({Name = "System Features"})
        SystemTab:AddToggle({
            Name = "Anti-AFK System",
            Default = false,
            Callback = function(v) 
                Config.AntiAFK.Enabled = v 
            end
        })

        -- 启动功能
        task.spawn(AutoClicker)
        task.spawn(AntiAFKSystem)
        OrionLib:Init()
    end

    -- 执行初始化
    Init()
end
