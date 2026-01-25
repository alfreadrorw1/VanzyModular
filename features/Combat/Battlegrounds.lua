-- Vanzyxxx Battlegrounds Ultimate
-- Auto Block, God Mode, Hitbox & More
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local Workspace = Services.Workspace
    local RunService = Services.RunService
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer
    
    local CombatTab = UI:Tab("Battlegrounds")
    CombatTab:Label("PVP Arena Specialist")

    -- Config Defaults
    Config.AutoBlock = false
    Config.BlockRange = 15
    Config.HitboxBG = false
    Config.HitboxSizeBG = 10
    Config.AntiVoidBG = false
    Config.GodMode = false    -- Anti-Stun
    Config.GhostMode = false  -- Desync
    Config.NoSlow = false     -- Lari kencang saat charge
    Config.AntiFling = false  -- Anti mental

    --------------------------------------------------------------------------------
    -- 1. SMART AUTO BLOCK
    --------------------------------------------------------------------------------
    local isBlocking = false
    local function GetClosestEnemy()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil, 9999 end
        local closestDist = 9999
        local closestTarget = nil
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local pChar = player.Character
                local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar and pChar:FindFirstChild("Humanoid")
                if pRoot and pHum and pHum.Health > 0 then
                    local dist = (root.Position - pRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestTarget = pRoot
                    end
                end
            end
        end
        return closestTarget, closestDist
    end

    spawn(function()
        while true do
            if Config.AutoBlock then
                local target, dist = GetClosestEnemy()
                if target and dist <= Config.BlockRange then
                    if not isBlocking then
                        isBlocking = true
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    end
                else
                    if isBlocking then
                        isBlocking = false
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end
                end
            elseif isBlocking then
                isBlocking = false
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end
            task.wait(0.1)
        end
    end)

    --------------------------------------------------------------------------------
    -- 2. HITBOX EXPANDER
    --------------------------------------------------------------------------------
    RunService.RenderStepped:Connect(function()
        if not Config.HitboxBG then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = Vector3.new(Config.HitboxSizeBG, Config.HitboxSizeBG, Config.HitboxSizeBG)
                    root.Transparency = 0.8
                    root.CanCollide = false
                    root.Material = Enum.Material.ForceField
                    root.Color = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- 3. GOD MODE (ANTI-COMBO / NO STUN)
    --------------------------------------------------------------------------------
    local function EnableGodMode()
        spawn(function()
            while Config.GodMode do
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if char and hum then
                    -- Hapus Attribute Stun/Ragdoll
                    char:SetAttribute("Stun", 0)
                    char:SetAttribute("Ragdoll", false)
                    char:SetAttribute("Stunned", false)
                    
                    -- Paksa Bangun
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Ragdoll or 
                       state == Enum.HumanoidStateType.FallingDown or 
                       state == Enum.HumanoidStateType.PlatformStanding then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        hum.PlatformStand = false
                    end
                end
                task.wait()
            end
        end)
    end

    --------------------------------------------------------------------------------
    -- 4. GHOST MODE (DESYNC)
    --------------------------------------------------------------------------------
    local OriginalCFrame = nil
    local function ToggleGhostMode(state)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if state then
            OriginalCFrame = root.CFrame
            local rootJoint = root:FindFirstChild("RootJoint")
            if rootJoint then rootJoint:Destroy() end
            
            spawn(function()
                while Config.GhostMode and root do
                    root.CFrame = OriginalCFrame * CFrame.new(0, -50, 0)
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait()
                end
            end)
        else
            if char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
        end
    end

    --------------------------------------------------------------------------------
    -- 5. NO SLOW (SPEED BYPASS)
    --------------------------------------------------------------------------------
    -- Memaksa kecepatan lari tetap 16/20 meski sedang charge skill berat
    spawn(function()
        while true do
            if Config.NoSlow then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum and hum.WalkSpeed < 16 then
                    hum.WalkSpeed = 16
                end
            end
            task.wait(0.1)
        end
    end)

    --------------------------------------------------------------------------------
    -- 6. ANTI-FLING & ANTI-VOID
    --------------------------------------------------------------------------------
    spawn(function()
        while true do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                -- Anti-Void logic
                if Config.AntiVoidBG and root.Position.Y < -50 then
                    local target, _ = GetClosestEnemy()
                    if target then
                        root.CFrame = target.CFrame * CFrame.new(0, 20, 0)
                    else
                        root.CFrame = CFrame.new(0, 50, 0)
                    end
                    root.AssemblyLinearVelocity = Vector3.zero
                end

                -- Anti-Fling logic
                if Config.AntiFling then
                    if root.AssemblyAngularVelocity.Magnitude > 200 or root.AssemblyLinearVelocity.Magnitude > 200 then
                        root.AssemblyAngularVelocity = Vector3.zero
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    --------------------------------------------------------------------------------
    -- UI CONTROLS
    --------------------------------------------------------------------------------
    CombatTab:Toggle("Auto Guard", function(s) Config.AutoBlock = s end)
    CombatTab:Slider("Guard Dist", 5, 30, function(v) Config.BlockRange = v end)
    
    CombatTab:Toggle("Hitbox Expander", function(s) Config.HitboxBG = s end)
    CombatTab:Slider("Hitbox Size", 5, 25, function(v) Config.HitboxSizeBG = v end)

    CombatTab:Label("--- God Features ---")
    CombatTab:Toggle("God Mode (No Stun)", function(s) 
        Config.GodMode = s 
        if s then EnableGodMode() end 
    end)
    CombatTab:Toggle("Ghost Mode (Desync)", function(s) 
        Config.GhostMode = s 
        ToggleGhostMode(s) 
    end)

    CombatTab:Label("--- Misc ---")
    CombatTab:Toggle("No Slow (Fast Charge)", function(s) Config.NoSlow = s end)
    CombatTab:Toggle("Anti-Void/Fling", function(s) 
        Config.AntiVoidBG = s 
        Config.AntiFling = s
    end)

    Config.OnReset:Connect(function()
        Config.AutoBlock = false; Config.HitboxBG = false
        Config.GodMode = false; Config.GhostMode = false
        Config.NoSlow = false; Config.AntiFling = false
    end)

    print("[Vanzyxxx] Ultimate Battlegrounds Loaded!")
end
