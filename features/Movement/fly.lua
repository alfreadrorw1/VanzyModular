-- Vanzyxxx Fly System with Gravity & Tilt
-- Mobile Friendly Fly V3

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera = Services.Workspace.CurrentCamera
    local RunService = Services.RunService
    
    -- Create Tab
    local MovementTab = UI:Tab("Movement")
    
    -- Add section label
    MovementTab:Label("Fly V3 (Fixed Gravity & Tilt)")
    
    -- Variables
    local FlyWidgetFrame = nil
    local FlySpeedLabel = nil
    local FlyToggleBtn = nil
    local FlyConnection = nil
    
    -- Create Fly Widget UI
    local function CreateFlyWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        local FW = Instance.new("Frame", screenGui)
        FW.Name = "FlyWidget"
        FW.Size = UDim2.new(0, 140, 0, 50)
        FW.Position = UDim2.new(0.5, -70, 0.1, 0)
        FW.BackgroundColor3 = Theme.Sidebar
        FW.Visible = false
        FW.ZIndex = 50
        
        local FWCorner = Instance.new("UICorner", FW)
        FWCorner.CornerRadius = UDim.new(0, 8)
        
        local FWStroke = Instance.new("UIStroke", FW)
        FWStroke.Color = Theme.Accent
        
        -- Speed Label
        local SL = Instance.new("TextLabel", FW)
        SL.Size = UDim2.new(1, 0, 0.4, 0)
        SL.BackgroundTransparency = 1
        SL.Text = "SPEED: " .. Config.FlySpeed
        SL.TextColor3 = Theme.Text
        SL.Font = Enum.Font.GothamBold
        SL.TextSize = 11
        FlySpeedLabel = SL
        
        -- Minus Button
        local FBMinus = Instance.new("TextButton", FW)
        FBMinus.Size = UDim2.new(0.25, 0, 0.5, 0)
        FBMinus.Position = UDim2.new(0.05, 0, 0.45, 0)
        FBMinus.BackgroundColor3 = Theme.Button
        FBMinus.Text = "-"
        FBMinus.TextColor3 = Theme.Text
        FBMinus.ZIndex = 51
        
        local MinusCorner = Instance.new("UICorner", FBMinus)
        MinusCorner.CornerRadius = UDim.new(0, 4)
        
        -- Toggle Button
        local FBToggle = Instance.new("TextButton", FW)
        FBToggle.Size = UDim2.new(0.35, 0, 0.5, 0)
        FBToggle.Position = UDim2.new(0.325, 0, 0.45, 0)
        FBToggle.BackgroundColor3 = Theme.ButtonRed
        FBToggle.Text = "OFF"
        FBToggle.TextColor3 = Theme.Text
        FBToggle.ZIndex = 51
        FlyToggleBtn = FBToggle
        
        local ToggleCorner = Instance.new("UICorner", FBToggle)
        ToggleCorner.CornerRadius = UDim.new(0, 4)
        
        -- Plus Button
        local FBPlus = Instance.new("TextButton", FW)
        FBPlus.Size = UDim2.new(0.25, 0, 0.5, 0)
        FBPlus.Position = UDim2.new(0.7, 0, 0.45, 0)
        FBPlus.BackgroundColor3 = Theme.Button
        FBPlus.Text = "+"
        FBPlus.TextColor3 = Theme.Text
        FBPlus.ZIndex = 51
        
        local PlusCorner = Instance.new("UICorner", FBPlus)
        PlusCorner.CornerRadius = UDim.new(0, 4)
        
        -- Button Events
        FBMinus.MouseButton1Click:Connect(function()
            Config.FlySpeed = math.max(10, Config.FlySpeed - 10)
            if FlySpeedLabel then
                FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed
            end
        end)
        
        FBPlus.MouseButton1Click:Connect(function()
            Config.FlySpeed = Config.FlySpeed + 10
            if FlySpeedLabel then
                FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed
            end
        end)
        
        FBToggle.MouseButton1Click:Connect(function()
            Config.Flying = not Config.Flying
            
            if FlyToggleBtn then
                FlyToggleBtn.Text = Config.Flying and "ON" or "OFF"
                FlyToggleBtn.BackgroundColor3 = Config.Flying and Theme.Accent or Theme.ButtonRed
            end
            
            -- Reset when turning off
            if not Config.Flying and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    hum.PlatformStand = false
                end
                
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                    if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
                    if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
                end
            end
        end)
        
        FlyWidgetFrame = FW
        return FW
    end
    
    -- Fly Logic
    local function StartFlyLogic()
        if FlyConnection then
            FlyConnection:Disconnect()
        end
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not Config.Flying then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum then return end

            -- Enable PlatformStand
            hum.PlatformStand = true

            -- Velocity Handler
            local bv = root:FindFirstChild("FlyVelocity")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "FlyVelocity"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = root
            end

            -- Gyro Handler
            local bg = root:FindFirstChild("FlyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "FlyGyro"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 10000
                bg.D = 100
                bg.Parent = root
            end

            -- Movement Direction
            local moveDir = hum.MoveDirection
            local camCFrame = Camera.CFrame
            local targetVelocity = Vector3.zero

            if moveDir.Magnitude > 0 then
                targetVelocity = camCFrame.LookVector * Config.FlySpeed
            else
                targetVelocity = Vector3.zero
            end
            
            bv.Velocity = targetVelocity

            -- Tilt Animation
            local forwardTilt = 0
            local sideTilt = 0
            
            local lv = camCFrame.LookVector
            local rv = camCFrame.RightVector
            local dotFwd = moveDir:Dot(lv)
            local dotRight = moveDir:Dot(rv)

            if moveDir.Magnitude > 0 then
                if dotFwd > 0.5 then forwardTilt = -45 end
                if dotFwd < -0.5 then forwardTilt = 25 end
                if dotRight > 0.5 then sideTilt = -45 end
                if dotRight < -0.5 then sideTilt = 45 end
            end

            local targetCFrame = camCFrame * CFrame.Angles(math.rad(forwardTilt), 0, math.rad(sideTilt))
            bg.CFrame = targetCFrame
        end)
    end
    
    -- UI Toggle in Menu
    MovementTab:Toggle("Fly (Menu)", function(state)
        Config.Flying = state
        
        if state then
            if not FlyWidgetFrame then
                CreateFlyWidget()
            end
            if FlyWidgetFrame then
                FlyWidgetFrame.Visible = true
            end
            if FlyToggleBtn then
                FlyToggleBtn.Text = "ON"
                FlyToggleBtn.BackgroundColor3 = Theme.Accent
            end
            StartFlyLogic()
        else
            if FlyWidgetFrame then
                FlyWidgetFrame.Visible = false
            end
            if FlyToggleBtn then
                FlyToggleBtn.Text = "OFF"
                FlyToggleBtn.BackgroundColor3 = Theme.ButtonRed
            end
        end
    end)
    
    -- Speed Slider
    MovementTab:Slider("Fly Speed", 10, 200, function(value)
        Config.FlySpeed = value
        if FlySpeedLabel then
            FlySpeedLabel.Text = "SPEED: " .. value
        end
    end)
    
    -- Create widget on startup
    spawn(function()
        task.wait(1)
        CreateFlyWidget()
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        Config.Flying = false
        
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        
        if FlyWidgetFrame then
            FlyWidgetFrame:Destroy()
            FlyWidgetFrame = nil
        end
    end)
    
    print("[Vanzyxxx] Fly system loaded!")
end