return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local MarketplaceService = game:GetService("MarketplaceService")

    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {} 
    local StartTime = 0
    local RecordConnection = nil
    
    -- // FILE SYSTEM CONFIG //
    local RootFolder = "VanzyData"
    local RecordsFolder = RootFolder .. "/Records"
    
    -- Dapatkan Nama Map untuk Folder Khusus
    local PlaceName = "UnknownPlace"
    local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if success and info and info.Name then
        -- Bersihkan nama map dari karakter ilegal untuk folder
        PlaceName = string.gsub(info.Name, "[^%w%s]", ""):gsub("%s+", "_")
    end
    local MapFolder = RecordsFolder .. "/" .. game.PlaceId .. "_" .. PlaceName

    -- // UTILITIES //
    if not isfolder(RootFolder) then makefolder(RootFolder) end
    if not isfolder(RecordsFolder) then makefolder(RecordsFolder) end
    if not isfolder(MapFolder) then makefolder(MapFolder) end

    -- High Precision Number (5 decimals)
    local function cn(num)
        return math.floor(num * 100000) / 100000
    end

    -- Serialization CFrame
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end

    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end

    -- Animation Scanner
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId then
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

    -- // UI WIDGET //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderPro"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui

    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 180, 0, 70)
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    WidgetFrame.BorderSizePixel = 0
    Instance.new("UICorner", WidgetFrame).CornerRadius = UDim.new(0, 8)
    
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 1.5

    -- Dragging Logic
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
    StatusLabel.Text = "MAP: " .. string.sub(PlaceName, 1, 15)
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 9
    StatusLabel.Font = Enum.Font.Gotham

    local StateLabel = Instance.new("TextLabel", WidgetFrame)
    StateLabel.Size = UDim2.new(1, 0, 0, 20)
    StateLabel.BackgroundTransparency = 1
    StateLabel.Text = "READY"
    StateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StateLabel.TextSize = 12
    StateLabel.Font = Enum.Font.GothamBold

    local function CreateMiniBtn(text, color, pos, size, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- // CORE LOGIC //

    local function StartRecording()
        if Recording or Replaying then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        Recording = true
        StartTime = os.clock()
        CurrentRecord = {Frames = {}, Metadata = {PlaceId = game.PlaceId, Created = os.time()}}
        
        StateLabel.Text = "RECORDING ●"
        StateLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)
        
        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = os.clock() - StartTime,
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end

    local function StopRecording(customName)
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end
        
        StateLabel.Text = "SAVING..."
        WStroke.Color = Theme.Accent
        
        local fileName = (customName or "Rec_" .. os.time()) .. ".json"
        writefile(MapFolder .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
        
        Services.StarterGui:SetCore("SendNotification", {Title = "Saved", Text = fileName, Duration = 2})
        StateLabel.Text = "READY"
    end

    -- Fitur Smart Resume: Cari frame terdekat dengan posisi pemain saat ini
    local function GetClosestFrameIndex(frames, currentPos)
        local closestIndex = 1
        local minDist = math.huge
        
        for i = 1, #frames, 5 do -- Scan setiap 5 frame untuk performa
            local frameCF = DeserializeCFrame(frames[i].cf)
            local dist = (frameCF.Position - currentPos).Magnitude
            if dist < minDist then
                minDist = dist
                closestIndex = i
            end
        end
        
        -- Jika jarak terlalu jauh (> 50 stud), anggap user ingin restart dari awal
        if minDist > 50 then
            return 1, false
        end
        return closestIndex, true
    end

    local function PlayReplay(data, attemptResume)
        if Recording or Replaying then return end
        if not data or not data.Frames or #data.Frames < 2 then 
            Services.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Data Corrupt/Empty", Duration = 2})
            return 
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")
        if not hrp or not hum then return end
        
        Replaying = true
        StateLabel.Text = "PLAYING ▶"
        StateLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)

        -- Setup Character
        hrp.Anchored = true
        hum.AutoRotate = false
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end

        -- Determine Start Point (Smart Resume)
        local frameIndex = 1
        if attemptResume then
            local idx, found = GetClosestFrameIndex(data.Frames, hrp.Position)
            if found then
                frameIndex = idx
                Services.StarterGui:SetCore("SendNotification", {Title = "Smart Resume", Text = "Continuing from Frame " .. idx, Duration = 2})
            else
                -- Jika tidak ketemu dekat, teleport ke awal
                hrp.CFrame = DeserializeCFrame(data.Frames[1].cf)
            end
        else
            hrp.CFrame = DeserializeCFrame(data.Frames[1].cf)
        end

        local startTimeOffset = data.Frames[frameIndex].t
        local replayStartReal = os.clock()
        local loadedTracks = {}

        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Camera.Value - 1, function()
            if not Replaying or not LocalPlayer.Character then StopReplay() return end
            
            if hrp.Anchored == false then hrp.Anchored = true end -- Force Anchor
            
            -- Calculate Logic Time
            local timeElapsed = os.clock() - replayStartReal
            local currentAnimTime = startTimeOffset + timeElapsed

            -- Advance Frames
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]

            if not nextFrame then
                StopReplay()
                return
            end

            -- Fast forward logic if lagging behind
            while nextFrame and currentAnimTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex + 1]
            end

            if not nextFrame then return end

            -- Interpolation
            local alpha = (currentAnimTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)

            -- Animation Sync
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
                    
                    if not track.IsPlaying then track:Play(0.1) end
                    track:AdjustSpeed(animData.s)
                    track:AdjustWeight(animData.w)
                    
                    -- Hard Sync jika drift > 0.3s
                    if math.abs(track.TimePosition - animData.t) > 0.3 then
                        track.TimePosition = animData.t
                    end
                end
                
                -- Stop unused anims
                for id, track in pairs(loadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
        end)
        
        -- Cleanup Function
        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            if LocalPlayer.Character then
                local h = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hm = LocalPlayer.Character:FindFirstChild("Humanoid")
                if h then h.Anchored = false end
                if hm then hm.AutoRotate = true end
            end
            for _, track in pairs(loadedTracks) do track:Stop() end
            StateLabel.Text = "READY"
            StateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            WStroke.Color = Theme.Accent
        end
    end

    function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end

    -- // CHECKPOINT MERGER LOGIC //
    local function PlayAllCheckpoints()
        local files = listfiles(MapFolder)
        if #files == 0 then 
            Services.StarterGui:SetCore("SendNotification", {Title = "No Data", Text = "Folder is empty", Duration = 2})
            return 
        end

        table.sort(files) -- Sort alfabetis (CP_1, CP_2, dst)
        
        local CombinedFrames = {}
        local LastTime = 0
        local Count = 0
        
        for _, file in ipairs(files) do
            if string.find(file, ".json") then
                local content = readfile(file)
                local data = HttpService:JSONDecode(content)
                if data and data.Frames then
                    Count = Count + 1
                    -- Stitching Logic
                    for i, frame in ipairs(data.Frames) do
                        local newFrame = {
                            t = frame.t + LastTime, -- Offset waktu
                            cf = frame.cf,
                            anims = frame.anims
                        }
                        table.insert(CombinedFrames, newFrame)
                    end
                    -- Update LastTime untuk file berikutnya
                    if #data.Frames > 0 then
                        LastTime = LastTime + data.Frames[#data.Frames].t
                    end
                end
            end
        end
        
        if #CombinedFrames > 0 then
            Services.StarterGui:SetCore("SendNotification", {Title = "Merged", Text = "Playing " .. Count .. " Checkpoints", Duration = 3})
            PlayReplay({Frames = CombinedFrames}, true) -- Enable Resume logic pada Combined
        end
    end

    -- // WIDGET BUTTONS //
    local RecBtn = CreateMiniBtn("REC", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 25), UDim2.new(0, 45, 0, 35), function()
        if Recording then 
            StopRecording() -- Akan pakai nama timestamp default
        else 
            StartRecording() 
        end
    end)
    
    local PlayBtn = CreateMiniBtn("PLAY", Color3.fromRGB(50, 200, 100), UDim2.new(0, 60, 0, 25), UDim2.new(0, 45, 0, 35), function()
        if Replaying then 
            StopReplay()
        elseif CurrentRecord.Frames and #CurrentRecord.Frames > 0 then
            PlayReplay(CurrentRecord, true)
        else
             Services.StarterGui:SetCore("SendNotification", {Title = "Info", Text = "Load file via menu", Duration = 2})
        end
    end)

    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 110, 0, 25), UDim2.new(0, 25, 0, 35), function()
        WidgetGui.Enabled = false
    end)

    -- // MENU TAB //
    local Tab = UI:Tab("Record Manager")
    
    Tab:Label("Controls & Status")
    Tab:Toggle("Show Widget", function(v) WidgetGui.Enabled = v end).SetState(true)
    Tab:Button("Stop All (Emergency)", Color3.fromRGB(200, 50, 50), function() StopRecording() StopReplay() end)
    
    Tab:Label("Map Folder: " .. PlaceName)
    local FileNameInput = "CP_1"
    Tab:Textbox("Save Name (ex: CP_1)", function(t) FileNameInput = t end)
    
    Tab:Button("Save Current Record", Theme.Button, function()
        if Recording then 
            StopRecording(FileNameInput) 
        elseif #CurrentRecord.Frames > 0 then
            -- Manual Save setelah stop
            local fileName = FileNameInput .. ".json"
            writefile(MapFolder .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
             Services.StarterGui:SetCore("SendNotification", {Title = "Saved Manual", Text = fileName, Duration = 2})
        else
            Services.StarterGui:SetCore("SendNotification", {Title = "Empty", Text = "Nothing to save", Duration = 2})
        end
    end)

    Tab:Label("Playback Options")
    Tab:Button("▶ PLAY ALL CPs (Merge)", Color3.fromRGB(100, 50, 200), PlayAllCheckpoints)
    
    Tab:Label("File List")
    local FileContainer = Tab:Container(250)
    
    local function RefreshFiles()
        for _, c in pairs(FileContainer:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        
        local files = listfiles(MapFolder)
        if #files == 0 then
            local lbl = Instance.new("TextButton", FileContainer)
            lbl.Text = "No records for this map."
            lbl.Size = UDim2.new(1,0,0,20)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(100,100,100)
            return
        end

        for _, file in ipairs(files) do
            local name = string.gsub(file, MapFolder .. "/", "")
            local btn = Instance.new("TextButton", FileContainer)
            btn.Size = UDim2.new(1, -5, 0, 25)
            btn.BackgroundColor3 = Theme.Button
            btn.Text = "  " .. name
            btn.TextColor3 = Color3.white
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            -- Load Btn
            local loadBtn = Instance.new("TextButton", btn)
            loadBtn.Size = UDim2.new(0, 40, 1, 0)
            loadBtn.Position = UDim2.new(1, -75, 0, 0)
            loadBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
            loadBtn.Text = "LOAD"
            loadBtn.TextColor3 = Color3.white
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            loadBtn.MouseButton1Click:Connect(function()
                local content = readfile(file)
                CurrentRecord = HttpService:JSONDecode(content)
                FileNameInput = string.gsub(name, ".json", "") -- Update input box
                Services.StarterGui:SetCore("SendNotification", {Title = "Loaded", Text = name, Duration = 2})
            end)
            
            -- Del Btn
            local delBtn = Instance.new("TextButton", btn)
            delBtn.Size = UDim2.new(0, 30, 1, 0)
            delBtn.Position = UDim2.new(1, -32, 0, 0)
            delBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
            delBtn.Text = "X"
            delBtn.TextColor3 = Color3.white
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            delBtn.MouseButton1Click:Connect(function()
                delfile(file)
                RefreshFiles()
            end)
        end
    end
    
    Tab:Button("Refresh File List", Theme.Button, RefreshFiles)
    RefreshFiles() -- Auto refresh on load
    
    Config.OnReset.Event:Connect(function()
        StopRecording()
        StopReplay()
        WidgetGui:Destroy()
    end)
    
    return true
end