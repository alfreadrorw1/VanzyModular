-- features/Fun/dummyArmy.lua
return function(UI, Services, Config, Theme)
    local Workspace = Services.Workspace
    local RunService = Services.RunService
    local Players = Services.Players
    local LocalPlayer = Players.LocalPlayer
    local HttpService = Services.HttpService
    
    local FunTab = UI:Tab("Dummy Army")
    local DummyArmy = {}
    local ArmyActive = false
    local ArmyCount = 100
    local FollowDistance = 5
    
    -- Dummy models (bisa custom)
    local DummyModels = {
        "rbxassetid://108158379", -- Classic R6
        "rbxassetid://121572214", -- R15 Standard
        "rbxassetid://7044269335", -- Noob Avatar
        "rbxassetid://2803842157", -- Robot
    }
    
    local function CreateDummy(index)
        local dummy = Instance.new("Model")
        dummy.Name = "DummySoldier_" .. index
        
        -- Load model dari asset
        local success, model = pcall(function()
            local randomModel = DummyModels[math.random(1, #DummyModels)]
            return game:GetService("InsertService"):LoadAsset(tonumber(randomModel:match("%d+")))
        end)
        
        if success and model then
            local character = model:GetChildren()[1]
            if character then
                character:Clone().Parent = dummy
            end
        else
            -- Fallback basic dummy
            local torso = Instance.new("Part")
            torso.Name = "Torso"
            torso.Size = Vector3.new(2, 2, 1)
            torso.BrickColor = BrickColor.new("Bright blue")
            torso.Parent = dummy
            
            local head = Instance.new("Part")
            head.Name = "Head"
            head.Size = Vector3.new(2, 1, 1)
            head.BrickColor = BrickColor.new("Bright yellow")
            head.Position = Vector3.new(0, 1.5, 0)
            head.Parent = dummy
            
            local face = Instance.new("Decal")
            face.Name = "face"
            face.Texture = "rbxasset://textures/face.png"
            face.Parent = head
        end
        
        -- Tambah Humanoid untuk movement
        local humanoid = Instance.new("Humanoid")
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.Parent = dummy
        
        -- Buat dummy unik
        local color = Color3.fromHSV(index/ArmyCount, 1, 1)
        for _, part in ipairs(dummy:GetDescendants()) do
            if part:IsA("BasePart") then
                part.BrickColor = BrickColor.new(color)
                part.Material = Enum.Material.Neon
                part.CanCollide = false
                
                -- Glowing effect
                local pointLight = Instance.new("PointLight")
                pointLight.Color = color
                pointLight.Range = 10
                pointLight.Brightness = 0.5
                pointLight.Parent = part
            end
        end
        
        -- Name tag
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = dummy
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "DUMMY " .. index
        nameLabel.TextColor3 = color
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 12
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Parent = billboard
        
        local roleLabel = Instance.new("TextLabel")
        roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
        roleLabel.Position = UDim2.new(0, 0, 0.5, 0)
        roleLabel.BackgroundTransparency = 1
        roleLabel.Text = "FOLLOWING [" .. LocalPlayer.Name .. "]"
        roleLabel.TextColor3 = Color3.new(1, 1, 1)
        roleLabel.Font = Enum.Font.Gotham
        roleLabel.TextSize = 8
        roleLabel.TextStrokeTransparency = 0
        roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        roleLabel.Parent = billboard
        
        dummy.Parent = Workspace
        return dummy
    end
    
    local function PositionDummyArmy()
        if not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local center = root.Position
        local radius = 15
        local angleStep = (2 * math.pi) / #DummyArmy
        
        for i, dummy in ipairs(DummyArmy) do
            if dummy and dummy.Parent then
                local humanoid = dummy:FindFirstChild("Humanoid")
                local dummyRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso")
                
                if humanoid and dummyRoot then
                    -- Hitung posisi dalam formasi lingkaran
                    local angle = i * angleStep
                    local x = math.cos(angle) * radius
                    local z = math.sin(angle) * radius
                    local targetPos = center + Vector3.new(x, 0, z)
                    
                    -- Atur agar dummy menghadap ke player
                    local lookPos = center
                    humanoid:MoveTo(targetPos, lookPos)
                    
                    -- Atur CFrame untuk menghadap ke center
                    dummyRoot.CFrame = CFrame.new(dummyRoot.Position, lookPos)
                end
            end
        end
    end
    
    local function MarchAnimation()
        for _, dummy in ipairs(DummyArmy) do
            if dummy and dummy.Parent then
                -- Animasi marching
                for _, part in ipairs(dummy:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- Pulsing glow effect
                        local light = part:FindFirstChild("PointLight")
                        if light then
                            light.Brightness = 0.3 + math.sin(tick() * 5) * 0.2
                        end
                    end
                end
            end
        end
    end
    
    FunTab:Button("🪖 SPAWN DUMMY ARMY (100)", Color3.fromRGB(255, 100, 0), function()
        -- Hapus army lama
        for _, dummy in ipairs(DummyArmy) do
            pcall(function() dummy:Destroy() end)
        end
        DummyArmy = {}
        
        -- Spawn dummy army
        Services.StarterGui:SetCore("SendNotification", {
            Title = "DUMMY ARMY",
            Text = "Spawning 100 soldiers...",
            Duration = 3
        })
        
        for i = 1, ArmyCount do
            local dummy = CreateDummy(i)
            table.insert(DummyArmy, dummy)
            task.wait(0.05) -- Delay untuk prevent lag
        end
        
        ArmyActive = true
        
        -- Position army
        local positionLoop
        positionLoop = RunService.Heartbeat:Connect(function()
            if ArmyActive then
                PositionDummyArmy()
                MarchAnimation()
            else
                positionLoop:Disconnect()
            end
        end)
        
        -- Cleanup
        Config.OnReset:Connect(function()
            ArmyActive = false
            for _, dummy in ipairs(DummyArmy) do
                pcall(function() dummy:Destroy() end)
            end
            DummyArmy = {}
        end)
    end)
    
    FunTab:Button("💥 MAKE ARMY DANCE", Theme.Accent, function()
        for _, dummy in ipairs(DummyArmy) do
            local humanoid = dummy:FindFirstChild("Humanoid")
            if humanoid then
                -- Load dance animation
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://5915713302" -- Dance animation
                
                local track = humanoid:LoadAnimation(animation)
                track:Play()
                track.Looped = true
            end
        end
    end)
    
    FunTab:Button("☠️ DISBAND ARMY", Color3.fromRGB(255, 50, 50), function()
        ArmyActive = false
        for _, dummy in ipairs(DummyArmy) do
            pcall(function() dummy:Destroy() end)
        end
        DummyArmy = {}
    end)
    
    -- Settings
    FunTab:Label("─ ARMY SETTINGS ─")
    
    FunTab:Slider("Army Size", 10, 500, function(value)
        ArmyCount = value
    end)
    
    FunTab:Slider("Formation Radius", 5, 50, function(value)
        FollowDistance = value
    end)
    
    local rainbowMode = false
    FunTab:Toggle("🌈 Rainbow Army", function(state)
        rainbowMode = state
        if state then
            spawn(function()
                while rainbowMode and #DummyArmy > 0 do
                    for i, dummy in ipairs(DummyArmy) do
                        local hue = (tick() + i/10) % 1
                        local color = Color3.fromHSV(hue, 1, 1)
                        
                        for _, part in ipairs(dummy:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Color = color
                                local light = part:FindFirstChild("PointLight")
                                if light then
                                    light.Color = color
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)
end