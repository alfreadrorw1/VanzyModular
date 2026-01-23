return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    
    local FolderPath = "VanzyData/Records"
    
    -- // UTILITIES //
    if not isfolder("VanzyData") then makefolder("VanzyData") end
    if not isfolder(FolderPath) then makefolder(FolderPath) end
    
    -- [IMPROVED] High Precision Number (5 decimals) to reduce jitter
    local function cn(num)
        return math.floor(num * 100000) / 100000
    end
    
    -- Serialization
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        -- Save full precision for rotation components to prevent "snapping"
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
                -- Ignore default roblox emote scripts to prevent conflicts
                if track.Animation.AnimationId then 
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightTarget),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        l = track.Looped -- Capture Loop state
                    })
                end
            end
        end
        return anims
    end
    
    -- // UI WIDGET (SAME AS BEFORE) //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui
    
    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 160, 0, 50)
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    WidgetFrame.BorderSizePixel = 0
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 1.5
    
    local dragging, dragInput, dragStart, startPos
    WidgetFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = WidgetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
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
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    
    local function CreateMiniBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = UDim2.new(0, 30, 0, 30)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        local corn = Instance.new("UICorner", btn)
        corn.CornerRadius = UDim.new(0, 6)
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
        CurrentRecord = {Frames = {}, Metadata = {PlaceId = game.PlaceId, Duration = 0}}
        
        StatusLabel.Text = "REC ●"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)
        
        -- Use Heartbeat (Physics Step) for accurate recording
        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording or not LocalPlayer.Character then return end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = os.clock() - StartTime, -- No rounding on time for recording
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end
    
    local function StopRecording()
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end
        
        StatusLabel.Text = "STOPPED"
        StatusLabel.TextColor3 = Theme.Accent
        WStroke.Color = Theme.Accent
        
        -- Auto Save
        local fileName = "Rec_" .. game.PlaceId .. "_" .. math.floor(os.time()) .. ".json"
        writefile(FolderPath .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
        
        Services.StarterGui:SetCore("SendNotification", {Title = "Saved", Text = fileName, Duration = 2})
    end
    
    -- [IMPROVED] Replay Engine with Anchoring
    local function PlayReplay(data)
        if Recording or Replaying then return end
        if not data or not data.Frames or #data.Frames < 2 then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")
        
        if not hrp or not hum then return end
        
        Replaying = true
        StatusLabel.Text = "PLAY ▶"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)
        
        -- 1. PREPARE CHARACTER (THE "ANTI-JITTER" FIX)
        -- We Anchor the HRP. This stops ALL physics interference.
        hrp.Anchored = true
        hum.AutoRotate = false
        
        -- Disable collisions on all parts to prevent flinging
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Teleport to start
        local startCF = DeserializeCFrame(data.Frames[1].cf)
        hrp.CFrame = startCF
        
        local replayStart = os.clock()
        local frameIndex = 1
        local loadedTracks = {}
        
        -- 2. RENDER LOOP (BindToRenderStep for Priority)
        -- Priority 2000 is usually Camera, we go 1999 to update BEFORE camera
        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Camera.Value - 1, function()
            if not Replaying or not LocalPlayer.Character then 
                StopReplay()
                return 
            end
            
            -- Keep Anchored (Just in case scripts try to unanchor)
            if hrp.Anchored == false then hrp.Anchored = true end
            
            local currentTime = os.clock() - replayStart
            
            -- Find Frames
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]
            
            -- End Check
            if not nextFrame then StopReplay() return end
            
            -- Time Advance
            while nextFrame and currentTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex + 1]
            end
            
            if not nextFrame then return end
            
            -- 3. SMOOTH INTERPOLATION
            local alpha = (currentTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            
            -- Apply CFrame (Since it's Anchored, this is perfectly smooth)
            hrp.CFrame = cf1:Lerp(cf2, alpha)
            
            -- 4. ANIMATION SYNC
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
                    
                    -- Smoothly adjust speed/weight
                    track:AdjustSpeed(animData.s)
                    track:AdjustWeight(animData.w)
                    
                    -- Only sync TimePosition if desync is large (>0.5s) to avoid audio stutter
                    if math.abs(track.TimePosition - animData.t) > 0.5 then
                        track.TimePosition = animData.t
                    end
                end
                
                for id, track in pairs(loadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
        end)
        
        -- RESTORE FUNCTION
        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            
            if LocalPlayer.Character then
                local h = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local hm = LocalPlayer.Character:FindFirstChild("Humanoid")
                if h then h.Anchored = false end -- Unanchor
                if hm then hm.AutoRotate = true end
                
                -- Restore collisions (optional, usually getting up fixes it)
            end
            
            for _, track in pairs(loadedTracks) do track:Stop() end
            
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            WStroke.Color = Theme.Accent
        end
    end
    
    function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end
    
    -- // BUTTONS //
    local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 10), function()
        if Recording then StopRecording() else StartRecording() end
    end)
    
    local PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 50, 0, 10), function()
        if Replaying then StopReplay()
        elseif CurrentRecord.Frames and #CurrentRecord.Frames > 0 then PlayReplay(CurrentRecord)
        else
            Services.StarterGui:SetCore("SendNotification", {Title = "No Data", Text = "Load a file first", Duration = 2})
        end
    end)
    
    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 120, 0, 10), function()
        WidgetGui.Enabled = false
    end)
    
    -- // MENU TAB //
    local Tab = UI:Tab("Record")
    Tab:Label("Floating Controls")
    Tab:Toggle("Show Widget", function(v) WidgetGui.Enabled = v end).SetState(true)
    
    Tab:Label("File Manager")
    local FileContainer = Tab:Container(180)
    
    local function RefreshFiles()
        for _, c in pairs(FileContainer:GetChildren()) do 
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end 
        end
        
        local files = listfiles(FolderPath)
        local found = false
        
        for _, file in ipairs(files) do
            if string.find(file, tostring(game.PlaceId)) then
                found = true
                local name = string.gsub(file, FolderPath .. "/", "")
                local btn = Instance.new("TextButton", FileContainer)
                btn.Size = UDim2.new(1, -10, 0, 30)
                btn.BackgroundColor3 = Theme.Button
                btn.Text = "  " .. string.sub(name, 1, 20)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                
                local playIco = Instance.new("TextButton", btn)
                playIco.Size = UDim2.new(0, 40, 1, 0)
                playIco.Position = UDim2.new(1, -40, 0, 0)
                playIco.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
                playIco.Text = "LOAD"
                playIco.TextColor3 = Color3.white
                Instance.new("UICorner", playIco).CornerRadius = UDim.new(0, 4)
                
                playIco.MouseButton1Click:Connect(function()
                    local content = readfile(file)
                    CurrentRecord = HttpService:JSONDecode(content)
                    Services.StarterGui:SetCore("SendNotification", {Title = "Loaded", Text = "Press Play ▶", Duration = 2})
                end)
                
                local delIco = Instance.new("TextButton", btn)
                delIco.Size = UDim2.new(0, 30, 1, 0)
                delIco.Position = UDim2.new(1, -75, 0, 0)
                delIco.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
                delIco.Text = "DEL"
                delIco.TextColor3 = Color3.white
                Instance.new("UICorner", delIco).CornerRadius = UDim.new(0, 4)
                
                delIco.MouseButton1Click:Connect(function()
                    delfile(file)
                    RefreshFiles()
                end)
            end
        end
    end
    
    Tab:Button("Refresh List", Theme.Button, RefreshFiles)
    RefreshFiles()
    
    Config.OnReset.Event:Connect(function()
        StopRecording()
        StopReplay()
        WidgetGui:Destroy()
    end)
    
    return true
end