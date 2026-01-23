return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local TweenService = Services.TweenService
    local LocalPlayer = Players.LocalPlayer
    
    -- // FILESYSTEM SETUP //
    local ROOT_FOLDER = "VanzyData"
    local REPLAY_FOLDER = ROOT_FOLDER .. "/Replays"
    local GAME_FOLDER = REPLAY_FOLDER .. "/" .. tostring(game.PlaceId)
    
    if not isfolder(ROOT_FOLDER) then makefolder(ROOT_FOLDER) end
    if not isfolder(REPLAY_FOLDER) then makefolder(REPLAY_FOLDER) end
    if not isfolder(GAME_FOLDER) then makefolder(GAME_FOLDER) end
    
    -- // STATE MANAGEMENT //
    local State = {
        Recording = false,
        Replaying = false,
        CurrentSegment = 1,
        DataBuffer = {},
        Queue = {}
    }
    local Connection = nil
    
    -- // HELPER FUNCTIONS //
    local function cn(num) return math.floor(num * 100000) / 100000 end
    
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end
    
    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end
    
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId and #track.Animation.AnimationId > 0 then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightTarget),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        p = track.Priority.Value
                    })
                end
            end
        end
        return anims
    end
    
    -- // UI ELEMENTS REFERENCES //
    local Tab = UI:Tab("Record") -- Menggunakan Tab dari Main UI
    local StatusLabel = nil -- Akan diisi nanti
    local FileListContainer = nil
    
    -- // WIDGET CREATION (STYLISH) //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidgetV4"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui
    
    local Widget = Instance.new("Frame", WidgetGui)
    Widget.Size = UDim2.new(0, 180, 0, 50)
    Widget.Position = UDim2.new(0.5, -90, 0.1, 0)
    Widget.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Widget.BorderSizePixel = 0
    Widget.Active = true
    
    local WStroke = Instance.new("UIStroke", Widget)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    local WCorner = Instance.new("UICorner", Widget)
    WCorner.CornerRadius = UDim.new(0, 12)
    
    -- Widget Drag
    local dragging, dragStart, startPos
    Widget.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Widget.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Widget.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Widget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Widget Status Text
    local WStatus = Instance.new("TextLabel", Widget)
    WStatus.Size = UDim2.new(1, 0, 0, 15)
    WStatus.Position = UDim2.new(0, 0, 0, 2)
    WStatus.BackgroundTransparency = 1
    WStatus.Text = "IDLE - READY"
    WStatus.TextColor3 = Theme.Accent
    WStatus.Font = Enum.Font.GothamBold
    WStatus.TextSize = 10
    
    -- Widget Buttons Container
    local WBtnContainer = Instance.new("Frame", Widget)
    WBtnContainer.Size = UDim2.new(1, -10, 0, 25)
    WBtnContainer.Position = UDim2.new(0, 5, 0, 20)
    WBtnContainer.BackgroundTransparency = 1
    
    local UILayout = Instance.new("UIListLayout", WBtnContainer)
    UILayout.FillDirection = Enum.FillDirection.Horizontal
    UILayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UILayout.Padding = UDim.new(0, 5)
    
    local function CreateWBtn(text, color, callback)
        local btn = Instance.new("TextButton", WBtnContainer)
        btn.Size = UDim2.new(0, 50, 1, 0)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.white
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- // UPDATE UI STATE FUNCTION //
    local function UpdateStatus(text, color)
        -- Update Widget
        WStatus.Text = text
        WStatus.TextColor3 = color
        WStroke.Color = color
        
        -- Update Main Menu Label (If exists)
        if StatusLabel then
            StatusLabel.Text = "STATUS: " .. text
            StatusLabel.TextColor3 = color
        end
    end
    
    -- // FILE MANAGER LOGIC //
    local function GetSegmentCount()
        local files = listfiles(GAME_FOLDER)
        local count = 0
        for _, file in ipairs(files) do
            if string.find(file, "Segment_") then count = count + 1 end
        end
        return count
    end
    
    local function RefreshFileList()
        if not FileListContainer then return end
        
        -- Clear old buttons
        for _, child in pairs(FileListContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local files = listfiles(GAME_FOLDER)
        local sortedFiles = {}
        for _, file in ipairs(files) do
            if string.find(file, "Segment_") then
                table.insert(sortedFiles, file)
            end
        end
        table.sort(sortedFiles)
        
        for i, file in ipairs(sortedFiles) do
            local fileName = string.gsub(file, GAME_FOLDER .. "/", "")
            
            local btn = Instance.new("TextButton", FileListContainer)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.Text = "  " .. fileName
            btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = UDim.new(0, 4)
            
            local delBtn = Instance.new("TextButton", btn)
            delBtn.Size = UDim2.new(0, 30, 1, 0)
            delBtn.Position = UDim2.new(1, -30, 0, 0)
            delBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            delBtn.Text = "X"
            delBtn.TextColor3 = Color3.white
            local dc = Instance.new("UICorner", delBtn)
            dc.CornerRadius = UDim.new(0, 4)
            
            delBtn.MouseButton1Click:Connect(function()
                delfile(file)
                RefreshFileList()
                State.CurrentSegment = GetSegmentCount() + 1
            end)
        end
        
        State.CurrentSegment = #sortedFiles + 1
    end
    
    -- // RECORDING SYSTEM //
    local function StartRec()
        if State.Recording or State.Replaying then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        State.Recording = true
        State.DataBuffer = { SegmentIndex = State.CurrentSegment, Frames = {} }
        local startTime = os.clock()
        
        UpdateStatus("RECORDING CP " .. State.CurrentSegment, Color3.fromRGB(255, 50, 50))
        
        Connection = RunService.Heartbeat:Connect(function()
            if not State.Recording then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(State.DataBuffer.Frames, {
                    t = os.clock() - startTime,
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end
    
    local function StopRec()
        if not State.Recording then return end
        State.Recording = false
        if Connection then Connection:Disconnect() end
        
        -- Save
        local fileName = string.format("Segment_%02d.json", State.CurrentSegment)
        writefile(GAME_FOLDER .. "/" .. fileName, HttpService:JSONEncode(State.DataBuffer))
        
        UpdateStatus("SAVED CP " .. State.CurrentSegment, Theme.Accent)
        RefreshFileList()
        
        Services.StarterGui:SetCore("SendNotification", {Title="Saved", Text=fileName, Duration=2})
    end
    
    -- // PLAYBACK SYSTEM //
    local function PlayAll()
        if State.Recording or State.Replaying then return end
        
        local files = listfiles(GAME_FOLDER)
        if #files == 0 then return end
        
        local segments = {}
        for _, file in ipairs(files) do
            if string.find(file, "Segment_") then
                table.insert(segments, HttpService:JSONDecode(readfile(file)))
            end
        end
        table.sort(segments, function(a,b) return a.SegmentIndex < b.SegmentIndex end)
        
        State.Replaying = true
        State.Queue = segments
        
        -- Setup Character
        local char = LocalPlayer.Character
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local animator = hum:FindFirstChildOfClass("Animator")
        
        -- ANCHOR MODE ON
        hrp.Anchored = true
        hum.AutoRotate = false
        for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        
        task.spawn(function()
            for i, seg in ipairs(State.Queue) do
                if not State.Replaying then break end
                
                UpdateStatus("PLAYING CP " .. seg.SegmentIndex, Color3.fromRGB(50, 255, 100))
                
                -- Instant Teleport to start of segment
                if #seg.Frames > 0 then hrp.CFrame = DeserializeCFrame(seg.Frames[1].cf) end
                
                local idx = 1
                local startT = os.clock()
                local dur = seg.Frames[#seg.Frames].t
                local loaded = {}
                local running = true
                
                local conn
                conn = RunService.RenderStepped:Connect(function()
                    if not State.Replaying then running = false return end
                    
                    hrp.Anchored = true -- Force anchor
                    
                    local now = os.clock() - startT
                    if now >= dur then running = false return end
                    
                    local curF = seg.Frames[idx]
                    local nxtF = seg.Frames[idx+1]
                    
                    while nxtF and now > nxtF.t do
                        idx = idx + 1
                        curF = seg.Frames[idx]
                        nxtF = seg.Frames[idx+1]
                    end
                    
                    if not nxtF then return end
                    
                    -- Smooth Move
                    local alpha = (now - curF.t) / (nxtF.t - curF.t)
                    hrp.CFrame = DeserializeCFrame(curF.cf):Lerp(DeserializeCFrame(nxtF.cf), math.clamp(alpha,0,1))
                    
                    -- Anim
                    if curF.anims and animator then
                        local active = {}
                        for _, a in ipairs(curF.anims) do
                            active[a.id] = true
                            local t = loaded[a.id]
                            if not t then
                                local anim = Instance.new("Animation")
                                anim.AnimationId = a.id
                                t = animator:LoadAnimation(anim)
                                t.Priority = Enum.AnimationPriority[Enum.AnimationPriority:GetEnumItems()[a.p+1].Name]
                                loaded[a.id] = t
                            end
                            if not t.IsPlaying then t:Play(0.1) end
                            t:AdjustSpeed(a.s)
                            t:AdjustWeight(a.w)
                            if math.abs(t.TimePosition - a.t) > 0.15 then t.TimePosition = a.t end
                        end
                        for id, t in pairs(loaded) do if not active[id] then t:Stop(0.2) end end
                    end
                end)
                
                repeat task.wait() until not running
                conn:Disconnect()
                for _, t in pairs(loaded) do t:Stop(0) end
            end
            StopSys()
        end)
    end
    
    function StopSys()
        State.Replaying = false
        State.Recording = false
        if Connection then Connection:Disconnect() end
        
        if LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
        UpdateStatus("READY", Theme.Accent)
    end
    
    local function ResetData()
        local files = listfiles(GAME_FOLDER)
        for _, f in ipairs(files) do delfile(f) end
        RefreshFileList()
        UpdateStatus("CLEARED", Color3.fromRGB(150, 150, 150))
    end
    
    -- // WIDGET BUTTONS //
    local WRec = CreateWBtn("REC", Color3.fromRGB(200, 50, 50), function() if State.Recording then StopRec() else StartRec() end end)
    local WPlay = CreateWBtn("PLAY", Color3.fromRGB(50, 200, 100), function() if State.Replaying then StopSys() else PlayAll() end end)
    local WHide = CreateWBtn("HIDE", Color3.fromRGB(50, 50, 50), function() WidgetGui.Enabled = false end)
    
    -- // MAIN UI TAB POPULATION //
    -- Label Status
    Tab:Label("Dashboard Status")
    
    -- Status Display
    local StatusFrame = Instance.new("Frame", Tab:Container(1).Parent) -- Hacky way to get parent if needed, but easier to just use Label
    -- Kita pakai cara library standar saja agar aman
    
    -- Status Text (We will update this via reference)
    local StatusContainer = Tab:Container(30)
    StatusLabel = Instance.new("TextLabel", StatusContainer)
    StatusLabel.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "STATUS: READY"
    StatusLabel.TextColor3 = Theme.Accent
    StatusLabel.Font = Enum.Font.GothamBlack
    StatusLabel.TextSize = 14
    
    Tab:Label("Controls")
    
    -- Record Button
    Tab:Button("● REC / STOP (New CP)", Color3.fromRGB(200, 50, 50), function()
        if State.Recording then StopRec() else StartRec() end
    end)
    
    -- Play Button
    Tab:Button("▶ PLAY ALL SEGMENTS", Color3.fromRGB(40, 180, 80), function()
        if State.Replaying then StopSys() else PlayAll() end
    end)
    
    -- Stop Force
    Tab:Button("■ FORCE STOP", Color3.fromRGB(150, 50, 50), StopSys)
    
    Tab:Label("Saved Segments")
    
    -- Create Container for File List
    FileListContainer = Tab:Container(150)
    
    Tab:Button("Refresh List", Theme.Button, RefreshFileList)
    Tab:Button("DELETE ALL DATA", Color3.fromRGB(100, 0, 0), ResetData)
    
    Tab:Label("Settings")
    Tab:Toggle("Show Floating Widget", function(state)
        WidgetGui.Enabled = state
    end).SetState(true)
    
    -- Auto Refresh on Load
    RefreshFileList()
    
    -- // CLEANUP //
    Config.OnReset.Event:Connect(function()
        StopSys()
        WidgetGui:Destroy()
    end)
    
    return true
end