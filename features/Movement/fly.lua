-- Vanzyxxx Fly System with Gravity & Tilt
-- Mobile Friendly Fly V3

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera = Services.Workspace.CurrentCamera
    local RunService = Services.RunService
    
    -- Create Tab
    local MovementTab = UI:Tab("Movement")
    MovementTab:Label("Fly V3 (Fixed Gravity & Tilt)")
    
    -- UI Widget Frame
    local FlyWidgetFrame = nil
    local FlyToggleBtn = nil
    local FlySpeedLabel = nil
    
    -- Create Fly Widget
    local function CreateFlyWidget()
        local ScreenGui = Services.CoreGui:FindFirstChild("Vanzyxxx")
        if not ScreenGui then return end
        
        local FW = Instance.new("Frame", ScreenGui)
        FW.Size = UDim2.new(0, 140, 0, 50)
        FW.Position = UDim2.new(0.5, -70, 0.1, 0)
        FW.BackgroundColor3 = Theme.Sidebar
        FW.Visible = false
        
        local FWCorner = Instance.new("UICorner", FW)
        FWCorner.CornerRadius = UDim.new(0, 8)
        
        local FWStroke = Instance.new("UIStroke", FW)
        FWStroke.Color = Theme.Accent
        
        -- Drag function
        local function Drag(frame, handle)
            handle = handle or frame
            local dragging, dragStart, startPos
            
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            
            Services.UserInputService.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                    local delta = input.Position - dragStart
                    frame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end
        
        Drag(FW)
        FlyWidgetFrame = FW
        
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
        
        local MinusCorner = Instance.new("UICorner", FBMinus)
        
        -- Toggle Button
        local FBToggle = Instance.new("TextButton", FW)
        FBToggle.Size = UDim2.new(0.35, 0, 0.5, 0)
        FBToggle.Position = UDim2.new(0.325, 0, 0.45, 0)
        FBToggle.BackgroundColor3 = Theme.ButtonRed
        FBToggle.Text = "OFF"
        FBToggle.TextColor3 = Theme.Text
        
        local ToggleCorner = Instance.new("UICorner", FBToggle)
        FlyToggleBtn = FBToggle
        
        -- Plus Button
        local FBPlus = Instance.new("TextButton", FW)
        FBPlus.Size = UDim2.new(0.25, 0, 0.5, 0)
        FBPlus.Position = UDim2.new(0.7, 0, 0.45, 0)
        FBPlus.BackgroundColor3 = Theme.Button
        FBPlus.Text = "+"
        FBPlus.TextColor3 = Theme.Text
        
        local PlusCorner = Instance.new("UICorner", FBPlus)
        
        -- Button Events
        FBMinus.MouseButton1Click:Connect(function()
            Config.FlySpeed = math.max(10, Config.FlySpeed - 10)
            FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed
        end)
        
        FBPlus.MouseButton1Click:Connect(function()
            Config.FlySpeed = Config.FlySpeed + 10
            FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed
        end)
        
        FBToggle.MouseButton1Click:Connect(function()
            Config.Flying = not Config.Flying
            FBToggle.Text = Config.Flying and "ON" or "OFF"
            FBToggle.BackgroundColor3 = Config.Flying and Theme.Accent or Theme.ButtonRed
            
            if not Config.Flying and LocalPlayer.Character then
                -- Reset character when off
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
    end
    
    -- Main Fly Logic with Gravity & Tilt
    local FlyConnection = nil
    
    local function StartFlyLogic()
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not Config.Flying then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum then return end

            -- Enable PlatformStand to disable default physics/animations
            hum.PlatformStand = true

            -- Velocity Handler
            local bv = root:FindFirstChild("FlyVelocity")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "FlyVelocity"
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = root
            end

            -- Gyro Handler (For Rotation/Tilt)
            local bg = root:FindFirstChild("FlyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "FlyGyro"
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 10000 -- Responsiveness
                bg.D = 100 -- Damping
                bg.Parent = root
            end

            -- Calculate Movement Direction
            local moveDir = hum.MoveDirection
            local camCFrame = Camera.CFrame
            local targetVelocity = Vector3.zero

            if moveDir.Magnitude > 0 then
                targetVelocity = camCFrame.LookVector * Config.FlySpeed
            else
                targetVelocity = Vector3.zero
            end
            
            bv.Velocity = targetVelocity

            -- Calculate Tilt Animation
            local forwardTilt = 0
            local sideTilt = 0
            
            -- Getting Controls relative to camera
            local lv = camCFrame.LookVector
            local rv = camCFrame.RightVector
            local dotFwd = moveDir:Dot(lv)
            local dotRight = moveDir:Dot(rv)

            if moveDir.Magnitude > 0 then
                -- Tilt forward when moving forward
                if dotFwd > 0.5 then forwardTilt = -45 end
                -- Tilt backward when moving backward
                if dotFwd < -0.5 then forwardTilt = 25 end
                -- Tilt sideways
                if dotRight > 0.5 then sideTilt = -45 end -- Right
                if dotRight < -0.5 then sideTilt = 45 end -- Left
            end

            -- Smoothly interpolate current CFrame to target tilt
            local targetCFrame = camCFrame * CFrame.Angles(math.rad(forwardTilt), 0, math.rad(sideTilt))
            bg.CFrame = targetCFrame
        end)
    end
    
    -- UI Toggle
    MovementTab:Toggle("Fly (Menu)", function(state)
        Config.Flying = state
        
        if state then
            if not FlyWidgetFrame then
                CreateFlyWidget()
            end
            FlyWidgetFrame.Visible = true
            StartFlyLogic()
        else
            if FlyWidgetFrame then
                FlyWidgetFrame.Visible = false
            end
            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end
        end
    end)
    
    -- Additional fly controls
    MovementTab:Slider("Fly Speed", 10, 200, function(value)
        Config.FlySpeed = value
        if FlySpeedLabel then
            FlySpeedLabel.Text = "SPEED: " .. value
        end
    end)
    
    -- Cleanup on reset
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
    
    -- Initialize widget on load
    spawn(function()
        task.wait(1)
        CreateFlyWidget()
    end)
    
    Services.StarterGui:SetCore("SendNotification", {
        Title = "Fly System",
        Text = "Fly V3 Loaded with Gravity & Tilt!"
    })
end