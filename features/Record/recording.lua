return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    local MarketplaceService = Services.MarketplaceService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    
    -- // PATH SYSTEM //
    local BasePath = "VanzyData"
    local RecordsPath = BasePath .. "/Records"
    
    -- Fungsi aman untuk membuat folder
    local function EnsureFolder(path)
        if makefolder and not isfolder(path) then
            makefolder(path)
        end
    end

    EnsureFolder(BasePath)
    EnsureFolder(RecordsPath)

    local function GetMapFolder()
        local mapId = tostring(game.PlaceId)
        local mapName = "Unknown"
        
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and info then
            mapName = info.Name:gsub("[^%w%s]", ""):gsub("%s+", "_")
        else
            mapName = "Map_" .. mapId
        end
        
        local fullPath = RecordsPath .. "/" .. mapName
        EnsureFolder(fullPath)
        return fullPath, mapName
    end
    
    local CurrentMapFolder, MapName = GetMapFolder()
    
    -- // UTILITIES (HIGH PRECISION) //
    local function cn(num)
        return math.floor(num * 100000) / 100000 -- 5 Decimal Precision
    end
    
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), cn(R00), cn(R01), cn(R02), cn(R10), cn(R11), cn(R12), cn(R20), cn(R21), cn(R22)}
    end
    
    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end
    
    local function Notify(title, text, dur)
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = dur or 2})
    end

    -- // ANIMATION SCANNER (IMPROVED) //
    -- Menangkap semua detail agar lari terlihat mirip
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId and track.IsPlaying and track.WeightCurrent > 0 then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightCurrent), -- Menggunakan WeightCurrent bukan Target agar smooth
                        s = cn(track.Speed),
                        t = cn(track.TimePosition)
                    })
                end
            end
        end
        return anims
    end
    
    -- // CORE: RECORDING //
    local function StartRecording()
        if Recording or Replaying then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        Recording = true
        StartTime = os.clock()
        CurrentRecord = {Frames = {}}
        
        -- Update Widget Status
        if _G.UpdateStatus then _G.UpdateStatus("REC ●", Color3.fromRGB(255, 50, 50)) end
        
        -- Merekam menggunakan Heartbeat (Physics Step) agar akurat
        RecordConnection = RunService.Heartbeat:Connect(function()
            if not Recording or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = os.clock() - StartTime, -- Exact time
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum)
                })
            end
        end)
    end
    
    local function StopRecordingAndSave()
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end
        
        if _G.UpdateStatus then _G.UpdateStatus("SAVING...", Color3.fromRGB(255, 200, 50)) end
        
        -- Auto Increment Name (CP1, CP2, etc)
        local nextNum = 1
        local files = listfiles(CurrentMapFolder)
        for _, f in pairs(files) do
            local num = tonumber(f:match("CP(%d+)"))
            if num and num >= nextNum then nextNum = num + 1 end
        end
        
        local fileName = "CP" .. nextNum .. ".json"
        writefile(CurrentMapFolder .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
        
        Notify("Saved", fileName, 3)
        
        if _G.UpdateStatus then _G.UpdateStatus("READY", Theme.Accent) end
        if _G.RefreshList then _G.RefreshList() end
    end
    
    -- // CORE: REPLAY ENGINE (ANTI-JITTER & SMOOTH ANIM) //
    local LoadedTracks = {}
    
    local function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end
    
    local function PlayReplayData(data, onFinishedCallback)
        if Recording or Replaying then return end
        if not data or not data.Frames or #data.Frames < 2 then 
            Notify("Error", "Data rusak/kosong", 2)
            if onFinishedCallback then onFinishedCallback() end
            return 
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")
        
        Replaying = true
        if _G.UpdateStatus then _G.UpdateStatus("PLAY ▶", Color3.fromRGB(50, 255, 100)) end
        
        -- 1. FIX GETAR (Physics Disable)
        hrp.Anchored = true
        hum.PlatformStand = true -- Mematikan physics humanoid agar tidak "berantem"
        hum.AutoRotate = false
        
        -- Matikan collision semua part
        for _, v in pairs(char:GetDescendants()) do 
            if v:IsA("BasePart") then 
                v.CanCollide = false 
                v.CanTouch = false
                v.CanQuery = false
            end 
        end
        
        -- 2. SETUP AWAL
        local startCF = DeserializeCFrame(data.Frames[1].cf)
        hrp.CFrame = startCF
        
        local replayStartReal = os.clock()
        local startIndex = 1
        
        -- 3. RENDER LOOP (High Priority)
        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Character.Value + 1, function()
            if not Replaying or not char.Parent then StopReplay() return end
            
            -- Pastikan tetap anchored
            if not hrp.Anchored then hrp.Anchored = true end
            
            local elapsed = os.clock() - replayStartReal
            
            -- Cari frame yang sesuai dengan waktu sekarang
            local frameIdx = startIndex
            while data.Frames[frameIdx+1] and data.Frames[frameIdx+1].t < elapsed do
                frameIdx = frameIdx + 1
            end
            
            -- Jika habis
            if not data.Frames[frameIdx+1] then
                StopReplay()
                if onFinishedCallback then onFinishedCallback() end
                return
            end
            
            startIndex = frameIdx -- Optimasi loop selanjutnya
            
            local currFrame = data.Frames[frameIdx]
            local nextFrame = data.Frames[frameIdx+1]
            
            -- Interpolasi Posisi (Smooth Movement)
            local alpha = (elapsed - currFrame.t) / (nextFrame.t - currFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)
            
            -- Sinkronisasi Animasi
            if currFrame.anims and animator then
                local activeIds = {}
                for _, anim in ipairs(currFrame.anims) do
                    activeIds[anim.id] = true
                    local track = LoadedTracks[anim.id]
                    
                    if not track then
                        local a = Instance.new("Animation")
                        a.AnimationId = anim.id
                        track = animator:LoadAnimation(a)
                        LoadedTracks[anim.id] = track
                    end
                    
                    if not track.IsPlaying then track:Play(0.1) end
                    
                    -- Update Speed & Weight
                    track:AdjustSpeed(anim.s)
                    track:AdjustWeight(anim.w)
                    
                    -- Anti-Glitch: Hanya paksa waktu jika drift terlalu jauh (>0.15s)
                    if math.abs(track.TimePosition - anim.t) > 0.15 then
                        track.TimePosition = anim.t
                    end
                end
                
                -- Stop animasi yang tidak ada di frame ini
                for id, track in pairs(LoadedTracks) do
                    if not activeIds[id] and track.IsPlaying then
                        track:Stop(0.2)
                    end
                end
            end
        end)
        
        -- Fungsi Stop Internal
        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            
            if char then
                if hrp then hrp.Anchored = false end
                if hum then 
                    hum.PlatformStand = false
                    hum.AutoRotate = true 
                end
                -- Balikin collision (optional, biasanya reset karakter lebih bersih)
                for _, v in pairs(char:GetDescendants()) do 
                    if v:IsA("BasePart") then v.CanCollide = true end 
                end
            end
            
            for _, t in pairs(LoadedTracks) do t:Stop() end
            LoadedTracks = {}
            
            if _G.UpdateStatus then _G.UpdateStatus("READY", Theme.Accent) end
        end
    end
    
    -- // PLAY ALL SYSTEM (CHAIN REACTION) //
    local function PlayAllCheckpoints()
        local files = listfiles(CurrentMapFolder)
        local sortedFiles = {}
        
        -- Sort CP1, CP2, CP10 correctly
        for _, file in ipairs(files) do
            local name = file:match("([^/]+)$") -- Get filename only
            local num = tonumber(string.match(name, "CP(%d+)"))
            if num then
                table.insert(sortedFiles, {path = file, num = num, name = name})
            end
        end
        
        table.sort(sortedFiles, function(a, b) return a.num < b.num end)
        
        if #sortedFiles == 0 then Notify("Error", "Tidak ada file CP", 2) return end
        
        local currentIndex = 1
        
        -- Fungsi rekursif untuk play berurutan
        local function PlayNext()
            if currentIndex > #sortedFiles then
                Notify("Selesai", "Semua CP Selesai!", 3)
                return
            end
            
            local dataItem = sortedFiles[currentIndex]
            Notify("Auto Play", "Playing: " .. dataItem.name, 2)
            
            local content = readfile(dataItem.path)
            local recordData = HttpService:JSONDecode(content)
            
            currentIndex = currentIndex + 1
            
            -- Play dan panggil diri sendiri (PlayNext) saat selesai
            PlayReplayData(recordData, PlayNext)
        end
        
        PlayNext() -- Mulai rantai
    end
    
    -- // UI CONSTRUCTION //
    local ScreenGui = UI:GetScreenGui()
    if not ScreenGui then ScreenGui = Instance.new("ScreenGui", Services.CoreGui) end
    
    -- Widget
    local Widget = Instance.new("Frame", ScreenGui)
    Widget.Size = UDim2.new(0, 160, 0, 50)
    Widget.Position = UDim2.new(0.5, -80, 0.15, 0)
    Widget.BackgroundColor3 = Theme.Main
    Widget.ZIndex = 100
    Widget.Visible = true
    Instance.new("UICorner", Widget).CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", Widget)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    -- Drag Logic
    local dragging, dragStart, startPos
    Widget.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=Widget.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta=i.Position-dragStart Widget.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
    
    -- Status Text
    local StatusTxt = Instance.new("TextLabel", Widget)
    StatusTxt.Size = UDim2.new(1,0,0,15); StatusTxt.Position = UDim2.new(0,0,1,-15)
    StatusTxt.BackgroundTransparency = 1; StatusTxt.Text = "READY"; StatusTxt.TextColor3 = Color3.fromRGB(150,150,150)
    StatusTxt.TextSize = 10; StatusTxt.Font = Enum.Font.Gotham; StatusTxt.ZIndex = 101
    
    _G.UpdateStatus = function(txt, col) StatusTxt.Text = txt StatusTxt.TextColor3 = col WStroke.Color = col end
    
    -- Buttons
    local function MkBtn(txt, col, x, cb)
        local b = Instance.new("TextButton", Widget)
        b.Size = UDim2.new(0, 30, 0, 30); b.Position = UDim2.new(0, x, 0, 5)
        b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.white; b.Font = Enum.Font.GothamBold; b.ZIndex = 102
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    
    MkBtn("●", Color3.fromRGB(200, 50, 50), 10, function() if Recording then StopRecordingAndSave() else StartRecording() end end)
    MkBtn("▶", Theme.Confirm, 45, function() if Replaying then StopReplay() else PlayAllCheckpoints() end end)
    MkBtn("_", Theme.Button, 115, function() Widget.Visible = false end)
    
    -- // MENU TAB //
    local RecTab = UI:Tab("Recording")
    RecTab:Toggle("Show Widget", function(v) Widget.Visible = v end).SetState(true)
    RecTab:Button("Force Stop", Theme.ButtonRed, function() StopRecordingAndSave() StopReplay() end)
    RecTab:Label("Map: " .. MapName)
    
    local RecContainer = RecTab:Container(220)
    RecContainer.ZIndex = 60
    
    -- // FIX DELETE & REFRESH //
    _G.RefreshList = function()
        for _, c in pairs(RecContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        
        local files = listfiles(CurrentMapFolder)
        local sorted = {}
        for _, f in ipairs(files) do
            local n = f:match("([^/]+)$")
            local num = tonumber(string.match(n, "CP(%d+)")) or 9999
            table.insert(sorted, {path=f, name=n, num=num})
        end
        table.sort(sorted, function(a,b) return a.num < b.num end)
        
        for _, d in ipairs(sorted) do
            local f = Instance.new("Frame", RecContainer)
            f.Size = UDim2.new(1, 0, 0, 35); f.BackgroundColor3 = Theme.Button; f.ZIndex = 61
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
            
            local lbl = Instance.new("TextLabel", f)
            lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0.05,0,0,0)
            lbl.Text = d.name; lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.ZIndex=62
            
            local playB = Instance.new("TextButton", f)
            playB.Size = UDim2.new(0, 40, 0.7, 0); playB.Position = UDim2.new(0.6, 0, 0.15, 0)
            playB.BackgroundColor3 = Theme.Confirm; playB.Text = "PLAY"; playB.TextColor3=Color3.white; playB.ZIndex=62
            Instance.new("UICorner", playB).CornerRadius = UDim.new(0, 4)
            
            local delB = Instance.new("TextButton", f)
            delB.Size = UDim2.new(0, 30, 0.7, 0); delB.Position = UDim2.new(0.85, 0, 0.15, 0)
            delB.BackgroundColor3 = Theme.ButtonRed; delB.Text = "DEL"; delB.TextColor3=Color3.white; delB.ZIndex=62
            Instance.new("UICorner", delB).CornerRadius = UDim.new(0, 4)
            
            playB.MouseButton1Click:Connect(function()
                local c = readfile(d.path)
                PlayReplayData(HttpService:JSONDecode(c))
            end)
            
            -- FIX DELETE LOGIC
            delB.MouseButton1Click:Connect(function()
                UI:Confirm("Hapus " .. d.name .. "?", function()
                    if delfile then
                        pcall(function() delfile(d.path) end)
                        task.wait(0.1) -- Beri waktu sistem menghapus
                        _G.RefreshList() -- Refresh UI
                        Notify("Deleted", d.name, 2)
                    end
                end)
            end)
        end
        RecContainer.CanvasSize = UDim2.new(0,0,0, (#sorted * 40) + 10)
    end
    
    RecTab:Button("Refresh List", Theme.Button, _G.RefreshList)
    RecTab:Button("▶ PLAY ALL (Chain)", Theme.Accent, PlayAllCheckpoints)
    
    _G.RefreshList()
    
    Config.OnReset:Connect(function()
        StopRecordingAndSave()
        StopReplay()
        if Widget then Widget:Destroy() end
    end)
    
    print("[Vanzyxxx] Recorder V4 (Fix All) Loaded")
end