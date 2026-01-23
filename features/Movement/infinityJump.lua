-- Vanzyxxx Infinity Jump Feature
-- Mobile Friendly Infinite Jump

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local UserInputService = Services.UserInputService
    
    -- Create Tab
    local MovementTab = UI:Tab("Movement")
    
    MovementTab:Label("Jump Modifiers")
    
    -- Infinity Jump Toggle
    local infJumpToggle = nil
    local jumpConnection = nil
    
    -- Function to setup infinity jump
    local function SetupInfinityJump()
        if jumpConnection then
            jumpConnection:Disconnect()
        end
        
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if Config.InfJump and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
    
    -- Toggle UI
    infJumpToggle = MovementTab:Toggle("Infinite Jump", function(state)
        Config.InfJump = state
        
        if state then
            SetupInfinityJump()
            
            -- Additional check for mobile touch jump
            if UserInputService.TouchEnabled then
                local touchJumpConnection = nil
                touchJumpConnection = UserInputService.TouchTap:Connect(function(position, gameProcessed)
                    if not gameProcessed and Config.InfJump and LocalPlayer.Character then
                        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)
                
                -- Store connection for cleanup
                Config.InfJumpTouchConnection = touchJumpConnection
            end
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Infinity Jump",
                Text = "Enabled! Press space to fly",
                Duration = 3
            })
        else
            if jumpConnection then
                jumpConnection:Disconnect()
                jumpConnection = nil
            end
            
            if Config.InfJumpTouchConnection then
                Config.InfJumpTouchConnection:Disconnect()
                Config.InfJumpTouchConnection = nil
            end
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Infinity Jump",
                Text = "Disabled",
                Duration = 2
            })
        end
    end)
    
    -- Jump Height Slider
    MovementTab:Slider("Jump Height", 10, 100, function(value)
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpHeight = value
            end
        end
    end)
    
    -- No Fall Damage Toggle
    MovementTab:Toggle("No Fall Damage", function(state)
        Config.NoFallDamage = state
        
        if state then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    -- Store original function
                    Config.OriginalFallDamage = humanoid.FallDamage
                    humanoid.FallDamage = 0
                end
            end
            
            -- Monitor for respawn
            LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(1)
                if Config.NoFallDamage then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.FallDamage = 0
                    end
                end
            end)
        else
            if Config.OriginalFallDamage then
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.FallDamage = Config.OriginalFallDamage
                    end
                end
            end
        end
    end)
    
    -- Bypass Jump Cooldown
    MovementTab:Toggle("No Jump Cooldown", function(state)
        Config.NoJumpCooldown = state
        
        if state then
            -- Remove jump cooldown by constantly resetting jump state
            local cooldownConnection = nil
            cooldownConnection = Services.RunService.Heartbeat:Connect(function()
                if Config.NoJumpCooldown and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        -- Force reset jump power
                        humanoid.Jump = true
                        task.wait()
                        humanoid.Jump = false
                    end
                end
            end)
            
            Config.JumpCooldownConnection = cooldownConnection
        else
            if Config.JumpCooldownConnection then
                Config.JumpCooldownConnection:Disconnect()
                Config.JumpCooldownConnection = nil
            end
        end
    end)
    
    -- Jump Boost Effect
    local jumpBoostParticle = nil
    MovementTab:Toggle("Jump Boost Effect", function(state)
        Config.JumpBoostEffect = state
        
        if state then
            local function createParticleEffect(char)
                if jumpBoostParticle then
                    jumpBoostParticle:Destroy()
                end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    jumpBoostParticle = Instance.new("ParticleEmitter")
                    jumpBoostParticle.Parent = root
                    jumpBoostParticle.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
                    jumpBoostParticle.Size = NumberSequence.new(0.5)
                    jumpBoostParticle.Transparency = NumberSequence.new(0.5)
                    jumpBoostParticle.Lifetime = NumberRange.new(0.5)
                    jumpBoostParticle.Rate = 20
                    jumpBoostParticle.Speed = NumberRange.new(2)
                    jumpBoostParticle.VelocitySpread = 180
                    jumpBoostParticle.Name = "JumpBoostEffect"
                end
            end
            
            if LocalPlayer.Character then
                createParticleEffect(LocalPlayer.Character)
            end
            
            LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(1)
                if Config.JumpBoostEffect then
                    createParticleEffect(char)
                end
            end)
        else
            if jumpBoostParticle then
                jumpBoostParticle:Destroy()
                jumpBoostParticle = nil
            end
        end
    end)
    
    -- Moon Jump (Super High Jump)
    local moonJumpActive = false
    MovementTab:Toggle("Moon Jump (Super High)", function(state)
        Config.MoonJump = state
        
        if state then
            local originalJumpHeight = 50
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    originalJumpHeight = humanoid.JumpHeight
                    humanoid.JumpHeight = 200
                end
            end
            
            moonJumpActive = true
            
            -- Monitor for character changes
            LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(1)
                if Config.MoonJump then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.JumpHeight = 200
                    end
                end
            end)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Moon Jump",
                Text = "Ultra high jumps activated!",
                Duration = 3
            })
        else
            moonJumpActive = false
            
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.JumpHeight = 50
                end
            end
        end
    end)
    
    -- Auto Bunny Hop
    local bunnyHopConnection = nil
    MovementTab:Toggle("Auto Bunny Hop", function(state)
        Config.AutoBunnyHop = state
        
        if state then
            bunnyHopConnection = Services.RunService.Heartbeat:Connect(function()
                if Config.AutoBunnyHop and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.2)
                    end
                end
            end)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Bunny Hop",
                Text = "Auto jumping activated!",
                Duration = 3
            })
        else
            if bunnyHopConnection then
                bunnyHopConnection:Disconnect()
                bunnyHopConnection = nil
            end
        end
    end)
    
    -- Jump Sound Effect
    MovementTab:Toggle("Jump Sound", function(state)
        Config.JumpSound = state
        
        if state then
            local function playJumpSound()
                if LocalPlayer.Character then
                    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local sound = Instance.new("Sound")
                        sound.Parent = root
                        sound.SoundId = "rbxassetid://9112471684" -- Jump sound
                        sound.Volume = 0.5
                        sound:Play()
                        game.Debris:AddItem(sound, 2)
                    end
                end
            end
            
            Config.JumpSoundConnection = UserInputService.JumpRequest:Connect(function()
                if Config.JumpSound then
                    playJumpSound()
                end
            end)
        else
            if Config.JumpSoundConnection then
                Config.JumpSoundConnection:Disconnect()
                Config.JumpSoundConnection = nil
            end
        end
    end)
    
    -- Initialize infinity jump on startup
    spawn(function()
        task.wait(1)
        if Config.InfJump then
            SetupInfinityJump()
            if infJumpToggle then
                infJumpToggle.SetState(true)
            end
        end
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        Config.InfJump = false
        Config.NoFallDamage = false
        Config.NoJumpCooldown = false
        Config.JumpBoostEffect = false
        Config.MoonJump = false
        Config.AutoBunnyHop = false
        Config.JumpSound = false
        
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
        
        if Config.InfJumpTouchConnection then
            Config.InfJumpTouchConnection:Disconnect()
            Config.InfJumpTouchConnection = nil
        end
        
        if Config.JumpCooldownConnection then
            Config.JumpCooldownConnection:Disconnect()
            Config.JumpCooldownConnection = nil
        end
        
        if bunnyHopConnection then
            bunnyHopConnection:Disconnect()
            bunnyHopConnection = nil
        end
        
        if Config.JumpSoundConnection then
            Config.JumpSoundConnection:Disconnect()
            Config.JumpSoundConnection = nil
        end
        
        if jumpBoostParticle then
            jumpBoostParticle:Destroy()
            jumpBoostParticle = nil
        end
        
        -- Reset jump height
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpHeight = 50
                if Config.OriginalFallDamage then
                    humanoid.FallDamage = Config.OriginalFallDamage
                end
            end
        end
    end)
    
    print("[Vanzyxxx] Infinity Jump system loaded!")
end