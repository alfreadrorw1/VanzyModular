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
    local ReplayQueue = {} 
    local LoadedTracks = {} 
    
    -- // FILE SYSTEM //
    local RootFolder = "VanzyData"
    local RecordsFolder = RootFolder .. "/Records"
    
    local MapName = "UnknownMap"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        MapName = info.Name:gsub("%W", "") 
    end)
    if MapName == "" then MapName = tostring(game.PlaceId) end
    
    local MapFolder = RecordsFolder .. "/" .. MapName

    if not isfolder(RootFolder) then makefolder(RootFolder) end
    if not isfolder(RecordsFolder) then makefolder(RecordsFolder) end
    if not isfolder(MapFolder) then makefolder(MapFolder) end

    -- // UTILITIES //
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

    local function Notify(title, text)
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 3;})
    end

    -- // FLOATING WIDGET UI //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    WidgetGui.Enabled = false -- [FIX] Default Hidden
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui

    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 200, 0, 70) -- [FIX] Lebih besar agar button muat
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    WidgetFrame.BorderSizePixel = 0
    
    local WCorner = Instance.new("UICorner", WidgetFrame)
    WCorner.CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2

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

    -- Status Label
    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0, 5)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.ZIndex = 2

    -- [FIX] Helper Button Function dengan ZIndex tinggi
    local function CreateMiniBtn(text, color, pos, size, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = size
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.white
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.ZIndex = 5 -- [FIX] Pastikan di atas layer lain
        
        local corn = Instance.new("UICorner", btn)
        corn.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- // LOGIC FUNCTIONS //
    
    local function StartRecording()
        if Recording or Replaying then return end
        local char = LocalPlayer.Character
        if not char then return end

        Recording = true
        StartTime = os.clock()
        CurrentRecord = {Frames = {}, Metadata = {Map = MapName}}
        
        StatusLabel.Text = "RECORDING ●"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        WStroke.Color = Color3.fromRGB(255, 50, 50)

        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = os.clock() - StartTime,
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
        
        local finalName = saveName or ("Rec_" .. math.floor(os.time()))
        if not finalName:find(".json") then finalName = finalName .. ".json" end

        writefile(MapFolder .. "/" .. finalName, HttpService:JSONEncode(CurrentRecord))
        Notify("Saved", finalName)
        StatusLabel.Text = "READY"
        StatusLabel.TextColor3 = Color3.white
        WStroke.Color = Theme.Accent
    end

    -- Global Stop
    function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end

    local function PlayReplayData(data, useSmartResume, onComplete)
        if not data or not data.Frames or #data.Frames < 2 then 
            if onComplete then onComplete() end return 
        end

        Replaying = true
        StatusLabel.Text = "PLAYING ▶"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        WStroke.Color = Color3.fromRGB(50, 255, 100)

        local char = LocalPlayer.Character
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local animator = hum:FindFirstChildOfClass("Animator")

        hrp.Anchored = true
        hum.AutoRotate = false
        for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end

        local startIndex = 1
        if useSmartResume then
            local minDist = 999999
            for i = 1, #data.Frames, 10 do
                local dist = (DeserializeCFrame(data.Frames[i].cf).Position - hrp.Position).Magnitude
                if dist < minDist then minDist = dist; startIndex = i end
            end
            if minDist > 50 then startIndex = 1 end
        end

        local startT = os.clock()
        local frameIndex = startIndex
        local startTimeOffset = data.Frames[startIndex].t
        LoadedTracks = {}

        RunService:BindToRenderStep("VanzyReplay", 2000, function()
            if not Replaying or not LocalPlayer.Character then StopReplay() return end
            hrp.Anchored = true 

            local timeElapsed = os.clock() - startT
            local logicTime = startTimeOffset + timeElapsed
            local curFrame, nextFrame = data.Frames[frameIndex], data.Frames[frameIndex+1]

            if not nextFrame then StopReplay(); if onComplete then onComplete() end return end

            while nextFrame and logicTime > nextFrame.t do
                frameIndex = frameIndex + 1
                curFrame = data.Frames[frameIndex]
                nextFrame = data.Frames[frameIndex+1]
            end
            if not nextFrame then return end

            local alpha = math.clamp((logicTime - curFrame.t) / (nextFrame.t - curFrame.t), 0, 1)
            hrp.CFrame = DeserializeCFrame(curFrame.cf):Lerp(DeserializeCFrame(nextFrame.cf), alpha)

            if curFrame.anims and animator then
                local active = {}
                for _, a in ipairs(curFrame.anims) do
                    active[a.id] = true
                    local t = LoadedTracks[a.id]
                    if not t then
                        local anim = Instance.new("Animation"); anim.AnimationId = a.id
                        t = animator:LoadAnimation(anim); LoadedTracks[a.id] = t
                    end
                    if not t.IsPlaying then t:Play(0.1) end
                    if math.abs(t.Speed - a.s) > 0.01 then t:AdjustSpeed(a.s) end
                    if math.abs(t.WeightTarget - a.w) > 0.01 then t:AdjustWeight(a.w) end
                    if math.abs(t.TimePosition - a.t) > 0.25 then t.TimePosition = a.t end
                end
                for id, t in pairs(LoadedTracks) do if not active[id] then t:Stop(0.2) end end
            end
        end)

        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            if LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                LocalPlayer.Character.Humanoid.AutoRotate = true
            end
            for _, t in pairs(LoadedTracks) do t:Stop() end
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.white
            WStroke.Color = Theme.Accent
        end
    end

    local function PlayAllCheckpoints()
        local files = listfiles(MapFolder)
        local sorted = {}
        for _, f in ipairs(files) do if f:find(".json") then table.insert(sorted, f) end end
        table.sort(sorted)

        local char = LocalPlayer.Character
        local bestIdx, bestDist = 1, 999999

        for i, f in ipairs(sorted) do
            local d = HttpService:JSONDecode(readfile(f))
            if d.Frames[1] then
                local dist = (DeserializeCFrame(d.Frames[1].cf).Position - char.HumanoidRootPart.Position).Magnitude
                if dist < bestDist then bestDist = dist; bestIdx = i end
            end
        end

        local function Chain(idx)
            if idx > #sorted then Notify("Done", "All Replays Finished"); return end
            local d = HttpService:JSONDecode(readfile(sorted[idx]))
            PlayReplayData(d, idx == bestIdx, function() task.wait(0.1); Chain(idx + 1) end)
        end
        Chain(bestIdx)
    end

    -- // WIDGET BUTTONS SETUP //
    -- Posisi diatur manual agar rapi di dalam WidgetFrame (Size: 200, 70)
    -- Y offset 30 agar ada di bawah label status
    
    local BtnRec = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 10, 0, 30), UDim2.new(0, 50, 0, 30), function()
        if Recording then StopRecording() else StartRecording() end
    end)
    
    local BtnPlay = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 70, 0, 30), UDim2.new(0, 50, 0, 30), function()
        if Replaying then StopReplay() else PlayAllCheckpoints() end
    end)

    local BtnHide = CreateMiniBtn("_", Color3.fromRGB(60, 60, 60), UDim2.new(0, 130, 0, 30), UDim2.new(0, 60, 0, 30), function()
        WidgetGui.Enabled = false
        -- Kita perlu update toggle di UI library jika bisa, tapi biasanya one-way cukup
        Notify("Widget Hidden", "Enable it again in Record Tab")
    end)


    -- // TAB UI (LIBRARY INTEGRATION) //
    local Tab = UI:Tab("Record")
    
    -- Menggunakan Label sebagai Header
    Tab:Label("Floating Widget Control")
    
    -- [FIX] Toggle untuk memunculkan Widget (Default False)
    Tab:Toggle("Show Floating Widget", false, function(v)
        WidgetGui.Enabled = v
    end)

    Tab:Label("Manual Controls")
    local SaveName = "CP_1"
    Tab:Input("Checkpoint Name", function(v) SaveName = v end)
    
    -- Menggunakan Button biasa agar lebih pasti muncul
    Tab:Button("Start Recording", Color3.fromRGB(200, 50, 50), StartRecording)
    Tab:Button("Stop & Save", Theme.Button, function() StopRecording(SaveName) end)
    Tab:Button("▶ PLAY CHAIN (Smart)", Color3.fromRGB(50, 200, 100), PlayAllCheckpoints)
    Tab:Button("Stop Replay", Color3.fromRGB(200, 50, 50), StopReplay)

    Tab:Label("Saved Files (" .. MapName .. ")")
    
    -- [FIX] Container dengan tinggi yang cukup
    local FileContainer = Tab:Container(300) 
    
    local function RefreshFiles()
        -- Hapus anak-anak lama di container
        for _, c in pairs(FileContainer:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        
        local files = listfiles(MapFolder)
        table.sort(files)

        for _, file in ipairs(files) do
            local name = file:gsub(MapFolder .. "/", "")
            
            -- Frame pembungkus per file agar rapi
            local Row = Instance.new("Frame", FileContainer)
            Row.Size = UDim2.new(1, -10, 0, 30)
            Row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Row.BorderSizePixel = 0
            Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)

            -- Label Nama File
            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size = UDim2.new(1, -80, 1, 0)
            Lbl.Position = UDim2.new(0, 5, 0, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = name
            Lbl.TextColor3 = Color3.white
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Font = Enum.Font.Gotham

            -- Tombol Load
            local LoadBtn = Instance.new("TextButton", Row)
            LoadBtn.Size = UDim2.new(0, 35, 1, -4)
            LoadBtn.Position = UDim2.new(1, -75, 0, 2)
            LoadBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
            LoadBtn.Text = "▶"
            LoadBtn.TextColor3 = Color3.white
            Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 4)
            
            LoadBtn.MouseButton1Click:Connect(function()
                local data = HttpService:JSONDecode(readfile(file))
                PlayReplayData(data, true)
            end)

            -- Tombol Hapus
            local DelBtn = Instance.new("TextButton", Row)
            DelBtn.Size = UDim2.new(0, 30, 1, -4)
            DelBtn.Position = UDim2.new(1, -35, 0, 2)
            DelBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
            DelBtn.Text = "X"
            DelBtn.TextColor3 = Color3.white
            Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 4)
            
            DelBtn.MouseButton1Click:Connect(function()
                delfile(file)
                RefreshFiles() -- Auto refresh setelah hapus
            end)
        end
    end
    
    Tab:Button("Refresh File List", Theme.Button, RefreshFiles)
    RefreshFiles() -- Load awal

    Config.OnReset.Event:Connect(function()
        StopRecording()
        StopReplay()
        WidgetGui:Destroy()
    end)

    return true
end