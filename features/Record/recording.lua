return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local CoreGui = Services.CoreGui
    
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local ReplayConnection = nil
    local RecordConnection = nil
    
    local FolderPath = "VanzyData/Records"
    
    -- // UTILITIES //
    
    -- Ensure folder structure
    if not isfolder("VanzyData") then makefolder("VanzyData") end
    if not isfolder(FolderPath) then makefolder(FolderPath) end
    
    -- Compact Number (save space)
    local function cn(num)
        return math.floor(num * 1000) / 1000
    end
    
    -- Serialization Helpers
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), cn(R00), cn(R01), cn(R02), cn(R10), cn(R11), cn(R12), cn(R20), cn(R21), cn(R22)}
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
                table.insert(anims, {
                    id = track.Animation.AnimationId,
                    w = cn(track.WeightTarget),
                    s = cn(track.Speed),
                    t = cn(track.TimePosition)
                })
            end
        end
        return anims
    end
    
    -- // UI CONSTRUCTION (FLOATING WIDGET) //
    
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui
    
    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 160, 0, 50)
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0) -- Top Right default
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    WidgetFrame.BorderSizePixel = 0
    WidgetFrame.Active = true
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 1.5
    
    -- Drag Logic for Widget
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
    
    -- Widget Buttons
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
    
    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    StatusLabel.Position = UDim2.new(0, 0, 1, -15)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    
    -- // RECORDING LOGIC //
    
    local function StartRecording()
        if Recording or Replaying then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        Recording = true
        StartTime = os.clock()
        CurrentRecord = {
            Metadata = {
                PlaceId = game.PlaceId,
                Date = os.date("%c"),
                Duration = 0
            },
            Frames = {}
        }
        
        StatusLabel.Text = "• RECORDING"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)
        
        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording then return end
            if not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = cn(os.clock() - StartTime), -- TimeStamp
                    cf = SerializeCFrame(hrp.CFrame), -- Position & Rotation
                    st = hum:GetState().Value, -- Humanoid State
                    vel = {cn(hrp.AssemblyLinearVelocity.X), cn(hrp.AssemblyLinearVelocity.Y), cn(hrp.AssemblyLinearVelocity.Z)},
                    anims = GetActiveAnimations(hum) -- Active Animations
                })
            end
        end)
    end
    
    local function StopRecording()
        if not Recording then return end
        Recording = false
        
        if RecordConnection then RecordConnection:Disconnect() end
        
        CurrentRecord.Metadata.Duration = cn(os.clock() - StartTime)
        StatusLabel.Text = "STOPPED"
        StatusLabel.TextColor3 = Theme.Accent
        WStroke.Color = Theme.Accent
        
        -- Save File Prompt
        local fileName = "Rec_" .. game.PlaceId .. "_" .. os.time() .. ".json"
        writefile(FolderPath .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Saved",
            Text = fileName,
            Duration = 3
        })
        
        -- Refresh UI List
        -- (Logic to refresh tab list will be added in Tab section)
    end
    
    -- // REPLAY LOGIC //
    
    local function PlayReplay(data)
        if Recording or Replaying then return end
        if not data or not data.Frames or #data.Frames == 0 then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")
        
        if not hrp or not hum then return end
        
        Replaying = true
        StatusLabel.Text = "▶ REPLAYING"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)
        
        -- Setup Character for Replay (Ghost Mode)
        local savedCFrame = hrp.CFrame
        
        -- Disable Physics to prevent gravity/collisions from ruining the replay
        -- This is CRITICAL for smooth replay without jitter
        local originalAutoRotate = hum.AutoRotate
        hum.AutoRotate = false
        
        -- Teleport to start
        local startFrame = data.Frames[1]
        hrp.CFrame = DeserializeCFrame(startFrame.cf)
        hrp.AssemblyLinearVelocity = Vector3.zero
        
        local replayStart = os.clock()
        local frameIndex = 1
        local loadedTracks = {} -- Cache for loaded animations
        
        ReplayConnection = RunService.RenderStepped:Connect(function()
            if not Replaying or not LocalPlayer.Character then 
                StopReplay() 
                return 
            end
            
            -- Force Physics State (Anti-Gravity/Collisions)
            -- We do this every frame because Roblox tries to reset it
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            
            local currentTime = os.clock() - replayStart
            
            -- Find current and next frame for interpolation
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]
            
            if not nextFrame then
                -- End of Replay
                StopReplay()
                return
            end
            
            -- Advance index if needed
            while nextFrame and currentTime > nextFrame.t do
                frameIndex = frameIndex + 1
                currentFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex + 1]
            end
            
            if not nextFrame then return end
            
            -- Interpolate CFrame (Smooth Movement)
            local alpha = (currentTime - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            
            hrp.CFrame = cf1:Lerp(cf2, alpha)
            hrp.AssemblyLinearVelocity = Vector3.zero -- Prevent physics drift
            
            -- Animation Sync
            -- We sync animations based on the current frame's data
            if currentFrame.anims and animator then
                local activeIds = {}
                
                -- Play/Adjust recorded animations
                for _, animData in ipairs(currentFrame.anims) do
                    activeIds[animData.id] = true
                    
                    local track = loadedTracks[animData.id]
                    if not track then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = animData.id
                        track = animator:LoadAnimation(animation)
                        loadedTracks[animData.id] = track
                    end
                    
                    if not track.IsPlaying then
                        track:Play()
                    end
                    
                    -- Sync speed and weight
                    if track.IsPlaying then
                        track:AdjustSpeed(animData.s)
                        track:AdjustWeight(animData.w)
                        -- Optional: Sync TimePosition (Can cause audio stutter, use sparingly)
                        -- if math.abs(track.TimePosition - animData.t) > 0.5 then
                        --     track.TimePosition = animData.t
                        -- end
                    end
                end
                
                -- Stop animations that are not in the current frame
                for id, track in pairs(loadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
        end)
        
        -- Restore function
        local function Restore()
            if ReplayConnection then ReplayConnection:Disconnect() end
            Replaying = false
            hum.AutoRotate = originalAutoRotate
            hum:ChangeState(Enum.HumanoidStateType.GettingUp) -- Reset physics
            
            -- Stop all forced anims
            for _, track in pairs(loadedTracks) do
                track:Stop()
            end
            
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.new(0.7,0.7,0.7)
            WStroke.Color = Theme.Accent
        end
        
        -- Hook StopReplay to Restore
        _G.StopReplayInternal = Restore
    end
    
    function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end
    
    -- // WIDGET BUTTONS SETUP //
    
    -- Record (Circle)
    local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 10), function()
        if Recording then StopRecording() else StartRecording() end
    end)
    
    -- Play (Triangle-ish)
    local PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 50, 0, 10), function()
        if Replaying then 
            StopReplay() 
        elseif CurrentRecord and #CurrentRecord.Frames > 0 then
            PlayReplay(CurrentRecord)
        else
             Services.StarterGui:SetCore("SendNotification", {
                Title = "No Data",
                Text = "Record something or load a file first",
                Duration = 2
            })
        end
    end)
    
    -- Hide Widget
    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 120, 0, 10), function()
        WidgetGui.Enabled = false
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Widget Hidden",
            Text = "Enable via Recording Menu",
            Duration = 2
        })
    end)
    
    -- // MAIN MENU INTEGRATION (FILE MANAGER) //
    
    local Tab = UI:Tab("Record")
    
    Tab:Label("Controls")
    Tab:Toggle("Show Floating Widget", function(v)
        WidgetGui.Enabled = v
    end).SetState(true)
    
    Tab:Button("Stop All Actions", Color3.fromRGB(200, 50, 50), function()
        StopRecording()
        StopReplay()
    end)
    
    Tab:Label("Saved Records (Current Game)")
    
    local FileListContainer = Tab:Container(150)
    
    local function RefreshFileList()
        -- Clear existing (naive clear, remove children except layout)
        for _, child in pairs(FileListContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        local files = listfiles(FolderPath)
        local found = false
        
        for _, file in ipairs(files) do
            if string.find(file, tostring(game.PlaceId)) and string.find(file, ".json") then
                found = true
                local fileName = string.gsub(file, FolderPath .. "/", "")
                local shortName = string.sub(fileName, 1, 25) .. "..."
                
                local btn = Instance.new("TextButton", FileListContainer)
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = Theme.ButtonDark
                btn.Text = "  " .. shortName
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.TextXAlignment = Enum.TextXAlignment.Left
                
                local playIcon = Instance.new("ImageButton", btn)
                playIcon.Size = UDim2.new(0, 20, 0, 20)
                playIcon.Position = UDim2.new(1, -60, 0, 5)
                playIcon.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                playIcon.Image = "" -- Can add icon ID
                
                local playCorner = Instance.new("UICorner", playIcon)
                playCorner.CornerRadius = UDim.new(0, 4)
                
                local delIcon = Instance.new("ImageButton", btn)
                delIcon.Size = UDim2.new(0, 20, 0, 20)
                delIcon.Position = UDim2.new(1, -30, 0, 5)
                delIcon.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                
                local delCorner = Instance.new("UICorner", delIcon)
                delCorner.CornerRadius = UDim.new(0, 4)
                
                -- Play Logic
                playIcon.MouseButton1Click:Connect(function()
                    local content = readfile(file)
                    local data = HttpService:JSONDecode(content)
                    CurrentRecord = data
                    PlayReplay(data)
                end)
                
                -- Delete Logic
                delIcon.MouseButton1Click:Connect(function()
                    delfile(file)
                    btn:Destroy()
                end)
            end
        end
        
        if not found then
            local lbl = Instance.new("TextLabel", FileListContainer)
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No records found for this game."
            lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
        end
    end
    
    Tab:Button("Refresh File List", Theme.Button, RefreshFileList)
    RefreshFileList()
    
    -- // CLEANUP //
    Config.OnReset.Event:Connect(function()
        StopRecording()
        StopReplay()
        WidgetGui:Destroy()
    end)
    
    return true
end