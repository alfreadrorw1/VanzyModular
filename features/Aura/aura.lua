-- Vanzyxxx Aura System
-- Custom Character Auras and Effects

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local HttpService = Services.HttpService
    local RunService = Services.RunService
    
    -- Create Tab
    local AuraTab = UI:Tab("Aura")
    
    AuraTab:Label("Character Auras")
    
    -- Aura Variables
    local CurrentAura = nil
    local AuraContainer = nil
    local AuraRotationSpeed = 1
    local AuraScale = 1
    local AuraTransparency = 0.5
    
    -- GitHub Aura List URL
    local GithubAura = "https://raw.githubusercontent.com/alfreadrorw1/vanzyx/main/aura.json"
    local AuraList = {}
    
    -- Preset Auras with IDs
    local PresetAuras = {
        {
            Name = "Reset (Remove Aura)",
            ID = "reset",
            Type = "reset"
        },
        {
            Name = "Fire Aura",
            ID = "9206613942",
            Type = "id"
        },
        {
            Name = "Ice Aura",
            ID = "9206615323",
            Type = "id"
        },
        {
            Name = "Lightning Aura",
            ID = "9206616377",
            Type = "id"
        },
        {
            Name = "Shadow Aura",
            ID = "9206617412",
            Type = "id"
        },
        {
            Name = "Holy Aura",
            ID = "9206618545",
            Type = "id"
        },
        {
            Name = "Rainbow Aura",
            ID = "9206619521",
            Type = "id"
        },
        {
            Name = "Dragon Aura",
            ID = "9206620543",
            Type = "id"
        }
    }
    
    -- Function to apply aura by ID
    local function ApplyAura(auraId, auraName)
        pcall(function()
            -- Remove existing aura
            if CurrentAura then
                CurrentAura:Destroy()
                CurrentAura = nil
            end
            
            -- Also remove any existing aura from character
            if LocalPlayer.Character then
                local existingAura = LocalPlayer.Character:FindFirstChild("VanzyAura")
                if existingAura then
                    existingAura:Destroy()
                end
            end
            
            if auraId == "reset" then
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Aura",
                    Text = "Aura removed",
                    Duration = 3
                })
                return
            end
            
            -- Load aura object
            local success, auraObjects = pcall(function()
                return game:GetObjects("rbxassetid://" .. auraId)
            end)
            
            if success and auraObjects[1] then
                local aura = auraObjects[1]:Clone()
                aura.Name = "VanzyAura"
                
                -- Apply settings to all parts
                for _, descendant in ipairs(aura:GetDescendants()) do
                    if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
                        descendant.Transparency = AuraTransparency
                        descendant.CanCollide = false
                        descendant.Massless = true
                        descendant.CastShadow = false
                        descendant.Anchored = false
                    elseif descendant:IsA("Decal") then
                        descendant.Transparency = AuraTransparency
                    end
                end
                
                -- Wait for character
                if not LocalPlayer.Character then
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Aura",
                        Text = "Waiting for character...",
                        Duration = 2
                    })
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(1)
                end
                
                aura.Parent = LocalPlayer.Character
                
                -- Attach to character
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local primary = aura:IsA("Model") and aura.PrimaryPart or aura:FindFirstChildWhichIsA("BasePart")
                
                if root and primary then
                    primary.CFrame = root.CFrame
                    
                    -- Create weld to attach aura
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = root
                    weld.Part1 = primary
                    weld.Parent = primary
                    
                    CurrentAura = aura
                    
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Aura",
                        Text = "Applied: " .. auraName,
                        Duration = 3
                    })
                    
                    print("[Vanzyxxx] Applied aura: " .. auraName .. " (ID: " .. auraId .. ")")
                end
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Failed to load aura",
                    Duration = 3
                })
            end
        end)
    end
    
    -- Function to rotate aura
    local auraRotationConnection = nil
    local function StartAuraRotation()
        if auraRotationConnection then
            auraRotationConnection:Disconnect()
        end
        
        auraRotationConnection = RunService.Heartbeat:Connect(function()
            if CurrentAura and Config.AuraRotate then
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, part in ipairs(CurrentAura:GetDescendants()) do
                        if part:IsA("BasePart") and part:FindFirstChildOfClass("WeldConstraint") then
                            part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(AuraRotationSpeed), 0)
                        end
                    end
                end
            end
        end)
    end
    
    -- Function to load auras from GitHub
    local function LoadAuraList()
        pcall(function()
            local jsonData = game:HttpGet(GithubAura)
            if jsonData then
                AuraList = HttpService:JSONDecode(jsonData)
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Aura List",
                    Text = "Loaded " .. #AuraList .. " auras from GitHub",
                    Duration = 3
                })
                
                UpdateAuraContainer()
            end
        end)
    end
    
    -- Function to update aura container
    local function UpdateAuraContainer()
        if not AuraContainer then return end
        
        -- Clear container
        for _, child in ipairs(AuraContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add preset auras
        for _, aura in ipairs(PresetAuras) do
            local auraBtn = Instance.new("TextButton", AuraContainer)
            auraBtn.Size = UDim2.new(1, 0, 0, 25)
            auraBtn.BackgroundColor3 = Theme.ButtonDark
            auraBtn.Text = aura.Name
            auraBtn.TextColor3 = Theme.Text
            auraBtn.Font = Enum.Font.Gotham
            auraBtn.TextSize = 11
            auraBtn.AutoButtonColor = true
            
            local btnCorner = Instance.new("UICorner", auraBtn)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            auraBtn.MouseButton1Click:Connect(function()
                ApplyAura(aura.ID, aura.Name)
            end)
        end
        
        -- Add separator
        local separator = Instance.new("TextLabel", AuraContainer)
        separator.Size = UDim2.new(1, 0, 0, 20)
        separator.BackgroundTransparency = 1
        separator.Text = "─ GitHub Auras ─"
        separator.TextColor3 = Theme.Accent
        separator.TextSize = 10
        separator.Font = Enum.Font.GothamBold
        
        -- Add GitHub auras
        for _, aura in ipairs(AuraList) do
            local auraBtn = Instance.new("TextButton", AuraContainer)
            auraBtn.Size = UDim2.new(1, 0, 0, 25)
            auraBtn.BackgroundColor3 = Theme.Button
            auraBtn.Text = aura.Name
            auraBtn.TextColor3 = Theme.Text
            auraBtn.Font = Enum.Font.Gotham
            auraBtn.TextSize = 11
            auraBtn.AutoButtonColor = true
            
            local btnCorner = Instance.new("UICorner", auraBtn)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            auraBtn.MouseButton1Click:Connect(function()
                ApplyAura(aura.ID, aura.Name)
            end)
        end
    end
    
    -- Create aura container
    AuraContainer = AuraTab:Container(200)
    
    -- Aura controls
    AuraTab:Button("Load Aura List from GitHub", Theme.Button, function()
        LoadAuraList()
    end)
    
    AuraTab:Button("Remove Current Aura", Theme.ButtonRed, function()
        ApplyAura("reset", "Reset")
    end)
    
    -- Custom aura ID input
    AuraTab:Label("Custom Aura ID")
    
    AuraTab:Input("Enter Asset ID...", function(text)
        if text and text ~= "" and tonumber(text) then
            ApplyAura(text, "Custom Aura")
        end
    end)
    
    -- Aura settings
    AuraTab:Label("Aura Settings")
    
    local auraRotateToggle = AuraTab:Toggle("Rotate Aura", function(state)
        Config.AuraRotate = state
        if state then
            StartAuraRotation()
        elseif auraRotationConnection then
            auraRotationConnection:Disconnect()
            auraRotationConnection = nil
        end
    end)
    
    AuraTab:Slider("Rotation Speed", 1, 20, function(value)
        AuraRotationSpeed = value
    end)
    
    AuraTab:Slider("Aura Scale", 0.5, 3, function(value)
        AuraScale = value
        if CurrentAura then
            for _, part in ipairs(CurrentAura:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Size = part.Size * value
                end
            end
        end
    end)
    
    AuraTab:Slider("Transparency", 0, 1, function(value)
        AuraTransparency = value
        if CurrentAura then
            for _, descendant in ipairs(CurrentAura:GetDescendants()) do
                if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
                    descendant.Transparency = value
                elseif descendant:IsA("Decal") then
                    descendant.Transparency = value
                end
            end
        end
    end)
    
    -- Color changing aura
    local auraRainbowToggle = AuraTab:Toggle("Rainbow Aura", function(state)
        Config.AuraRainbow = state
        
        if state then
            local rainbowConnection = nil
            rainbowConnection = RunService.Heartbeat:Connect(function()
                if Config.AuraRainbow and CurrentAura then
                    local hue = tick() % 5 / 5
                    local color = Color3.fromHSV(hue, 1, 1)
                    
                    for _, part in ipairs(CurrentAura:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Color = color
                        end
                    end
                elseif not Config.AuraRainbow and rainbowConnection then
                    rainbowConnection:Disconnect()
                end
            end)
            
            Config.AuraRainbowConnection = rainbowConnection
        elseif Config.AuraRainbowConnection then
            Config.AuraRainbowConnection:Disconnect()
            Config.AuraRainbowConnection = nil
        end
    end)
    
    -- Particle effects
    AuraTab:Label("Particle Effects")
    
    local particleToggle = AuraTab:Toggle("Enable Particles", function(state)
        Config.AuraParticles = state
        
        if state and CurrentAura then
            for _, part in ipairs(CurrentAura:GetDescendants()) do
                if part:IsA("BasePart") and not part:FindFirstChildOfClass("ParticleEmitter") then
                    local emitter = Instance.new("ParticleEmitter")
                    emitter.Parent = part
                    emitter.Color = ColorSequence.new(Theme.Accent)
                    emitter.Size = NumberSequence.new(0.2)
                    emitter.Transparency = NumberSequence.new(0.5)
                    emitter.Lifetime = NumberRange.new(1)
                    emitter.Rate = 10
                    emitter.Speed = NumberRange.new(2)
                    emitter.VelocitySpread = 180
                    emitter.Name = "AuraParticle"
                end
            end
        elseif not state and CurrentAura then
            for _, part in ipairs(CurrentAura:GetDescendants()) do
                local emitter = part:FindFirstChild("AuraParticle")
                if emitter then
                    emitter:Destroy()
                end
            end
        end
    end)
    
    -- Glow effect
    AuraTab:Toggle("Glow Effect", function(state)
        Config.AuraGlow = state
        
        if state and CurrentAura then
            for _, part in ipairs(CurrentAura:GetDescendants()) do
                if part:IsA("BasePart") then
                    local surfaceGui = Instance.new("SurfaceGui")
                    surfaceGui.Parent = part
                    surfaceGui.AlwaysOnTop = true
                    surfaceGui.Brightness = 1
                    
                    local frame = Instance.new("Frame")
                    frame.Parent = surfaceGui
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundColor3 = Theme.Accent
                    frame.BackgroundTransparency = 0.7
                end
            end
        elseif not state and CurrentAura then
            for _, part in ipairs(CurrentAura:GetDescendants()) do
                local surfaceGui = part:FindFirstChildOfClass("SurfaceGui")
                if surfaceGui then
                    surfaceGui:Destroy()
                end
            end
        end
    end)
    
    -- Auto reapply aura on respawn
    local lastAuraId = nil
    local lastAuraName = nil
    AuraTab:Toggle("Auto Reapply on Respawn", function(state)
        Config.AutoReapplyAura = state
        
        if state then
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(2)
                if lastAuraId and lastAuraName then
                    ApplyAura(lastAuraId, lastAuraName)
                end
            end)
        end
    end)
    
    -- Store last applied aura
    local originalApplyAura = ApplyAura
    ApplyAura = function(auraId, auraName)
        lastAuraId = auraId
        lastAuraName = auraName
        originalApplyAura(auraId, auraName)
    end
    
    -- Initialize aura container
    spawn(function()
        task.wait(1)
        UpdateAuraContainer()
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        -- Remove aura
        ApplyAura("reset", "Reset")
        
        -- Reset settings
        Config.AuraRotate = false
        Config.AuraRainbow = false
        Config.AuraParticles = false
        Config.AuraGlow = false
        Config.AutoReapplyAura = false
        
        -- Disconnect connections
        if auraRotationConnection then
            auraRotationConnection:Disconnect()
            auraRotationConnection = nil
        end
        
        if Config.AuraRainbowConnection then
            Config.AuraRainbowConnection:Disconnect()
            Config.AuraRainbowConnection = nil
        end
    end)
    
    print("[Vanzyxxx] Aura system loaded!")
end