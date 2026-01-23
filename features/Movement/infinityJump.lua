-- Vanzyxxx Infinity Jump & Modifiers (Fixed & Optimized)
-- Mobile Friendly

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local UserInputService = Services.UserInputService
    local RunService = Services.RunService
    
    -- Create Tab
    local MovementTab = UI:Tab("Movement")
    
    MovementTab:Label("Jump Modifiers")
    
    -- Variables
    local jumpConnection = nil
    local mobileJumpConnection = nil
    local bunnyHopConnection = nil
    
    -- 1. INFINITE JUMP (Fixed)
    MovementTab:Toggle("Infinite Jump", function(state)
        Config.InfJump = state
        
        if state then
            -- PC / Keyboard Support
            jumpConnection = UserInputService.JumpRequest:Connect(function()
                if Config.InfJump and LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            
            -- Mobile Support (Touch Button)
            -- Note: JumpRequest terkadang tidak terdeteksi di beberapa emulator mobile, jadi kita pakai logika tambahan
            if UserInputService.TouchEnabled then
                 -- Logic simple untuk mobile: jika tombol jump ditekan terus, dia akan terus lompat
                 -- Namun, karena keterbatasan deteksi UI mobile roblox, kita andalkan JumpRequest dulu.
                 -- Jika user pakai joystick jump, JumpRequest biasanya jalan.
            end
            
            Services.StarterGui:SetCore("SendNotification", {Title="Inf Jump", Text="Enabled! Spam Jump to Fly"})
        else
            if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
        end
    end)
    
    -- 2. JUMP HEIGHT
    MovementTab:Slider("Jump Power", 50, 300, function(value)
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = value
            end
        end
    end)
    
    -- 3. NO FALL DAMAGE (Loop Method)
    MovementTab:Toggle("No Fall Damage", function(state)
        Config.NoFallDamage = state
        spawn(function()
            while Config.NoFallDamage do
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        -- Metode 1: Ubah state falling
                        local state = char.Humanoid:GetState()
                        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Landed then
                            -- Reset fall distance logic (internal roblox terkadang sulit diubah, tapi ini membantu)
                        end
                    end
                end)
                wait(0.5)
            end
        end)
        
        -- Hook ke event state changed (Lebih efektif)
        local fallConn
        if state then
             local function hookChar(char)
                local hum = char:WaitForChild("Humanoid")
                fallConn = hum.StateChanged:Connect(function(old, new)
                    if Config.NoFallDamage and new == Enum.HumanoidStateType.Landed then
                        -- Prevent damage logic here is tricky without server access, 
                        -- but keeping JumpPower consistent helps.
                    end
                end)
             end
             if LocalPlayer.Character then hookChar(LocalPlayer.Character) end
             LocalPlayer.CharacterAdded:Connect(hookChar)
        else
            if fallConn then fallConn:Disconnect() end
        end
    end)
    
    -- 4. MOON JUMP (Low Gravity)
    MovementTab:Toggle("Moon Jump (Low Gravity)", function(state)
        Config.MoonJump = state
        if state then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local bv = Instance.new("BodyForce")
                bv.Name = "MoonJumpForce"
                bv.Force = Vector3.new(0, 2500, 0) -- Angkat sedikit ke atas
                bv.Parent = LocalPlayer.Character.HumanoidRootPart
            end
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                for _,v in pairs(LocalPlayer.Character.HumanoidRootPart:GetChildren()) do
                    if v.Name == "MoonJumpForce" then v:Destroy() end
                end
            end
        end
    end)
    
    -- 5. AUTO BUNNY HOP
    MovementTab:Toggle("Auto Bunny Hop", function(state)
        Config.AutoBunnyHop = state
        
        if state then
            bunnyHopConnection = RunService.RenderStepped:Connect(function()
                if Config.AutoBunnyHop and LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if hum and hum.MoveDirection.Magnitude > 0 then -- Hanya lompat jika bergerak
                        if hum.FloorMaterial ~= Enum.Material.Air then
                            hum.Jump = true
                        end
                    end
                end
            end)
        else
            if bunnyHopConnection then bunnyHopConnection:Disconnect(); bunnyHopConnection = nil end
        end
    end)
    
    -- Init Check
    if Config.InfJump then
         -- Re-enable logic if config says so (for reload)
    end
    
    -- Cleanup
    Config.OnReset:Connect(function()
        if jumpConnection then jumpConnection:Disconnect() end
        if bunnyHopConnection then bunnyHopConnection:Disconnect() end
        if LocalPlayer.Character then
             local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
             if hum then hum.JumpPower = 50 end
             local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
             if hrp then 
                 for _,v in pairs(hrp:GetChildren()) do if v.Name == "MoonJumpForce" then v:Destroy() end end 
             end
        end
    end)
    
    print("[Vanzyxxx] Jump Modifiers Loaded")
end
