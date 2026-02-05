-- Vanzyxxx Record-Replay-Auto Walk System
-- Clean, Simple, and User-Friendly

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService
    
    -- Create Tab
    local RecordTab = UI:Tab("Record & Replay")
    
    -- Section Label
    RecordTab:Label("📼 Record-Replay System")
    
    -- VARIABLES
    local RecordWidgetFrame = nil
    local IsRecording = false
    local IsPlaying = false
    local IsPaused = false
    local CurrentMap = nil
    local CurrentCP = "CP1"
    
    -- DATA STRUCTURE (SIMPLE & CLEAN)
    local RecordData = {}  -- Data sedang direkam
    local SavedData = {}   -- Data tersimpan
    
    -- ============================================
    -- 1️⃣ UI MINI DRAGGABLE
    -- ============================================
    local function CreateRecordWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        -- Main Widget Frame
        local Widget = Instance.new("Frame", screenGui)
        Widget.Name = "RecordWidget"
        Widget.Size = UDim2.new(0, 200, 0, 210)
        Widget.Position = UDim2.new(0.5, -100, 0.8, 0)
        Widget.BackgroundColor3 = Theme.Sidebar
        Widget.Visible = false
        Widget.ZIndex = 50
        
        local Corner = Instance.new("UICorner", Widget)
        Corner.CornerRadius = UDim.new(0, 8)
        
        local Stroke = Instance.new("UIStroke", Widget)
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 2
        
        -- Drag Handler
        local DragBtn = Instance.new("TextButton", Widget)
        DragBtn.Size = UDim2.new(1, 0, 0, 25)
        DragBtn.BackgroundColor3 = Theme.Button
        DragBtn.Text = "≡ Drag"
        DragBtn.TextColor3 = Theme.Text
        DragBtn.Font = Enum.Font.GothamBold
        DragBtn.TextSize = 10
        DragBtn.ZIndex = 51
        
        local Corner2 = Instance.new("UICorner", DragBtn)
        Corner2.CornerRadius = UDim.new(0, 6)
        
        -- Drag Function
        local function Drag(frame, handle)
            handle = handle or frame
            local dragging, dragStart, startPos
            
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or 
                   input.UserInputType == Enum.UserInputType.MouseButton1 then
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
            
            UserInputService.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or 
                    input.UserInputType == Enum.UserInputType.Touch) and dragging then
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
        
        Drag(Widget, DragBtn)
        
        -- Status Label
        local StatusLabel = Instance.new("TextLabel", Widget)
        StatusLabel.Size = UDim2.new(1, -10, 0, 20)
        StatusLabel.Position = UDim2.new(0, 5, 0, 30)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "Status: IDLE"
        StatusLabel.TextColor3 = Theme.Text
        StatusLabel.Font = Enum.Font.Gotham
        StatusLabel.TextSize = 11
        
        -- Map Selection
        local MapLabel = Instance.new("TextLabel", Widget)
        MapLabel.Size = UDim2.new(1, -10, 0, 15)
        MapLabel.Position = UDim2.new(0, 5, 0, 55)
        MapLabel.BackgroundTransparency = 1
        MapLabel.Text = "Map:"
        MapLabel.TextColor3 = Theme.Text
        MapLabel.Font = Enum.Font.Gotham
        MapLabel.TextSize = 10
        
        local MapInput = Instance.new("TextBox", Widget)
        MapInput.Size = UDim2.new(1, -10, 0, 20)
        MapInput.Position = UDim2.new(0, 5, 0, 70)
        MapInput.BackgroundColor3 = Theme.Button
        MapInput.TextColor3 = Theme.Text
        MapInput.Font = Enum.Font.Gotham
        MapInput.TextSize = 11
        MapInput.PlaceholderText = "Enter map name..."
        
        local MapCorner = Instance.new("UICorner", MapInput)
        MapCorner.CornerRadius = UDim.new(0, 4)
        
        -- CP Selection
        local CPLabel = Instance.new("TextLabel", Widget)
        CPLabel.Size = UDim2.new(1, -10, 0, 15)
        CPLabel.Position = UDim2.new(0, 5, 0, 95)
        CPLabel.BackgroundTransparency = 1
        CPLabel.Text = "Checkpoint:"
        CPLabel.TextColor3 = Theme.Text
        CPLabel.Font = Enum.Font.Gotham
        CPLabel.TextSize = 10
        
        local CPInput = Instance.new("TextBox", Widget)
        CPInput.Size = UDim2.new(1, -10, 0, 20)
        CPInput.Position = UDim2.new(0, 5, 0, 110)
        CPInput.BackgroundColor3 = Theme.Button
        CPInput.Text = "CP1"
        CPInput.TextColor3 = Theme.Text
        CPInput.Font = Enum.Font.Gotham
        CPInput.TextSize = 11
        
        local CPCorner = Instance.new("UICorner", CPInput)
        CPCorner.CornerRadius = UDim.new(0, 4)
        
        -- Button Container
        local ButtonContainer = Instance.new("Frame", Widget)
        ButtonContainer.Size = UDim2.new(1, -10, 0, 60)
        ButtonContainer.Position = UDim2.new(0, 5, 0, 140)
        ButtonContainer.BackgroundTransparency = 1
        
        -- Control Buttons
        local BtnRecord = Instance.new("TextButton", ButtonContainer)
        BtnRecord.Size = UDim2.new(0.48, 0, 0, 25)
        BtnRecord.Position = UDim2.new(0, 0, 0, 0)
        BtnRecord.BackgroundColor3 = Theme.ButtonRed
        BtnRecord.Text = "⏺ RECORD"
        BtnRecord.TextColor3 = Theme.Text
        BtnRecord.Font = Enum.Font.GothamBold
        BtnRecord.TextSize = 10
        
        local BtnPlay = Instance.new("TextButton", ButtonContainer)
        BtnPlay.Size = UDim2.new(0.48, 0, 0, 25)
        BtnPlay.Position = UDim2.new(0.52, 0, 0, 0)
        BtnPlay.BackgroundColor3 = Theme.Confirm
        BtnPlay.Text = "▶ PLAY"
        BtnPlay.TextColor3 = Theme.Text
        BtnPlay.Font = Enum.Font.GothamBold
        BtnPlay.TextSize = 10
        
        local BtnPause = Instance.new("TextButton", ButtonContainer)
        BtnPause.Size = UDim2.new(0.48, 0, 0, 25)
        BtnPause.Position = UDim2.new(0, 0, 0, 30)
        BtnPause.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        BtnPause.Text = "⏸ PAUSE"
        BtnPause.TextColor3 = Theme.Text
        BtnPause.Font = Enum.Font.GothamBold
        BtnPause.TextSize = 10
        
        local BtnSave = Instance.new("TextButton", ButtonContainer)
        BtnSave.Size = UDim2.new(0.48, 0, 0, 25)
        BtnSave.Position = UDim2.new(0.52, 0, 0, 30)
        BtnSave.BackgroundColor3 = Theme.Accent
        BtnSave.Text = "💾 SAVE"
        BtnSave.TextColor3 = Theme.Text
        BtnSave.Font = Enum.Font.GothamBold
        BtnSave.TextSize = 10
        
        -- Add corners to all buttons
        for _, btn in pairs({BtnRecord, BtnPlay, BtnPause, BtnSave}) do
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        end
        
        -- Store references
        RecordWidgetFrame = Widget
        
        -- ============================================
        -- BUTTON EVENTS
        -- ============================================
        
        -- RECORD Button
        BtnRecord.MouseButton1Click:Connect(function()
            IsRecording = not IsRecording
            
            if IsRecording then
                -- Start Recording
                CurrentMap = MapInput.Text
                CurrentCP = CPInput.Text
                
                if CurrentMap == "" then
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Error",
                        Text = "Enter map name first!",
                        Duration = 3
                    })
                    IsRecording = false
                    return
                end
                
                BtnRecord.Text = "⏹ STOP"
                BtnRecord.BackgroundColor3 = Theme.Button
                StatusLabel.Text = "Status: RECORDING " .. CurrentCP
                
                StartRecording()
            else
                -- Stop Recording
                BtnRecord.Text = "⏺ RECORD"
                BtnRecord.BackgroundColor3 = Theme.ButtonRed
                StatusLabel.Text = "Status: IDLE"
                
                StopRecording()
            end
        end)
        
        -- PLAY Button
        BtnPlay.MouseButton1Click:Connect(function()
            if IsPlaying then
                -- Stop playing
                BtnPlay.Text = "▶ PLAY"
                BtnPlay.BackgroundColor3 = Theme.Confirm
                StatusLabel.Text = "Status: IDLE"
                
                StopReplay()
            else
                -- Start playing
                CurrentMap = MapInput.Text
                CurrentCP = CPInput.Text
                
                if CurrentMap == "" then
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Error",
                        Text = "Enter map name first!",
                        Duration = 3
                    })
                    return
                end
                
                BtnPlay.Text = "⏹ STOP"
                BtnPlay.BackgroundColor3 = Theme.Button
                StatusLabel.Text = "Status: PLAYING " .. CurrentCP
                
                PlayReplay()
            end
        end)
        
        -- PAUSE Button
        BtnPause.MouseButton1Click:Connect(function()
            if IsPlaying then
                IsPaused = not IsPaused
                
                if IsPaused then
                    BtnPause.Text = "⏯ RESUME"
                    BtnPause.BackgroundColor3 = Theme.Confirm
                    StatusLabel.Text = "Status: PAUSED"
                else
                    BtnPause.Text = "⏸ PAUSE"
                    BtnPause.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                    StatusLabel.Text = "Status: PLAYING " .. CurrentCP
                end
            end
        end)
        
        -- SAVE Button
        BtnSave.MouseButton1Click:Connect(function()
            SaveCurrentRecord()
        end)
        
        return Widget
    end
    
    -- ============================================
    -- 2️⃣ RECORDING SYSTEM (SMOOTH & STABLE)
    -- ============================================
    local RecordConnection = nil
    local RecordStartTime = 0
    local LastFrameTime = 0
    
    function StartRecording()
        if not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Reset data
        RecordData = {
            Map = CurrentMap,
            CP = CurrentCP,
            Frames = {},
            StartTime = tick()
        }
        
        RecordStartTime = tick()
        LastFrameTime = 0
        
        -- Create recording loop
        RecordConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not IsRecording then return end
            if not LocalPlayer.Character then return end
            
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Calculate frame time
            local currentTime = tick() - RecordStartTime
            local timeDelta = currentTime - LastFrameTime
            
            -- Only record if significant movement or time passed
            if timeDelta > 0.05 then -- 20 FPS recording (smooth)
                local frame = {
                    Time = currentTime,
                    CFrame = root.CFrame,
                    Position = root.Position
                }
                
                table.insert(RecordData.Frames, frame)
                LastFrameTime = currentTime
            end
        end)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Recording",
            Text = "Started recording " .. CurrentCP,
            Duration = 2
        })
    end
    
    function StopRecording()
        if RecordConnection then
            RecordConnection:Disconnect()
            RecordConnection = nil
        end
        
        if #RecordData.Frames > 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Recording",
                Text = string.format("Recorded %d frames", #RecordData.Frames),
                Duration = 3
            })
        else
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Recording",
                Text = "No frames recorded",
                Duration = 3
            })
        end
    end
    
    -- ============================================
    -- 3️⃣ CHECKPOINT SYSTEM (EDITABLE)
    -- ============================================
    local Checkpoints = {}
    local CurrentCheckpointIndex = 1
    
    -- Auto-detect checkpoints
    local function SetupCheckpointDetection()
        -- This function would detect checkpoint parts in the game
        -- For now, we'll use manual CP input
    end
    
    function AddCheckpoint(name)
        if not Checkpoints[name] then
            Checkpoints[name] = {
                Name = name,
                Index = #Checkpoints + 1,
                Data = {}
            }
            return true
        end
        return false
    end
    
    function RemoveCheckpoint(name)
        if Checkpoints[name] then
            Checkpoints[name] = nil
            return true
        end
        return false
    end
    
    -- ============================================
    -- 4️⃣ REPLAY SYSTEM (PLAY/PAUSE/RESUME)
    -- ============================================
    local PlayConnection = nil
    local CurrentFrameIndex = 1
    local ReplayStartTime = 0
    
    function PlayReplay()
        if not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Load saved data for this map and CP
        local replayData = SavedData[CurrentMap]
        if not replayData then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "No saved data for " .. CurrentMap,
                Duration = 3
            })
            return
        end
        
        local cpData = replayData[CurrentCP]
        if not cpData or #cpData == 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "No data for " .. CurrentCP,
                Duration = 3
            })
            return
        end
        
        IsPlaying = true
        IsPaused = false
        CurrentFrameIndex = 1
        ReplayStartTime = tick()
        
        -- Store original position for smooth return
        local originalCF = root.CFrame
        
        PlayConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not IsPlaying then return end
            if IsPaused then return end
            if not LocalPlayer.Character then return end
            
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Calculate current time in replay
            local currentReplayTime = tick() - ReplayStartTime
            
            -- Find current frame
            while CurrentFrameIndex <= #cpData and 
                  cpData[CurrentFrameIndex].Time < currentReplayTime do
                CurrentFrameIndex = CurrentFrameIndex + 1
            end
            
            if CurrentFrameIndex > #cpData then
                -- Replay finished
                StopReplay()
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Replay",
                    Text = "Finished playing",
                    Duration = 2
                })
                return
            end
            
            -- Apply smooth movement (lerp between frames)
            local currentFrame = cpData[CurrentFrameIndex]
            local nextFrame = cpData[math.min(CurrentFrameIndex + 1, #cpData)]
            
            if nextFrame then
                local t = (currentReplayTime - currentFrame.Time) / 
                         (nextFrame.Time - currentFrame.Time)
                t = math.clamp(t, 0, 1)
                
                -- Smooth interpolation
                local targetCF = currentFrame.CFrame:Lerp(nextFrame.CFrame, t)
                root.CFrame = root.CFrame:Lerp(targetCF, 0.3) -- Smooth follow
            else
                root.CFrame = root.CFrame:Lerp(currentFrame.CFrame, 0.3)
            end
        end)
    end
    
    function StopReplay()
        IsPlaying = false
        IsPaused = false
        
        if PlayConnection then
            PlayConnection:Disconnect()
            PlayConnection = nil
        end
        
        -- Reset to original position smoothly
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                -- No sudden teleport, just stop
            end
        end
    end
    
    -- ============================================
    -- 5️⃣ SAVE SYSTEM (SUPER SIMPLE)
    -- ============================================
    function SaveCurrentRecord()
        if #RecordData.Frames == 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Save",
                Text = "No data to save!",
                Duration = 3
            })
            return
        end
        
        if not CurrentMap then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Enter map name first!",
                Duration = 3
            })
            return
        end
        
        -- Initialize map data if not exists
        if not SavedData[CurrentMap] then
            SavedData[CurrentMap] = {}
        end
        
        -- Save checkpoint data
        SavedData[CurrentMap][CurrentCP] = RecordData.Frames
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Saved!",
            Text = string.format("%s/%s (%d frames)", CurrentMap, CurrentCP, #RecordData.Frames),
            Duration = 3
        })
        
        -- Update UI dropdowns
        UpdateMapList()
    end
    
    function LoadSavedData(mapName, cpName)
        if SavedData[mapName] and SavedData[mapName][cpName] then
            return SavedData[mapName][cpName]
        end
        return nil
    end
    
    -- ============================================
    -- 6️⃣ DELETE SYSTEM
    -- ============================================
    function DeleteCheckpoint(mapName, cpName)
        if SavedData[mapName] and SavedData[mapName][cpName] then
            SavedData[mapName][cpName] = nil
            
            -- If map is empty, remove it
            if next(SavedData[mapName]) == nil then
                SavedData[mapName] = nil
            end
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Deleted",
                Text = string.format("%s/%s", mapName, cpName),
                Duration = 3
            })
            
            return true
        end
        return false
    end
    
    function DeleteMap(mapName)
        if SavedData[mapName] then
            SavedData[mapName] = nil
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Deleted",
                Text = "Map: " .. mapName,
                Duration = 3
            })
            
            return true
        end
        return false
    end
    
    -- ============================================
    -- 7️⃣ AUTO WALK SYSTEM
    -- ============================================
    local AutoWalkActive = false
    local AutoWalkConnection = nil
    
    function StartAutoWalk(mapName, cpName)
        local walkData = LoadSavedData(mapName, cpName)
        if not walkData or #walkData == 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "No path data found",
                Duration = 3
            })
            return
        end
        
        AutoWalkActive = true
        local currentStep = 1
        
        AutoWalkConnection = RunService.Heartbeat:Connect(function()
            if not AutoWalkActive then return end
            if not LocalPlayer.Character then return end
            
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            if currentStep > #walkData then
                currentStep = 1  -- Loop back to start
            end
            
            local targetPos = walkData[currentStep].Position
            local distance = (root.Position - targetPos).Magnitude
            
            -- Move towards target
            if distance > 2 then
                local direction = (targetPos - root.Position).Unit
                root.Velocity = direction * 20  -- Walk speed
            else
                currentStep = currentStep + 1
            end
        end)
    end
    
    function StopAutoWalk()
        AutoWalkActive = false
        if AutoWalkConnection then
            AutoWalkConnection:Disconnect()
            AutoWalkConnection = nil
        end
        
        if LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.zero
            end
        end
    end
    
    -- ============================================
    -- 8️⃣ UI INTEGRATION
    -- ============================================
    
    -- Update Map List in UI
    local MapListContainer = nil
    local CPListContainer = nil
    
    function UpdateMapList()
        if MapListContainer then
            -- Clear existing
            for _, child in ipairs(MapListContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Add maps
            for mapName, _ in pairs(SavedData) do
                local btn = Instance.new("TextButton", MapListContainer)
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Theme.Button
                btn.Text = mapName
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                btn.MouseButton1Click:Connect(function()
                    UpdateCPList(mapName)
                end)
            end
        end
    end
    
    function UpdateCPList(mapName)
        if CPListContainer and SavedData[mapName] then
            -- Clear existing
            for _, child in ipairs(CPListContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Add checkpoints
            for cpName, _ in pairs(SavedData[mapName]) do
                local btn = Instance.new("TextButton", CPListContainer)
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Theme.ButtonDark
                btn.Text = cpName
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                -- Play button
                btn.MouseButton1Click:Connect(function()
                    CurrentMap = mapName
                    CurrentCP = cpName
                    PlayReplay()
                end)
                
                -- Delete button (right click)
                btn.MouseButton2Click:Connect(function()
                    UI:Confirm("Delete " .. cpName .. "?", function()
                        DeleteCheckpoint(mapName, cpName)
                        UpdateCPList(mapName)
                    end)
                end)
            end
        end
    end
    
    -- ============================================
    -- MAIN UI ELEMENTS
    -- ============================================
    
    -- Create containers for map and CP lists
    RecordTab:Label("📁 Saved Records")
    
    RecordTab:Label("Maps:")
    MapListContainer = RecordTab:Container(100)
    
    RecordTab:Label("Checkpoints:")
    CPListContainer = RecordTab:Container(150)
    
    -- Auto Walk Section
    RecordTab:Label("🚶 Auto Walk")
    
    RecordTab:Toggle("Enable Auto Walk", function(state)
        if state then
            if CurrentMap and CurrentCP then
                StartAutoWalk(CurrentMap, CurrentCP)
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Select map and CP first!",
                    Duration = 3
                })
            end
        else
            StopAutoWalk()
        end
    end)
    
    -- Management Buttons
    RecordTab:Button("🗑 Delete Current CP", Theme.ButtonRed, function()
        if CurrentMap and CurrentCP then
            UI:Confirm("Delete " .. CurrentCP .. "?", function()
                DeleteCheckpoint(CurrentMap, CurrentCP)
                UpdateCPList(CurrentMap)
            end)
        end
    end)
    
    RecordTab:Button("🗑 Delete Current Map", Theme.ButtonRed, function()
        if CurrentMap then
            UI:Confirm("Delete entire " .. CurrentMap .. "?", function()
                DeleteMap(CurrentMap)
                UpdateMapList()
            end)
        end
    end)
    
    RecordTab:Button("🔄 Refresh Lists", Theme.Button, function()
        UpdateMapList()
    end)
    
    -- Widget Toggle
    RecordTab:Toggle("Show Record Widget", function(state)
        if state then
            if not RecordWidgetFrame then
                CreateRecordWidget()
            end
            if RecordWidgetFrame then
                RecordWidgetFrame.Visible = true
            end
        else
            if RecordWidgetFrame then
                RecordWidgetFrame.Visible = false
            end
        end
    end)
    
    -- ============================================
    -- INITIALIZATION & CLEANUP
    -- ============================================
    
    -- Initialize on startup
    spawn(function()
        task.wait(1)
        UpdateMapList()
        
        -- Load from DataStore if available
        pcall(function()
            if readfile and isfile then
                local filePath = "Vanzyxxx_RecordData.json"
                if isfile(filePath) then
                    local json = readfile(filePath)
                    if json then
                        SavedData = Services.HttpService:JSONDecode(json)
                        UpdateMapList()
                    end
                end
            end
        end)
    end)
    
    -- Auto-save to file periodically
    local SaveConnection = RunService.Heartbeat:Connect(function()
        -- Save every 30 seconds if there's data
        if next(SavedData) and tick() % 30 < 0.1 then
            pcall(function()
                if writefile then
                    local json = Services.HttpService:JSONEncode(SavedData)
                    writefile("Vanzyxxx_RecordData.json", json)
                end
            end)
        end
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        -- Stop all systems
        IsRecording = false
        IsPlaying = false
        AutoWalkActive = false
        
        if RecordConnection then RecordConnection:Disconnect() end
        if PlayConnection then PlayConnection:Disconnect() end
        if AutoWalkConnection then AutoWalkConnection:Disconnect() end
        if SaveConnection then SaveConnection:Disconnect() end
        
        if RecordWidgetFrame then
            RecordWidgetFrame:Destroy()
            RecordWidgetFrame = nil
        end
        
        -- Save data before exit
        pcall(function()
            if writefile then
                local json = Services.HttpService:JSONEncode(SavedData)
                writefile("Vanzyxxx_RecordData.json", json)
            end
        end)
    end)
    
    print("[Vanzyxxx] Record-Replay-AutoWalk System loaded!")
end