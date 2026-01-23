return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    local MarketplaceService = Services.MarketplaceService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    local ReplayConnection = nil
    
    -- // PATH SYSTEM //
    local BasePath = "VanzyData"
    local RecordsPath = BasePath .. "/Records"
    local CurrentMapFolder = nil
    local MapName = nil
    
    -- // UTILITIES //
    local function SetupFolders()
        if not isfolder or not makefolder then return false end
        
        -- Create base folders
        if not isfolder(BasePath) then
            makefolder(BasePath)
        end
        
        if not isfolder(RecordsPath) then
            makefolder(RecordsPath)
        end
        
        -- Get current map info
        local mapId = tostring(game.PlaceId)
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and productInfo then
            -- Clean map name for folder
            MapName = productInfo.Name:gsub("[^%w%s]", ""):gsub("%s+", "_")
            if MapName == "" then
                MapName = "Map_" .. mapId
            end
        else
            MapName = "Map_" .. mapId
        end
        
        -- Create map-specific folder
        CurrentMapFolder = RecordsPath .. "/" .. MapName
        if not isfolder(CurrentMapFolder) then
            makefolder(CurrentMapFolder)
        end
        
        return true
    end
    
    -- High precision number (6 decimals)
    local function cn(num)
        return math.floor(num * 1000000) / 1000000
    end
    
    -- Serialization functions
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
    
    -- FIXED: Animation Scanner yang lebih akurat
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId and track.Animation.AnimationId ~= "" then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightCurrent),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        l = track.Looped,
                        n = track.Name or "Unknown"
                    })
                end
            end
        end
        
        return anims
    end
    
    -- Character state dengan lebih detail untuk gerakan natural
    local function GetCharacterState(humanoid, hrp)
        local velocity = hrp and hrp.Velocity or Vector3.new(0, 0, 0)
        local moveDirection = hrp and hrp.CFrame.LookVector or Vector3.new(0, 0, 1)
        
        return {
            ws = cn(humanoid.WalkSpeed),
            jp = cn(humanoid.JumpPower),
            state = tostring(humanoid:GetState().Name),
            hr = cn(humanoid.HipHeight),
            vx = cn(velocity.X),
            vy = cn(velocity.Y),
            vz = cn(velocity.Z),
            mx = cn(moveDirection.X),
            my = cn(moveDirection.Y),
            mz = cn(moveDirection.Z),
            gr = humanoid:GetState() == Enum.HumanoidStateType.Freefall
        }
    end
    
    -- Get current checkpoint number
    local function GetNextCheckpointNumber()
        if not isfolder or not isfolder(CurrentMapFolder) then return 1 end
        
        local files = listfiles(CurrentMapFolder)
        local maxNum = 0
        
        for _, file in ipairs(files) do
            local filename = file:match("[^/\\]+$") or file
            local cpNum = filename:match("^CP(%d+)%.json$")
            if cpNum then
                local num = tonumber(cpNum)
                if num and num > maxNum then
                    maxNum = num
                end
            end
        end
        
        return maxNum + 1
    end
    
    -- FIXED: Fungsi untuk mendapatkan path file yang benar
    local function GetFileList()
        if not isfolder or not isfolder(CurrentMapFolder) then return {} end
        
        local files = {}
        local rawFiles = listfiles(CurrentMapFolder)
        
        for _, rawFile in ipairs(rawFiles) do
            -- Ekstrak nama file dari path
            local fileName = rawFile:match("[^/\\]+$") or rawFile
            if fileName:match("^CP%d+%.json$") then
                table.insert(files, {
                    fullPath = rawFile,
                    name = fileName,
                    cpNum = tonumber(fileName:match("CP(%d+)")) or 0
                })
            end
        end
        
        table.sort(files, function(a, b)
            return a.cpNum < b.cpNum
        end)
        
        return files
    end
    
    -- // UI FLOATING WIDGET //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    WidgetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WidgetGui.ResetOnSpawn = false
    
    if syn and syn.protect_gui then
        syn.protect_gui(WidgetGui)
    end
    
    WidgetGui.Parent = Services.CoreGui
    
    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 170, 0, 55)
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Theme.Main
    WidgetFrame.BackgroundTransparency = 0.05
    WidgetFrame.BorderSizePixel = 0
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    -- Drag functionality
    local dragging, dragStart, startPos
    WidgetFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = WidgetFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            WidgetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, -10, 0, 15)
    StatusLabel.Position = UDim2.new(0, 5, 1, -15)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local MapLabel = Instance.new("TextLabel", WidgetFrame)
    MapLabel.Size = UDim2.new(1, -10, 0, 12)
    MapLabel.Position = UDim2.new(0, 5, 0, 2)
    MapLabel.BackgroundTransparency = 1
    MapLabel.Text = ""
    MapLabel.TextColor3 = Theme.Accent
    MapLabel.TextSize = 9
    MapLabel.Font = Enum.Font.Gotham
    MapLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Button creation function
    local function CreateMiniBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = UDim2.new(0, 30, 0, 30)
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
    
    -- // CORE RECORDING LOGIC //
    local function StartRecording()
        if Recording or Replaying then return end
        
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
        CurrentRecord = {
            Frames = {},
            Metadata = {
                PlaceId = game.PlaceId,
                MapName = MapName,
                StartTime = StartTime,
                Character = LocalPlayer.Name,
                Checkpoint = GetNextCheckpointNumber()
            }
        }
        
        StatusLabel.Text = "REC ●"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)
        
        -- Use Heartbeat for stable recording
        RecordConnection = RunService.Heartbeat:Connect(function(dt)
            if not Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = cn(os.clock() - StartTime),
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum),
                    state = GetCharacterState(hum, hrp),
                    dt = cn(dt)
                })
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Recording Started",
            Text = "Checkpoint #" .. CurrentRecord.Metadata.Checkpoint,
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
        
        CurrentRecord.Metadata.Duration = cn(os.clock() - StartTime)
        CurrentRecord.Metadata.FrameCount = #CurrentRecord.Frames
        
        StatusLabel.Text = "STOPPED"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        WStroke.Color = Color3.fromRGB(255, 200, 50)
        
        -- Auto-save if we have frames
        if #CurrentRecord.Frames > 0 and writefile then
            local cpNum = CurrentRecord.Metadata.Checkpoint
            local fileName = "CP" .. cpNum .. ".json"
            local filePath = CurrentMapFolder .. "/" .. fileName
            
            writefile(filePath, HttpService:JSONEncode(CurrentRecord))
            
            StarterGui:SetCore("SendNotification", {
                Title = "Saved ✓",
                Text = "CP" .. cpNum .. " (" .. #CurrentRecord.Frames .. " frames)",
                Duration = 3
            })
            
            print("[VanzyRecord] Saved CP" .. cpNum .. " with " .. #CurrentRecord.Frames .. " frames")
        else
            CurrentRecord = {}
            StarterGui:SetCore("SendNotification", {
                Title = "No Data",
                Text = "Recording was empty",
                Duration = 2
            })
        end
    end
    
    -- FIXED: Load All Checkpoints dengan path yang benar
    local function LoadAllCheckpoints()
        local files = GetFileList()
        local checkpoints = {}
        
        for _, fileInfo in ipairs(files) do
            if readfile then
                local success, data = pcall(function()
                    local content = readfile(fileInfo.fullPath)
                    return HttpService:JSONDecode(content)
                end)
                
                if success and data and data.Frames then
                    table.insert(checkpoints, {
                        file = fileInfo.name,
                        fullPath = fileInfo.fullPath,
                        data = data,
                        cpNum = fileInfo.cpNum
                    })
                end
            end
        end
        
        return checkpoints
    end
    
    local function MergeCheckpoints(checkpoints)
        if #checkpoints == 0 then return nil end
        
        local merged = {
            Frames = {},
            Metadata = {
                PlaceId = game.PlaceId,
                MapName = MapName,
                IsMerged = true,
                CheckpointCount = #checkpoints,
                TotalCheckpoints = {}
            }
        }
        
        local totalTimeOffset = 0
        
        for i, cp in ipairs(checkpoints) do
            if cp.data and cp.data.Frames then
                table.insert(merged.Metadata.TotalCheckpoints, {
                    number = cp.cpNum,
                    frames = #cp.data.Frames,
                    duration = cp.data.Metadata.Duration or 0
                })
                
                for _, frame in ipairs(cp.data.Frames) do
                    local newFrame = table.clone(frame)
                    newFrame.t = newFrame.t + totalTimeOffset
                    newFrame.cpIndex = i
                    table.insert(merged.Frames, newFrame)
                end
                
                -- Add transition time between checkpoints
                totalTimeOffset = totalTimeOffset + (cp.data.Metadata.Duration or 0) + 0.3
            end
        end
        
        merged.Metadata.TotalDuration = totalTimeOffset
        merged.Metadata.TotalFrames = #merged.Frames
        
        return merged
    end
    
    -- FIXED: Play Replay dengan gerakan natural dan anti-getar
    local function PlayReplay(data, startCpIndex, startFrameIndex)
        if Recording or Replaying then return end
        
        if not data or not data.Frames or #data.Frames < 2 then
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Invalid replay data",
                Duration = 2
            })
            return
        end
        
        local char = LocalPlayer.Character
        if not char then
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Character not found",
                Duration = 2
            })
            return
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        
        if not hrp or not hum then return end
        
        Replaying = true
        
        StatusLabel.Text = "PLAY ▶"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)
        
        -- FIXED: Persiapan karakter yang lebih baik untuk gerakan natural
        -- Jangan langsung anchor, tapi gunakan BodyVelocity untuk kontrol halus
        local controlBody = Instance.new("BodyVelocity", hrp)
        controlBody.MaxForce = Vector3.new(40000, 40000, 40000)
        controlBody.P = 1000
        controlBody.Velocity = Vector3.zero
        
        local controlGyro = Instance.new("BodyGyro", hrp)
        controlGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        controlGyro.P = 1000
        controlGyro.D = 100
        
        hum.AutoRotate = false
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        
        -- Disable collisions sementara
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Calculate start index
        local startIndex = 1
        if startCpIndex and startFrameIndex then
            for i, frame in ipairs(data.Frames) do
                if (frame.cpIndex or 1) >= startCpIndex then
                    startIndex = i
                    if startFrameIndex > 1 then
                        startIndex = math.min(startIndex + startFrameIndex - 1, #data.Frames)
                    end
                    break
                end
            end
        end
        
        -- Teleport to start position
        local startFrame = data.Frames[startIndex]
        if startFrame and startFrame.cf then
            hrp.CFrame = DeserializeCFrame(startFrame.cf)
        end
        
        local replayStart = os.clock()
        local frameIndex = startIndex
        local loadedTracks = {}
        local lastCpIndex = startCpIndex or 1
        local lastCFrame = hrp.CFrame
        
        -- FIXED: Cleanup function yang benar
        local function CleanupReplay()
            Replaying = false
            
            if ReplayConnection then
                ReplayConnection:Disconnect()
                ReplayConnection = nil
            end
            
            if controlBody and controlBody.Parent then
                controlBody:Destroy()
            end
            
            if controlGyro and controlGyro.Parent then
                controlGyro:Destroy()
            end
            
            if char and char.Parent then
                if hum then
                    hum.AutoRotate = true
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                end
                
                -- Restore collisions
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            
            -- Stop all animation tracks
            for _, track in pairs(loadedTracks) do
                if track and track.IsPlaying then
                    track:Stop(0.1)
                end
            end
            
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            WStroke.Color = Theme.Accent
        end
        
        -- FIXED: Render loop dengan kontrol fisika yang lebih baik
        ReplayConnection = RunService.Heartbeat:Connect(function(dt)
            if not Replaying or not LocalPlayer.Character then
                CleanupReplay()
                return
            end
            
            local currentTime = os.clock() - replayStart
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]
            
            -- Check if replay finished
            if not nextFrame then
                CleanupReplay()
                StarterGui:SetCore("SendNotification", {
                    Title = "Replay Complete",
                    Text = "Finished all checkpoints",
                    Duration = 3
                })
                return
            end
            
            -- Time-based frame advancement
            while nextFrame and currentTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex + 1]
            end
            
            if not currentFrame or not nextFrame then return end
            
            -- Calculate interpolation alpha
            local frameTimeDiff = nextFrame.t - currentFrame.t
            local alpha = frameTimeDiff > 0 and (currentTime - currentFrame.t) / frameTimeDiff or 0
            alpha = math.clamp(alpha, 0, 1)
            
            -- Interpolate position SMOOTHLY
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            local targetCF = cf1:Lerp(cf2, alpha)
            
            -- FIXED: Gunakan BodyVelocity untuk gerakan halus, bukan langsung set CFrame
            local targetPos = targetCF.Position
            local currentPos = hrp.Position
            local direction = (targetPos - currentPos)
            
            -- Kontrol kecepatan untuk gerakan natural
            local distance = direction.Magnitude
            local maxSpeed = 50  -- Kecepatan maksimum
            local desiredSpeed = math.min(distance / dt, maxSpeed)
            
            if distance > 0.1 then
                controlBody.Velocity = direction.Unit * desiredSpeed
            else
                controlBody.Velocity = Vector3.zero
            end
            
            -- Kontrol rotasi dengan BodyGyro
            controlGyro.CFrame = targetCF
            
            -- Track checkpoint changes
            local currentCpIndex = currentFrame.cpIndex or 1
            if currentCpIndex ~= lastCpIndex then
                lastCpIndex = currentCpIndex
                StatusLabel.Text = "PLAY CP" .. currentCpIndex
            end
            
            -- FIXED: Animation synchronization yang lebih baik
            if currentFrame.anims and animator then
                local activeIds = {}
                
                for _, animData in ipairs(currentFrame.anims) do
                    activeIds[animData.id] = true
                    
                    local track = loadedTracks[animData.id]
                    if not track then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = animData.id
                        track = animator:LoadAnimation(animation)
                        loadedTracks[animData.id] = track
                    end
                    
                    if not track.IsPlaying then
                        track:Play(0.1)
                    end
                    
                    -- Adjust dengan smoothing
                    local currentSpeed = track.Speed
                    local targetSpeed = animData.s or 1
                    if math.abs(currentSpeed - targetSpeed) > 0.05 then
                        track:AdjustSpeed(targetSpeed)
                    end
                    
                    local currentWeight = track.WeightCurrent
                    local targetWeight = animData.w or 1
                    if math.abs(currentWeight - targetWeight) > 0.05 then
                        track:AdjustWeight(targetWeight)
                    end
                end
                
                -- Stop unused tracks
                for id, track in pairs(loadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
            
            lastCFrame = targetCF
        end)
        
        -- Store cleanup function
        _G.VanzyStopReplay = CleanupReplay
        
        StarterGui:SetCore("SendNotification", {
            Title = "Replay Started",
            Text = "Playing from CP" .. (startCpIndex or 1),
            Duration = 2
        })
    end
    
    local function StopReplay()
        if _G.VanzyStopReplay then
            _G.VanzyStopReplay()
            _G.VanzyStopReplay = nil
        end
    end
    
    -- FIXED: Play All Checkpoints dengan path yang benar
    local function PlayAllCheckpoints(continueFromCurrent)
        local checkpoints = LoadAllCheckpoints()
        
        if #checkpoints == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "No Data",
                Text = "No checkpoints found for this map",
                Duration = 2
            })
            return
        end
        
        print("[VanzyRecord] Found " .. #checkpoints .. " checkpoints")
        
        local mergedData = MergeCheckpoints(checkpoints)
        
        if not mergedData then
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Failed to merge checkpoints",
                Duration = 2
            })
            return
        end
        
        if continueFromCurrent then
            -- For now, just start from beginning
            PlayReplay(mergedData, 1, 1)
        else
            PlayReplay(mergedData, 1, 1)
        end
    end
    
    -- // WIDGET BUTTONS //
    local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 10), function()
        if Recording then
            StopRecording()
        else
            StartRecording()
        end
    end)
    
    local PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 50, 0, 10), function()
        if Replaying then
            StopReplay()
        elseif CurrentRecord.Frames and #CurrentRecord.Frames > 0 then
            PlayReplay(CurrentRecord)
        else
            local checkpoints = LoadAllCheckpoints()
            if #checkpoints > 0 then
                PlayReplay(checkpoints[#checkpoints].data)
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "No Data",
                    Text = "Record or load a checkpoint first",
                    Duration = 2
                })
            end
        end
    end)
    
    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 90, 0, 10), function()
        WidgetGui.Enabled = not WidgetGui.Enabled
        HideBtn.Text = WidgetGui.Enabled and "_" or "+"
    end)
    
    local AllBtn = CreateMiniBtn("A", Color3.fromRGB(100, 150, 255), UDim2.new(0, 130, 0, 10), function()
        PlayAllCheckpoints(false)
    end)
    
    -- // MENU TAB //
    local Tab = UI:Tab("Record")
    
    -- Update map label
    spawn(function()
        task.wait(1)
        if SetupFolders() and MapName then
            MapLabel.Text = MapName:sub(1, 20)
        end
    end)
    
    Tab:Label("Floating Widget Controls")
    Tab:Toggle("Show Widget", function(v)
        WidgetGui.Enabled = v
        HideBtn.Text = v and "_" or "+"
    end).SetState(true)
    
    Tab:Label("Quick Actions")
    Tab:Button("📥 Record Checkpoint", Theme.Button, function()
        if Recording then
            StopRecording()
        else
            StartRecording()
        end
    end)
    
    Tab:Button("▶ Play Last CP", Theme.Confirm, function()
        if Replaying then
            StopReplay()
        else
            local checkpoints = LoadAllCheckpoints()
            if #checkpoints > 0 then
                PlayReplay(checkpoints[#checkpoints].data)
            end
        end
    end)
    
    Tab:Button("▶▶ Play All CP", Theme.PlayBtn or Color3.fromRGB(255, 170, 0), function()
        PlayAllCheckpoints(false)
    end)
    
    Tab:Button("⏹ Stop Replay", Theme.ButtonRed, StopReplay)
    
    Tab:Label("Checkpoint Manager - " .. (MapName or "Current Map"))
    
    local FileContainer = Tab:Container(200)
    local FileContainerLayout = nil
    
    local function RefreshFileList()
        if not FileContainer then return end
        
        -- Clear container
        for _, child in ipairs(FileContainer:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Setup layout
        FileContainerLayout = Instance.new("UIListLayout", FileContainer)
        FileContainerLayout.Padding = UDim.new(0, 5)
        
        if not isfolder or not SetupFolders() then
            local lbl = Instance.new("TextLabel", FileContainer)
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "File system not available"
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            return
        end
        
        local files = GetFileList()
        
        if #files == 0 then
            local lbl = Instance.new("TextLabel", FileContainer)
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No checkpoints saved yet"
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            return
        end
        
        -- Create file buttons
        for _, fileInfo in ipairs(files) do
            local frame = Instance.new("Frame", FileContainer)
            frame.Size = UDim2.new(1, -5, 0, 35)
            frame.BackgroundColor3 = Theme.Button
            frame.BackgroundTransparency = 0.1
            
            local corner = Instance.new("UICorner", frame)
            corner.CornerRadius = UDim.new(0, 4)
            
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "📍 CP" .. fileInfo.cpNum
            label.TextColor3 = Theme.Text
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            Instance.new("UIPadding", label).PaddingLeft = UDim.new(0, 10)
            
            -- Load button
            local loadBtn = Instance.new("TextButton", frame)
            loadBtn.Size = UDim2.new(0, 50, 0.7, 0)
            loadBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
            loadBtn.BackgroundColor3 = Theme.Confirm
            loadBtn.Text = "LOAD"
            loadBtn.TextColor3 = Color3.new(1, 1, 1)
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 10
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            
            loadBtn.MouseButton1Click:Connect(function()
                if readfile then
                    local success, data = pcall(function()
                        local content = readfile(fileInfo.fullPath)
                        return HttpService:JSONDecode(content)
                    end)
                    
                    if success and data then
                        CurrentRecord = data
                        StarterGui:SetCore("SendNotification", {
                            Title = "Loaded ✓",
                            Text = "CP" .. fileInfo.cpNum .. " ready to play",
                            Duration = 2
                        })
                    else
                        StarterGui:SetCore("SendNotification", {
                            Title = "Error",
                            Text = "Failed to load CP" .. fileInfo.cpNum,
                            Duration = 2
                        })
                    end
                end
            end)
            
            -- FIXED: Delete button dengan path yang benar
            local delBtn = Instance.new("TextButton", frame)
            delBtn.Size = UDim2.new(0, 40, 0.7, 0)
            delBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed
            delBtn.Text = "DEL"
            delBtn.TextColor3 = Color3.new(1, 1, 1)
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            
            delBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete CP" .. fileInfo.cpNum .. "?", function()
                    if delfile and isfile then
                        -- Cek dulu file exist
                        if isfile(fileInfo.fullPath) then
                            delfile(fileInfo.fullPath)
                            StarterGui:SetCore("SendNotification", {
                                Title = "Deleted",
                                Text = "CP" .. fileInfo.cpNum .. " removed",
                                Duration = 2
                            })
                            -- Refresh setelah delay kecil
                            task.wait(0.3)
                            RefreshFileList()
                        else
                            StarterGui:SetCore("SendNotification", {
                                Title = "Error",
                                Text = "File not found",
                                Duration = 2
                            })
                        end
                    end
                end)
            end)
        end
        
        -- FIXED: Play All button dengan logika yang benar
        if #files > 1 then
            local playAllFrame = Instance.new("Frame", FileContainer)
            playAllFrame.Size = UDim2.new(1, -5, 0, 40)
            playAllFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
            
            local playAllCorner = Instance.new("UICorner", playAllFrame)
            playAllCorner.CornerRadius = UDim.new(0, 6)
            
            local playAllBtn = Instance.new("TextButton", playAllFrame)
            playAllBtn.Size = UDim2.new(1, -20, 0.7, 0)
            playAllBtn.Position = UDim2.new(0, 10, 0.15, 0)
            playAllBtn.BackgroundColor3 = Theme.PlayBtn or Color3.fromRGB(255, 170, 0)
            playAllBtn.Text = "▶ PLAY ALL " .. #files .. " CHECKPOINTS"
            playAllBtn.TextColor3 = Color3.new(1, 1, 1)
            playAllBtn.Font = Enum.Font.GothamBlack
            playAllBtn.TextSize = 12
            Instance.new("UICorner", playAllBtn).CornerRadius = UDim.new(0, 4)
            
            playAllBtn.MouseButton1Click:Connect(function()
                PlayAllCheckpoints(false)
            end)
        end
        
        -- Update container size
        if FileContainerLayout then
            FileContainer.CanvasSize = UDim2.new(0, 0, 0, FileContainerLayout.AbsoluteContentSize.Y + 10)
        end
    end
    
    Tab:Button("🔄 Refresh List", Theme.ButtonDark, RefreshFileList)
    
    -- Auto-refresh on tab open
    Tab:Label("")  -- Spacer
    Tab:Button("📂 Open Map Folder", Theme.Button, function()
        if SetupFolders() then
            StarterGui:SetCore("SendNotification", {
                Title = "Folder Ready",
                Text = MapName .. " folder created",
                Duration = 2
            })
        end
    end)
    
    -- Initialize
    spawn(function()
        task.wait(0.5)
        SetupFolders()
        RefreshFileList()
    end)
    
    -- Cleanup on script reset
    Config.OnReset:Connect(function()
        StopRecording()
        StopReplay()
        if WidgetGui then
            WidgetGui:Destroy()
        end
    end)
    
    print("[Vanzyxxx] Record & Replay System Loaded | Map: " .. (MapName or "Unknown"))
    return true
end