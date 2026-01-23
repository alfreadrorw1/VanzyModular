--[[
    PATH: features/Movement/fly.lua
    FITUR: Fly V3 dengan Tilt & Mobile Widget
]]

return function(UI, Services, Config)
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera = Services.Workspace.CurrentCamera

    -- 1. SETUP UI TAB
    -- Karena pakai sistem 'Smart Check', ini akan masuk ke Tab "Movement" yang sama dengan speed.lua nanti
    local Tab = UI:Tab("Movement")

    -- 2. LOCAL STATE
    local State = {
        Flying = false,
        Speed = 50,
        Connections = {}
    }

    -- 3. WIDGET SETUP (Self-Contained UI)
    -- Kita buat widget di sini agar module ini mandiri
    local FlyWidget = Instance.new("Frame")
    FlyWidget.Size = UDim2.new(0,140,0,50)
    FlyWidget.Position = UDim2.new(0.5,-70,0.1,0)
    FlyWidget.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
    FlyWidget.Visible = false
    FlyWidget.Parent = UI.ScreenGui -- Mengakses ScreenGui dari Library
    
    -- (Isi Widget: Tombol Speed +/- dan Indikator)
    local SpeedLbl = Instance.new("TextLabel", FlyWidget)
    SpeedLbl.Size = UDim2.new(1,0,0.4,0); SpeedLbl.BackgroundTransparency=1; SpeedLbl.Text="SPEED: 50"; SpeedLbl.TextColor3=Color3.new(1,1,1)
    
    local BtnUp = Instance.new("TextButton", FlyWidget); BtnUp.Size=UDim2.new(0.25,0,0.5,0); BtnUp.Position=UDim2.new(0.7,0,0.45,0); BtnUp.Text="+"
    local BtnDown = Instance.new("TextButton", FlyWidget); BtnDown.Size=UDim2.new(0.25,0,0.5,0); BtnDown.Position=UDim2.new(0.05,0,0.45,0); BtnDown.Text="-"
    
    BtnUp.MouseButton1Click:Connect(function() State.Speed = State.Speed + 10; SpeedLbl.Text="SPEED: "..State.Speed end)
    BtnDown.MouseButton1Click:Connect(function() State.Speed = math.max(10, State.Speed - 10); SpeedLbl.Text="SPEED: "..State.Speed end)

    -- 4. LOGIC FLY V3 (The Core Logic)
    local function StartFly()
        FlyWidget.Visible = true
        State.Flying = true
        
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if hum then hum.PlatformStand = true end

        -- Loop Fisika
        local HB = RunService.Heartbeat:Connect(function()
            if not State.Flying or not root then return end
            
            -- Velocity
            local bv = root:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity", root)
            bv.Name = "FlyVelocity"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            
            -- Gyro (Tilt)
            local bg = root:FindFirstChild("FlyGyro") or Instance.new("BodyGyro", root)
            bg.Name = "FlyGyro"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 10000; bg.D = 100

            -- Kalkulasi Arah
            local moveDir = hum.MoveDirection
            local camCFrame = Camera.CFrame
            
            if moveDir.Magnitude > 0 then
                bv.Velocity = camCFrame.LookVector * State.Speed
            else
                bv.Velocity = Vector3.zero
            end

            -- Kalkulasi Tilt
            local forwardTilt, sideTilt = 0, 0
            local lv, rv = camCFrame.LookVector, camCFrame.RightVector
            local dotFwd, dotRight = moveDir:Dot(lv), moveDir:Dot(rv)

            if moveDir.Magnitude > 0 then
                if dotFwd > 0.5 then forwardTilt = -45 end
                if dotFwd < -0.5 then forwardTilt = 25 end
                if dotRight > 0.5 then sideTilt = -45 end
                if dotRight < -0.5 then sideTilt = 45 end
            end

            bg.CFrame = camCFrame * CFrame.Angles(math.rad(forwardTilt), 0, math.rad(sideTilt))
        end)
        
        table.insert(State.Connections, HB)
    end

    local function StopFly()
        State.Flying = false
        FlyWidget.Visible = false
        
        -- Cleanup Physics
        for _, conn in pairs(State.Connections) do conn:Disconnect() end
        State.Connections = {}
        
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hum then hum.PlatformStand = false end
            if root then
                if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
                if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end

    -- 5. MENU CONTROLS
    Tab:Toggle("Fly V3 (Menu)", function(enabled)
        if enabled then StartFly() else StopFly() end
    end)

    -- 6. CLEANUP HANDLER (Saat script utama di-close)
    table.insert(Config.CleanupEvents, function()
        StopFly()
        FlyWidget:Destroy()
    end)
end
