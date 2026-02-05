-- Vanzyxxx Record-Replay-Auto Walk System
-- Clean, Simple, and User-Friendly

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService
    local TweenService = Services.TweenService
    
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
    -- 1️⃣ UI MINI DRAGGABLE - VERSION FIXED
    -- ============================================
    local function CreateRecordWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        -- Main Widget Frame (sedikit lebih besar untuk button horizontal)
        local Widget = Instance.new("Frame", screenGui)
        Widget.Name = "RecordWidget"
        Widget.Size = UDim2.new(0, 280, 0, 140)
        Widget.Position = UDim2.new(0.5, -140, 0.8, 0)
        Widget.BackgroundColor3 = Theme.Sidebar
        Widget.BackgroundTransparency = 0.2
        Widget.Visible = false
        Widget.ZIndex = 50
        
        local Corner = Instance.new("UICorner", Widget)
        Corner.CornerRadius = UDim.new(0, 12)
        
        local Stroke = Instance.new("UIStroke", Widget)
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 2
        
        -- Title Bar dengan Drag
        local TitleBar = Instance.new("Frame", Widget)
        TitleBar.Size = UDim2.new(1, 0, 0, 30)
        TitleBar.BackgroundColor3 = Theme.Accent
        TitleBar.BackgroundTransparency = 0.3
        
        local TitleCorner = Instance.new("UICorner", TitleBar)
        TitleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
        
        local TitleLabel = Instance.new("TextLabel", TitleBar)
        TitleLabel.Size = UDim2.new(1, 0, 1, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = "🎥 RECORD CONTROLLER"
        TitleLabel.TextColor3 = Theme.Text
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 12
        
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
        
        Drag(Widget, TitleBar)
        
        -- Status Display
        local StatusContainer = Instance.new("Frame", Widget)
        StatusContainer.Size = UDim2.new(1, -20, 0, 25)
        StatusContainer.Position = UDim2.new(0, 10, 0, 35)
        StatusContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        StatusContainer.BackgroundTransparency = 0.5
        
        local StatusCorner = Instance.new("UICorner", StatusContainer)
        StatusCorner.CornerRadius = UDim.new(0, 6)
        
        local StatusLabel = Instance.new("TextLabel", StatusContainer)
        StatusLabel.Size = UDim2.new(1, 0, 1, 0)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "🟢 IDLE"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
        StatusLabel.Font = Enum.Font.GothamBold
        StatusLabel.TextSize = 11
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatusLabel.PaddingLeft = UDim.new(0, 8)
        
        -- Map & CP Input Row
        local InputRow = Instance.new("Frame", Widget)
        InputRow.Size = UDim2.new(1, -20, 0, 30)
        InputRow.Position = UDim2.new(0, 10, 0, 65)
        InputRow.BackgroundTransparency = 1
        
        -- Map Input
        local MapFrame = Instance.new("Frame", InputRow)
        MapFrame.Size = UDim2.new(0.48, 0, 1, 0)
        MapFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        
        local MapCorner = Instance.new("UICorner", MapFrame)
        MapCorner.CornerRadius = UDim.new(0, 4)
        
        local MapLabel = Instance.new("TextLabel", MapFrame)
        MapLabel.Size = UDim2.new(0.3, 0, 1, 0)
        MapLabel.BackgroundTransparency = 1
        MapLabel.Text = "MAP:"
        MapLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        MapLabel.Font = Enum.Font.GothamBold
        MapLabel.TextSize = 10
        
        local MapInput = Instance.new("TextBox", MapFrame)
        MapInput.Size = UDim2.new(0.65, 0, 1, 0)
        MapInput.Position = UDim2.new(0.35, 0, 0, 0)
        MapInput.BackgroundTransparency = 1
        MapInput.TextColor3 = Theme.Text
        MapInput.Font = Enum.Font.Gotham
        MapInput.TextSize = 11
        MapInput.PlaceholderText = "Map Name"
        MapInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        
        -- CP Input
        local CPFrame = Instance.new("Frame", InputRow)
        CPFrame.Size = UDim2.new(0.48, 0, 1, 0)
        CPFrame.Position = UDim2.new(0.52, 0, 0, 0)
        CPFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        
        local CPCorner = Instance.new("UICorner", CPFrame)
        CPCorner.CornerRadius = UDim.new(0, 4)
        
        local CPLabel = Instance.new("TextLabel", CPFrame)
        CPLabel.Size = UDim2.new(0.3, 0, 1, 0)
        CPLabel.BackgroundTransparency = 1
        CPLabel.Text = "CP:"
        CPLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        CPLabel.Font = Enum.Font.GothamBold
        CPLabel.TextSize = 10
        
        local CPInput = Instance.new("TextBox", CPFrame)
        CPInput.Size = UDim2.new(0.65, 0, 1, 0)
        CPInput.Position = UDim2.new(0.35, 0, 0, 0)
        CPInput.BackgroundTransparency = 1
        CPInput.Text = "CP1"
        CPInput.TextColor3 = Theme.Text
        CPInput.Font = Enum.Font.Gotham
        CPInput.TextSize = 11
        
        -- BUTTON CONTAINER (HORIZONTAL LAYOUT)
        local ButtonContainer = Instance.new("Frame", Widget)
        ButtonContainer.Size = UDim2.new(1, -20, 0, 40)
        ButtonContainer.Position = UDim2.new(0, 10, 0, 100)
        ButtonContainer.BackgroundTransparency = 1
        
        -- First Row of Buttons (Record, Play, Pause)
        local ButtonRow1 = Instance.new("Frame", ButtonContainer)
        ButtonRow1.Size = UDim2.new(1, 0, 0.5, 0)
        ButtonRow1.BackgroundTransparency = 1
        
        -- Record Button
        local BtnRecord = Instance.new("TextButton", ButtonRow1)
        BtnRecord.Size = UDim2.new(0.32, 0, 1, -2)
        BtnRecord.Position = UDim2.new(0, 0, 0, 0)
        BtnRecord.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        BtnRecord.Text = "⏺ RECORD"
        BtnRecord.TextColor3 = Color3.new(1, 1, 1)
        BtnRecord.Font = Enum.Font.GothamBold
        BtnRecord.TextSize = 10
        BtnRecord.ZIndex = 51
        
        local RecordCorner = Instance.new("UICorner", BtnRecord)
        RecordCorner.CornerRadius = UDim.new(0, 6)
        
        -- Play Button
        local BtnPlay = Instance.new("TextButton", ButtonRow1)
        BtnPlay.Size = UDim2.new(0.32, 0, 1, -2)
        BtnPlay.Position = UDim2.new(0.34, 0, 0, 0)
        BtnPlay.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        BtnPlay.Text = "▶ PLAY"
        BtnPlay.TextColor3 = Color3.new(1, 1, 1)
        BtnPlay.Font = Enum.Font.GothamBold
        BtnPlay.TextSize = 10
        BtnPlay.ZIndex = 51
        
        local PlayCorner = Instance.new("UICorner", BtnPlay)
        PlayCorner.CornerRadius = UDim.new(0, 6)
        
        -- Pause Button
        local BtnPause = Instance.new("TextButton", ButtonRow1)
        BtnPause.Size = UDim2.new(0.32, 0, 1, -2)
        BtnPause.Position = UDim2.new(0.68, 0, 0, 0)
        BtnPause.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        BtnPause.Text = "⏸ PAUSE"
        BtnPause.TextColor3 = Color3.new(1, 1, 1)
        BtnPause.Font = Enum.Font.GothamBold
        BtnPause.TextSize = 10
        BtnPause.ZIndex = 51
        
        local PauseCorner = Instance.new("UICorner", BtnPause)
        PauseCorner.CornerRadius = UDim.new(0, 6)
        
        -- Second Row of Buttons (Stop, Replay, Save)
        local ButtonRow2 = Instance.new("Frame", ButtonContainer)
        ButtonRow2.Size = UDim2.new(1, 0, 0.5, 0)
        ButtonRow2.Position = UDim2.new(0, 0, 0.5, 0)
        ButtonRow2.BackgroundTransparency = 1
        
        -- Stop Button
        local BtnStop = Instance.new("TextButton", ButtonRow2)
        BtnStop.Size = UDim2.new(0.32, 0, 1, -2)
        BtnStop.Position = UDim2.new(0, 0, 0, 0)
        BtnStop.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        BtnStop.Text = "⏹ STOP"
        BtnStop.TextColor3 = Color3.new(1, 1, 1)
        BtnStop.Font = Enum.Font.GothamBold
        BtnStop.TextSize = 10
        BtnStop.ZIndex = 51
        
        local StopCorner = Instance.new("UICorner", BtnStop)
        StopCorner.CornerRadius = UDim.new(0, 6)
        
        -- Replay Button
        local BtnReplay = Instance.new("TextButton", ButtonRow2)
        BtnReplay.Size = UDim2.new(0.32, 0, 1, -2)
        BtnReplay.Position = UDim2.new(0.34, 0, 0, 0)
        BtnReplay.BackgroundColor3 = Color3.fromRGB(90, 120, 220)
        BtnReplay.Text = "↺ REPLAY"
        BtnReplay.TextColor3 = Color3.new(1, 1, 1)
        BtnReplay.Font = Enum.Font.GothamBold
        BtnReplay.TextSize = 10
        BtnReplay.ZIndex = 51
        
        local ReplayCorner = Instance.new("UICorner", BtnReplay)
        ReplayCorner.CornerRadius = UDim.new(0, 6)
        
        -- Save Button
        local BtnSave = Instance.new("TextButton", ButtonRow2)
        BtnSave.Size = UDim2.new(0.32, 0, 1, -2)
        BtnSave.Position = UDim2.new(0.68, 0, 0, 0)
        BtnSave.BackgroundColor3 = Theme.Accent
        BtnSave.Text = "💾 SAVE"
        BtnSave.TextColor3 = Color3.new(1, 1, 1)
        BtnSave.Font = Enum.Font.GothamBold
        BtnSave.TextSize = 10
        BtnSave.ZIndex = 51
        
        local SaveCorner = Instance.new("UICorner", BtnSave)
        SaveCorner.CornerRadius = UDim.new(0, 6)
        
        -- Store references
        RecordWidgetFrame = Widget
        
        -- Function untuk update status
        local function UpdateStatus(text, color)
            StatusLabel.Text = text
            StatusLabel.TextColor3 = color or Color3.fromRGB(200, 255, 200)
        end
        
        -- ============================================
        -- BUTTON EVENTS - IMPROVED
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
                BtnRecord.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                UpdateStatus("🔴 RECORDING " .. CurrentCP, Color3.fromRGB(255, 100, 100))
                
                StartRecording()
            else
                -- Stop Recording
                BtnRecord.Text = "⏺ RECORD"
                BtnRecord.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
                UpdateStatus("🟢 IDLE", Color3.fromRGB(200, 255, 200))
                
                StopRecording()
            end
        end)
        
        -- PLAY Button
        BtnPlay.MouseButton1Click:Connect(function()
            if IsPlaying and not IsPaused then
                -- Already playing, pause it
                IsPaused = true
                BtnPlay.Text = "▶ RESUME"
                BtnPlay.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
                UpdateStatus("⏸ PAUSED", Color3.fromRGB(255, 200, 100))
            else
                -- Start or resume playing
                if not IsPlaying then
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
                    
                    IsPlaying = true
                end
                
                IsPaused = false
                BtnPlay.Text = "⏸ PAUSE"
                BtnPlay.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                UpdateStatus("▶ PLAYING " .. CurrentCP, Color3.fromRGB(100, 255, 100))
                
                if IsPlaying then
                    PlayReplay()
                end
            end
        end)
        
        -- PAUSE Button (alternative to Play's pause)
        BtnPause.MouseButton1Click:Connect(function()
            if IsPlaying then
                IsPaused = not IsPaused
                
                if IsPaused then
                    BtnPause.Text = "▶ RESUME"
                    BtnPause.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
                    UpdateStatus("⏸ PAUSED", Color3.fromRGB(255, 200, 100))
                else
                    BtnPause.Text = "⏸ PAUSE"
                    BtnPause.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                    UpdateStatus("▶ PLAYING " .. CurrentCP, Color3.fromRGB(100, 255, 100))
                end
            end
        end)
        
        -- STOP Button
        BtnStop.MouseButton1Click:Connect(function()
            if IsPlaying or IsRecording then
                IsPlaying = false
                IsRecording = false
                IsPaused = false
                
                -- Reset all buttons
                BtnRecord.Text = "⏺ RECORD"
                BtnRecord.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
                
                BtnPlay.Text = "▶ PLAY"
                BtnPlay.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
                
                BtnPause.Text = "⏸ PAUSE"
                BtnPause.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                
                UpdateStatus("🟢 IDLE", Color3.fromRGB(200, 255, 200))
                
                StopReplay()
                StopRecording()
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Stopped",
                    Text = "All actions stopped",
                    Duration = 2
                })
            end
        end)
        
        -- REPLAY Button (restart from beginning)
        BtnReplay.MouseButton1Click:Connect(function()
            if IsPlaying then
                StopReplay()
                task.wait(0.1)
            end
            
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
            
            IsPlaying = true
            IsPaused = false
            
            BtnPlay.Text = "⏸ PAUSE"
            BtnPlay.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            UpdateStatus("↺ REPLAYING " .. CurrentCP, Color3.fromRGB(100, 200, 255))
            
            PlayReplay()
        end)
        
        -- SAVE Button
        BtnSave.MouseButton1Click:Connect(function()
            SaveCurrentRecord()
        end)
        
        -- Hover effects untuk semua button
        local function AddHoverEffect(button, normalColor, hoverColor)
            local originalSize = button.Size
            local hoverTween
            
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = hoverColor
                hoverTween = TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize + UDim2.new(0, 2, 0, 2)})
                hoverTween:Play()
            end)
            
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = normalColor
                if hoverTween then hoverTween:Cancel() end
                button.Size = originalSize
            end)
        end
        
        -- Apply hover effects
        AddHoverEffect(BtnRecord, Color3.fromRGB(220, 60, 60), Color3.fromRGB(240, 80, 80))
        AddHoverEffect(BtnPlay, Color3.fromRGB(60, 180, 60), Color3.fromRGB(80, 200, 80))
        AddHoverEffect(BtnPause, Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 190, 30))
        AddHoverEffect(BtnStop, Color3.fromRGB(80, 80, 80), Color3.fromRGB(100, 100, 100))
        AddHoverEffect(BtnReplay, Color3.fromRGB(90, 120, 220), Color3.fromRGB(110, 140, 240))
        AddHoverEffect(BtnSave, Theme.Accent, Color3.fromRGB(
            math.min(Theme.Accent.R * 255 + 30, 255)/255,
            math.min(Theme.Accent.G * 255 + 30, 255)/255,
            math.min(Theme.Accent.B * 255 + 30, 255)/255
        ))
        
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
                    Position = root.Position,
                    Velocity = root.Velocity
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
        end
    end
    
    -- ============================================
    -- 3️⃣ CHECKPOINT SYSTEM (EDITABLE)
    -- ============================================
    local Checkpoints = {}
    local CurrentCheckpointIndex = 1
    
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
    -- 4️⃣ REPLAY SYSTEM (PLAY/PAUSE/RESUME/STOP)
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
            IsPlaying = false
            return
        end
        
        local cpData = replayData[CurrentCP]
        if not cpData or #cpData == 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "No data for " .. CurrentCP,
                Duration = 3
            })
            IsPlaying = false
            return
        end
        
        IsPlaying = true
        IsPaused = false
        CurrentFrameIndex = 1
        ReplayStartTime = tick()
        
        PlayConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not IsPlaying then 
                if PlayConnection then PlayConnection:Disconnect() end
                return 
            end
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
                root.CFrame = root.CFrame:Lerp(targetCF, 0.5)
            else
                root.CFrame = currentFrame.CFrame
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
    end
    
    -- ============================================
    -- 5️⃣ SAVE SYSTEM (SUPER SIMPLE)
    -- ============================================
    function SaveCurrentRecord()
        if #RecordData.Frames == 0 then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Save",
                Text = "No data to save! Record first!",
                Duration = 3
            })
            return
        end
        
        if not CurrentMap or CurrentMap == "" then
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
            Title = "💾 SAVED!",
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
                Title = "🗑 Deleted",
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
                Title = "🗑 Deleted",
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
                root.Velocity = direction * 16  -- Walk speed
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
                btn.Text = "🗺 " .. mapName
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                btn.MouseButton1Click:Connect(function()
                    UpdateCPList(mapName)
                end)
                
                -- Delete on right click
                btn.MouseButton2Click:Connect(function()
                    UI:Confirm("Delete entire " .. mapName .. "?", function()
                        DeleteMap(mapName)
                        UpdateMapList()
                    end)
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
                btn.Text = "📍 " .. cpName
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                -- Play button
                btn.MouseButton1Click:Connect(function()
                    CurrentMap = mapName
                    CurrentCP = cpName
                    
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Selected",
                        Text = string.format("%s/%s", mapName, cpName),
                        Duration = 2
                    })
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
    
    local AutoWalkToggle = RecordTab:Toggle("Enable Auto Walk", function(state)
        if state then
            if CurrentMap and CurrentCP then
                StartAutoWalk(CurrentMap, CurrentCP)
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Auto Walk",
                    Text = "Started following path",
                    Duration = 2
                })
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Select map and CP first!",
                    Duration = 3
                })
                AutoWalkToggle:SetState(false)
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
    
    RecordTab:Button("📋 Export Data", Theme.Accent, function()
        local count = 0
        for mapName, mapData in pairs(SavedData) do
            for cpName, cpData in pairs(mapData) do
                count = count + #cpData
            end
        end
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Data Info",
            Text = string.format("%d maps, %d total frames", 
                #(SavedData and {} or {}), count),
            Duration = 4
        })
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
    
    -- Quick Play Section
    RecordTab:Label("⚡ Quick Actions")
    
    local QuickInputRow = Instance.new("Frame", RecordTab:Container(40))
    QuickInputRow.Size = UDim2.new(1, 0, 1, 0)
    QuickInputRow.BackgroundTransparency = 1
    
    local QuickMapInput = Instance.new("TextBox", QuickInputRow)
    QuickMapInput.Size = UDim2.new(0.4, 0, 1, 0)
    QuickMapInput.PlaceholderText = "Map"
    QuickMapInput.BackgroundColor3 = Theme.Button
    QuickMapInput.TextColor3 = Theme.Text
    QuickMapInput.Font = Enum.Font.Gotham
    QuickMapInput.TextSize = 11
    
    local QuickCPInput = Instance.new("TextBox", QuickInputRow)
    QuickCPInput.Size = UDim2.new(0.3, 0, 1, 0)
    QuickCPInput.Position = UDim2.new(0.42, 0, 0, 0)
    QuickCPInput.Text = "CP1"
    QuickCPInput.BackgroundColor3 = Theme.Button
    QuickCPInput.TextColor3 = Theme.Text
    QuickCPInput.Font = Enum.Font.Gotham
    QuickCPInput.TextSize = 11
    
    local QuickPlayBtn = Instance.new("TextButton", QuickInputRow)
    QuickPlayBtn.Size = UDim2.new(0.25, 0, 1, 0)
    QuickPlayBtn.Position = UDim2.new(0.74, 0, 0, 0)
    QuickPlayBtn.BackgroundColor3 = Theme.Confirm
    QuickPlayBtn.Text = "▶ PLAY"
    QuickPlayBtn.TextColor3 = Theme.Text
    QuickPlayBtn.Font = Enum.Font.GothamBold
    QuickPlayBtn.TextSize = 11
    
    QuickPlayBtn.MouseButton1Click:Connect(function()
        CurrentMap = QuickMapInput.Text
        CurrentCP = QuickCPInput.Text
        
        if CurrentMap == "" then return end
        
        IsPlaying = true
        IsPaused = false
        PlayReplay()
    end)
    
    -- Add corners
    for _, obj in pairs({QuickMapInput, QuickCPInput, QuickPlayBtn}) do
        Instance.new("UICorner", obj).CornerRadius = UDim.new(0, 4)
    end
    
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
                        
                        Services.StarterGui:SetCore("SendNotification", {
                            Title = "Loaded",
                            Text = "Record data loaded from file",
                            Duration = 2
                        })
                    end
                end
            end
        end)
    end)
    
    -- Auto-save to file periodically
    local SaveConnection = RunService.Heartbeat:Connect(function()
        -- Save every 60 seconds if there's data
        if next(SavedData) and tick() % 60 < 0.1 then
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
        IsPaused = false
        
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
    print("[Vanzyxxx] Widget Layout: 6 buttons horizontal (Record, Play, Pause, Stop, Replay, Save)")
end