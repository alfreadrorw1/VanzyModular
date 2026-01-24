return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    local MarketplaceService = Services.MarketplaceService
    local TweenService = Services.TweenService
    local CoreGui = Services.CoreGui
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // GLOBAL VARIABLES //
    local Recording = false
    local Replaying = false
    local AutoWalking = false
    local CurrentRecord = {Frames = {}, Metadata = {}}
    local StartTime = 0
    local RecordConnection = nil
    local ReplayConnection = nil
    local AutoWalkConnection = nil
    local WidgetGui = nil
    local StatusLabel = nil
    local MapLabel = nil
    local WStroke = nil
    local AutoWalkBtn = nil
    local PlayBtn = nil
    
    -- // DATA STORAGE //
    local BasePath = "VanzyData"
    local RecordsPath = BasePath .. "/Records"
    local AutoWalkPath = BasePath .. "/AutoWalk"
    local CurrentMapFolder = nil
    local MapName = nil
    local Checkpoints = {}
    local AutoWalkMaps = {}
    local CurrentAutoWalkMap = nil
    local CurrentCheckpointIndex = 1
    local LastSafePosition = nil
    
    -- // UI COMPONENTS //
    local FileContainer = nil
    local MapContainer = nil
    local RefreshInProgress = false

    -- // UTILITY FUNCTIONS //
    local function cn(num)
        return math.floor(num * 1000000) / 1000000
    end

    local function SetupFolders()
        if not isfolder or not makefolder then 
            warn("[VanzyRecord] File system not available")
            return false 
        end
        
        if not isfolder(BasePath) then
            makefolder(BasePath)
        end
        
        if not isfolder(RecordsPath) then
            makefolder(RecordsPath)
        end
        
        if not isfolder(AutoWalkPath) then
            makefolder(AutoWalkPath)
        end
        
        local mapId = tostring(game.PlaceId)
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and productInfo then
            MapName = productInfo.Name:gsub("[^%w%s]", ""):gsub("%s+", "_")
            if MapName == "" then
                MapName = "Map_" .. mapId
            end
        else
            MapName = "Map_" .. mapId
        end
        
        CurrentMapFolder = RecordsPath .. "/" .. MapName
        if not isfolder(CurrentMapFolder) then
            makefolder(CurrentMapFolder)
        end
        
        print("[VanzyRecord] Folders setup for map: " .. MapName)
        return true
    end

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

    -- // ANTI-FALL DETECTION SYSTEM //
    local function IsCharacterFalling(char)
        if not char then return false end
        
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if hum and hrp then
            if hum:GetState().Name == "Freefall" then
                return true
            end
            
            if hrp.Velocity.Y < -50 then
                return true
            end
            
            local ray = Ray.new(hrp.Position, Vector3.new(0, -100, 0))
            local hit, pos = workspace:FindPartOnRay(ray, char)
            
            if hit and (hrp.Position.Y - pos.Y) > 20 then
                return true
            end
        end
        
        return false
    end

    local function GetLastSafeFrameIndex(frames)
        if not frames then return 1 end
        
        local lastSafe = 1
        for i, frame in ipairs(frames) do
            if frame.state and (frame.state.state == "Freefall" or frame.state.gr == true) then
                break
            end
            lastSafe = i
        end
        return lastSafe
    end

    local function TrimFallingFrames(recordData)
        if not recordData or not recordData.Frames then return recordData end
        
        local safeIndex = GetLastSafeFrameIndex(recordData.Frames)
        if safeIndex < #recordData.Frames then
            for i = #recordData.Frames, safeIndex + 1, -1 do
                table.remove(recordData.Frames, i)
            end
        end
        
        return recordData
    end

    -- // CHECKPOINT POPUP SYSTEM //
    local function ShowCheckpointPopup(cpNum, callback)
        local popupResult = {value = nil}
        
        local PopupGui = Instance.new("ScreenGui")
        PopupGui.Name = "CheckpointPopup"
        PopupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        PopupGui.DisplayOrder = 999 -- High ZIndex
        
        if syn and syn.protect_gui then
            syn.protect_gui(PopupGui)
        end
        
        PopupGui.Parent = CoreGui
        
        local PopupFrame = Instance.new("Frame", PopupGui)
        PopupFrame.Size = UDim2.new(0, 320, 0, 200)
        PopupFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
        PopupFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
        PopupFrame.BackgroundTransparency = 0.05
        PopupFrame.ZIndex = 1000
        
        local Corner = Instance.new("UICorner", PopupFrame)
        Corner.CornerRadius = UDim.new(0, 12)
        Corner.ZIndex = 1000
        
        local Stroke = Instance.new("UIStroke", PopupFrame)
        Stroke.Color = Color3.fromRGB(160, 32, 240)
        Stroke.Thickness = 3
        Stroke.ZIndex = 1000
        
        local Title = Instance.new("TextLabel", PopupFrame)
        Title.Size = UDim2.new(1, 0, 0, 50)
        Title.BackgroundTransparency = 1
        Title.Text = "⚠️ CHECKPOINT SYSTEM"
        Title.TextColor3 = Color3.fromRGB(255, 200, 50)
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 18
        Title.ZIndex = 1001
        
        local Message = Instance.new("TextLabel", PopupFrame)
        Message.Size = UDim2.new(0.9, 0, 0, 70)
        Message.Position = UDim2.new(0.05, 0, 0.25, 0)
        Message.BackgroundTransparency = 1
        Message.Text = "Player fell at Checkpoint #" .. cpNum .. "\n\nContinue from last safe position?"
        Message.TextColor3 = Color3.fromRGB(220, 220, 220)
        Message.Font = Enum.Font.Gotham
        Message.TextSize = 14
        Message.TextWrapped = true
        Message.ZIndex = 1001
        
        local ButtonContainer = Instance.new("Frame", PopupFrame)
        ButtonContainer.Size = UDim2.new(0.9, 0, 0, 50)
        ButtonContainer.Position = UDim2.new(0.05, 0, 0.7, 0)
        ButtonContainer.BackgroundTransparency = 1
        ButtonContainer.ZIndex = 1001
        
        local YesBtn = Instance.new("TextButton", ButtonContainer)
        YesBtn.Size = UDim2.new(0.45, 0, 1, 0)
        YesBtn.Position = UDim2.new(0, 0, 0, 0)
        YesBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
        YesBtn.Text = "✅ YES"
        YesBtn.TextColor3 = Color3.new(1, 1, 1)
        YesBtn.Font = Enum.Font.GothamBold
        YesBtn.TextSize = 14
        YesBtn.ZIndex = 1002
        
        local YesCorner = Instance.new("UICorner", YesBtn)
        YesCorner.CornerRadius = UDim.new(0, 6)
        YesCorner.ZIndex = 1002
        
        local NoBtn = Instance.new("TextButton", ButtonContainer)
        NoBtn.Size = UDim2.new(0.45, 0, 1, 0)
        NoBtn.Position = UDim2.new(0.55, 0, 0, 0)
        NoBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
        NoBtn.Text = "❌ NO"
        NoBtn.TextColor3 = Color3.new(1, 1, 1)
        NoBtn.Font = Enum.Font.GothamBold
        NoBtn.TextSize = 14
        NoBtn.ZIndex = 1002
        
        local NoCorner = Instance.new("UICorner", NoBtn)
        NoCorner.CornerRadius = UDim.new(0, 6)
        NoCorner.ZIndex = 1002
        
        YesBtn.MouseButton1Click:Connect(function()
            popupResult.value = true
            PopupGui:Destroy()
            if callback then callback(true) end
        end)
        
        NoBtn.MouseButton1Click:Connect(function()
            popupResult.value = false
            PopupGui:Destroy()
            if callback then callback(false) end
        end)
        
        return popupResult
    end

    -- // DATA LOADING FUNCTIONS //
    local function LoadCheckpoints()
        Checkpoints = {}
        
        if not isfolder or not isfolder(CurrentMapFolder) then 
            return {} 
        end
        
        local files = listfiles(CurrentMapFolder)
        local loadedFiles = {}
        
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("[^/\\]+$") or filePath
            local cpNum = tonumber(fileName:match("^CP(%d+)%.json$"))
            
            if cpNum and readfile then
                local success, data = pcall(function()
                    local content = readfile(filePath)
                    return HttpService:JSONDecode(content)
                end)
                
                if success and data then
                    Checkpoints[cpNum] = data
                    table.insert(loadedFiles, {
                        name = fileName,
                        cpNum = cpNum,
                        data = data
                    })
                end
            end
        end
        
        table.sort(loadedFiles, function(a, b)
            return a.cpNum < b.cpNum
        end)
        
        print("[VanzyRecord] Loaded " .. #loadedFiles .. " checkpoints")
        return loadedFiles
    end

    local function ScanAutoWalkMaps()
        AutoWalkMaps = {}
        
        if not isfolder or not isfolder(AutoWalkPath) then 
            return {} 
        end
        
        local mapFolders = listfolders(AutoWalkPath)
        
        for _, folderPath in ipairs(mapFolders) do
            local mapName = folderPath:match("[^/\\]+$") or folderPath
            local cpFiles = listfiles(folderPath)
            local checkpointList = {}
            
            for _, filePath in ipairs(cpFiles) do
                local fileName = filePath:match("[^/\\]+$") or filePath
                if fileName:match("^CP%d+%.json$") then
                    table.insert(checkpointList, {
                        name = fileName,
                        path = filePath
                    })
                end
            end
            
            if #checkpointList > 0 then
                table.sort(checkpointList, function(a, b)
                    local aNum = tonumber(a.name:match("CP(%d+)")) or 0
                    local bNum = tonumber(b.name:match("CP(%d+)")) or 0
                    return aNum < bNum
                end)
                
                table.insert(AutoWalkMaps, {
                    name = mapName,
                    path = folderPath,
                    checkpoints = checkpointList,
                    count = #checkpointList
                })
            end
        end
        
        print("[VanzyRecord] Found " .. #AutoWalkMaps .. " AutoWalk maps")
        return AutoWalkMaps
    end

    -- // RECORDING SYSTEM //
    local function StartRecording()
        if Recording or Replaying or AutoWalking then 
            StarterGui:SetCore("SendNotification", {
                Title = "Cannot Record",
                Text = "Stop replay/autowalk first",
                Duration = 2
            })
            return 
        end
        
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
                Checkpoint = #LoadCheckpoints() + 1,
                LastSafeFrame = 1
            }
        }
        
        if StatusLabel then
            StatusLabel.Text = "REC ●"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
        
        if WStroke then
            WStroke.Color = Color3.fromRGB(255, 50, 50)
        end
        
        RecordConnection = RunService.Heartbeat:Connect(function(dt)
            if not Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                local isFalling = IsCharacterFalling(LocalPlayer.Character)
                local frameTime = cn(os.clock() - StartTime)
                
                if not isFalling then
                    LastSafePosition = hrp.CFrame
                    CurrentRecord.Metadata.LastSafeFrame = #CurrentRecord.Frames + 1
                    
                    table.insert(CurrentRecord.Frames, {
                        t = frameTime,
                        cf = SerializeCFrame(hrp.CFrame),
                        state = {
                            state = tostring(hum:GetState().Name),
                            vx = cn(hrp.Velocity.X),
                            vy = cn(hrp.Velocity.Y),
                            vz = cn(hrp.Velocity.Z),
                            gr = (hum:GetState().Name == "Freefall")
                        },
                        dt = cn(dt),
                        isSafe = true
                    })
                else
                    table.insert(CurrentRecord.Frames, {
                        t = frameTime,
                        cf = SerializeCFrame(hrp.CFrame),
                        state = {state = "Freefall", gr = true},
                        dt = cn(dt),
                        isSafe = false
                    })
                    
                    if #CurrentRecord.Frames - CurrentRecord.Metadata.LastSafeFrame > 20 then
                        StopRecording()
                        return
                    end
                end
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Recording Started",
            Text = "Anti-fall system active",
            Duration = 2
        })
        
        print("[VanzyRecord] Recording started")
    end

    local function StopRecording()
        if not Recording then return end
        
        Recording = false
        
        if RecordConnection then
            RecordConnection:Disconnect()
            RecordConnection = nil
        end
        
        if #CurrentRecord.Frames == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "Empty Recording",
                Text = "No frames recorded",
                Duration = 2
            })
            return
        end
        
        local lastSafeIndex = CurrentRecord.Metadata.LastSafeFrame or #CurrentRecord.Frames
        local fallingDetected = false
        
        for i = lastSafeIndex + 1, #CurrentRecord.Frames do
            if CurrentRecord.Frames[i] and not CurrentRecord.Frames[i].isSafe then
                fallingDetected = true
                break
            end
        end
        
        if fallingDetected then
            ShowCheckpointPopup(CurrentRecord.Metadata.Checkpoint, function(continue)
                if continue then
                    TrimFallingFrames(CurrentRecord)
                    
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        if LastSafePosition then
                            char:FindFirstChild("HumanoidRootPart").CFrame = LastSafePosition
                        elseif #CurrentRecord.Frames > 0 then
                            local lastFrame = CurrentRecord.Frames[#CurrentRecord.Frames]
                            if lastFrame and lastFrame.cf then
                                char:FindFirstChild("HumanoidRootPart").CFrame = DeserializeCFrame(lastFrame.cf)
                            end
                        end
                    end
                    
                    StarterGui:SetCore("SendNotification", {
                        Title = "Continued Recording",
                        Text = "From safe position",
                        Duration = 2
                    })
                    
                    SaveCheckpoint()
                else
                    CurrentRecord = {Frames = {}, Metadata = {}}
                    StarterGui:SetCore("SendNotification", {
                        Title = "Recording Discarded",
                        Text = "Falling frames detected",
                        Duration = 2
                    })
                end
            end)
        else
            SaveCheckpoint()
        end
        
        if StatusLabel then
            StatusLabel.Text = "STOPPED"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
        
        if WStroke then
            WStroke.Color = Color3.fromRGB(255, 200, 50)
        end
    end

    local function SaveCheckpoint()
        if #CurrentRecord.Frames == 0 then return end
        
        local safeRecord = TrimFallingFrames(table.clone(CurrentRecord))
        
        if #safeRecord.Frames == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "No Safe Frames",
                Text = "Checkpoint not saved",
                Duration = 2
            })
            return
        end
        
        safeRecord.Metadata.EndTime = os.clock()
        safeRecord.Metadata.Duration = cn(safeRecord.Metadata.EndTime - safeRecord.Metadata.StartTime)
        safeRecord.Metadata.FrameCount = #safeRecord.Frames
        safeRecord.Metadata.IsSafe = true
        
        local cpNum = CurrentRecord.Metadata.Checkpoint
        local fileName = "CP" .. cpNum .. ".json"
        local filePath = CurrentMapFolder .. "/" .. fileName
        
        if writefile then
            writefile(filePath, HttpService:JSONEncode(safeRecord))
            
            StarterGui:SetCore("SendNotification", {
                Title = "Checkpoint Saved ✓",
                Text = "CP" .. cpNum .. " (" .. #safeRecord.Frames .. " frames)",
                Duration = 3
            })
            
            print("[VanzyRecord] Saved CP" .. cpNum .. " with " .. #safeRecord.Frames .. " frames")
            
            RefreshAllData()
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Save Failed",
                Text = "File system not available",
                Duration = 2
            })
        end
        
        CurrentRecord = {Frames = {}, Metadata = {}}
    end

    -- // REPLAY SYSTEM //
    local function PlayReplay(checkpointData)
        if Recording or Replaying or AutoWalking then 
            StarterGui:SetCore("SendNotification", {
                Title = "Cannot Replay",
                Text = "Stop current activity first",
                Duration = 2
            })
            return 
        end
        
        if not checkpointData or not checkpointData.Frames then
            StarterGui:SetCore("SendNotification", {
                Title = "Invalid Data",
                Text = "No replay data found",
                Duration = 2
            })
            return
        end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        Replaying = true
        
        if StatusLabel then
            StatusLabel.Text = "REPLAY ▶"
            StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        end
        
        if WStroke then
            WStroke.Color = Color3.fromRGB(50, 255, 100)
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then return end
        
        local controlBody = Instance.new("BodyVelocity", hrp)
        controlBody.MaxForce = Vector3.new(40000, 40000, 40000)
        controlBody.P = 1000
        
        local controlGyro = Instance.new("BodyGyro", hrp)
        controlGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        controlGyro.P = 1000
        
        hum.AutoRotate = false
        
        local replayStart = os.clock()
        local frameIndex = 1
        
        ReplayConnection = RunService.Heartbeat:Connect(function()
            if not Replaying or not LocalPlayer.Character then return end
            
            if frameIndex > #checkpointData.Frames then
                Replaying = false
                ReplayConnection:Disconnect()
                ReplayConnection = nil
                
                controlBody:Destroy()
                controlGyro:Destroy()
                hum.AutoRotate = true
                
                if StatusLabel then
                    StatusLabel.Text = "READY"
                    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
                
                if WStroke then
                    WStroke.Color = Theme.Accent
                end
                
                return
            end
            
            local frame = checkpointData.Frames[frameIndex]
            if frame and frame.cf then
                hrp.CFrame = DeserializeCFrame(frame.cf)
            end
            
            frameIndex = frameIndex + 1
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "Replay Started",
            Text = "Playing " .. #checkpointData.Frames .. " frames",
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
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local controlBody = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyVelocity")
            local controlGyro = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyGyro")
            
            if controlBody then controlBody:Destroy() end
            if controlGyro then controlGyro:Destroy() end
            
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.AutoRotate = true end
        end
        
        if StatusLabel then
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        if WStroke then
            WStroke.Color = Theme.Accent
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Replay Stopped",
            Duration = 1
        })
    end

    -- // AUTOWALK SYSTEM //
    local function StartAutoWalk(mapData, startCp)
        if Recording or Replaying or AutoWalking then 
            StarterGui:SetCore("SendNotification", {
                Title = "Cannot Start",
                Text = "Stop current activity first",
                Duration = 2
            })
            return 
        end
        
        if not mapData or not mapData.checkpoints or #mapData.checkpoints == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "Invalid Map",
                Text = "No checkpoints in this map",
                Duration = 2
            })
            return
        end
        
        AutoWalking = true
        CurrentAutoWalkMap = mapData
        CurrentCheckpointIndex = startCp or 1
        
        if StatusLabel then
            StatusLabel.Text = "AUTO WALK"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        end
        
        if WStroke then
            WStroke.Color = Color3.fromRGB(100, 200, 255)
        end
        
        if AutoWalkBtn then
            AutoWalkBtn.Text = "⏹"
            AutoWalkBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then return end
        
        local controlBody = Instance.new("BodyVelocity", hrp)
        controlBody.MaxForce = Vector3.new(40000, 40000, 40000)
        controlBody.P = 1000
        
        local controlGyro = Instance.new("BodyGyro", hrp)
        controlGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        controlGyro.P = 1000
        
        hum.AutoRotate = false
        
        local checkpointPositions = {}
        
        for i, cpInfo in ipairs(mapData.checkpoints) do
            local success, data = pcall(function()
                local content = readfile(cpInfo.path)
                return HttpService:JSONDecode(content)
            end)
            
            if success and data and data.Frames and #data.Frames > 0 then
                local lastFrame = data.Frames[#data.Frames]
                if lastFrame and lastFrame.cf then
                    checkpointPositions[i] = DeserializeCFrame(lastFrame.cf).Position
                end
            end
        end
        
        AutoWalkConnection = RunService.Heartbeat:Connect(function()
            if not AutoWalking or not char or char.Parent == nil then
                if AutoWalkConnection then
                    AutoWalkConnection:Disconnect()
                    AutoWalkConnection = nil
                end
                return
            end
            
            if CurrentCheckpointIndex <= #mapData.checkpoints then
                local targetPos = checkpointPositions[CurrentCheckpointIndex]
                
                if targetPos then
                    local currentPos = hrp.Position
                    local distance = (targetPos - currentPos).Magnitude
                    
                    if distance > 3 then
                        local direction = (targetPos - currentPos).Unit
                        controlBody.Velocity = direction * 16
                        controlGyro.CFrame = CFrame.lookAt(currentPos, targetPos)
                        
                        if StatusLabel then
                            StatusLabel.Text = "AUTO → CP" .. CurrentCheckpointIndex
                        end
                    else
                        CurrentCheckpointIndex = CurrentCheckpointIndex + 1
                        
                        if CurrentCheckpointIndex <= #mapData.checkpoints then
                            StarterGui:SetCore("SendNotification", {
                                Title = "AutoWalk",
                                Text = "Moving to CP" .. CurrentCheckpointIndex,
                                Duration = 1
                            })
                        else
                            StopAutoWalk()
                            StarterGui:SetCore("SendNotification", {
                                Title = "AutoWalk Complete",
                                Text = "Reached all checkpoints",
                                Duration = 3
                            })
                        end
                    end
                end
            else
                StopAutoWalk()
            end
        end)
        
        StarterGui:SetCore("SendNotification", {
            Title = "AutoWalk Started",
            Text = mapData.name .. " (from CP" .. (startCp or 1) .. ")",
            Duration = 2
        })
    end

    local function StopAutoWalk()
        if not AutoWalking then return end
        
        AutoWalking = false
        
        if AutoWalkConnection then
            AutoWalkConnection:Disconnect()
            AutoWalkConnection = nil
        end
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local controlBody = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyVelocity")
            local controlGyro = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyGyro")
            
            if controlBody then controlBody:Destroy() end
            if controlGyro then controlGyro:Destroy() end
            
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.AutoRotate = true end
        end
        
        if StatusLabel then
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        if WStroke then
            WStroke.Color = Theme.Accent
        end
        
        if AutoWalkBtn then
            AutoWalkBtn.Text = "A"
            AutoWalkBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "AutoWalk Stopped",
            Text = "Stopped at CP" .. (CurrentCheckpointIndex - 1),
            Duration = 2
        })
    end

    -- // AUTO-REFRESH SYSTEM //
    local function RefreshAllData()
        if RefreshInProgress then return end
        
        RefreshInProgress = true
        
        SetupFolders()
        
        local checkpoints = LoadCheckpoints()
        local autoWalkMaps = ScanAutoWalkMaps()
        
        if FileContainer then
            -- Clear existing UI elements
            local children = FileContainer:GetChildren()
            for i = #children, 1, -1 do
                local child = children[i]
                if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            if #checkpoints == 0 then
                local lbl = Instance.new("TextLabel", FileContainer)
                lbl.Size = UDim2.new(1, 0, 0, 40)
                lbl.BackgroundTransparency = 1
                lbl.Text = "No checkpoints saved yet\nStart recording to create checkpoints"
                lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 12
                lbl.TextWrapped = true
                lbl.ZIndex = 5
            else
                for _, cpInfo in ipairs(checkpoints) do
                    local frame = Instance.new("Frame", FileContainer)
                    frame.Size = UDim2.new(1, -5, 0, 35)
                    frame.BackgroundColor3 = Theme.Button
                    frame.BackgroundTransparency = 0.1
                    frame.ZIndex = 5
                    
                    local corner = Instance.new("UICorner", frame)
                    corner.CornerRadius = UDim.new(0, 4)
                    corner.ZIndex = 5
                    
                    local label = Instance.new("TextLabel", frame)
                    label.Size = UDim2.new(0.6, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "📍 CP" .. cpInfo.cpNum
                    label.TextColor3 = Theme.Text
                    label.TextSize = 12
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Font = Enum.Font.Gotham
                    label.ZIndex = 6
                    
                    local padding = Instance.new("UIPadding", label)
                    padding.PaddingLeft = UDim.new(0, 10)
                    padding.ZIndex = 6
                    
                    local loadBtn = Instance.new("TextButton", frame)
                    loadBtn.Size = UDim2.new(0, 50, 0.7, 0)
                    loadBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
                    loadBtn.BackgroundColor3 = Theme.Confirm
                    loadBtn.Text = "PLAY"
                    loadBtn.TextColor3 = Color3.new(1, 1, 1)
                    loadBtn.Font = Enum.Font.GothamBold
                    loadBtn.TextSize = 10
                    loadBtn.ZIndex = 6
                    
                    local btnCorner = Instance.new("UICorner", loadBtn)
                    btnCorner.CornerRadius = UDim.new(0, 4)
                    btnCorner.ZIndex = 6
                    
                    loadBtn.MouseButton1Click:Connect(function()
                        PlayReplay(cpInfo.data)
                    end)
                    
                    local delBtn = Instance.new("TextButton", frame)
                    delBtn.Size = UDim2.new(0, 40, 0.7, 0)
                    delBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
                    delBtn.BackgroundColor3 = Theme.ButtonRed
                    delBtn.Text = "DEL"
                    delBtn.TextColor3 = Color3.new(1, 1, 1)
                    delBtn.Font = Enum.Font.GothamBold
                    delBtn.TextSize = 10
                    delBtn.ZIndex = 6
                    
                    local delCorner = Instance.new("UICorner", delBtn)
                    delCorner.CornerRadius = UDim.new(0, 4)
                    delCorner.ZIndex = 6
                    
                    delBtn.MouseButton1Click:Connect(function()
                        UI:Confirm("Delete CP" .. cpInfo.cpNum .. "?", function()
                            local fileName = "CP" .. cpInfo.cpNum .. ".json"
                            local filePath = CurrentMapFolder .. "/" .. fileName
                            
                            if delfile and isfile(filePath) then
                                delfile(filePath)
                                StarterGui:SetCore("SendNotification", {
                                    Title = "Deleted",
                                    Text = "CP" .. cpInfo.cpNum .. " removed",
                                    Duration = 2
                                })
                                
                                task.wait(0.5)
                                RefreshAllData()
                            end
                        end)
                    end)
                end
            end
        end
        
        if MapContainer then
            -- Clear existing UI elements
            local children = MapContainer:GetChildren()
            for i = #children, 1, -1 do
                local child = children[i]
                if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            if #autoWalkMaps == 0 then
                local lbl = Instance.new("TextLabel", MapContainer)
                lbl.Size = UDim2.new(1, 0, 0, 60)
                lbl.BackgroundTransparency = 1
                lbl.Text = "No AutoWalk maps found\n\nSave checkpoints first, then use 'Create AutoWalk Map' button"
                lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 12
                lbl.TextWrapped = true
                lbl.ZIndex = 5
            else
                for _, map in ipairs(autoWalkMaps) do
                    local frame = Instance.new("Frame", MapContainer)
                    frame.Size = UDim2.new(1, -5, 0, 55)
                    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                    frame.BackgroundTransparency = 0.1
                    frame.ZIndex = 5
                    
                    local corner = Instance.new("UICorner", frame)
                    corner.CornerRadius = UDim.new(0, 6)
                    corner.ZIndex = 5
                    
                    local mapNameLabel = Instance.new("TextLabel", frame)
                    mapNameLabel.Size = UDim2.new(0.7, 0, 0.5, 0)
                    mapNameLabel.Position = UDim2.new(0, 10, 0, 5)
                    mapNameLabel.BackgroundTransparency = 1
                    mapNameLabel.Text = "🗺️ " .. map.name
                    mapNameLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
                    mapNameLabel.TextSize = 12
                    mapNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    mapNameLabel.Font = Enum.Font.GothamBold
                    mapNameLabel.ZIndex = 6
                    
                    local cpCountLabel = Instance.new("TextLabel", frame)
                    cpCountLabel.Size = UDim2.new(0.7, 0, 0.5, 0)
                    cpCountLabel.Position = UDim2.new(0, 10, 0, 25)
                    cpCountLabel.BackgroundTransparency = 1
                    cpCountLabel.Text = "📁 " .. map.count .. " checkpoints"
                    cpCountLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
                    cpCountLabel.TextSize = 10
                    cpCountLabel.TextXAlignment = Enum.TextXAlignment.Left
                    cpCountLabel.Font = Enum.Font.Gotham
                    cpCountLabel.ZIndex = 6
                    
                    local playBtn = Instance.new("TextButton", frame)
                    playBtn.Size = UDim2.new(0, 60, 0.7, 0)
                    playBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
                    playBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
                    playBtn.Text = AutoWalking and "⏹ STOP" : "▶ PLAY"
                    playBtn.TextColor3 = Color3.new(1, 1, 1)
                    playBtn.Font = Enum.Font.GothamBold
                    playBtn.TextSize = 11
                    playBtn.ZIndex = 6
                    
                    local btnCorner = Instance.new("UICorner", playBtn)
                    btnCorner.CornerRadius = UDim.new(0, 4)
                    btnCorner.ZIndex = 6
                    
                    playBtn.MouseButton1Click:Connect(function()
                        if AutoWalking then
                            StopAutoWalk()
                        else
                            StartAutoWalk(map, 1)
                        end
                    end)
                end
            end
        end
        
        if MapLabel then
            MapLabel.Text = MapName and (MapName:sub(1, 20) .. " (" .. #checkpoints .. " CPs)") or "Loading..."
        end
        
        RefreshInProgress = false
        
        print("[VanzyRecord] Data refreshed: " .. #checkpoints .. " CPs, " .. #autoWalkMaps .. " maps")
    end

    -- // CREATE AUTOWALK MAP FUNCTION //
    local function CreateAutoWalkMap()
        local checkpoints = LoadCheckpoints()
        
        if #checkpoints == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "No Checkpoints",
                Text = "Save checkpoints first",
                Duration = 2
            })
            return
        end
        
        local autoWalkMapFolder = AutoWalkPath .. "/" .. MapName
        if not isfolder(autoWalkMapFolder) then
            makefolder(autoWalkMapFolder)
        end
        
        local copied = 0
        for _, cpInfo in ipairs(checkpoints) do
            local sourceFile = CurrentMapFolder .. "/CP" .. cpInfo.cpNum .. ".json"
            local destFile = autoWalkMapFolder .. "/CP" .. cpInfo.cpNum .. ".json"
            
            if isfile(sourceFile) then
                local content = readfile(sourceFile)
                writefile(destFile, content)
                copied = copied + 1
            end
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "AutoWalk Map Created ✓",
            Text = MapName .. " (" .. copied .. " checkpoints)",
            Duration = 3
        })
        
        RefreshAllData()
    end

    -- // WIDGET CREATION //
    local function CreateWidget()
        WidgetGui = Instance.new("ScreenGui")
        WidgetGui.Name = "VanzyRecorderWidget"
        WidgetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        WidgetGui.DisplayOrder = 10 -- Higher than main UI
        WidgetGui.ResetOnSpawn = false
        
        if syn and syn.protect_gui then
            syn.protect_gui(WidgetGui)
        end
        
        WidgetGui.Parent = CoreGui
        
        local WidgetFrame = Instance.new("Frame", WidgetGui)
        WidgetFrame.Size = UDim2.new(0, 210, 0, 55)
        WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
        WidgetFrame.BackgroundColor3 = Theme.Main
        WidgetFrame.BackgroundTransparency = 0.05
        WidgetFrame.BorderSizePixel = 0
        WidgetFrame.ZIndex = 11
        
        local WCorner = Instance.new("UICorner", WidgetFrame)
        WCorner.CornerRadius = UDim.new(0, 8)
        WCorner.ZIndex = 11
        
        WStroke = Instance.new("UIStroke", WidgetFrame)
        WStroke.Color = Theme.Accent
        WStroke.Thickness = 2
        WStroke.ZIndex = 11
        
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
        
        StatusLabel = Instance.new("TextLabel", WidgetFrame)
        StatusLabel.Size = UDim2.new(1, -10, 0, 15)
        StatusLabel.Position = UDim2.new(0, 5, 1, -15)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "READY"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        StatusLabel.TextSize = 10
        StatusLabel.Font = Enum.Font.Gotham
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatusLabel.ZIndex = 12
        
        MapLabel = Instance.new("TextLabel", WidgetFrame)
        MapLabel.Size = UDim2.new(1, -10, 0, 12)
        MapLabel.Position = UDim2.new(0, 5, 0, 2)
        MapLabel.BackgroundTransparency = 1
        MapLabel.Text = "Loading..."
        MapLabel.TextColor3 = Theme.Accent
        MapLabel.TextSize = 9
        MapLabel.Font = Enum.Font.Gotham
        MapLabel.TextXAlignment = Enum.TextXAlignment.Left
        MapLabel.ZIndex = 12
        
        local function CreateMiniBtn(text, color, pos, callback)
            local btn = Instance.new("TextButton", WidgetFrame)
            btn.Size = UDim2.new(0, 30, 0, 30)
            btn.Position = pos
            btn.BackgroundColor3 = color
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.ZIndex = 12
            
            local corn = Instance.new("UICorner", btn)
            corn.CornerRadius = UDim.new(0, 6)
            corn.ZIndex = 12
            
            btn.MouseButton1Click:Connect(callback)
            return btn
        end
        
        local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 10), function()
            if Recording then
                StopRecording()
            else
                StartRecording()
            end
        end)
        
        PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 50, 0, 10), function()
            if Replaying then
                StopReplay()
            else
                local checkpoints = LoadCheckpoints()
                if #checkpoints > 0 then
                    PlayReplay(checkpoints[#checkpoints].data)
                else
                    StarterGui:SetCore("SendNotification", {
                        Title = "No Checkpoints",
                        Text = "Record something first",
                        Duration = 2
                    })
                end
            end
        end)
        
        local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 90, 0, 10), function()
            WidgetGui.Enabled = not WidgetGui.Enabled
            HideBtn.Text = WidgetGui.Enabled and "_" or "+"
        end)
        
        AutoWalkBtn = CreateMiniBtn("A", Color3.fromRGB(100, 150, 255), UDim2.new(0, 130, 0, 10), function()
            if AutoWalking then
                StopAutoWalk()
            else
                StarterGui:SetCore("SendNotification", {
                    Title = "AutoWalk",
                    Text = "Select map from menu",
                    Duration = 2
                })
            end
        end)
        
        local RefreshBtn = CreateMiniBtn("↻", Color3.fromRGB(255, 170, 0), UDim2.new(0, 170, 0, 10), function()
            RefreshAllData()
            StarterGui:SetCore("SendNotification", {
                Title = "Refreshed",
                Text = "Data reloaded",
                Duration = 1
            })
        end)
        
        return WidgetGui
    end

    -- // UI TAB CREATION //
    local Tab = UI:Tab("Record")
    
    Tab:Label("Floating Widget Controls")
    local WidgetToggle = Tab:Toggle("Show Widget", function(state)
        if WidgetGui then
            WidgetGui.Enabled = state
        end
    end)
    WidgetToggle.SetState(true)
    
    Tab:Label("Recording System (Anti-Fall)")
    Tab:Button("🎥 Start Recording", Theme.Button, StartRecording)
    Tab:Button("⏹️ Stop Recording", Color3.fromRGB(255, 100, 100), StopRecording)
    
    Tab:Label("Replay System")
    Tab:Button("▶ Play Last Checkpoint", Theme.Confirm, function()
        local checkpoints = LoadCheckpoints()
        if #checkpoints > 0 then
            PlayReplay(checkpoints[#checkpoints].data)
        end
    end)
    
    Tab:Button("⏹ Stop Replay", Theme.ButtonRed, StopReplay)
    
    Tab:Label("AutoWalk System")
    
    local AutoWalkContainer = Tab:Container(200)
    MapContainer = AutoWalkContainer
    
    Tab:Button("🔄 Refresh AutoWalk Maps", Color3.fromRGB(80, 100, 200), function()
        RefreshAllData()
    end)
    
    Tab:Button("💾 Create AutoWalk Map", Color3.fromRGB(100, 50, 200), CreateAutoWalkMap)
    
    Tab:Label("Checkpoint Manager")
    
    local CheckpointContainer = Tab:Container(250)
    FileContainer = CheckpointContainer
    
    Tab:Button("🔄 Refresh Checkpoints", Theme.ButtonDark, function()
        RefreshAllData()
    end)
    
    Tab:Button("🗑️ Clear All Checkpoints", Theme.ButtonRed, function()
        UI:Confirm("Delete ALL checkpoints?", function()
            local checkpoints = LoadCheckpoints()
            for _, cpInfo in ipairs(checkpoints) do
                local filePath = CurrentMapFolder .. "/CP" .. cpInfo.cpNum .. ".json"
                if delfile and isfile(filePath) then
                    delfile(filePath)
                end
            end
            
            StarterGui:SetCore("SendNotification", {
                Title = "Cleared All",
                Text = "All checkpoints deleted",
                Duration = 3
            })
            
            task.wait(0.5)
            RefreshAllData()
        end)
    end)
    
    -- // INITIALIZATION //
    spawn(function()
        task.wait(1)
        CreateWidget()
        SetupFolders()
        
        task.wait(1)
        RefreshAllData()
        
        StarterGui:SetCore("SendNotification", {
            Title = "VanzyRecord Ready",
            Text = "Anti-Fall + AutoWalk System Loaded",
            Duration = 4
        })
        
        print("[VanzyRecord] System fully initialized")
        
        -- Auto-refresh every 30 seconds
        while true do
            task.wait(30)
            if not Recording and not Replaying and not AutoWalking then
                RefreshAllData()
            end
        end
    end)
    
    -- // CLEANUP //
    Config.OnReset:Connect(function()
        StopRecording()
        StopReplay()
        StopAutoWalk()
        
        if WidgetGui then
            WidgetGui:Destroy()
        end
    end)
    
    -- Return public API
    return {
        StartRecording = StartRecording,
        StopRecording = StopRecording,
        PlayReplay = PlayReplay,
        StopReplay = StopReplay,
        StartAutoWalk = StartAutoWalk,
        StopAutoWalk = StopAutoWalk,
        RefreshAllData = RefreshAllData,
        CreateAutoWalkMap = CreateAutoWalkMap
    }
end