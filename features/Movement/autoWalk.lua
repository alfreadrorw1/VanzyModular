-- Vanzyxxx Record & Replay System
-- Full Modular dengan Auto-Walk Map System

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    
    -- Create Tab
    local RecordTab = UI:Tab("Record&Replay")
    RecordTab:Label("🎬 Motion Capture System")
    
    -- ================================
    -- DATA STRUCTURES
    -- ================================
    
    -- Struktur data per frame
    -- {
    --   time = tick(),
    --   position = Vector3.new(x, y, z),
    --   lookVector = Vector3.new(x, 0, z), -- Arah hadap (horizontal only)
    --   checkpoint = nil, -- Nama checkpoint jika ada
    --   checkpointIndex = 0 -- Index checkpoint
    -- }
    
    -- Struktur data recording
    -- {
    --   mapName = "Map Name",
    --   mapId = 123456789,
    --   totalFrames = 0,
    --   duration = 0,
    --   checkpoints = {}, -- Table checkpoint {name, frameIndex}
    --   frames = {} -- Table frame data
    -- }
    
    -- ================================
    -- GLOBAL VARIABLES
    -- ================================
    local RecordingData = {
        isRecording = false,
        isPlaying = false,
        isAutoWalking = false,
        currentRecording = nil,
        currentPlaybackIndex = 1,
        frameData = {},
        recordingsList = {},
        connection = nil,
        playbackConnection = nil,
        autoWalkConnection = nil
    }
    
    local Storage = {
        FileName = "VanzyRecordings.json",
        MaxRecordings = 20
    }
    
    -- ================================
    -- RECORDING FUNCTIONS
    -- ================================
    
    -- Fungsi untuk memulai recording
    local function StartRecording()
        if RecordingData.isRecording then return end
        
        RecordingData.isRecording = true
        RecordingData.frameData = {}
        RecordingData.currentRecording = {
            mapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            mapId = game.PlaceId,
            startTime = tick(),
            totalFrames = 0,
            duration = 0,
            checkpoints = {},
            frames = {}
        }
        
        -- Setup recording connection
        RecordingData.connection = RunService.Heartbeat:Connect(function(deltaTime)
            local char = LocalPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            -- Dapatkan posisi dan arah hadap
            local position = root.Position
            local lookVector = root.CFrame.LookVector * Vector3.new(1, 0, 1) -- Horizontal only
            
            -- Simpan frame dengan interpolasi smooth
            local frame = {
                time = tick(),
                position = position,
                lookVector = lookVector.Unit, -- Normalize
                velocity = root.Velocity,
                checkpoint = nil,
                checkpointIndex = 0
            }
            
            -- Deteksi checkpoint otomatis
            DetectCheckpoint(frame)
            
            table.insert(RecordingData.frameData, frame)
            RecordingData.currentRecording.totalFrames = RecordingData.currentRecording.totalFrames + 1
        end)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "🎬 RECORDING STARTED",
            Text = "Recording movement...",
            Duration = 3
        })
    end
    
    -- Fungsi deteksi checkpoint otomatis
    local function DetectCheckpoint(frame)
        -- Logic deteksi checkpoint bisa dikustomisasi
        -- Contoh: Deteksi berdasarkan area/part tertentu
        local char = LocalPlayer.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Cek collision dengan part bernama "Checkpoint"
        local region = Region3.new(root.Position - Vector3.new(5,5,5), root.Position + Vector3.new(5,5,5))
        local parts = Services.Workspace:FindPartsInRegion3(region, char, 100)
        
        for _, part in ipairs(parts) do
            if part.Name:match("Checkpoint") or part.Name:match("CP") or part.Name:match("Spawn") then
                local cpName = part.Name
                local cpIndex = #RecordingData.currentRecording.checkpoints + 1
                
                frame.checkpoint = cpName
                frame.checkpointIndex = cpIndex
                
                table.insert(RecordingData.currentRecording.checkpoints, {
                    name = cpName,
                    frameIndex = #RecordingData.frameData,
                    position = root.Position,
                    time = tick() - RecordingData.currentRecording.startTime
                })
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "📍 CHECKPOINT",
                    Text = cpName .. " detected!",
                    Duration = 2
                })
                break
            end
        end
    end
    
    -- Fungsi menghentikan recording
    local function StopRecording()
        if not RecordingData.isRecording then return end
        
        RecordingData.isRecording = false
        
        if RecordingData.connection then
            RecordingData.connection:Disconnect()
            RecordingData.connection = nil
        end
        
        -- Finalize recording data
        RecordingData.currentRecording.duration = tick() - RecordingData.currentRecording.startTime
        RecordingData.currentRecording.frames = RecordingData.frameData
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "✅ RECORDING STOPPED",
            Text = string.format("Recorded %d frames (%.1fs)", 
                RecordingData.currentRecording.totalFrames,
                RecordingData.currentRecording.duration),
            Duration = 5
        })
    end
    
    -- Fungsi menyimpan recording
    local function SaveRecording(recordingName)
        if not RecordingData.currentRecording then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "⚠️ ERROR",
                Text = "No recording to save!",
                Duration = 3
            })
            return
        end
        
        -- Load existing recordings
        local allRecordings = LoadRecordings()
        
        -- Add new recording
        local saveData = RecordingData.currentRecording
        saveData.name = recordingName or ("Recording_" .. os.date("%Y%m%d_%H%M%S"))
        saveData.saveTime = os.date("%Y-%m-%d %H:%M:%S")
        
        -- Optimize data size (optional: compress positions)
        for i, frame in ipairs(saveData.frames) do
            -- Round position values to reduce file size
            frame.position = Vector3.new(
                math.round(frame.position.X * 100) / 100,
                math.round(frame.position.Y * 100) / 100,
                math.round(frame.position.Z * 100) / 100
            )
        end
        
        table.insert(allRecordings, saveData)
        
        -- Limit number of recordings
        if #allRecordings > Storage.MaxRecordings then
            table.remove(allRecordings, 1)
        end
        
        -- Save to file
        if writefile then
            local success, err = pcall(function()
                writefile(Storage.FileName, HttpService:JSONEncode(allRecordings))
            end)
            
            if success then
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "💾 SAVED",
                    Text = saveData.name .. " saved!",
                    Duration = 3
                })
                RecordingData.recordingsList = allRecordings
                UpdateRecordingsList()
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "❌ SAVE FAILED",
                    Text = "Error: " .. tostring(err),
                    Duration = 5
                })
            end
        end
    end
    
    -- ================================
    -- REPLAY FUNCTIONS
    -- ================================
    
    -- Fungsi memainkan recording
    local function PlayRecording(recordingData, startFromCheckpoint)
        if RecordingData.isPlaying then return end
        
        RecordingData.isPlaying = true
        RecordingData.currentPlaybackIndex = 1
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Cari starting point berdasarkan checkpoint
        if startFromCheckpoint and #recordingData.checkpoints > 0 then
            for i, cp in ipairs(recordingData.checkpoints) do
                if cp.name == startFromCheckpoint then
                    RecordingData.currentPlaybackIndex = cp.frameIndex
                    break
                end
            end
        end
        
        -- Setup playback dengan interpolasi smooth
        RecordingData.playbackConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not RecordingData.isPlaying then return end
            
            local frames = recordingData.frames
            if RecordingData.currentPlaybackIndex > #frames then
                StopPlayback()
                return
            end
            
            local currentFrame = frames[RecordingData.currentPlaybackIndex]
            local nextFrame = frames[RecordingData.currentPlaybackIndex + 1]
            
            if currentFrame and root then
                -- Interpolasi posisi untuk smooth movement
                local targetPosition = currentFrame.position
                
                if nextFrame then
                    -- Linear interpolation antara frame saat ini dan berikutnya
                    local lerpAlpha = 0.3 -- Adjust untuk smoothness
                    targetPosition = currentFrame.position:Lerp(nextFrame.position, lerpAlpha)
                end
                
                -- Terapkan posisi dengan physics yang aman
                root.CFrame = CFrame.new(targetPosition) * 
                    CFrame.lookAt(targetPosition, targetPosition + currentFrame.lookVector)
                
                -- Lock velocity untuk mencegah physics error
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                
                RecordingData.currentPlaybackIndex = RecordingData.currentPlaybackIndex + 1
            end
        end)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "▶️ PLAYBACK STARTED",
            Text = "Playing recording...",
            Duration = 3
        })
    end
    
    -- Fungsi menghentikan playback
    local function StopPlayback()
        RecordingData.isPlaying = false
        
        if RecordingData.playbackConnection then
            RecordingData.playbackConnection:Disconnect()
            RecordingData.playbackConnection = nil
        end
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "⏹️ PLAYBACK STOPPED",
            Text = "Playback finished",
            Duration = 3
        })
    end
    
    -- ================================
    -- AUTO WALK SYSTEM
    -- ================================
    
    local function StartAutoWalk(recordingData)
        if RecordingData.isAutoWalking then return end
        
        RecordingData.isAutoWalking = true
        RecordingData.currentPlaybackIndex = 1
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not root or not humanoid then return end
        
        RecordingData.autoWalkConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not RecordingData.isAutoWalking then return end
            
            local frames = recordingData.frames
            if RecordingData.currentPlaybackIndex > #frames then
                StopAutoWalk()
                return
            end
            
            local currentFrame = frames[RecordingData.currentPlaybackIndex]
            local nextFrame = frames[RecordingData.currentPlaybackIndex + 1]
            
            if currentFrame then
                -- Calculate movement direction
                local targetPosition = currentFrame.position
                local currentPosition = root.Position
                
                -- Calculate direction vector
                local direction = (targetPosition - currentPosition)
                local distance = direction.Magnitude
                
                if distance > 1 then -- Jika jarak lebih dari 1 stud
                    -- Normalize direction dan terapkan ke humanoid
                    direction = direction.Unit
                    
                    -- Set move direction (natural walking)
                    humanoid:MoveTo(targetPosition)
                    
                    -- Interpolasi rotation untuk smooth turning
                    local targetLook = currentFrame.lookVector
                    local currentLook = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                    
                    if targetLook.Magnitude > 0 and currentLook.Magnitude > 0 then
                        local rotation = CFrame.lookAt(Vector3.zero, targetLook):Lerp(
                            CFrame.lookAt(Vector3.zero, currentLook), 0.7
                        )
                        root.CFrame = CFrame.new(root.Position) * rotation
                    end
                end
                
                RecordingData.currentPlaybackIndex = RecordingData.currentPlaybackIndex + 1
                
                -- Speed control (skip frames untuk kontrol kecepatan)
                if RecordingData.currentPlaybackIndex % 2 == 0 then
                    RecordingData.currentPlaybackIndex = RecordingData.currentPlaybackIndex + 1
                end
            end
        end)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "🚶 AUTO WALK",
            Text = "Auto walk started",
            Duration = 3
        })
    end
    
    local function StopAutoWalk()
        RecordingData.isAutoWalking = false
        
        if RecordingData.autoWalkConnection then
            RecordingData.autoWalkConnection:Disconnect()
            RecordingData.autoWalkConnection = nil
        end
        
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:MoveTo(char.PrimaryPart.Position) -- Stop movement
            end
        end
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "🛑 AUTO WALK STOPPED",
            Text = "Auto walk finished",
            Duration = 3
        })
    end
    
    -- ================================
    -- STORAGE FUNCTIONS
    -- ================================
    
    local function LoadRecordings()
        if not isfile or not isfile(Storage.FileName) then
            return {}
        end
        
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(Storage.FileName))
        end)
        
        return success and data or {}
    end
    
    local function DeleteRecording(index)
        local allRecordings = LoadRecordings()
        
        if index >= 1 and index <= #allRecordings then
            table.remove(allRecordings, index)
            
            if writefile then
                pcall(function()
                    writefile(Storage.FileName, HttpService:JSONEncode(allRecordings))
                end)
            end
            
            RecordingData.recordingsList = allRecordings
            UpdateRecordingsList()
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "🗑️ DELETED",
                Text = "Recording deleted",
                Duration = 3
            })
        end
    end
    
    -- ================================
    -- UI ELEMENTS
    -- ================================
    
    local RecordingsContainer = nil
    local SelectedRecording = nil
    
    local function UpdateRecordingsList()
        if not RecordingsContainer then return end
        
        -- Clear container
        for _, child in ipairs(RecordingsContainer:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        RecordingData.recordingsList = LoadRecordings()
        
        if #RecordingData.recordingsList == 0 then
            local emptyLabel = Instance.new("TextLabel", RecordingsContainer)
            emptyLabel.Size = UDim2.new(1, 0, 0, 30)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No recordings saved yet"
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextSize = 12
            return
        end
        
        for i, recording in ipairs(RecordingData.recordingsList) do
            local frame = Instance.new("Frame", RecordingsContainer)
            frame.Size = UDim2.new(1, 0, 0, 35)
            frame.BackgroundColor3 = Theme.Button
            frame.ZIndex = 50
            
            local corner = Instance.new("UICorner", frame)
            corner.CornerRadius = UDim.new(0, 6)
            
            -- Recording Info
            local infoLabel = Instance.new("TextLabel", frame)
            infoLabel.Size = UDim2.new(0.7, 0, 1, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = string.format("📁 %s\n🗺️ %s | ⏱️ %.1fs | 📊 %d frames",
                recording.name or "Unnamed",
                recording.mapName or "Unknown",
                recording.duration or 0,
                recording.totalFrames or 0)
            infoLabel.TextColor3 = Theme.Text
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 10
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.ZIndex = 51
            
            local padding = Instance.new("UIPadding", infoLabel)
            padding.PaddingLeft = UDim.new(0, 10)
            
            -- Select Button
            local selectBtn = Instance.new("TextButton", frame)
            selectBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
            selectBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
            selectBtn.BackgroundColor3 = Theme.Confirm
            selectBtn.Text = "SELECT"
            selectBtn.TextColor3 = Theme.Text
            selectBtn.Font = Enum.Font.GothamBold
            selectBtn.TextSize = 9
            selectBtn.ZIndex = 51
            
            local selectCorner = Instance.new("UICorner", selectBtn)
            selectCorner.CornerRadius = UDim.new(0, 4)
            
            -- Delete Button
            local deleteBtn = Instance.new("TextButton", frame)
            deleteBtn.Size = UDim2.new(0.1, 0, 0.7, 0)
            deleteBtn.Position = UDim2.new(0.88, 0, 0.15, 0)
            deleteBtn.BackgroundColor3 = Theme.ButtonRed
            deleteBtn.Text = "X"
            deleteBtn.TextColor3 = Theme.Text
            deleteBtn.Font = Enum.Font.GothamBold
            deleteBtn.TextSize = 10
            deleteBtn.ZIndex = 51
            
            local deleteCorner = Instance.new("UICorner", deleteBtn)
            deleteCorner.CornerRadius = UDim.new(0, 4)
            
            -- Button Events
            selectBtn.MouseButton1Click:Connect(function()
                SelectedRecording = recording
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "✅ SELECTED",
                    Text = recording.name .. " selected",
                    Duration = 3
                })
            end)
            
            deleteBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete " .. recording.name .. "?", function()
                    DeleteRecording(i)
                end)
            end)
        end
    end
    
    -- ================================
    -- UI SETUP
    -- ================================
    
    -- Recording Controls
    RecordTab:Label("Recording Controls")
    
    local recordingStatus = RecordTab:Toggle("Start Recording", function(state)
        if state then
            StartRecording()
        else
            StopRecording()
        end
    end)
    
    RecordTab:Button("💾 Save Recording", Theme.Confirm, function()
        if RecordingData.currentRecording then
            UI:Confirm("Save current recording?", function()
                SaveRecording("Recording_" .. os.date("%H%M%S"))
            end)
        else
            Services.StarterGui:SetCore("SendNotification", {
                Title = "⚠️ NO DATA",
                Text = "Record something first!",
                Duration = 3
            })
        end
    end)
    
    -- Playback Controls
    RecordTab:Label("Playback Controls")
    
    RecordTab:Button("▶️ Play Selected", Theme.PlayBtn or Color3.fromRGB(0, 170, 255), function()
        if SelectedRecording then
            PlayRecording(SelectedRecording)
        else
            Services.StarterGui:SetCore("SendNotification", {
                Title = "⚠️ NO SELECTION",
                Text = "Select a recording first!",
                Duration = 3
            })
        end
    end)
    
    RecordTab:Button("⏹️ Stop Playback", Theme.ButtonRed, function()
        StopPlayback()
        StopAutoWalk()
    end)
    
    -- Auto Walk Controls
    RecordTab:Label("Auto Walk System")
    
    local autoWalkToggle = RecordTab:Toggle("🚶 Enable Auto Walk", function(state)
        if state then
            if SelectedRecording then
                StartAutoWalk(SelectedRecording)
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "⚠️ NO SELECTION",
                    Text = "Select a recording first!",
                    Duration = 3
                })
                autoWalkToggle.SetState(false)
            end
        else
            StopAutoWalk()
        end
    end)
    
    -- Recordings List
    RecordTab:Label("Saved Recordings")
    RecordingsContainer = RecordTab:Container(200)
    
    RecordTab:Button("🔄 Refresh List", Theme.ButtonDark, function()
        UpdateRecordingsList()
    end)
    
    -- Checkpoint Playback (Advanced)
    RecordTab:Label("Checkpoint Playback")
    
    RecordTab:Button("🎯 Play from Checkpoint", Theme.Accent, function()
        if SelectedRecording and #SelectedRecording.checkpoints > 0 then
            local checkpointNames = {}
            for _, cp in ipairs(SelectedRecording.checkpoints) do
                table.insert(checkpointNames, cp.name)
            end
            
            -- Simple selection via notification (bisa dikembangkan jadi dropdown)
            Services.StarterGui:SetCore("SendNotification", {
                Title = "🎯 CHECKPOINTS",
                Text = "Available: " .. table.concat(checkpointNames, ", "),
                Duration = 5
            })
            
            -- Example: Play from first checkpoint
            if #checkpointNames > 0 then
                PlayRecording(SelectedRecording, checkpointNames[1])
            end
        end
    end)
    
    -- ================================
    -- INITIALIZATION
    -- ================================
    
    -- Load recordings on startup
    spawn(function()
        task.wait(1)
        RecordingData.recordingsList = LoadRecordings()
        UpdateRecordingsList()
    end)
    
    -- Cleanup on reset
    Config.OnReset:Connect(function()
        RecordingData.isRecording = false
        RecordingData.isPlaying = false
        RecordingData.isAutoWalking = false
        
        if RecordingData.connection then
            RecordingData.connection:Disconnect()
            RecordingData.connection = nil
        end
        
        if RecordingData.playbackConnection then
            RecordingData.playbackConnection:Disconnect()
            RecordingData.playbackConnection = nil
        end
        
        if RecordingData.autoWalkConnection then
            RecordingData.autoWalkConnection:Disconnect()
            RecordingData.autoWalkConnection = nil
        end
    end)
    
    -- ================================
    -- HELPER FUNCTIONS (OPTIONAL)
    -- ================================
    
    -- Fungsi untuk export recording sebagai script
    local function ExportAsScript(recordingData)
        local scriptTemplate = [[
-- Auto-generated Movement Script
-- Map: %s
-- Frames: %d
-- Duration: %.1f seconds

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local movementData = {
    totalFrames = %d,
    checkpoints = %s,
    frames = {
%s
    }
}

local currentIndex = 1
local isPlaying = false
local connection = nil

local function PlayMovement()
    isPlaying = true
    connection = RunService.RenderStepped:Connect(function()
        if currentIndex > movementData.totalFrames then
            connection:Disconnect()
            return
        end
        
        local frame = movementData.frames[currentIndex]
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(frame.position) * 
                    CFrame.lookAt(frame.position, frame.position + frame.lookVector)
            end
        end
        
        currentIndex = currentIndex + 1
    end)
end

-- Call PlayMovement() to start
]]
        
        -- Format checkpoint data
        local cpString = "{"
        for i, cp in ipairs(recordingData.checkpoints) do
            cpString = cpString .. string.format('{name="%s", frame=%d}, ', cp.name, cp.frameIndex)
        end
        cpString = cpString .. "}"
        
        -- Format frame data
        local framesString = ""
        for i, frame in ipairs(recordingData.frames) do
            if i % 50 == 0 then -- Only include every 50th frame to reduce size
                framesString = framesString .. string.format(
                    '        {position=Vector3.new(%.2f, %.2f, %.2f), lookVector=Vector3.new(%.2f, 0, %.2f)},\n',
                    frame.position.X, frame.position.Y, frame.position.Z,
                    frame.lookVector.X, frame.lookVector.Z
                )
            end
        end
        
        local finalScript = string.format(
            scriptTemplate,
            recordingData.mapName,
            recordingData.totalFrames,
            recordingData.duration,
            recordingData.totalFrames,
            cpString,
            framesString
        )
        
        return finalScript
    end
    
    -- Export button (optional)
    RecordTab:Button("📤 Export as Script", Theme.Accent, function()
        if SelectedRecording then
            local script = ExportAsScript(SelectedRecording)
            setclipboard(script)
            Services.StarterGui:SetCore("SendNotification", {
                Title = "📋 COPIED",
                Text = "Script copied to clipboard!",
                Duration = 3
            })
        end
    end)
    
    print("[Vanzyxxx] Record & Replay System Loaded!")
end