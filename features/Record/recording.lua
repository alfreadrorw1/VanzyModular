return function(UI, Services, Config, Theme)
    -- // SERVICES //
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    
    local LocalPlayer = Players.LocalPlayer
    
    -- // VARIABLES //
    local Recording = false
    local Replaying = false
    local CurrentRecord = {}
    local StartTime = 0
    local RecordConnection = nil
    
    -- File System Paths
    local RootFolder = "VanzyData"
    local RecordFolder = RootFolder .. "/Records"
    
    -- Init Folders (Safe Mode)
    if makefolder then
        if not isfolder(RootFolder) then makefolder(RootFolder) end
        if not isfolder(RecordFolder) then makefolder(RecordFolder) end
    end

    local function GetMapFolder()
        local placeId = game.PlaceId
        local mapName = "Unknown"
        pcall(function()
            local info = Services.MarketplaceService:GetProductInfo(placeId)
            if info then mapName = info.Name:gsub("%W", "") end
        end)
        local path = RecordFolder .. "/" .. placeId .. "_" .. mapName
        if makefolder and not isfolder(path) then makefolder(path) end
        return path
    end
    
    local CurrentMapFolder = GetMapFolder()

    -- // UTILITIES //
    local function cn(num) return math.floor(num * 100000) / 100000 end 

    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end

    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end

    local function Notify(title, text, dur)
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = dur or 2})
    end

    -- // ANIMATION SCANNER //
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
        
        if _G.UpdateRecStatus then _G.UpdateRecStatus("REC ●", Color3.fromRGB(255, 50, 50)) end

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

    local function StopRecordingAndSave(customName)
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end

        if _G.UpdateRecStatus then _G.UpdateRecStatus("SAVING...", Color3.fromRGB(255, 200, 50)) end

        local fileName = customName or ("Rec_" .. math.floor(os.time()))
        if not string.find(fileName, ".json") then fileName = fileName .. ".json" end
        
        if writefile then
            writefile(CurrentMapFolder .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
            Notify("Saved", fileName, 3)
        end
        
        if _G.UpdateRecStatus then _G.UpdateRecStatus("READY", Theme.Accent) end
        if _G.RefreshRecList then _G.RefreshRecList() end
    end

    -- // CORE: REPLAY ENGINE //
    local LoadedTracks = {}

    local function StopReplay()
        if _G.StopReplayInternal then _G.StopReplayInternal() end
    end

    local function PlayReplayData(data, continueNextCallback)
        if Recording or Replaying then return end
        if not data or not data.Frames or #data.Frames < 2 then 
            Notify("Error", "Invalid Data", 2)
            if continueNextCallback then continueNextCallback() end
            return 
        end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")

        Replaying = true
        if _G.UpdateRecStatus then _G.UpdateRecStatus("PLAY ▶", Color3.fromRGB(50, 255, 100)) end

        hrp.Anchored = true
        hum.AutoRotate = false
        for _, v in pairs(char:GetDescendants()) do 
            if v:IsA("BasePart") then v.CanCollide = false end 
        end

        -- Smart Resume Logic
        local startIndex = 1
        local currentPos = hrp.Position
        local startCF = DeserializeCFrame(data.Frames[1].cf)
        
        if (currentPos - startCF.Position).Magnitude > 5 then
            local closestDist = math.huge
            local closestIdx = 1
            for i = 1, #data.Frames, 10 do
                local framePos = DeserializeCFrame(data.Frames[i].cf).Position
                local dist = (currentPos - framePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestIdx = i
                end
            end
            if closestDist < 25 then
                startIndex = closestIdx
                Notify("Resume", math.floor((startIndex/#data.Frames)*100) .. "%", 1)
            else
                hrp.CFrame = startCF
            end
        else
            hrp.CFrame = startCF
        end

        local replayStartReal = os.clock()
        local recordingOffset = data.Frames[startIndex].t 

        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Camera.Value - 1, function()
            if not Replaying or not char.Parent then StopReplay() return end
            if not hrp.Anchored then hrp.Anchored = true end
            
            local elapsed = os.clock() - replayStartReal
            local targetTime = recordingOffset + elapsed
            
            local frameIdx = startIndex
            while data.Frames[frameIdx+1] and data.Frames[frameIdx+1].t < targetTime do
                frameIdx = frameIdx + 1
            end
            
            if not data.Frames[frameIdx+1] then
                StopReplay()
                if continueNextCallback then continueNextCallback() end
                return
            end

            startIndex = frameIdx

            local currFrame = data.Frames[frameIdx]
            local nextFrame = data.Frames[frameIdx+1]

            local alpha = (targetTime - currFrame.t) / (nextFrame.t - currFrame.t)
            alpha = math.clamp(alpha, 0, 1)

            local cf1 = DeserializeCFrame(currFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)

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
                    track:AdjustSpeed(anim.s)
                    track:AdjustWeight(anim.w)
                    if math.abs(track.TimePosition - anim.t) > 0.2 then
                        track.TimePosition = anim.t
                    end
                end
                for id, track in pairs(LoadedTracks) do
                    if not activeIds[id] and track.IsPlaying then track:Stop(0.2) end
                end
            end
        end)

        _G.StopReplayInternal = function()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            if char then
                if hrp then hrp.Anchored = false end
                if hum then hum.AutoRotate = true end
            end
            for _, t in pairs(LoadedTracks) do t:Stop() end
            LoadedTracks = {}
            if _G.UpdateRecStatus then _G.UpdateRecStatus("READY", Theme.Accent) end
        end
    end

    local function PlayAllCPs()
        local success, files = pcall(function() return listfiles(CurrentMapFolder) end)
        if not success or #files == 0 then Notify("Error", "No Files", 2) return end

        local sortedFiles = {}
        for _, file in ipairs(files) do
            local name = file:gsub(CurrentMapFolder.."/", ""):gsub(".json", "")
            local num = tonumber(string.match(name, "CP(%d+)")) or 9999
            table.insert(sortedFiles, {path = file, num = num, name = name})
        end
        table.sort(sortedFiles, function(a, b) return a.num < b.num end)
        
        local currentIndex = 1
        local function PlayNext()
            if currentIndex > #sortedFiles then Notify("Done", "All Played", 2) return end
            local dataItem = sortedFiles[currentIndex]
            Notify("Chain", "Playing "..dataItem.name, 2)
            currentIndex = currentIndex + 1
            local content = readfile(dataItem.path)
            PlayReplayData(HttpService:JSONDecode(content), PlayNext)
        end
        PlayNext()
    end

    -- // UI WIDGET (Z-INDEX FIX) //
    local ScreenGui = UI:GetScreenGui()
    if not ScreenGui then 
        warn("Main ScreenGui not found, creating temp")
        ScreenGui = Instance.new("ScreenGui", Services.CoreGui)
    end

    local Widget = Instance.new("Frame", ScreenGui)
    Widget.Name = "VanzyRecorderWidget"
    Widget.Size = UDim2.new(0, 160, 0, 50)
    -- Posisi di tengah agak atas biar keliatan
    Widget.Position = UDim2.new(0.5, -80, 0.15, 0) 
    Widget.BackgroundColor3 = Theme.Main
    Widget.ZIndex = 100 -- ZIndex Tinggi
    Widget.Visible = true -- Force Visible
    
    Instance.new("UICorner", Widget).CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", Widget)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    -- Drag Logic
    local dragging, dragStart, startPos
    Widget.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=true dragStart=i.Position startPos=Widget.Position end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta=i.Position-dragStart Widget.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end end)

    local StatusTxt = Instance.new("TextLabel", Widget)
    StatusTxt.Size = UDim2.new(1,0,0,15); StatusTxt.Position = UDim2.new(0,0,1,-15)
    StatusTxt.BackgroundTransparency = 1; StatusTxt.Text = "READY"; StatusTxt.TextColor3 = Color3.fromRGB(150,150,150)
    StatusTxt.TextSize = 10; StatusTxt.Font = Enum.Font.Gotham; StatusTxt.ZIndex = 101
    
    _G.UpdateRecStatus = function(txt, col) StatusTxt.Text = txt StatusTxt.TextColor3 = col WStroke.Color = col end

    local function MkBtn(txt, col, x, cb)
        local b = Instance.new("TextButton", Widget)
        b.Size = UDim2.new(0, 30, 0, 30); b.Position = UDim2.new(0, x, 0, 5)
        b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.white; b.Font = Enum.Font.GothamBold; b.ZIndex = 102
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    
    MkBtn("●", Color3.fromRGB(200, 50, 50), 15, function()
        if Recording then
            local nextNum = 1
            pcall(function()
                local files = listfiles(CurrentMapFolder)
                for _,f in pairs(files) do if string.find(f, "CP") then nextNum = nextNum + 1 end end 
            end)
            UI:Confirm("Save CP"..nextNum.."?", function() StopRecordingAndSave("CP"..nextNum) end)
        else
            StartRecording()
        end
    end)
    
    MkBtn("▶", Theme.Confirm, 55, function() if Replaying then StopReplay() else PlayAllCPs() end end)
    MkBtn("_", Theme.Button, 115, function() Widget.Visible = false end)

    -- // MAIN MENU UI TAB //
    local RecTab = UI:Tab("Record")
    
    RecTab:Toggle("Show Widget", function(v) Widget.Visible = v end).SetState(true)
    RecTab:Button("Force Stop & Save", Theme.ButtonRed, function() StopRecordingAndSave("CrashSave"); StopReplay() end)
    RecTab:Label("Files: " .. GetMapFolder():match("Records/(.+)$"))
    
    -- Container dengan Tinggi Manual dan ZIndex Aman
    local RecContainer = RecTab:Container(220) 
    RecContainer.ZIndex = 60 

    _G.RefreshRecList = function()
        for _, c in pairs(RecContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        
        local success, files = pcall(function() return listfiles(CurrentMapFolder) end)
        if not success or #files == 0 then return end
        
        local sorted = {}
        for _, f in ipairs(files) do
            local n = f:gsub(CurrentMapFolder.."/","")
            local num = tonumber(string.match(n, "CP(%d+)")) or 9999
            table.insert(sorted, {path=f, name=n, num=num})
        end
        table.sort(sorted, function(a,b) return a.num < b.num end)

        for _, fileData in ipairs(sorted) do
            local f = Instance.new("Frame", RecContainer)
            f.Size = UDim2.new(1, 0, 0, 35); f.BackgroundColor3 = Theme.Button; f.ZIndex = 61
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
            
            local lbl = Instance.new("TextLabel", f)
            lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0.05,0,0,0)
            lbl.Text = fileData.name; lbl.TextColor3 = Theme.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.ZIndex=62
            
            local loadBtn = Instance.new("TextButton", f)
            loadBtn.Size = UDim2.new(0, 40, 0.7, 0); loadBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
            loadBtn.BackgroundColor3 = Theme.Confirm; loadBtn.Text = "PLAY"; loadBtn.TextColor3=Color3.white; loadBtn.Font=Enum.Font.GothamBold; loadBtn.TextSize=10; loadBtn.ZIndex=62
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            
            local delBtn = Instance.new("TextButton", f)
            delBtn.Size = UDim2.new(0, 30, 0.7, 0); delBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed; delBtn.Text = "DEL"; delBtn.TextColor3=Color3.white; delBtn.Font=Enum.Font.GothamBold; delBtn.TextSize=10; delBtn.ZIndex=62
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            
            loadBtn.MouseButton1Click:Connect(function()
                local content = readfile(fileData.path)
                PlayReplayData(HttpService:JSONDecode(content))
            end)
            delBtn.MouseButton1Click:Connect(function()
                delfile(fileData.path)
                _G.RefreshRecList()
            end)
        end
        -- Update Canvas Size
        RecContainer.CanvasSize = UDim2.new(0,0,0, (#sorted * 40) + 10)
    end

    RecTab:Button("Refresh List", Theme.Button, _G.RefreshRecList)
    RecTab:Button("▶ PLAY ALL (Chain)", Theme.Accent, PlayAllCPs)

    _G.RefreshRecList()
    
    Config.OnReset:Connect(function()
        StopRecordingAndSave("Autosave_Reset")
        StopReplay()
        if Widget then Widget:Destroy() end
    end)
    
    print("[Vanzyxxx] Recorder V3 (Visible Fix) Loaded")
end
