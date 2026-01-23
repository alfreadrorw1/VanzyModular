return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local TweenService = Services.TweenService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // CONFIGURATION //
    local ROOT_FOLDER = "VanzyData"
    local REPLAY_FOLDER = ROOT_FOLDER .. "/Replays"
    local GAME_FOLDER = REPLAY_FOLDER .. "/" .. tostring(game.PlaceId)
    
    -- // STATE //
    local State = {
        Recording = false,
        Replaying = false,
        CurrentSegment = 1,
        SessionId = os.time(), -- ID unik untuk sesi rekaman ini
        DataBuffer = {},
        Queue = {} -- Antrian segment untuk playback
    }
    
    local Connection = nil
    
    -- // UTILITIES & FILESYSTEM //
    local function InitFolders()
        if not isfolder(ROOT_FOLDER) then makefolder(ROOT_FOLDER) end
        if not isfolder(REPLAY_FOLDER) then makefolder(REPLAY_FOLDER) end
        if not isfolder(GAME_FOLDER) then makefolder(GAME_FOLDER) end
    end
    InitFolders()

    -- High Precision Number (5 decimal)
    local function cn(num)
        return math.floor(num * 100000) / 100000
    end
    
    -- Serialization CFrame (Full Rotation Matrix for absolute precision)
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end
    
    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end
    
    -- Advanced Animation Scanner (1:1 Copy)
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                -- Filter animasi core Roblox yang kadang ngebug, fokus ke AnimationId valid
                if track.Animation.AnimationId and #track.Animation.AnimationId > 0 then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightTarget),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        p = track.Priority.Value -- Capture Priority (Idle, Action, Movement)
                    })
                end
            end
        end
        return anims
    end
    
    -- // UI CONSTRUCTION (MODULAR WIDGET) //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderPro"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui
    
    -- Main Container
    local MainFrame = Instance.new("Frame", WidgetGui)
    MainFrame.Size = UDim2.new(0, 200, 0, 90)
    MainFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainFrame.BorderSizePixel = 0
    
    local MFStroke = Instance.new("UIStroke", MainFrame)
    MFStroke.Color = Theme.Accent
    MFStroke.Thickness = 2
    
    local MFCorner = Instance.new("UICorner", MainFrame)
    MFCorner.CornerRadius = UDim.new(0, 10)
    
    -- Dragging
    local dragging, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- UI Elements
    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "RECORDER: SEGMENT 1"
    Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Size = UDim2.new(1, -10, 0, 15)
    StatusText.Position = UDim2.new(0, 5, 0, 22)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Ready to record CP 1"
    StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextSize = 10
    StatusText.TextXAlignment = Enum.TextXAlignment.Left

    local function CreateBtn(text, color, pos, size, callback)
        local btn = Instance.new("TextButton", MainFrame)
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.white
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- // CORE SYSTEM: RECORDING //
    
    local function StartRecordingSegment()
        if State.Recording or State.Replaying then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        State.Recording = true
        State.DataBuffer = {
            SegmentIndex = State.CurrentSegment,
            Frames = {}
        }
        
        local startTime = os.clock()
        
        Title.Text = "RECORDING: SEGMENT " .. State.CurrentSegment
        StatusText.Text = "Recording... (Press Stop to Save)"
        StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        MFStroke.Color = Color3.fromRGB(255, 50, 50)
        
        -- Heartbeat loop for Physics precision
        Connection = RunService.Heartbeat:Connect(function()
            if not State.Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(State.DataBuffer.Frames, {
                    t = os.clock() - startTime,
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end
    
    local function StopAndSaveSegment()
        if not State.Recording then return end
        
        State.Recording = false
        if Connection then Connection:Disconnect() end
        
        -- Save File
        -- Format: Segment_[Index].json
        local fileName = string.format("Segment_%02d.json", State.CurrentSegment)
        local filePath = GAME_FOLDER .. "/" .. fileName
        
        writefile(filePath, HttpService:JSONEncode(State.DataBuffer))
        
        -- Prepare for next segment
        State.CurrentSegment = State.CurrentSegment + 1
        
        Title.Text = "NEXT: SEGMENT " .. State.CurrentSegment
        StatusText.Text = "Saved! Ready for next CP."
        StatusText.TextColor3 = Theme.Accent
        MFStroke.Color = Theme.Accent
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Segment Saved",
            Text = fileName .. " stored locally.",
            Duration = 2
        })
    end
    
    -- // CORE SYSTEM: SEQUENTIAL REPLAY //
    
    -- Load all segments from folder
    local function LoadSegments()
        local files = listfiles(GAME_FOLDER)
        local segments = {}
        
        for _, file in ipairs(files) do
            if string.find(file, "Segment_") and string.find(file, ".json") then
                local content = readfile(file)
                local data = HttpService:JSONDecode(content)
                table.insert(segments, data)
            end
        end
        
        -- Sort by SegmentIndex (1, 2, 3...)
        table.sort(segments, function(a, b)
            return a.SegmentIndex < b.SegmentIndex
        end)
        
        return segments
    end
    
    local function PlaySequence()
        if State.Recording or State.Replaying then return end
        
        local segments = LoadSegments()
        if #segments == 0 then
            StatusText.Text = "No segments found!"
            return
        end
        
        State.Replaying = true
        State.Queue = segments
        
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        
        if not hrp or not hum then return end
        
        -- PRE-REPLAY SETUP (ANCHOR MODE - ANTI GETAR)
        hrp.Anchored = true
        hum.AutoRotate = false
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        
        Title.Text = "PLAYING SEQUENCE"
        MFStroke.Color = Color3.fromRGB(50, 255, 100)
        
        -- Process Queue
        task.spawn(function()
            for i, segmentData in ipairs(State.Queue) do
                if not State.Replaying then break end
                
                StatusText.Text = "Playing Segment " .. segmentData.SegmentIndex .. " of " .. #State.Queue
                StatusText.TextColor3 = Color3.fromRGB(50, 255, 100)
                
                -- Teleport to start of THIS segment immediately
                if #segmentData.Frames > 0 then
                    local startCF = DeserializeCFrame(segmentData.Frames[1].cf)
                    hrp.CFrame = startCF
                end
                
                local frameIndex = 1
                local replayStart = os.clock()
                local segmentDuration = segmentData.Frames[#segmentData.Frames].t
                local loadedTracks = {}
                local isSegmentRunning = true
                
                -- Segment Loop
                local renderConn
                renderConn = RunService.RenderStepped:Connect(function()
                    if not State.Replaying then 
                        isSegmentRunning = false
                        return 
                    end
                    
                    -- Enforce Anchor
                    if not hrp.Anchored then hrp.Anchored = true end
                    
                    local currentTime = os.clock() - replayStart
                    
                    -- Check End of Segment
                    if currentTime >= segmentDuration then
                        isSegmentRunning = false
                        return
                    end
                    
                    -- Frame Advance Logic
                    local currentFrame = segmentData.Frames[frameIndex]
                    local nextFrame = segmentData.Frames[frameIndex + 1]
                    
                    while nextFrame and currentTime > nextFrame.t do
                        frameIndex = frameIndex + 1
                        currentFrame = segmentData.Frames[frameIndex]
                        nextFrame = segmentData.Frames[frameIndex + 1]
                    end
                    
                    if not nextFrame then return end
                    
                    -- 1. Smooth Movement Interpolation
                    local alpha = (currentTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
                    local cf1 = DeserializeCFrame(currentFrame.cf)
                    local cf2 = DeserializeCFrame(nextFrame.cf)
                    hrp.CFrame = cf1:Lerp(cf2, math.clamp(alpha, 0, 1))
                    
                    -- 2. Animation Sync (1:1 Mirroring)
                    if currentFrame.anims and animator then
                        local activeIds = {}
                        for _, anim in ipairs(currentFrame.anims) do
                            activeIds[anim.id] = true
                            
                            local track = loadedTracks[anim.id]
                            if not track then
                                local a = Instance.new("Animation")
                                a.AnimationId = anim.id
                                track = animator:LoadAnimation(a)
                                track.Priority = Enum.AnimationPriority[Enum.AnimationPriority:GetEnumItems()[anim.p + 1].Name] or Enum.AnimationPriority.Action
                                loadedTracks[anim.id] = track
                            end
                            
                            if not track.IsPlaying then track:Play(0.1) end
                            
                            -- Force Update Properties
                            track:AdjustSpeed(anim.s)
                            track:AdjustWeight(anim.w)
                            
                            -- Sync Time if drift > 0.1s
                            if math.abs(track.TimePosition - anim.t) > 0.1 then
                                track.TimePosition = anim.t
                            end
                        end
                        
                        -- Stop unused anims
                        for id, track in pairs(loadedTracks) do
                            if not activeIds[id] then track:Stop(0.2) end
                        end
                    end
                end)
                
                -- Wait until segment finishes
                repeat task.wait() until not isSegmentRunning
                
                renderConn:Disconnect()
                
                -- Stop all anims from this segment before next one
                for _, track in pairs(loadedTracks) do track:Stop(0) end
            end
            
            -- End of Sequence
            StopReplaySystem()
        end)
    end
    
    function StopReplaySystem()
        State.Replaying = false
        State.Recording = false
        if Connection then Connection:Disconnect() end
        
        -- Restore Character
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp then hrp.Anchored = false end
            if hum then hum.AutoRotate = true end
        end
        
        Title.Text = "RECORDER: SEGMENT " .. State.CurrentSegment
        StatusText.Text = "Sequence Finished."
        StatusText.TextColor3 = Theme.Accent
        MFStroke.Color = Theme.Accent
    end
    
    -- // RESET FEATURE //
    local function ResetSegments()
        local files = listfiles(GAME_FOLDER)
        for _, file in ipairs(files) do
            delfile(file)
        end
        State.CurrentSegment = 1
        Title.Text = "RECORDER: SEGMENT 1"
        StatusText.Text = "All segments cleared."
        Services.StarterGui:SetCore("SendNotification", {Title = "Reset", Text = "Deleted all segments", Duration = 2})
    end

    -- // BUTTONS LAYOUT //
    
    -- Row 1: Record Control
    CreateBtn("REC SEGMENT", Color3.fromRGB(200, 50, 50), UDim2.new(0, 5, 0, 45), UDim2.new(0, 90, 0, 18), function()
        if State.Recording then 
            StopAndSaveSegment()
        else 
            StartRecordingSegment() 
        end
    end)
    
    -- Row 2: Playback Control
    CreateBtn("PLAY ALL ►", Color3.fromRGB(40, 180, 80), UDim2.new(0, 100, 0, 45), UDim2.new(0, 95, 0, 18), function()
        if State.Replaying then StopReplaySystem() else PlaySequence() end
    end)
    
    -- Row 3: Utilities
    CreateBtn("RESET", Color3.fromRGB(80, 80, 80), UDim2.new(0, 5, 0, 68), UDim2.new(0, 60, 0, 18), ResetSegments)
    CreateBtn("HIDE UI", Color3.fromRGB(40, 40, 40), UDim2.new(0, 135, 0, 68), UDim2.new(0, 60, 0, 18), function()
        WidgetGui.Enabled = false
    end)
    
    -- // MENU INTEGRATION //
    local Tab = UI:Tab("Record Pro")
    Tab:Label("Controls")
    Tab:Toggle("Show Recorder UI", function(v) WidgetGui.Enabled = v end).SetState(true)
    
    Tab:Label("Segment Info")
    Tab:Button("Force Stop / Fix", Color3.fromRGB(200, 50, 50), StopReplaySystem)
    Tab:Button("Delete All Segments", Color3.fromRGB(150, 50, 50), ResetSegments)
    
    -- Auto cleanup
    Config.OnReset.Event:Connect(function()
        StopReplaySystem()
        WidgetGui:Destroy()
    end)
    
    return true
end