-- Vanzyxxx Sword Combat System
-- Kill Aura & Hitbox Expander
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local Workspace = Services.Workspace
    local RunService = Services.RunService
    local LocalPlayer = Players.LocalPlayer
    local VirtualUser = game:GetService("VirtualUser")

    local CombatTab = UI:Tab("Combat")
    CombatTab:Label("Sword PVP & Rage")

    -- Config Defaults
    Config.KillAura = false
    Config.AuraRange = 15
    Config.AuraAnim = true -- Ayunkan pedang (Animation)
    Config.TeamCheck = false
    
    Config.Hitbox = false
    Config.HitboxSize = 5
    Config.HitboxTransparency = 0.7

    -- Variables
    local AuraCircle = nil
    
    --------------------------------------------------------------------------------
    -- 1. VISUALIZER (Lingkaran Jarak Aura)
    --------------------------------------------------------------------------------
    local function UpdateVisualizer()
        if not Config.KillAura then 
            if AuraCircle then AuraCircle:Destroy() AuraCircle = nil end
            return 
        end

        -- Buat lingkaran jika belum ada
        if not AuraCircle then
            AuraCircle = Instance.new("Part")
            AuraCircle.Name = "AuraVisualizer"
            AuraCircle.Shape = Enum.PartType.Cylinder
            AuraCircle.Material = Enum.Material.Neon
            AuraCircle.Color = Config.RainbowTheme and Theme.Accent or Config.CustomColor
            AuraCircle.Transparency = 0.8
            AuraCircle.Anchored = true
            AuraCircle.CanCollide = false
            AuraCircle.CastShadow = false
            AuraCircle.Parent = Workspace
        end

        -- Update posisi lingkaran di kaki karakter
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Cylinder di Roblox itu miring, jadi perlu diputar
            AuraCircle.Size = Vector3.new(0.1, Config.AuraRange * 2, Config.AuraRange * 2)
            AuraCircle.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
            AuraCircle.Color = Config.RainbowTheme and Theme.Accent or Config.CustomColor
        else
            AuraCircle.CFrame = CFrame.new(0, -1000, 0) -- Sembunyikan kalau mati
        end
    end

    --------------------------------------------------------------------------------
    -- 2. KILL AURA (Auto Attack)
    --------------------------------------------------------------------------------
    local function GetTarget()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end

        local closestDist = Config.AuraRange
        local target = nil

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                -- Team Check
                if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end

                local pChar = player.Character
                local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar and pChar:FindFirstChild("Humanoid")

                if pRoot and pHum and pHum.Health > 0 then
                    local dist = (root.Position - pRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        target = pRoot -- Return bagian tubuh target
                    end
                end
            end
        end
        return target
    end

    local function Attack(targetPart)
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        
        -- Hanya serang jika pegang pedang/alat
        if tool and targetPart then
            -- 1. Face Target (Menghadap musuh)
            char.HumanoidRootPart.CFrame = CFrame.lookAt(
                char.HumanoidRootPart.Position, 
                Vector3.new(targetPart.Position.X, char.HumanoidRootPart.Position.Y, targetPart.Position.Z)
            )

            -- 2. Activate Tool (Pukul)
            tool:Activate()
            
            -- Alternatif buat executor mobile yang bandel
            if Config.AuraAnim then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            end
        end
    end

    spawn(function()
        while true do
            if Config.KillAura then
                local target = GetTarget()
                if target then
                    Attack(target)
                end
            end
            UpdateVisualizer() -- Update visual lingkaran
            task.wait(0.1) -- Kecepatan pukulan (0.1 detik)
        end
    end)

    --------------------------------------------------------------------------------
    -- 3. HITBOX EXPANDER (Memperbesar Musuh)
    --------------------------------------------------------------------------------
    -- Loop ini jalan cepat untuk memastikan hitbox musuh tetap besar
    RunService.RenderStepped:Connect(function()
        if not Config.Hitbox then return end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end

                local pChar = player.Character
                local root = pChar and pChar:FindFirstChild("HumanoidRootPart")
                
                if root then
                    -- Ubah ukuran root part musuh
                    root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    root.Transparency = Config.HitboxTransparency
                    root.CanCollide = false -- Biar gak nabrak kotak raksasa
                    
                    -- Warna hitbox biar kelihatan (Opsional, merah)
                    root.Color = Color3.fromRGB(255, 0, 0)
                    root.Material = Enum.Material.ForceField
                end
            end
        end
    end)
    
    -- Reset Hitbox saat dimatikan
    local function ResetHitbox()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = Vector3.new(2, 2, 1) -- Ukuran normal Roblox
                    root.Transparency = 1
                    root.Material = Enum.Material.Plastic
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- UI CONTROLS
    --------------------------------------------------------------------------------
    
    -- Kill Aura Section
    CombatTab:Label("Kill Aura (Auto Hit)")
    
    CombatTab:Toggle("Enable Kill Aura", function(state)
        Config.KillAura = state
        if not state and AuraCircle then 
            AuraCircle:Destroy() 
            AuraCircle = nil 
        end
    end)

    CombatTab:Slider("Aura Range", 5, 50, function(val)
        Config.AuraRange = val
    end)

    CombatTab:Toggle("Team Check", function(state)
        Config.TeamCheck = state
    end)
    
    -- Hitbox Section
    CombatTab:Label("Hitbox Expander (Reach)")

    CombatTab:Toggle("Enable Hitbox Expander", function(state)
        Config.Hitbox = state
        if not state then ResetHitbox() end
    end)

    CombatTab:Slider("Hitbox Size", 2, 20, function(val)
        Config.HitboxSize = val
    end)
    
    CombatTab:Slider("Transparency", 0, 10, function(val)
        Config.HitboxTransparency = val / 10
    end)

    -- Cleanup
    Config.OnReset:Connect(function()
        Config.KillAura = false
        Config.Hitbox = false
        if AuraCircle then AuraCircle:Destroy() end
        ResetHitbox()
        print("[Vanzyxxx] Combat Unloaded")
    end)

    print("[Vanzyxxx] Sword Combat Loaded!")
end
