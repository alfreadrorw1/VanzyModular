-- Vanzyxxx Fly System with Gravity & Tilt
-- Mobile Friendly Fly V3 (Fixed Physics & Smooth Tilt)

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera = Services.Workspace.CurrentCamera
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService
    
    -- Create Tab
    local MovementTab = UI:Tab("Movement")
    
    -- Add section label
    MovementTab:Label("Fly V3 (Fixed Gravity & Tilt)")
    
    -- Variables
    local FlyWidgetFrame = nil
    local FlySpeedLabel = nil
    local FlyToggleBtn = nil
    local FlyConnection = nil
    
    -- Drag Function (Added for Widget)
    local function Drag(frame, handle)
        handle = handle or frame
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

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
        FWStroke.Thickness = 2
        
        -- Drag Handler (Invisible)
        local DragBtn = Instance.new("TextButton", FW)
        DragBtn.Size = UDim2.new(1,0,1,0)
        DragBtn.BackgroundTransparency = 1
        DragBtn.Text = ""
        DragBtn.ZIndex = 49
        Drag(FW, DragBtn) -- Apply Drag
        
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
        Instance.new("UICorner", FBMinus).CornerRadius = UDim.new(0, 4)
        
        -- Toggle Button
        local FBToggle = Instance.new("TextButton", FW)
        FBToggle.Size = UDim2.new(0.35, 0, 0.5, 0)
        FBToggle.Position = UDim2.new(0.325, 0, 0.45, 0)
        FBToggle.BackgroundColor3 = Theme.ButtonRed
        FBToggle.Text = "OFF"
        FBToggle.TextColor3 = Theme.Text
        FBToggle.ZIndex = 51
        Instance.new("UICorner", FBToggle).CornerRadius = UDim.new(0, 4)
        FlyToggleBtn = FBToggle
        
        -- Plus Button
        local FBPlus = Instance.new("TextButton", FW)
        FBPlus.Size = UDim2.new(0.25, 0, 0.5, 0)
        FBPlus.Position = UDim2.new(0.7, 0, 0.45, 0)
        FBPlus.BackgroundColor3 = Theme.Button
        FBPlus.Text = "+"
        FBPlus.TextColor3 = Theme.Text
        FBPlus.ZIndex = 51
        Instance.new("UICorner", FBPlus).CornerRadius = UDim.new(0, 4)
        
        -- Button Events
        FBMinus.MouseButton1Click:Connect(function()
            Config.FlySpeed = math.max(10, Config.FlySpeed - 10)
            if FlySpeedLabel then FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed end
        end)
        
        FBPlus.MouseButton1Click:Connect(function()
            Config.FlySpeed = Config.FlySpeed + 10
            if FlySpeedLabel then FlySpeedLabel.Text = "SPEED: " .. Config.FlySpeed end
        end)
        
        FBToggle.MouseButton1Click:Connect(function()
            Config.Flying = not Config.Flying
            
            if FlyToggleBtn then
                FlyToggleBtn.Text = Config.Flying and "ON" or "OFF"
                FlyToggleBtn.BackgroundColor3 = Config.Flying and Theme.Accent or Theme.ButtonRed
            end
            
            -- FORCE CLEANUP ON TOGGLE OFF
            if not Config.Flying then
                StopFlyLogic()
            end
        end)
        
        FlyWidgetFrame = FW
        return FW
    end
    
    function StopFlyLogic()
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
                if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
            end
        end
    end

    -- Fly Logic Loop
    local function StartFlyLogic()
        if FlyConnection then FlyConnection:Disconnect() end
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not Config.Flying then return end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum then return end

            -- 1. Anti Gravity & Physics
            hum.PlatformStand = true
            
            local bv = root:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
            bv.Name = "FlyVelocity"
            bv.Parent = root
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9) -- Lock all axes

            local bg = root:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
            bg.Name = "FlyGyro"
            bg.Parent = root
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 1000 -- Smooth power
            bg.D = 50   -- Damping

            -- 2. Movement Calculation
            local moveDir = hum.MoveDirection
            local camCFrame = Camera.CFrame
            local targetVelocity = Vector3.zero

            if moveDir.Magnitude > 0 then
                -- Move towards camera look direction
                targetVelocity = camCFrame.LookVector * Config.FlySpeed
            else
                -- Stop completely (Anti-Fall)
                targetVelocity = Vector3.zero
            end
            
            bv.Velocity = targetVelocity

            -- 3. Smooth Tilt Logic
            local targetCFrame = camCFrame -- Default: Look at camera
            
            if moveDir.Magnitude > 0 then
                -- Calculate Tilt
                local lv = camCFrame.LookVector
                local rv = camCFrame.RightVector
                local dotFwd = moveDir:Dot(lv)
                local dotRight = moveDir:Dot(rv)

                local forwardTilt = 0
                local sideTilt = 0

                -- Forward/Backward Tilt (Nunduk/Dangak)
                if dotFwd > 0.5 then forwardTilt = -20 end -- Nunduk dikit
                if dotFwd < -0.5 then forwardTilt = 15 end  -- Dangak dikit
                
                -- Left/Right Tilt (Miring)
                if dotRight > 0.5 then sideTilt = -30 end
                if dotRight < -0.5 then sideTilt = 30 end

                targetCFrame = camCFrame * CFrame.Angles(math.rad(forwardTilt), 0, math.rad(sideTilt))
            end

            -- Apply Smooth Rotation (Lerp)
            bg.CFrame = bg.CFrame:Lerp(targetCFrame, 0.2)
        end)
    end
    
    -- UI Toggle in Menu
    MovementTab:Toggle("Fly (Menu)", function(state)
        Config.Flying = state
        
        if state then
            if not FlyWidgetFrame then CreateFlyWidget() end
            if FlyWidgetFrame then FlyWidgetFrame.Visible = true end
            if FlyToggleBtn then
                FlyToggleBtn.Text = "ON"
                FlyToggleBtn.BackgroundColor3 = Theme.Accent
            end
            StartFlyLogic()
        else
            if FlyWidgetFrame then FlyWidgetFrame.Visible = false end
            if FlyToggleBtn then
                FlyToggleBtn.Text = "OFF"
                FlyToggleBtn.BackgroundColor3 = Theme.ButtonRed
            end
            StopFlyLogic()
        end
    end)
    
    -- Speed Slider
    MovementTab:Slider("Fly Speed", 10, 200, function(value)
        Config.FlySpeed = value
        if FlySpeedLabel then FlySpeedLabel.Text = "SPEED: " .. value end
    end)
    
    -- Create widget on startup
    spawn(function()
        task.wait(1)
        CreateFlyWidget()
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        Config.Flying = false
        if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
        if FlyWidgetFrame then FlyWidgetFrame:Destroy(); FlyWidgetFrame = nil end
        StopFlyLogic()
    end)
    
    print("[Vanzyxxx] Fly V3 (Fixed Physics) loaded!")
end
