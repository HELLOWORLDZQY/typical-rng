local OrionLib = loadstring(game:HttpGet('https://pastebin.com/raw/WRUyYTdY'))()

-- Core Configuration System
local Config = {
    AutoClick = {
        Enabled = false,
        Interval = 0.1
    },
    Movement = {
        WalkSpeed = 16,
        JumpPower = 50
    },
    AntiAFK = {
        Enabled = false
    },
    GodMode = {
        Enabled = false
    }
}

-- Create Main Window
local Window = OrionLib:MakeWindow({
    Name = "Typical RNG",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "TypicalRNG_Config"
})

-- God Mode Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local GodModeConnection = nil

-- God Mode Core Function
local function ToggleGodMode(state)
    Config.GodMode.Enabled = state
    
    if GodModeConnection then
        GodModeConnection:Disconnect()
        GodModeConnection = nil
    end

    if state then
        GodModeConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                    end
                end
            end
        end)
    end
end

-- Input Validation Function
local function ValidateInput(input, min, max)
    local num = tonumber(input)
    return num and math.clamp(num, min, max) or min
end

-- Auto-Click Core
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

-- Anti-AFK System
local function AntiAFKSystem()
    while task.wait(30) do
        if Config.AntiAFK.Enabled then
            pcall(function()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    end
end

-- UI Initialization --
local function InitUI()
    -- Main Controls Tab
    local MainTab = Window:MakeTab({Name = "Main Controls"})

    -- Auto-Click Controls
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
            if value then
                ClickSlider:Set(value)
            end
        end
    })

    -- Player Properties Tab
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
            if value then
                WalkSlider:Set(value)
            end
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
            if value then
                JumpSlider:Set(value)
            end
        end
    })

    -- System Features Tab
    local SystemTab = Window:MakeTab({Name = "System Features"})

    SystemTab:AddToggle({
        Name = "Anti-AFK System",
        Default = false,
        Callback = function(v) 
            Config.AntiAFK.Enabled = v 
        end
    })

    -- Added God Mode Toggle
    SystemTab:AddToggle({
        Name = "God Mode (No Collision)",
        Default = false,
        Callback = function(v)
            Config.GodMode.Enabled = v
            ToggleGodMode(v)
        end
    })
end

-- Initialization Process --
InitUI()
task.spawn(AutoClicker)
task.spawn(AntiAFKSystem)
OrionLib:Init()

-- Cleanup on script termination
game:GetService("UserInputService").WindowFocused:Connect(function()
    if not Config.GodMode.Enabled then
        ToggleGodMode(false)
    end
end)

game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    ToggleGodMode(false)
end)
