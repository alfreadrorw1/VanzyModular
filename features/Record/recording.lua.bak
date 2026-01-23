return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    local MarketplaceService = game:GetService("MarketplaceService")

    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    
    -- Variables for Replay Logic
    local ReplayQueue = {} -- Queue for Checkpoints (CP1, CP2...)
    local QueueIndex = 0
    local LoadedTracks = {} -- Cache for animations
    local LastValidPos = nil -- For resuming logic

    -- // FILE SYSTEM & PATHS //
    local RootFolder = "VanzyData"
    local RecordsFolder = RootFolder .. "/Records"
    
    -- Get Map Name (Sanitized)
    local MapName = "UnknownMap"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        MapName = info.Name:gsub("%W", "") -- Remove special chars
    end)
    if MapName == "" then MapName = tostring(game.PlaceId) end
    
    local MapFolder = RecordsFolder .. "/" .. MapName

    -- Ensure Folders Exist
    if not isfolder(RootFolder) then makefolder(RootFolder) end
    if not isfolder(RecordsFolder) then makefolder(RecordsFolder) end
    if not isfolder(MapFolder) then makefolder(MapFolder) end

    -- // UTILITIES //
    
    -- [Precision] 5 decimals to reduce float size but keep smoothness
    local function cn(num)
        return math.floor(num * 100000) / 100000
    end

    -- [Serialization]
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end

    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end

    -- [Animation Scanner]
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                -- Filter core animations if needed, but capturing all is safer for realism
                if track.Animation.AnimationId and track.IsPlaying then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightTarget),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        l = track.Looped
                    })
                end
            end
        end
        return anims
    end

    -- [Notification Helper]
    local function Notify(title, text)
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 3;
        })
    end

    -- // UI WIDGET //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui

    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 180, 0, 50) -- Sedikit lebih lebar
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    WidgetFrame.BorderSizePixel = 0
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 1.5

    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    WidgetFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = WidgetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    WidgetFrame.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            WidgetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    StatusLabel.Position = UDim2.new(0, 0, 1, -15)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY - " .. MapName
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham

    local function CreateMiniBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = UDim2.new(0, 30, 0, 30)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.white
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        local corn = Instance.new("UICorner", btn)
        corn.CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- // CORE: RECORDING //
    local function StartRecording()
        if Recording or Replaying then return end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        Recording = true
        StartTime = os.clock()
        CurrentRecord = {
            Frames = {}, 
            Metadata = {
                Map = MapName, 
                Date = os.date("%x"),
                StartPos = SerializeCFrame(char.HumanoidRootPart.CFrame)
            }
        }
        
        StatusLabel.Text = "REC ●"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)

        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording then return end
            local char = LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = os.clock() - StartTime, -- Exact Delta Time
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end

    local function StopRecording(saveName)
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end
        
        StatusLabel.Text = "SAVING..."
        WStroke.Color = Theme.Accent

        -- Auto name handling
        local finalName = saveName
        if not finalName then
            finalName = "Rec_" .. math.floor(os.time())
        end
        if not finalName:find(".json") then finalName = finalName .. ".json" end

        writefile(MapFolder .. "/" .. finalName, HttpService:JSONEncode(CurrentRecord))
        Notify("Saved", finalName .. " to " .. MapFolder)
        StatusLabel.Text = "READY"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end

    -- // CORE: REPLAY ENGINE //

    -- Function to stop replay and clean up
    function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end

    -- Helper: Find closest frame index to current player position (Smart Resume)
    local function FindClosestFrameIndex(frames, currentPos)
        local closestIndex = 1
        local minDist = 999999
        
        -- Optimization: Scan with step of 10 to find rough area, then refine
        for i = 1, #frames, 5 do
            local dataCF = DeserializeCFrame(frames[i].cf)
            local dist = (dataCF.Position - currentPos).Magnitude
            if dist < minDist then
                minDist = dist
                closestIndex = i
            end
        end
        
        -- If closest point is too far (> 50 studs), probably assume start
        if minDist > 50 then return 1 end
        return closestIndex
    end

    -- The Main Play Function
    local function PlayReplayData(data, useSmartResume, onComplete)
        if not data or not data.Frames or #data.Frames < 2 then 
            if onComplete then onComplete() end
            return 
        end

        Replaying = true
        StatusLabel.Text = "PLAYING ▶"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")

        if not hrp or not hum then 
            StopReplay() 
            return 
        end

        -- Setup Character
        hrp.Anchored = true
        hum.AutoRotate = false
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end

        -- Determine Start Index
        local startIndex = 1
        if useSmartResume then
            startIndex = FindClosestFrameIndex(data.Frames, hrp.Position)
            Notify("Smart Resume", "Starting from frame: " .. startIndex .. "/" .. #data.Frames)
        end

        -- If at the end, reset to 1
        if startIndex >= #data.Frames - 5 then startIndex = 1 end

        -- Initial Teleport
        local startFrame = data.Frames[startIndex]
        hrp.CFrame = DeserializeCFrame(startFrame.cf)

        local startTimeOffset = startFrame.t
        local replayStartReal = os.clock()
        local frameIndex = startIndex

        -- Clear old tracks cache
        LoadedTracks = {}

        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Camera.Value - 1, function()
            if not Replaying or not LocalPlayer.Character then StopReplay() return end
            
            -- Enforce Anchor
            if hrp.Anchored == false then hrp.Anchored = true end

            -- Calculate Logic Time
            local timeElapsed = os.clock() - replayStartReal
            local currentLogicTime = startTimeOffset + timeElapsed

            -- Advance Frames
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]

            -- Check completion
            if not nextFrame then
                StopReplay()
                if onComplete then onComplete() end
                return
            end

            -- Fast forward if lag behind
            while nextFrame and currentLogicTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex + 1]
            end

            if not nextFrame then return end

            -- INTERPOLATION (Smoothness)
            local alpha = (currentLogicTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)

            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)

            -- ANIMATION SYNC
            if currentFrame.anims and animator then
                local activeIds = {}
                for _, animData in ipairs(currentFrame.anims) do
                    activeIds[animData.id] = true
                    
                    local track = LoadedTracks[animData.id]
                    if not track then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = animData.id
                        track = animator:LoadAnimation(animation)
                        LoadedTracks[animData.id] = track
                    end

                    if not track.IsPlaying then track:Play(0.1) end
                    
                    -- Sync Properties
                    if math.abs(track.Speed - animData.s) > 0.01 then track:AdjustSpeed(animData.s) end
                    if math.abs(track.WeightTarget - animData.w) > 0.01 then track:AdjustWeight(animData.w) end
                    
                    -- Only hard-sync time if desync is noticeable (> 0.2s) to prevent audio/visual stutter
                    if math.abs(track.TimePosition - animData.t) > 0.2 then
                        track.TimePosition = animData.t
                    end
                end

                -- Stop inactive tracks
                for id, track in pairs(LoadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
        end)

        -- Clean Up Internal
        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            if LocalPlayer.Character then
                local h = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hm = LocalPlayer.Character:FindFirstChild("Humanoid")
                if h then h.Anchored = false end
                if hm then hm.AutoRotate = true end
            end
            for _, track in pairs(LoadedTracks) do track:Stop() end
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            WStroke.Color = Theme.Accent
        end
    end

    -- // CHECKPOINT CHAIN LOGIC //
    local function PlayAllCheckpoints()
        -- 1. Get all CP files and Sort them
        local files = listfiles(MapFolder)
        local sortedCPs = {}
        
        for _, file in ipairs(files) do
            local name = string.gsub(file, MapFolder .. "/", "")
            -- Filter only CP files if naming convention is used, or just all JSONs
            if name:find(".json") then
                table.insert(sortedCPs, {path = file, name = name})
            end
        end

        -- Simple sort by name (CP_1, CP_2)
        table.sort(sortedCPs, function(a, b) return a.name < b.name end)

        if #sortedCPs == 0 then Notify("Error", "No recordings found in " .. MapName) return end

        -- 2. Determine where to start based on player position (Global Smart Resume)
        local startIndex = 1
        local char = LocalPlayer.Character
        local bestDist = 999999
        
        -- Cek CP mana yang paling dekat dengan player saat ini
        for i, cp in ipairs(sortedCPs) do
            local content = readfile(cp.path)
            local data = HttpService:JSONDecode(content)
            if data.Frames and #data.Frames > 0 then
                local startCF = DeserializeCFrame(data.Frames[1].cf)
                local dist = (char.HumanoidRootPart.Position - startCF.Position).Magnitude
                
                -- Jika dekat dengan awal CP ini, mungkin kita mau mulai dari sini
                -- Atau kita bisa cek frame tengah juga (lebih berat)
                if dist < bestDist then
                    bestDist = dist
                    startIndex = i
                end
            end
        end

        Notify("Chain Play", "Starting chain from: " .. sortedCPs[startIndex].name)

        -- 3. Recursive Execution
        local function PlayNext(index)
            if index > #sortedCPs then
                Notify("Finished", "All Checkpoints completed")
                return
            end

            local cpData = HttpService:JSONDecode(readfile(sortedCPs[index].path))
            
            -- Only use Smart Resume for the FIRST played file in the chain
            -- The rest should play from start to ensure continuity
            local useSmart = (index == startIndex) 
            
            PlayReplayData(cpData, useSmart, function()
                -- When finished, small delay then next
                task.wait(0.1)
                PlayNext(index + 1)
            end)
        end

        PlayNext(startIndex)
    end

    -- // WIDGET BUTTONS //
    local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 10), function()
        if Recording then 
            -- Ask for name logic handled in StopRecording usually, but for widget simple stop:
            StopRecording(nil) -- Auto name
        else 
            StartRecording() 
        end
    end)
    
    local PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 50, 0, 10), function()
        if Replaying then 
            StopReplay() 
        else
            -- Widget Play Button defaults to "Play All" for convenience
            PlayAllCheckpoints()
        end
    end)

    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 130, 0, 10), function()
        WidgetGui.Enabled = false
    end)

    -- // TAB MENU (FILE MANAGER) //
    local Tab = UI:Tab("Record Manager")
    
    Tab:Label("Control Center [" .. MapName .. "]")
    Tab:Toggle("Show Widget", function(v) WidgetGui.Enabled = v end).SetState(true)
    
    Tab:Label("Recording Options")
    local SaveNameInput = "CP_1"
    Tab:Input("Checkpoint Name", function(v) SaveNameInput = v end)
    
    Tab:Button("Start Recording", Color3.fromRGB(200,50,50), StartRecording)
    Tab:Button("Stop & Save", Theme.Button, function() StopRecording(SaveNameInput) end)
    
    Tab:Label("Playback Options")
    Tab:Button("▶ PLAY ALL (Smart Chain)", Color3.fromRGB(50, 200, 100), PlayAllCheckpoints)
    Tab:Button("Stop Replay", Color3.fromRGB(200, 50, 50), StopReplay)

    Tab:Label("File List (Map: " .. MapName .. ")")
    local FileContainer = Tab:Container(250)
    
    local function RefreshFiles()
        for _, c in pairs(FileContainer:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        
        local files = listfiles(MapFolder)
        table.sort(files) -- Alphabetical

        for _, file in ipairs(files) do
            local name = string.gsub(file, MapFolder .. "/", "")
            local btn = Instance.new("TextButton", FileContainer)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.BackgroundColor3 = Theme.Button
            btn.Text = "  " .. name
            btn.TextColor3 = Color3.white
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            -- Play Single File
            local pBtn = Instance.new("TextButton", btn)
            pBtn.Size = UDim2.new(0, 40, 1, -4)
            pBtn.Position = UDim2.new(1, -45, 0, 2)
            pBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
            pBtn.Text = "LOAD"
            pBtn.TextColor3 = Color3.white
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
            
            pBtn.MouseButton1Click:Connect(function()
                local content = readfile(file)
                local data = HttpService:JSONDecode(content)
                -- Single play with Smart Resume check
                PlayReplayData(data, true) 
            end)
            
            -- Delete File
            local dBtn = Instance.new("TextButton", btn)
            dBtn.Size = UDim2.new(0, 30, 1, -4)
            dBtn.Position = UDim2.new(1, -80, 0, 2)
            dBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
            dBtn.Text = "X"
            dBtn.TextColor3 = Color3.white
            Instance.new("UICorner", dBtn).CornerRadius = UDim.new(0, 4)
            
            dBtn.MouseButton1Click:Connect(function()
                delfile(file)
                RefreshFiles()
            end)
        end
    end
    
    Tab:Button("Refresh List", Theme.Button, RefreshFiles)
    RefreshFiles()

    -- Cleanup on script reload
    Config.OnReset.Event:Connect(function()
        StopRecording()
        StopReplay()
        WidgetGui:Destroy()
    end)

    return true
end