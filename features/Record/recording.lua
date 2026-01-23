return function(UI, Services, Config, Theme)
    --// SERVICES & VARIABLES
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local TweenService = Services.TweenService
    local StarterGui = Services.StarterGui
    
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    
    --// FOLDER SYSTEM SETUP
    local RootFolder = "VanzyData"
    local RecordFolder = RootFolder .. "/Records"
    
    -- Dapatkan Nama Map untuk Folder Khusus
    local MapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    MapName = MapName:gsub("%W", "") -- Hapus karakter aneh agar aman buat nama folder
    local CurrentMapFolder = RecordFolder .. "/" .. MapName
    
    -- Init Folder
    if not isfolder(RootFolder) then makefolder(RootFolder) end
    if not isfolder(RecordFolder) then makefolder(RecordFolder) end
    if not isfolder(CurrentMapFolder) then makefolder(CurrentMapFolder) end

    --// STATE
    local Recorder = {
        IsRecording = false,
        IsPlaying = false,
        Data = {},
        StartTime = 0,
        CurrentConnection = nil,
        ActiveTracks = {}, -- Cache animasi saat replay
        WidgetVisible = true
    }

    --// UTILS: PRECISION & FORMATTING
    local function Round(num)
        return math.floor(num * 100000) / 100000 -- 5 Decimal Precision
    end

    local function Notify(title, text, duration)
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end

    local function GetCharacter()
        return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    end

    --// CORE: RECORDING SYSTEM
    function Recorder:StartRecording()
        if self.IsPlaying then return Notify("Error", "Stop playback first!", 2) end
        
        self.IsRecording = true
        self.Data = {}
        self.StartTime = os.clock()
        
        local Char = GetCharacter()
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        
        if not Root or not Hum then return end

        Notify("Recorder", "Started Recording...", 2)

        self.CurrentConnection = RunService.Heartbeat:Connect(function()
            if not self.IsRecording then return end
            
            local TimeNow = os.clock() - self.StartTime
            local FrameData = {
                t = Round(TimeNow),
                -- Simpan CFrame (Posisi + Rotasi)
                cf = {
                    Round(Root.CFrame.X), Round(Root.CFrame.Y), Round(Root.CFrame.Z),
                    Round(Root.CFrame.LookVector.X), Round(Root.CFrame.LookVector.Y), Round(Root.CFrame.LookVector.Z)
                },
                -- Simpan Animasi
                anims = {}
            }

            -- Capture Animasi
            for _, track in pairs(Hum:GetPlayingAnimationTracks()) do
                if track.Animation then
                    table.insert(FrameData.anims, {
                        id = track.Animation.AnimationId,
                        w = Round(track.Weight),
                        s = Round(track.Speed),
                        tp = Round(track.TimePosition)
                    })
                end
            end
            
            table.insert(self.Data, FrameData)
        end)
    end

    function Recorder:StopRecording()
        self.IsRecording = false
        if self.CurrentConnection then
            self.CurrentConnection:Disconnect()
            self.CurrentConnection = nil
        end
        Notify("Recorder", "Recording Stopped. Data Frames: " .. #self.Data, 3)
    end

    function Recorder:SaveRecording(filename)
        if #self.Data == 0 then return Notify("Error", "No data to save!", 2) end
        
        local path = CurrentMapFolder .. "/" .. filename .. ".json"
        writefile(path, HttpService:JSONEncode(self.Data))
        Notify("System", "Saved to: " .. filename, 3)
        Recorder:RefreshFileList() -- Update UI List
    end

    --// CORE: REPLAY SYSTEM (Interpolated & Smart)
    function Recorder:StopReplay()
        self.IsPlaying = false
        
        local Char = GetCharacter()
        local Hum = Char:FindFirstChild("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")

        -- Cleanup Physics
        if Root then Root.Anchored = false end
        if Hum then 
            Hum.AutoRotate = true 
            Hum.PlatformStand = false
        end

        -- Stop All Forced Anims
        for _, track in pairs(self.ActiveTracks) do
            track:Stop()
        end
        self.ActiveTracks = {}
        
        Notify("System", "Replay Stopped", 2)
    end

    function Recorder:PlayData(Dataset, StartFromNearest)
        if self.IsRecording then return end
        if #Dataset == 0 then return end

        self.IsPlaying = true
        local Char = GetCharacter()
        local Hum = Char:FindFirstChild("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        
        -- Setup Physics
        Root.Anchored = true
        Hum.AutoRotate = false
        Hum.PlatformStand = true -- Matikan physics kaki biar mulus
        
        -- Preload Animations (Optimization)
        local AnimCache = {} 
        local function GetTrack(id)
            if not AnimCache[id] then
                local anim = Instance.new("Animation")
                anim.AnimationId = id
                local track = Hum:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action4
                AnimCache[id] = track
                table.insert(self.ActiveTracks, track)
            end
            return AnimCache[id]
        end

        -- Logic: Start from Middle?
        local StartIndex = 1
        if StartFromNearest then
            local CurrentPos = Root.Position
            local MinDist = 100 -- Jarak toleransi (studs)
            
            for i = 1, #Dataset, 5 do -- Scan every 5 frames for speed
                local d = Dataset[i]
                local RecPos = Vector3.new(d.cf[1], d.cf[2], d.cf[3])
                local Dist = (CurrentPos - RecPos).Magnitude
                
                if Dist < MinDist then
                    MinDist = Dist
                    StartIndex = i
                end
            end
            
            if StartIndex > 1 then
                Notify("Smart Replay", "Resuming from Frame: " .. StartIndex, 2)
            end
        end

        -- Playback Loop
        local StartTick = os.clock()
        -- Adjust start time so we don't jump if resuming
        local TimeOffset = Dataset[StartIndex].t 
        
        for i = StartIndex, #Dataset do
            if not self.IsPlaying then break end
            
            local Frame = Dataset[i]
            local NextFrame = Dataset[i+1]
            
            -- Sync Time
            local TargetTime = Frame.t - TimeOffset
            local ActualTime = os.clock() - StartTick
            
            -- Wait logic (busy wait for precision)
            if ActualTime < TargetTime then
                -- Optional: Interpolasi antar frame jika FPS drop
                local waitTime = TargetTime - ActualTime
                if waitTime > 0.03 then task.wait(waitTime) end 
            end

            -- 1. Apply Position (CFrame Construct)
            local Pos = Vector3.new(Frame.cf[1], Frame.cf[2], Frame.cf[3])
            local Look = Vector3.new(Frame.cf[4], Frame.cf[5], Frame.cf[6])
            
            -- Smooth Lerp jika ada next frame
            if NextFrame then
                local Alpha = 0.5 -- Simple smoothing
                local NextPos = Vector3.new(NextFrame.cf[1], NextFrame.cf[2], NextFrame.cf[3])
                Pos = Pos:Lerp(NextPos, Alpha)
            end
            
            Root.CFrame = CFrame.new(Pos, Pos + Look)

            -- 2. Apply Animations
            for _, animData in pairs(Frame.anims) do
                local track = GetTrack(animData.id)
                if not track.IsPlaying then track:Play(0) end
                
                track.TimePosition = animData.tp
                track:AdjustWeight(animData.w)
                track:AdjustSpeed(animData.s)
            end
            
            -- Stop animations that are NOT in this frame
            for id, track in pairs(AnimCache) do
                local isPresent = false
                for _, a in pairs(Frame.anims) do
                    if a.id == id then isPresent = true break end
                end
                if not isPresent and track.IsPlaying then
                    track:Stop(0.1)
                end
            end
            
            RunService.Heartbeat:Wait()
        end
        
        self:StopReplay()
    end

    --// FEATURE: PLAY ALL (CP1 -> CP2 -> ...)
    function Recorder:PlayAllCheckpoints()
        local files = listfiles(CurrentMapFolder)
        local CombinedData = {}
        local SortedFiles = {}

        -- Filter & Sort JSON files
        for _, file in ipairs(files) do
            if file:sub(-5) == ".json" then
                table.insert(SortedFiles, file)
            end
        end
        table.sort(SortedFiles) -- Urutkan CP1, CP2, CP3...

        Notify("Manager", "Merging " .. #SortedFiles .. " Checkpoints...", 3)

        -- Load & Merge Data
        for _, file in ipairs(SortedFiles) do
            local content = readfile(file)
            local data = HttpService:JSONDecode(content)
            
            -- Append data to CombinedData
            for _, frame in ipairs(data) do
                table.insert(CombinedData, frame)
            end
        end

        if #CombinedData > 0 then
            -- Smart Play: Jika player ada di tengah CP2, dia akan lanjut dari situ
            self:PlayData(CombinedData, true)
        else
            Notify("Error", "No recordings found in folder!", 3)
        end
    end

    --// UI INTEGRATION
    local Tab = UI:Tab("Record")
    local FileListContainer = nil

    -- 1. Main Controls
    Tab:Label("RECORDING CONTROLS")
    
    Tab:Toggle("Show Widget", function(state)
        Recorder.WidgetVisible = state
        if Recorder.WidgetGUI then Recorder.WidgetGUI.Visible = state end
    end):SetState(true)

    Tab:Button("Stop All / Unanchor", Theme.ButtonRed, function()
        Recorder:StopRecording()
        Recorder:StopReplay()
    end)

    -- 2. File Manager
    Tab:Label("FILE MANAGER (Map: " .. MapName .. ")")
    
    Tab:Input("File Name (e.g., CP1)", function(text)
        Recorder.TargetFileName = text
    end)

    Tab:Button("Save Recording", Theme.Confirm, function()
        if Recorder.TargetFileName and Recorder.TargetFileName ~= "" then
            Recorder:SaveRecording(Recorder.TargetFileName)
        else
            Notify("Error", "Enter file name first!", 2)
        end
    end)

    Tab:Button("▶ PLAY ALL (Auto-Merge)", Theme.PlayBtn, function()
        Recorder:PlayAllCheckpoints()
    end)

    Tab:Button("Refresh List", Theme.Button, function()
        Recorder:RefreshFileList()
    end)

    -- Container List File
    Tab:Label("Saved Recordings:")
    FileListContainer = Tab:Container(150)

    function Recorder:RefreshFileList()
        -- Clear old children
        for _, v in pairs(FileListContainer:GetChildren()) do
            if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end
        end

        local files = listfiles(CurrentMapFolder)
        table.sort(files)

        for _, filepath in ipairs(files) do
            if filepath:sub(-5) == ".json" then
                local filename = filepath:match("([^/]+)$"):sub(1, -6) -- Ambil nama file tanpa path/ext
                
                local btn = Instance.new("TextButton", FileListContainer)
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Theme.ButtonDark
                btn.Text = "  " .. filename
                btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                
                -- Play Icon
                local playBtn = Instance.new("TextButton", btn)
                playBtn.Size = UDim2.new(0, 20, 0, 20)
                playBtn.Position = UDim2.new(1, -50, 0, 2)
                playBtn.BackgroundColor3 = Theme.PlayBtn
                playBtn.Text = "▶"
                playBtn.TextColor3 = Color3.white
                
                -- Delete Icon
                local delBtn = Instance.new("TextButton", btn)
                delBtn.Size = UDim2.new(0, 20, 0, 20)
                delBtn.Position = UDim2.new(1, -25, 0, 2)
                delBtn.BackgroundColor3 = Theme.ButtonRed
                delBtn.Text = "X"
                delBtn.TextColor3 = Color3.white

                -- Events
                playBtn.MouseButton1Click:Connect(function()
                    local content = readfile(filepath)
                    local data = HttpService:JSONDecode(content)
                    Notify("Load", "Playing " .. filename, 2)
                    Recorder:PlayData(data, true) -- True = Support resume
                end)

                delBtn.MouseButton1Click:Connect(function()
                    delfile(filepath)
                    Notify("Delete", "Deleted " .. filename, 2)
                    Recorder:RefreshFileList()
                end)
                
                -- Load to Memory (untuk di-save ulang)
                btn.MouseButton1Click:Connect(function()
                    local content = readfile(filepath)
                    Recorder.Data = HttpService:JSONDecode(content)
                    Notify("System", "Loaded " .. filename .. " to memory", 1)
                end)
            end
        end
    end

    -- Initial Load
    Recorder:RefreshFileList()

    --// FLOATING WIDGET UI
    local function CreateWidget()
        local WG = Instance.new("ScreenGui", Services.CoreGui)
        WG.Name = "VanzyRecWidget"
        
        local Frame = Instance.new("Frame", WG)
        Frame.Size = UDim2.new(0, 130, 0, 40)
        Frame.Position = UDim2.new(0.5, -65, 0.05, 0)
        Frame.BackgroundColor3 = Theme.Main
        Frame.BorderSizePixel = 0
        
        local Stroke = Instance.new("UIStroke", Frame)
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 2
        
        local Corner = Instance.new("UICorner", Frame)
        Corner.CornerRadius = UDim.new(0, 8)
        
        -- Status Dot
        local Dot = Instance.new("Frame", Frame)
        Dot.Size = UDim2.new(0, 10, 0, 10)
        Dot.Position = UDim2.new(0, 10, 0.5, -5)
        Dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray (Idle)
        local DotCorner = Instance.new("UICorner", Dot)
        DotCorner.CornerRadius = UDim.new(1, 0)
        
        -- Logic Visual Loop
        spawn(function()
            while WG.Parent do
                if Recorder.IsRecording then
                    Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
                    local t = (os.clock() % 1)
                    Dot.BackgroundTransparency = t > 0.5 and 0.5 or 0
                elseif Recorder.IsPlaying then
                    Dot.BackgroundColor3 = Color3.fromRGB(50, 255, 50) -- Green
                    Dot.BackgroundTransparency = 0
                else
                    Dot.BackgroundColor3 = Theme.Accent
                    Dot.BackgroundTransparency = 0
                end
                task.wait(0.1)
            end
        end)
        
        -- Rec Button
        local RecBtn = Instance.new("TextButton", Frame)
        RecBtn.Size = UDim2.new(0, 30, 0, 30)
        RecBtn.Position = UDim2.new(0, 30, 0, 5)
        RecBtn.BackgroundColor3 = Theme.ButtonDark
        RecBtn.Text = "●"
        RecBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        RecBtn.Font = Enum.Font.GothamBlack
        RecBtn.TextSize = 18
        Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)
        
        RecBtn.MouseButton1Click:Connect(function()
            if Recorder.IsRecording then
                Recorder:StopRecording()
            else
                Recorder:StartRecording()
            end
        end)
        
        -- Play Last Button
        local PlayBtn = Instance.new("TextButton", Frame)
        PlayBtn.Size = UDim2.new(0, 30, 0, 30)
        PlayBtn.Position = UDim2.new(0, 65, 0, 5)
        PlayBtn.BackgroundColor3 = Theme.ButtonDark
        PlayBtn.Text = "▶"
        PlayBtn.TextColor3 = Theme.PlayBtn
        PlayBtn.Font = Enum.Font.GothamBlack
        PlayBtn.TextSize = 18
        Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)
        
        PlayBtn.MouseButton1Click:Connect(function()
            if Recorder.IsPlaying then
                Recorder:StopReplay()
            else
                if #Recorder.Data > 0 then
                    Recorder:PlayData(Recorder.Data, true)
                else
                    -- Try play all if memory empty
                    Recorder:PlayAllCheckpoints()
                end
            end
        end)

        -- Hide Button
        local HideBtn = Instance.new("TextButton", Frame)
        HideBtn.Size = UDim2.new(0, 25, 0, 25)
        HideBtn.Position = UDim2.new(1, -30, 0.5, -12)
        HideBtn.BackgroundTransparency = 1
        HideBtn.Text = "_"
        HideBtn.TextColor3 = Color3.white
        HideBtn.Font = Enum.Font.GothamBlack
        
        HideBtn.MouseButton1Click:Connect(function()
            Frame.Visible = false
            Notify("Widget", "Widget Hidden. Use main menu to show.", 2)
            Recorder.WidgetVisible = false
        end)
        
        -- Drag Logic
        local dragInput, dragStart, startPos
        Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = input.Position
                startPos = Frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragStart = nil
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if dragStart then
                    local delta = input.Position - dragStart
                    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end)

        Recorder.WidgetGUI = Frame
        return WG
    end

    CreateWidget()

    return Recorder
end