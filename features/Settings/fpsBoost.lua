-- FPS Boost Module
return function(UI, Services, Config, Theme)
    local RunService = Services.RunService
    local Lighting = Services.Lighting
    local Workspace = Services.Workspace
    local StarterGui = Services.StarterGui
    local UserInputService = Services.UserInputService
    
    local FPSBoostTab = UI:Tab("Settings")
    
    -- Performance Variables
    local OriginalSettings = {}
    local PerformanceMode = false
    local CurrentFPS = 60
    local FPSCounter = nil
    
    -- Save original settings
    local function SaveOriginalSettings()
        OriginalSettings = {
            -- Lighting
            GlobalShadows = Lighting.GlobalShadows,
            Technology = Lighting.Technology,
            Brightness = Lighting.Brightness,
            FogEnd = Lighting.FogEnd,
            ShadowSoftness = Lighting.ShadowSoftness,
            
            -- Workspace
            StreamingEnabled = Workspace.StreamingEnabled,
            StreamingMinRadius = Workspace.StreamingMinRadius,
            StreamingTargetRadius = Workspace.StreamingTargetRadius,
            
            -- Render
            GraphicsQualityLevel = settings().Rendering.QualityLevel
        }
    end
    
    -- Create FPS Counter
    local function CreateFPSCounter()
        if FPSCounter then FPSCounter:Destroy() end
        
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        FPSCounter = Instance.new("ScreenGui", screenGui.Parent)
        FPSCounter.Name = "VanzyFPSCounter"
        FPSCounter.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        FPSCounter.ResetOnSpawn = false
        
        if syn and syn.protect_gui then
            syn.protect_gui(FPSCounter)
        end
        
        local frame = Instance.new("Frame", FPSCounter)
        frame.Size = UDim2.new(0, 80, 0, 30)
        frame.Position = UDim2.new(0.02, 0, 0.02, 0)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 1
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "FPS: 60"
        label.TextColor3 = Theme.Accent
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        
        -- FPS Tracking
        local lastTime = tick()
        local frames = 0
        
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            local currentTime = tick()
            
            if currentTime - lastTime >= 1 then
                CurrentFPS = frames
                label.Text = "FPS: " .. CurrentFPS
                frames = 0
                lastTime = currentTime
                
                -- Change color based on FPS
                if CurrentFPS >= 60 then
                    label.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif CurrentFPS >= 30 then
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    label.TextColor3 = Color3.fromRGB(255, 50, 50)
                end
            end
        end)
        
        -- Make draggable
        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        return FPSCounter
    end
    
    -- Apply FPS Boost Settings
    local function ApplyFPSBoost()
        -- Save original settings if not already saved
        if next(OriginalSettings) == nil then
            SaveOriginalSettings()
        end
        
        -- Apply optimization settings
        PerformanceMode = true
        
        -- Lighting Optimizations
        Lighting.GlobalShadows = false
        Lighting.Technology = Enum.Technology.Compatibility
        Lighting.FogEnd = 999999
        Lighting.ShadowSoftness = 0
        
        -- Adjust brightness based on time of day
        if Lighting.ClockTime > 18 or Lighting.ClockTime < 6 then
            Lighting.Brightness = 0.5
        else
            Lighting.Brightness = 1.5
        end
        
        -- Workspace Optimizations
        Workspace.StreamingEnabled = false
        Workspace.StreamingMinRadius = 200
        Workspace.StreamingTargetRadius = 500
        
        -- Render Settings
        settings().Rendering.QualityLevel = 1
        
        -- Physics optimizations
        game:GetService("PhysicsService"):RegisterCollisionGroup("Optimized")
        game:GetService("PhysicsService"):CollisionGroupSetCollidable("Optimized", "Optimized", false)
        
        -- Player character optimizations
        local Players = Services.Players
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CollisionGroup = "Optimized"
                        part.CastShadow = false
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
        
        -- Terrain optimization
        if Workspace:FindFirstChildOfClass("Terrain") then
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            terrain.Decoration = false
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "FPS Boost Activated",
            Text = "Performance settings applied",
            Duration = 3
        })
        
        print("[Vanzyxxx] FPS Boost Activated")
    end
    
    -- Restore Original Settings
    local function RestoreOriginalSettings()
        if next(OriginalSettings) == nil then return end
        
        PerformanceMode = false
        
        -- Restore Lighting
        Lighting.GlobalShadows = OriginalSettings.GlobalShadows
        Lighting.Technology = OriginalSettings.Technology
        Lighting.Brightness = OriginalSettings.Brightness
        Lighting.FogEnd = OriginalSettings.FogEnd
        Lighting.ShadowSoftness = OriginalSettings.ShadowSoftness
        
        -- Restore Workspace
        Workspace.StreamingEnabled = OriginalSettings.StreamingEnabled
        Workspace.StreamingMinRadius = OriginalSettings.StreamingMinRadius
        Workspace.StreamingTargetRadius = OriginalSettings.StreamingTargetRadius
        
        -- Restore Render
        settings().Rendering.QualityLevel = OriginalSettings.GraphicsQualityLevel
        
        StarterGui:SetCore("SendNotification", {
            Title = "Settings Restored",
            Text = "Original settings loaded",
            Duration = 3
        })
        
        print("[Vanzyxxx] Original Settings Restored")
    end
    
    -- UI Elements
    FPSBoostTab:Label("Performance Optimizer")
    
    -- Current FPS Display
    FPSBoostTab:Label("Current FPS: " .. CurrentFPS)
    
    -- FPS Counter Toggle
    local counterToggle = FPSBoostTab:Toggle("Show FPS Counter", function(state)
        if state then
            if not FPSCounter then
                CreateFPSCounter()
            end
            FPSCounter.Enabled = true
        elseif FPSCounter then
            FPSCounter.Enabled = false
        end
    end)
    
    -- FPS Boost Presets
    FPSBoostTab:Label("Optimization Presets")
    
    FPSBoostTab:Button("⚡ Maximum Performance", Color3.fromRGB(0, 200, 100), function()
        ApplyFPSBoost()
        
        -- Additional aggressive optimizations
        settings().Rendering.QualityLevel = 1
        Lighting.Outlines = false
        
        -- Reduce particle effects
        for _, effect in ipairs(Workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") then
                effect.Rate = 0
                effect.Enabled = false
            elseif effect:IsA("Smoke") or effect:IsA("Fire") or effect:IsA("Sparkles") then
                effect.Enabled = false
            end
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Max Performance",
            Text = "All optimizations applied",
            Duration = 3
        })
    end)
    
    FPSBoostTab:Button("🔄 Balanced", Color3.fromRGB(255, 170, 0), function()
        ApplyFPSBoost()
        
        -- Less aggressive settings
        settings().Rendering.QualityLevel = 3
        Lighting.Outlines = true
        Lighting.GlobalShadows = false
        
        StarterGui:SetCore("SendNotification", {
            Title = "Balanced Mode",
            Text = "Balance between quality and performance",
            Duration = 3
        })
    end)
    
    FPSBoostTab:Button("🎨 Quality", Color3.fromRGB(100, 150, 255), function()
        RestoreOriginalSettings()
        
        -- Just disable shadows for minor boost
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = OriginalSettings.GraphicsQualityLevel or 8
        
        StarterGui:SetCore("SendNotification", {
            Title = "Quality Mode",
            Text = "Quality optimized, minor performance boost",
            Duration = 3
        })
    end)
    
    -- Custom Settings
    FPSBoostTab:Label("Custom Settings")
    
    local customContainer = FPSBoostTab:Container(180)
    
    -- Shadow Toggle
    local shadowToggle = Instance.new("TextButton", customContainer)
    shadowToggle.Size = UDim2.new(1, -10, 0, 25)
    shadowToggle.BackgroundColor3 = Theme.Button
    shadowToggle.Text = "🌑 Shadows: ON"
    shadowToggle.TextColor3 = Color3.new(1, 1, 1)
    shadowToggle.Font = Enum.Font.Gotham
    shadowToggle.TextSize = 11
    
    local shadowCorner = Instance.new("UICorner", shadowToggle)
    shadowCorner.CornerRadius = UDim.new(0, 4)
    
    local shadowsEnabled = true
    shadowToggle.MouseButton1Click:Connect(function()
        shadowsEnabled = not shadowsEnabled
        Lighting.GlobalShadows = shadowsEnabled
        shadowToggle.Text = shadowsEnabled and "🌑 Shadows: ON" or "🌑 Shadows: OFF"
        shadowToggle.BackgroundColor3 = shadowsEnabled and Theme.Button or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Graphics Quality Slider
    local qualityFrame = Instance.new("Frame", customContainer)
    qualityFrame.Size = UDim2.new(1, -10, 0, 35)
    qualityFrame.BackgroundColor3 = Theme.Button
    
    local qualityCorner = Instance.new("UICorner", qualityFrame)
    qualityCorner.CornerRadius = UDim.new(0, 6)
    
    local qualityLabel = Instance.new("TextLabel", qualityFrame)
    qualityLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
    qualityLabel.Position = UDim2.new(0.05, 0, 0, 0)
    qualityLabel.BackgroundTransparency = 1
    qualityLabel.Text = "Graphics: 8"
    qualityLabel.TextColor3 = Color3.new(1, 1, 1)
    qualityLabel.TextSize = 10
    qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local qualitySlider = Instance.new("TextButton", qualityFrame)
    qualitySlider.Size = UDim2.new(0.9, 0, 0.3, 0)
    qualitySlider.Position = UDim2.new(0.05, 0, 0.6, 0)
    qualitySlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    qualitySlider.Text = ""
    
    local qualityFill = Instance.new("Frame", qualitySlider)
    qualityFill.Size = UDim2.new(1, 0, 1, 0)
    qualityFill.BackgroundColor3 = Theme.Accent
    
    local qualityValue = 8
    qualitySlider.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            local percent = math.clamp(
                (UserInputService:GetMouseLocation().X - qualitySlider.AbsolutePosition.X) / 
                qualitySlider.AbsoluteSize.X,
                0, 1
            )
            qualityFill.Size = UDim2.new(percent, 0, 1, 0)
            qualityValue = math.floor(1 + percent * 9)  -- 1-10 scale
            qualityLabel.Text = "Graphics: " .. qualityValue
            
            settings().Rendering.QualityLevel = qualityValue
            
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                connection:Disconnect()
            end
        end)
    end)
    
    -- View Distance Slider
    local distanceFrame = Instance.new("Frame", customContainer)
    distanceFrame.Size = UDim2.new(1, -10, 0, 35)
    distanceFrame.BackgroundColor3 = Theme.Button
    
    local distanceCorner = Instance.new("UICorner", distanceFrame)
    distanceCorner.CornerRadius = UDim.new(0, 6)
    
    local distanceLabel = Instance.new("TextLabel", distanceFrame)
    distanceLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0.05, 0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "View Distance: 500"
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextSize = 10
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local distanceSlider = Instance.new("TextButton", distanceFrame)
    distanceSlider.Size = UDim2.new(0.9, 0, 0.3, 0)
    distanceSlider.Position = UDim2.new(0.05, 0, 0.6, 0)
    distanceSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    distanceSlider.Text = ""
    
    local distanceFill = Instance.new("Frame", distanceSlider)
    distanceFill.Size = UDim2.new(0.5, 0, 1, 0)
    distanceFill.BackgroundColor3 = Theme.Accent
    
    local distanceValue = 500
    distanceSlider.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            local percent = math.clamp(
                (UserInputService:GetMouseLocation().X - distanceSlider.AbsolutePosition.X) / 
                distanceSlider.AbsoluteSize.X,
                0, 1
            )
            distanceFill.Size = UDim2.new(percent, 0, 1, 0)
            distanceValue = math.floor(50 + percent * 1950)  -- 50-2000 range
            distanceLabel.Text = "View Distance: " .. distanceValue
            
            Workspace.StreamingTargetRadius = distanceValue
            Workspace.StreamingMinRadius = math.floor(distanceValue / 2)
            
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                connection:Disconnect()
            end
        end)
    end)
    
    -- Particle Effects Toggle
    local particleToggle = Instance.new("TextButton", customContainer)
    particleToggle.Size = UDim2.new(1, -10, 0, 25)
    particleToggle.BackgroundColor3 = Theme.Button
    particleToggle.Text = "✨ Particles: ON"
    particleToggle.TextColor3 = Color3.new(1, 1, 1)
    particleToggle.Font = Enum.Font.Gotham
    particleToggle.TextSize = 11
    
    local particleCorner = Instance.new("UICorner", particleToggle)
    particleCorner.CornerRadius = UDim.new(0, 4)
    
    local particlesEnabled = true
    particleToggle.MouseButton1Click:Connect(function()
        particlesEnabled = not particlesEnabled
        
        for _, effect in ipairs(Workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") then
                effect.Enabled = particlesEnabled
                if particlesEnabled then
                    effect.Rate = 20
                else
                    effect.Rate = 0
                end
            elseif effect:IsA("Smoke") or effect:IsA("Fire") then
                effect.Enabled = particlesEnabled
            end
        end
        
        particleToggle.Text = particlesEnabled and "✨ Particles: ON" or "✨ Particles: OFF"
        particleToggle.BackgroundColor3 = particlesEnabled and Theme.Button or Color3.fromRGB(80, 80, 80)
    end)
    
    -- Apply/Restore Buttons
    FPSBoostTab:Label("") -- Spacer
    
    FPSBoostTab:Button("⚙️ Apply Custom Settings", Theme.Confirm, function()
        settings().Rendering.QualityLevel = qualityValue
        Workspace.StreamingTargetRadius = distanceValue
        Workspace.StreamingMinRadius = math.floor(distanceValue / 2)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Custom Settings Applied",
            Text = "Quality: " .. qualityValue .. " | Distance: " .. distanceValue,
            Duration = 3
        })
    end)
    
    FPSBoostTab:Button("🔄 Restore Defaults", Theme.ButtonRed, function()
        RestoreOriginalSettings()
        
        -- Reset UI
        qualityValue = 8
        qualityFill.Size = UDim2.new(0.7, 0, 1, 0)
        qualityLabel.Text = "Graphics: 8"
        
        distanceValue = 500
        distanceFill.Size = UDim2.new(0.25, 0, 1, 0)
        distanceLabel.Text = "View Distance: 500"
        
        shadowsEnabled = true
        shadowToggle.Text = "🌑 Shadows: ON"
        shadowToggle.BackgroundColor3 = Theme.Button
        
        particlesEnabled = true
        particleToggle.Text = "✨ Particles: ON"
        particleToggle.BackgroundColor3 = Theme.Button
        
        counterToggle.SetState(false)
        if FPSCounter then
            FPSCounter.Enabled = false
        end
    end)
    
    -- Auto-optimize on join
    FPSBoostTab:Toggle("Auto-optimize on join", function(state)
        Config.AutoOptimize = state
    end)
    
    -- Performance Monitor
    FPSBoostTab:Label("Performance Monitor")
    
    local monitorContainer = FPSBoostTab:Container(80)
    
    local memLabel = Instance.new("TextLabel", monitorContainer)
    memLabel.Size = UDim2.new(1, -10, 0, 20)
    memLabel.BackgroundTransparency = 1
    memLabel.Text = "Memory: -- MB"
    memLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    memLabel.Font = Enum.Font.Gotham
    memLabel.TextSize = 10
    
    local pingLabel = Instance.new("TextLabel", monitorContainer)
    pingLabel.Size = UDim2.new(1, -10, 0, 20)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: -- ms"
    pingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.TextSize = 10
    
    local perfLabel = Instance.new("TextLabel", monitorContainer)
    perfLabel.Size = UDim2.new(1, -10, 0, 20)
    perfLabel.BackgroundTransparency = 1
    perfLabel.Text = "Performance: --"
    perfLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    perfLabel.Font = Enum.Font.Gotham
    perfLabel.TextSize = 10
    
    -- Performance monitoring thread
    spawn(function()
        while task.wait(2) do
            -- Memory usage (estimasi)
            local stats = stats and stats() or nil
            if stats then
                local mem = math.floor(stats:GetTotalMemoryUsageMb())
                memLabel.Text = "Memory: " .. mem .. " MB"
            end
            
            -- Ping (estimasi)
            local ping = math.random(50, 150) -- Placeholder
            pingLabel.Text = "Ping: " .. ping .. " ms"
            
            -- Performance rating
            local rating = "Good"
            if CurrentFPS < 30 then
                rating = "Poor"
            elseif CurrentFPS < 60 then
                rating = "Average"
            end
            
            perfLabel.Text = "Performance: " .. rating
        end
    end)
    
    -- Auto-apply on script start
    spawn(function()
        task.wait(3)
        if Config.AutoOptimize then
            ApplyFPSBoost()
            StarterGui:SetCore("SendNotification", {
                Title = "Auto-Optimized",
                Text = "FPS boost applied automatically",
                Duration = 3
            })
        end
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        RestoreOriginalSettings()
        if FPSCounter then
            FPSCounter:Destroy()
        end
    end)
    
    print("[Vanzyxxx] FPS Boost Module Loaded")
    return true
end