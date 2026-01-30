-- visualCosmetics.lua
-- Menggabungkan fitur Sayap, Aura, Glowstick, dan Boombox
return function(UI, Services, Config, Theme)
    local Tab = UI:Tab("Cosmetics")
    local RunService = Services.RunService
    local LocalPlayer = Services.Players.LocalPlayer
    
    Tab:Label("Vanzyxxx Visual Style")

    -- VARIABLES
    local Visuals = {
        Wings = nil,
        Aura = nil,
        Glowstick = nil,
        Boombox = nil
    }
    
    -- UTILITY: Attach Part to Character
    local function CreateAccessory(name, size, color, offset)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("UpperTorso") and not char:FindFirstChild("Torso") then return nil end
        
        local root = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CanCollide = false
        p.Massless = true
        p.Material = Enum.Material.Neon
        p.Color = color
        p.Parent = char
        
        local w = Instance.new("Weld")
        w.Part0 = root
        w.Part1 = p
        w.C0 = offset
        w.Parent = p
        
        return p
    end

    -------------------------------------------------------------------------
    -- 1. SAYAP TERBANG (Procedural Wings)
    -------------------------------------------------------------------------
    Tab:Toggle("Neon Wings (Sayap)", function(state)
        if state then
            if Visuals.Wings then Visuals.Wings:Destroy() end
            local char = LocalPlayer.Character
            if not char then return end
            
            -- Folder Wings
            local folder = Instance.new("Folder", char)
            folder.Name = "VanzyWings"
            Visuals.Wings = folder
            
            -- Buat sayap kiri dan kanan menggunakan Loop sederhana
            local function MakeWing(side) -- 1 = Right, -1 = Left
                for i = 1, 5 do
                    local p = Instance.new("Part", folder)
                    p.Size = Vector3.new(0.5, 2, 0.2)
                    p.Material = Enum.Material.Neon
                    p.Color = Theme.Accent
                    p.CanCollide = false
                    p.Massless = true
                    
                    local w = Instance.new("Weld", p)
                    w.Part0 = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                    w.Part1 = p
                    -- Matematika posisi sayap
                    w.C0 = CFrame.new(side * 1.5, 0.5 + (i*0.2), 0.5) * CFrame.Angles(0, 0, side * math.rad(30 + (i*5)))
                end
            end
            
            MakeWing(1)
            MakeWing(-1)
            
        else
            if Visuals.Wings then Visuals.Wings:Destroy() Visuals.Wings = nil end
        end
    end)

    -------------------------------------------------------------------------
    -- 2. AURA SYSTEM
    -------------------------------------------------------------------------
    Tab:Toggle("Ultra Aura V3", function(state)
        if state then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Lingkaran Aura
            local auraMain = Instance.new("Part", char)
            auraMain.Name = "VanzyAura"
            auraMain.Size = Vector3.new(0.1, 0.1, 0.1)
            auraMain.Anchored = true
            auraMain.CanCollide = false
            auraMain.Transparency = 1
            Visuals.Aura = auraMain
            
            local particle = Instance.new("ParticleEmitter", auraMain)
            particle.Texture = "rbxassetid://243098098" -- Tekstur Ring
            particle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)})
            particle.Color = ColorSequence.new(Theme.Accent)
            particle.Lifetime = NumberRange.new(0.5)
            particle.Rate = 50
            particle.Speed = NumberRange.new(0)
            
            -- Loop Posisi
            spawn(function()
                while Visuals.Aura and Visuals.Aura.Parent do
                    if root then
                        Visuals.Aura.CFrame = root.CFrame * CFrame.new(0, -2.5, 0)
                    end
                    task.wait()
                end
            end)
        else
            if Visuals.Aura then Visuals.Aura:Destroy() Visuals.Aura = nil end
        end
    end)

    -------------------------------------------------------------------------
    -- 3. GLOWSTICK RAINBOW
    -------------------------------------------------------------------------
    Tab:Toggle("Glowstick Rainbow", function(state)
        if state then
            local p = CreateAccessory("Glowstick", Vector3.new(0.2, 2, 0.2), Color3.new(1,1,1), CFrame.new(1, -0.5, -0.5) * CFrame.Angles(math.rad(90),0,0))
            if p then
                Visuals.Glowstick = p
                local light = Instance.new("PointLight", p)
                light.Range = 10
                light.Brightness = 2
                
                -- Rainbow Loop
                spawn(function()
                    while Visuals.Glowstick and Visuals.Glowstick.Parent do
                        local hue = tick() % 5 / 5
                        local color = Color3.fromHSV(hue, 1, 1)
                        p.Color = color
                        light.Color = color
                        task.wait(0.05)
                    end
                end)
            end
        else
            if Visuals.Glowstick then Visuals.Glowstick:Destroy() Visuals.Glowstick = nil end
        end
    end)
    
    -------------------------------------------------------------------------
    -- 4. BOOMBOX KECE (Visual Only)
    -------------------------------------------------------------------------
    Tab:Toggle("Boombox Back Visual", function(state)
        if state then
            -- Membuat model kotak sederhana mirip boombox di punggung
            local box = CreateAccessory("Boombox", Vector3.new(2, 1, 0.5), Color3.fromRGB(30,30,30), CFrame.new(0, 0, 0.8))
            if box then
                Visuals.Boombox = box
                -- Hiasan Speaker
                local speaker = Instance.new("Decal", box)
                speaker.Texture = "http://www.roblox.com/asset/?id=14686414772" -- Texture Speaker
                speaker.Face = Enum.NormalId.Back
            end
        else
             if Visuals.Boombox then Visuals.Boombox:Destroy() Visuals.Boombox = nil end
        end
    end)
end
