-- Sistem RECORDING & REPLAY dengan Anti-Jatuh, Checkpoint, dan Autowalk
return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    local MarketplaceService = Services.MarketplaceService
    local TweenService = Services.TweenService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- ====================================
    -- VARIABLES & CONFIGURATION
    -- ====================================
    local Recording = false
    local Replaying = false
    local Autowalking = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    local ReplayConnection = nil
    local AutowalkConnection = nil
    
    -- Anti-Jatuh System
    local FallDetectionEnabled = true
    local FallHeightThreshold = -50 -- Y position threshold untuk deteksi jatuh
    local LastSafeFrameIndex = 0
    local FallDetected = false
    local FallStartTime = 0
    
    -- Checkpoint System
    local Checkpoints = {}
    local CurrentCheckpoint = 0
    local CheckpointFolder = nil
    local MapName = nil
    
    -- Autowalk System
    local SelectedMap = nil
    local MapData = nil
    local AutowalkTargetIndex = 1
    local AutowalkSpeed = 30
    
    -- Path System
    local BasePath = "VanzyData"
    local RecordsPath = BasePath .. "/Records"
    local AutowalkPath = BasePath .. "/Autowalk"
    
    -- ====================================
    -- UTILITY FUNCTIONS
    -- ====================================
    local function SetupFolders()
        if not isfolder or not makefolder then return false end
        
        if not isfolder(BasePath) then makefolder(BasePath) end
        if not isfolder(RecordsPath) then makefolder(RecordsPath) end
        if not isfolder(AutowalkPath) then makefolder(AutowalkPath) end
        
        -- Get map info
        local mapId = tostring(game.PlaceId)
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and productInfo then
            MapName = productInfo.Name:gsub("[^%w%s]", ""):gsub("%s+", "_")
        else
            MapName = "Map_" .. mapId
        end
        
        -- Create map folders
        CheckpointFolder = RecordsPath .. "/" .. MapName
        if not isfolder(CheckpointFolder) then
            makefolder(CheckpointFolder)
        end
        
        return true
    end
    
    -- High precision number
    local function cn(num)
        return math.floor(num * 1000000) / 1000000
    end
    
    -- Serialization
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {
            cn(x), cn(y), cn(z),
            cn(R00), cn(R01), cn(R02),
            cn(R10), cn(R11), cn(R12),
            cn(R20), cn(R21), cn(R22)
        }
    end
    
    local function DeserializeCFrame(t)
        return CFrame.new(
            t[1], t[2], t[3],
            t[4], t[5], t[6],
            t[7], t[8], t[9],
            t[10], t[11], t[12]
        )
    end
    
    -- ====================================
    -- FALL DETECTION SYSTEM
    -- ====================================
    local function DetectFall(positionY, velocityY)
        -- Deteksi jatuh berdasarkan posisi Y dan velocity
        if positionY < FallHeightThreshold then
            return true
        end
        
        -- Deteksi jatuh cepat (velocity negatif besar)
        if velocityY < -50 then
            return true
        end
        
        return false
    end
    
    local function FindLastSafeFrame()
        if not CurrentRecord or not CurrentRecord.Frames then return 0 end
        
        for i = #CurrentRecord.Frames, 1, -1 do
            local frame = CurrentRecord.Frames[i]
            if frame and frame.cf then
                local yPos = frame.cf[2] -- Y position
                if yPos >= FallHeightThreshold then
                    return i
                end
            end
        end
        
        return 0
    end
    
    local function TrimFallenFrames()
        if not CurrentRecord or not CurrentRecord.Frames then return end
        
        local lastSafe = FindLastSafeFrame()
        if lastSafe > 0 and lastSafe < #CurrentRecord.Frames then
            -- Potong frames setelah jatuh
            for i = #CurrentRecord.Frames, lastSafe + 1, -1 do
                table.remove(CurrentRecord.Frames, i)
            end
            print("[System] Trimmed fallen frames. Safe frames:", lastSafe)
        end
    end
    
    -- ====================================
    -- AUTO REFRESH SYSTEM
    -- ====================================
    local function AutoRefresh()
        print("[AutoRefresh] Starting refresh...")
        
        -- 1. Stop semua aktivitas
        if Recording then
            if RecordConnection then
                RecordConnection:Disconnect()
                RecordConnection = nil
            end
            Recording = false
        end
        
        if Replaying then
            if ReplayConnection then
                ReplayConnection:Disconnect()
                ReplayConnection = nil
            end
            Replaying = false
        end
        
        if Autowalking then
            if AutowalkConnection then
                AutowalkConnection:Disconnect()
                AutowalkConnection = nil
            end
            Autowalking = false
        end
        
        -- 2. Trim frames jatuh
        TrimFallenFrames()
        
        -- 3. Update last safe position
        LastSafeFrameIndex = FindLastSafeFrame()
        
        -- 4. Reset player position to last safe position if needed
        if LastSafeFrameIndex > 0 and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local safeFrame = CurrentRecord.Frames[LastSafeFrameIndex]
                if safeFrame and safeFrame.cf then
                    hrp.CFrame = DeserializeCFrame(safeFrame.cf)
                    print("[AutoRefresh] Player returned to safe position")
                end
            end
        end
        
        -- 5. Update checkpoint
        if LastSafeFrameIndex > 0 then
            local framesPerCheckpoint = 100 -- Setiap 100 frames = 1 checkpoint
            CurrentCheckpoint = math.floor(LastSafeFrameIndex / framesPerCheckpoint) + 1
            print("[AutoRefresh] Updated checkpoint: CP" .. CurrentCheckpoint)
        end
        
        -- 6. Reset fall detection flag
        FallDetected = false
        
        -- 7. Update UI status
        UpdateWidgetStatus("READY")
        
        print("[AutoRefresh] Refresh completed")
        
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Refresh",
            Text = "System refreshed. Ready to continue.",
            Duration = 2
        })
    end
    
    -- ====================================
    -- CHECKPOINT SYSTEM
    -- ====================================
    local function ShowCheckpointPopup()
        -- Tampilkan popup pilihan checkpoint
        local popup = Instance.new("ScreenGui")
        popup.Name = "CheckpointPopup"
        popup.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        if syn and syn.protect_gui then
            syn.protect_gui(popup)
        end
        
        popup.Parent = Services.CoreGui
        
        local frame = Instance.new("Frame", popup)
        frame.Size = UDim2.new(0, 300, 0, 180)
        frame.Position = UDim2.new(0.5, -150, 0.5, -90)
        frame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
        frame.BackgroundTransparency = 0.1
        
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 2
        
        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, -20, 0, 40)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "CHECKPOINT DETECTED"
        title.TextColor3 = Theme.Accent
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        
        local desc = Instance.new("TextLabel", frame)
        desc.Size = UDim2.new(1, -20, 0, 50)
        desc.Position = UDim2.new(0, 10, 0, 50)
        desc.BackgroundTransparency = 1
        desc.Text = "Continue from CP" .. CurrentCheckpoint .. "?"
        desc.TextColor3 = Color3.new(1, 1, 1)
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 14
        desc.TextWrapped = true
        
        local yesBtn = Instance.new("TextButton", frame)
        yesBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
        yesBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
        yesBtn.BackgroundColor3 = Theme.Confirm
        yesBtn.Text = "YES"
        yesBtn.TextColor3 = Color3.new(1, 1, 1)
        yesBtn.Font = Enum.Font.GothamBold
        
        local yesCorner = Instance.new("UICorner", yesBtn)
        yesCorner.CornerRadius = UDim.new(0, 6)
        
        local noBtn = Instance.new("TextButton", frame)
        noBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
        noBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
        noBtn.BackgroundColor3 = Theme.ButtonRed
        noBtn.Text = "NO"
        noBtn.TextColor3 = Color3.new(1, 1, 1)
        noBtn.Font = Enum.Font.GothamBold
        
        local noCorner = Instance.new("UICorner", noBtn)
        noCorner.CornerRadius = UDim.new(0, 6)
        
        yesBtn.MouseButton1Click:Connect(function()
            -- Resume dari checkpoint
            if LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and CurrentRecord.Frames and #CurrentRecord.Frames > 0 then
                    -- Cari frame terdekat untuk checkpoint ini
                    local targetFrame = math.min(CurrentCheckpoint * 100, #CurrentRecord.Frames)
                    if CurrentRecord.Frames[targetFrame] then
                        hrp.CFrame = DeserializeCFrame(CurrentRecord.Frames[targetFrame].cf)
                    end
                end
            end
            popup:Destroy()
            StarterGui:SetCore("SendNotification", {
                Title = "Checkpoint Loaded",
                Text = "Resumed from CP" .. CurrentCheckpoint,
                Duration = 2
            })
        end)
        
        noBtn.MouseButton1Click:Connect(function()
            -- Hentikan saja
            popup:Destroy()
            StarterGui:SetCore("SendNotification", {
                Title = "Stopped",
                Text = "Recording stopped at CP" .. CurrentCheckpoint,
                Duration = 2
            })
        end)
    end
    
    -- ====================================
    -- RECORDING SYSTEM
    -- ====================================
    local function StartRecording()
        if Recording or Replaying or Autowalking then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Character not found!",
                Duration = 2
            })
            return
        end
        
        Recording = true
        StartTime = os.clock()
        FallDetected = false
        LastSafeFrameIndex = 0
        
        -- Initialize atau continue recording
        if not CurrentRecord.Frames then
            CurrentRecord = {
                Frames = {},
                Metadata = {
                    PlaceId = game.PlaceId,
                    MapName = MapName,
                    StartTime = StartTime,
                    Character = LocalPlayer.Name
                }
            }
        end
        
        UpdateWidgetStatus("REC ●")
        
        -- Recording loop dengan fall detection
        RecordConnection = RunService.Heartbeat:Connect(function(dt)
            if not Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                local currentTime = os.clock() - StartTime
                local currentPos = hrp.Position
                local currentVel = hrp.Velocity
                
                -- Deteksi jatuh
                if FallDetectionEnabled and DetectFall(currentPos.Y, currentVel.Y) then
                    if not FallDetected then
                        FallDetected = true
                        FallStartTime = currentTime
                        print("[FallDetection] Fall detected at time:", currentTime)
                        
                        -- Auto stop recording jika jatuh
                        spawn(function()
                            task.wait(0.5) -- Tunggu sebentar untuk konfirmasi
                            if FallDetected then
                                StopRecording()
                                ShowCheckpointPopup()
                            end
                        end)
                    end
                else
                    FallDetected = false
                end
                
                -- Hanya rekam jika tidak jatuh
                if not FallDetected then
                    table.insert(CurrentRecord.Frames, {
                        t = cn(currentTime),
                        cf = SerializeCFrame(hrp.CFrame),
                        dt = cn(dt),
                        cp = CurrentCheckpoint -- Simpan checkpoint index
                    })
                    LastSafeFrameIndex = #CurrentRecord.Frames
                end
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Recording Started",
            Text = "Recording active. Fall detection ON.",
            Duration = 2
        })
    end
    
    local function StopRecording()
        if not Recording then return end
        
        Recording = false
        
        if RecordConnection then
            RecordConnection:Disconnect()
            RecordConnection = nil
        end
        
        -- Auto refresh setelah stop
        AutoRefresh()
        
        StarterGui:SetCore("SendNotification", {
            Title = "Recording Stopped",
            Text = #CurrentRecord.Frames .. " frames recorded",
            Duration = 2
        })
    end
    
    -- ====================================
    -- REPLAY SYSTEM (ANTI JATUH)
    -- ====================================
    local function PlayReplay()
        if Replaying or Recording or Autowalking then return end
        
        if not CurrentRecord or not CurrentRecord.Frames or #CurrentRecord.Frames < 2 then
            StarterGui:SetCore("SendNotification", {
                Title = "No Data",
                Text = "Record something first!",
                Duration = 2
            })
            return
        end
        
        -- Gunakan hanya frames yang aman (tidak jatuh)
        local safeFrames = {}
        for i, frame in ipairs(CurrentRecord.Frames) do
            if frame.cf and frame.cf[2] >= FallHeightThreshold then
                table.insert(safeFrames, frame)
            end
        end
        
        if #safeFrames < 2 then
            StarterGui:SetCore("SendNotification", {
                Title = "No Safe Data",
                Text = "All frames contain falls",
                Duration = 2
            })
            return
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then return end
        
        Replaying = true
        UpdateWidgetStatus("REPLAY ▶")
        
        -- Persiapan replay
        hrp.Anchored = true
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        
        local replayStart = os.clock()
        local frameIndex = 1
        
        ReplayConnection = RunService.Heartbeat:Connect(function()
            if not Replaying then return end
            
            local currentTime = os.clock() - replayStart
            local currentFrame = safeFrames[frameIndex]
            local nextFrame = safeFrames[frameIndex + 1]
            
            if not nextFrame then
                -- Replay selesai
                StopReplay()
                return
            end
            
            while nextFrame and currentTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = safeFrames[frameIndex]
                nextFrame = safeFrames[frameIndex + 1]
            end
            
            if not currentFrame or not nextFrame then return end
            
            local alpha = (currentTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Replay Started",
            Text = "Playing safe frames only",
            Duration = 2
        })
    end
    
    local function StopReplay()
        if not Replaying then return end
        
        Replaying = false
        
        if ReplayConnection then
            ReplayConnection:Disconnect()
            ReplayConnection = nil
        end
        
        -- Kembalikan karakter ke posisi normal
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hrp then hrp.Anchored = false end
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
        
        UpdateWidgetStatus("READY")
        AutoRefresh() -- Auto refresh setelah replay
    end
    
    -- ====================================
    -- AUTOWALK SYSTEM
    -- ====================================
    local function LoadAutowalkMaps()
        if not isfolder or not isfolder(AutowalkPath) then return {} end
        
        local maps = {}
        local folders = listfiles(AutowalkPath)
        
        for _, folder in ipairs(folders) do
            if isfolder(folder) then
                local mapName = folder:match("[^/\\]+$")
                table.insert(maps, mapName)
            end
        end
        
        return maps
    end
    
    local function LoadMapData(mapName)
        if not isfolder then return nil end
        
        local mapPath = AutowalkPath .. "/" .. mapName
        if not isfolder(mapPath) then return nil end
        
        local mapData = {
            Name = mapName,
            Checkpoints = {}
        }
        
        -- Load checkpoints
        local files = listfiles(mapPath)
        for _, file in ipairs(files) do
            if file:match("CP%d+%.json$") then
                local success, data = pcall(function()
                    local content = readfile(file)
                    return HttpService:JSONDecode(content)
                end)
                
                if success and data then
                    table.insert(mapData.Checkpoints, {
                        data = data,
                        cpNum = tonumber(file:match("CP(%d+)")) or 0
                    })
                end
            end
        end
        
        -- Sort checkpoints
        table.sort(mapData.Checkpoints, function(a, b)
            return a.cpNum < b.cpNum
        end)
        
        return mapData
    end
    
    local function StartAutowalk()
        if Autowalking or Recording or Replaying then return end
        if not MapData or #MapData.Checkpoints == 0 then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then return end
        
        Autowalking = true
        UpdateWidgetStatus("AUTOWALK 🚶")
        
        -- Temukan checkpoint terdekat
        local currentPos = hrp.Position
        local closestIndex = 1
        local closestDist = math.huge
        
        for i, cp in ipairs(MapData.Checkpoints) do
            if cp.data.Frames and #cp.data.Frames > 0 then
                local cpPos = Vector3.new(
                    cp.data.Frames[1].cf[1],
                    cp.data.Frames[1].cf[2],
                    cp.data.Frames[1].cf[3]
                )
                local dist = (currentPos - cpPos).Magnitude
                
                if dist < closestDist then
                    closestDist = dist
                    closestIndex = i
                end
            end
        end
        
        AutowalkTargetIndex = closestIndex
        
        -- Autowalk loop
        AutowalkConnection = RunService.Heartbeat:Connect(function(dt)
            if not Autowalking or not LocalPlayer.Character then
                StopAutowalk()
                return
            end
            
            if not hrp or not hum then return end
            
            if AutowalkTargetIndex > #MapData.Checkpoints then
                StopAutowalk()
                StarterGui:SetCore("SendNotification", {
                    Title = "Autowalk Complete",
                    Text = "Reached end of map",
                    Duration = 3
                })
                return
            end
            
            local targetCP = MapData.Checkpoints[AutowalkTargetIndex]
            if not targetCP or not targetCP.data.Frames or #targetCP.data.Frames == 0 then
                AutowalkTargetIndex = AutowalkTargetIndex + 1
                return
            end
            
            -- Target position dari checkpoint pertama
            local targetFrame = targetCP.data.Frames[1]
            local targetPos = Vector3.new(targetFrame.cf[1], targetFrame.cf[2], targetFrame.cf[3])
            local currentPos = hrp.Position
            local direction = (targetPos - currentPos)
            local distance = direction.Magnitude
            
            -- Move towards target
            if distance > 5 then
                direction = direction.Unit
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + direction)
                hrp.Velocity = direction * AutowalkSpeed
                hum.WalkSpeed = AutowalkSpeed
            else
                -- Reached checkpoint, move to next
                AutowalkTargetIndex = AutowalkTargetIndex + 1
                StarterGui:SetCore("SendNotification", {
                    Title = "Checkpoint Reached",
                    Text = "Moving to next...",
                    Duration = 1
                })
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Autowalk Started",
            Text = "Following " .. MapData.Name,
            Duration = 2
        })
    end
    
    local function StopAutowalk()
        if not Autowalking then return end
        
        Autowalking = false
        
        if AutowalkConnection then
            AutowalkConnection:Disconnect()
            AutowalkConnection = nil
        end
        
        -- Stop movement
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hrp then hrp.Velocity = Vector3.zero end
            if hum then hum.WalkSpeed = 16 end
        end
        
        UpdateWidgetStatus("READY")
        
        StarterGui:SetCore("SendNotification", {
            Title = "Autowalk Stopped",
            Text = "Stopped at CP" .. (AutowalkTargetIndex - 1),
            Duration = 2
        })
    end
    
    -- ====================================
    -- UI WIDGET
    -- ====================================
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    WidgetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WidgetGui.ResetOnSpawn = false
    
    if syn and syn.protect_gui then
        syn.protect_gui(WidgetGui)
    end
    
    WidgetGui.Parent = Services.CoreGui
    
    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 200, 0, 60)
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Theme.Main
    WidgetFrame.BackgroundTransparency = 0.05
    WidgetFrame.BorderSizePixel = 0
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, -10, 0, 15)
    StatusLabel.Position = UDim2.new(0, 5, 1, -15)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    
    local MapLabel = Instance.new("TextLabel", WidgetFrame)
    MapLabel.Size = UDim2.new(1, -10, 0, 12)
    MapLabel.Position = UDim2.new(0, 5, 0, 2)
    MapLabel.BackgroundTransparency = 1
    MapLabel.Text = "System Ready"
    MapLabel.TextColor3 = Theme.Accent
    MapLabel.TextSize = 9
    MapLabel.Font = Enum.Font.Gotham
    
    local function UpdateWidgetStatus(status)
        StatusLabel.Text = status
        
        if status == "REC ●" then
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            WStroke.Color = Color3.fromRGB(255, 50, 50)
        elseif status == "REPLAY ▶" then
            StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
            WStroke.Color = Color3.fromRGB(50, 255, 100)
        elseif status == "AUTOWALK 🚶" then
            StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
            WStroke.Color = Color3.fromRGB(100, 150, 255)
        else
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            WStroke.Color = Theme.Accent
        end
    end
    
    local function CreateWidgetBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = UDim2.new(0, 35, 0, 35)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        
        local corn = Instance.new("UICorner", btn)
        corn.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Widget buttons
    local RecBtn = CreateWidgetBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 15), function()
        if Recording then
            StopRecording()
        else
            StartRecording()
        end
    end)
    
    local PlayBtn = CreateWidgetBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 55, 0, 15), function()
        if Replaying then
            StopReplay()
        else
            PlayReplay()
        end
    end)
    
    local AutoBtn = CreateWidgetBtn("A", Color3.fromRGB(100, 150, 255), UDim2.new(0, 100, 0, 15), function()
        if Autowalking then
            StopAutowalk()
        else
            StartAutowalk()
        end
    end)
    
    local HideBtn = CreateWidgetBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 145, 0, 15), function()
        WidgetGui.Enabled = not WidgetGui.Enabled
    end)
    
    -- ====================================
    -- UI TAB SYSTEM
    -- ====================================
    local Tab = UI:Tab("Record")
    
    -- Update map label
    spawn(function()
        task.wait(1)
        if SetupFolders() and MapName then
            MapLabel.Text = MapName:sub(1, 20)
        end
    end)
    
    Tab:Label("Floating Widget")
    Tab:Toggle("Show Widget", function(v)
        WidgetGui.Enabled = v
    end).SetState(true)
    
    Tab:Label("Recording Controls")
    Tab:Button("● Start Recording", Color3.fromRGB(200, 50, 50), StartRecording)
    Tab:Button("⏹ Stop Recording", Color3.fromRGB(255, 100, 50), StopRecording)
    Tab:Button("▶ Play Replay", Color3.fromRGB(50, 200, 100), PlayReplay)
    Tab:Button("⏹ Stop Replay", Color3.fromRGB(50, 100, 200), StopReplay)
    
    Tab:Toggle("Fall Detection", function(state)
        FallDetectionEnabled = state
    end).SetState(true)
    
    Tab:Slider("Fall Threshold", -100, 0, function(value)
        FallHeightThreshold = value
    end)
    
    Tab:Label("Checkpoint System")
    Tab:Button("Refresh Checkpoints", Theme.Button, function()
        -- Refresh checkpoint list
    end)
    
    Tab:Label("Autowalk System")
    
    -- Map Selection
    local mapContainer = Tab:Container(100)
    
    local function RefreshAutowalkMaps()
        for _, child in ipairs(mapContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local maps = LoadAutowalkMaps()
        
        if #maps == 0 then
            local lbl = Instance.new("TextLabel", mapContainer)
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No autowalk maps found"
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            return
        end
        
        for i, mapName in ipairs(maps) do
            local btn = Instance.new("TextButton", mapContainer)
            btn.Size = UDim2.new(1, -10, 0, 25)
            btn.BackgroundColor3 = Theme.Button
            btn.Text = "🗺️ " .. mapName
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                SelectedMap = mapName
                MapData = LoadMapData(mapName)
                if MapData then
                    MapLabel.Text = "AW: " .. mapName
                    StarterGui:SetCore("SendNotification", {
                        Title = "Map Loaded",
                        Text = mapName .. " loaded for autowalk",
                        Duration = 2
                    })
                end
            end)
        end
    end
    
    Tab:Button("🔄 Refresh Maps", Theme.ButtonDark, RefreshAutowalkMaps)
    
    -- Autowalk Controls
    Tab:Label("Autowalk Controls")
    Tab:Button("▶ Start Autowalk", Color3.fromRGB(100, 150, 255), StartAutowalk)
    Tab:Button("⏹ Stop Autowalk", Color3.fromRGB(150, 100, 200), StopAutowalk)
    
    Tab:Slider("Autowalk Speed", 10, 100, function(value)
        AutowalkSpeed = value
    end)
    
    -- System Controls
    Tab:Label("System Controls")
    Tab:Button("🔄 Auto Refresh", Theme.Button, AutoRefresh)
    Tab:Button("Reset System", Theme.ButtonRed, function()
        AutoRefresh()
        CurrentRecord = {}
        CurrentCheckpoint = 0
        MapData = nil
        SelectedMap = nil
        UpdateWidgetStatus("RESET")
    end)
    
    -- Initialize
    spawn(function()
        task.wait(1)
        SetupFolders()
        RefreshAutowalkMaps()
        UpdateWidgetStatus("READY")
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        StopRecording()
        StopReplay()
        StopAutowalk()
        if WidgetGui then
            WidgetGui:Destroy()
        end
    end)
    
    print("[Vanzyxxx] Advanced Recording System Loaded")
    return true
end