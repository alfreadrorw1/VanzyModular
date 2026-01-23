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
    local CurrentMapFolder = nil
    local MapName = nil
    
    -- // UTILITIES //
    local function SetupFolders()
        if not isfolder then return end
        
        if not isfolder(BasePath) then makefolder(BasePath) end
        if not isfolder(RecordsPath) then makefolder(RecordsPath) end
        
        local mapId = tostring(game.PlaceId)
        local success, productInfo = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and productInfo then
            MapName = productInfo.Name:gsub("[^%w%s]", ""):gsub("%s+", "_")
        else
            MapName = "Map_" .. mapId
        end
        
        CurrentMapFolder = RecordsPath .. "/" .. MapName
        if not isfolder(CurrentMapFolder) then
            makefolder(CurrentMapFolder)
        end
        return true
    end
    
    -- High precision number
    local function cn(num)
        return math.floor(num * 1000000) / 1000000
    end
    
    -- Serialization
    local function SerializeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {cn(x), cn(y), cn(z), cn(R00), cn(R01), cn(R02), cn(R10), cn(R11), cn(R12), cn(R20), cn(R21), cn(R22)}
    end
    
    local function DeserializeCFrame(t)
        return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
    end
    
    -- Improved Animation Scanner
    local function GetActiveAnimations(humanoid)
        local anims = {}
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                -- Filter animasi core yang mengganggu jika perlu, tapi biasanya kita butuh semuanya
                if track.Animation.AnimationId and track.IsPlaying and track.WeightCurrent > 0.01 then
                    table.insert(anims, {
                        id = track.Animation.AnimationId,
                        w = cn(track.WeightCurrent),
                        s = cn(track.Speed),
                        t = cn(track.TimePosition),
                        p = track.Priority.Value -- Save priority
                    })
                end
            end
        end
        return anims
    end
    
    local function GetCharacterState(humanoid)
        return {
            ws = cn(humanoid.WalkSpeed),
            jp = cn(humanoid.JumpPower),
            state = humanoid:GetState().Value, -- Simpan Enum Value ID
            hh = cn(humanoid.HipHeight)
        }
    end
    
    local function GetNextCheckpointNumber()
        if not isfolder(CurrentMapFolder) then return 1 end
        local files = listfiles(CurrentMapFolder)
        local maxNum = 0
        for _, file in ipairs(files) do
            local filename = file:match(".*/(.*)$") or file
            local cpNum = filename:match("CP(%d+)%.json")
            if cpNum then
                local num = tonumber(cpNum)
                if num and num > maxNum then maxNum = num end
            end
        end
        return maxNum + 1
    end
    
    -- // UI WIDGET //
    local WidgetGui = Instance.new("ScreenGui")
    WidgetGui.Name = "VanzyRecorderWidget"
    WidgetGui.ResetOnSpawn = false
    if syn and syn.protect_gui then syn.protect_gui(WidgetGui) end
    WidgetGui.Parent = Services.CoreGui
    
    local WidgetFrame = Instance.new("Frame", WidgetGui)
    WidgetFrame.Size = UDim2.new(0, 180, 0, 50) -- Sedikit diperlebar
    WidgetFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
    WidgetFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
    WidgetFrame.BackgroundTransparency = 0.1
    Instance.new("UICorner", WidgetFrame).CornerRadius = UDim.new(0, 8)
    local WStroke = Instance.new("UIStroke", WidgetFrame)
    WStroke.Color = Theme.Accent
    WStroke.Thickness = 2
    
    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    WidgetFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = WidgetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    WidgetFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            WidgetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    local StatusLabel = Instance.new("TextLabel", WidgetFrame)
    StatusLabel.Size = UDim2.new(1, -10, 0, 15)
    StatusLabel.Position = UDim2.new(0, 5, 1, -15)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "READY"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local function CreateMiniBtn(text, color, pos, callback)
        local btn = Instance.new("TextButton", WidgetFrame)
        btn.Size = UDim2.new(0, 30, 0, 30)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- // RECORDING //
    local function StartRecording()
        if Recording or Replaying then return end
        local char = LocalPlayer.Character
        if not char then return end
        
        Recording = true
        StartTime = os.clock()
        CurrentRecord = {
            Frames = {},
            Metadata = {
                MapName = MapName,
                Checkpoint = GetNextCheckpointNumber()
            }
        }
        
        StatusLabel.Text = "REC ●"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        
        RecordConnection = RunService.Heartbeat:Connect(function(dt)
            if not Recording or not LocalPlayer.Character then return end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and hum then
                table.insert(CurrentRecord.Frames, {
                    t = cn(os.clock() - StartTime),
                    cf = SerializeCFrame(hrp.CFrame),
                    anims = GetActiveAnimations(hum),
                    state = GetCharacterState(hum)
                })
            end
        end)
    end
    
    local function StopRecording()
        if not Recording then return end
        Recording = false
        if RecordConnection then RecordConnection:Disconnect() end
        
        CurrentRecord.Metadata.Duration = cn(os.clock() - StartTime)
        StatusLabel.Text = "SAVING..."
        
        if #CurrentRecord.Frames > 0 then
            local cpNum = CurrentRecord.Metadata.Checkpoint
            local fileName = "CP" .. cpNum .. ".json"
            if writefile then
                writefile(CurrentMapFolder .. "/" .. fileName, HttpService:JSONEncode(CurrentRecord))
                StatusLabel.Text = "SAVED CP" .. cpNum
            end
        else
            StatusLabel.Text = "EMPTY"
        end
        task.wait(1)
        StatusLabel.Text = "READY"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- // PLAY ALL LOGIC //
    local function LoadAllCheckpoints()
        if not isfolder(CurrentMapFolder) then return {} end
        local files = listfiles(CurrentMapFolder)
        local checkpoints = {}
        
        for _, file in ipairs(files) do
            if file:match("CP%d+%.json") then
                local success, content = pcall(readfile, file)
                if success then
                    local data = HttpService:JSONDecode(content)
                    data.CPNum = tonumber(file:match("CP(%d+)")) -- Simpan nomor CP
                    table.insert(checkpoints, data)
                end
            end
        end
        
        -- Urutkan dari CP 1 ke CP seterusnya
        table.sort(checkpoints, function(a, b)
            return (a.CPNum or 0) < (b.CPNum or 0)
        end)
        
        return checkpoints
    end
    
    local function MergeCheckpoints(checkpoints)
        if #checkpoints == 0 then return nil end
        
        local merged = {Frames = {}, Metadata = {IsMerged = true}}
        local currentTimeOffset = 0
        
        for i, cp in ipairs(checkpoints) do
            local lastFrameTime = 0
            
            for _, frame in ipairs(cp.Frames) do
                local newFrame = table.clone(frame)
                newFrame.t = newFrame.t + currentTimeOffset -- Geser waktu agar nyambung
                newFrame.cpIndex = cp.CPNum -- Tandai ini bagian CP berapa
                table.insert(merged.Frames, newFrame)
                lastFrameTime = frame.t
            end
            
            -- Tambahkan sedikit jeda antar checkpoint agar animasi tidak patah
            currentTimeOffset = currentTimeOffset + lastFrameTime + 0.1
        end
        
        return merged
    end
    
    -- // REPLAY ENGINE (ANTI-GETAR) //
    local function PlayReplay(data)
        if Recording or Replaying or not data or #data.Frames == 0 then return end
        
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if not hrp or not hum then return end
        
        Replaying = true
        StatusLabel.Text = "PLAYING..."
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        
        -- Setup Character
        hrp.Anchored = true
        hum.AutoRotate = false
        -- Matikan collision agar tidak nyangkut saat lari
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        
        local loadedTracks = {}
        local replayStart = os.clock()
        local frameIndex = 1
        
        -- Cleanup Function
        local function Cleanup()
            RunService:UnbindFromRenderStep("VanzyReplay")
            Replaying = false
            if char and char.Parent then
                hrp.Anchored = false
                hum.AutoRotate = true
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
            for _, t in pairs(loadedTracks) do t:Stop() end
            StatusLabel.Text = "READY"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        _G.StopVanzyReplay = Cleanup
        
        -- Teleport ke awal
        hrp.CFrame = DeserializeCFrame(data.Frames[1].cf)
        
        -- Menggunakan BindToRenderStep agar prioritas lebih tinggi dari Camera (Mencegah Getar)
        RunService:BindToRenderStep("VanzyReplay", Enum.RenderPriority.Character.Value + 10, function()
            if not Replaying or not LocalPlayer.Character then Cleanup() return end
            
            local now = os.clock() - replayStart
            
            -- Cari frame yang sesuai waktu
            while data.Frames[frameIndex + 1] and now > data.Frames[frameIndex + 1].t do
                frameIndex = frameIndex + 1
            end
            
            local currentFrame = data.Frames[frameIndex]
            local nextFrame = data.Frames[frameIndex + 1]
            
            if not nextFrame then Cleanup() return end
            
            -- Interpolasi Posisi (Smooth Movement)
            local alpha = (now - currentFrame.t) / (nextFrame.t - currentFrame.t)
            alpha = math.clamp(alpha, 0, 1)
            
            local cf1 = DeserializeCFrame(currentFrame.cf)
            local cf2 = DeserializeCFrame(nextFrame.cf)
            hrp.CFrame = cf1:Lerp(cf2, alpha)
            
            -- Update Status CP
            if currentFrame.cpIndex then
                StatusLabel.Text = "PLAY CP" .. currentFrame.cpIndex
            end
            
            -- Handle State & Property
            if currentFrame.state then
                hum.WalkSpeed = currentFrame.state.ws
                hum.JumpPower = currentFrame.state.jp
                hum.HipHeight = currentFrame.state.hh or 0
                -- Paksa ubah state agar engine Roblox merespon (misal jatuh/lari)
                hum:ChangeState(currentFrame.state.state) 
            end
            
            -- Handle Animasi (Ditingkatkan)
            if currentFrame.anims and animator then
                local activeIds = {}
                for _, anim in ipairs(currentFrame.anims) do
                    activeIds[anim.id] = true
                    
                    local track = loadedTracks[anim.id]
                    if not track then
                        local newAnim = Instance.new("Animation")
                        newAnim.AnimationId = anim.id
                        track = animator:LoadAnimation(newAnim)
                        track.Priority = Enum.AnimationPriority[anim.p] or Enum.AnimationPriority.Movement
                        loadedTracks[anim.id] = track
                    end
                    
                    if not track.IsPlaying then track:Play() end
                    
                    -- Update Weight & Speed secara real-time
                    track:AdjustWeight(anim.w, 0.1)
                    track:AdjustSpeed(anim.s)
                    
                    -- Sync TimePosition jika drift terlalu jauh (lebih dari 0.1 detik)
                    if math.abs(track.TimePosition - anim.t) > 0.1 then
                        track.TimePosition = anim.t
                    end
                end
                
                -- Stop animasi yang tidak ada di frame ini
                for id, track in pairs(loadedTracks) do
                    if not activeIds[id] then track:Stop(0.1) end
                end
            end
        end)
    end
    
    -- // WIDGET BUTTONS //
    local RecBtn = CreateMiniBtn("●", Color3.fromRGB(200, 50, 50), UDim2.new(0, 5, 0, 5), function()
        if Recording then StopRecording() else StartRecording() end
    end)
    
    local StopBtn = CreateMiniBtn("■", Color3.fromRGB(255, 150, 0), UDim2.new(0, 40, 0, 5), function()
        if Replaying then _G.StopVanzyReplay() end
    end)
    
    local PlayBtn = CreateMiniBtn("▶", Color3.fromRGB(50, 200, 100), UDim2.new(0, 75, 0, 5), function()
        local cps = LoadAllCheckpoints()
        if #cps > 0 then PlayReplay(cps[#cps]) end -- Play last CP
    end)
    
    local AllBtn = CreateMiniBtn("ALL", Color3.fromRGB(0, 150, 255), UDim2.new(0, 110, 0, 5), function()
        local cps = LoadAllCheckpoints()
        local merged = MergeCheckpoints(cps)
        if merged then PlayReplay(merged) end
    end)
    
    local HideBtn = CreateMiniBtn("_", Color3.fromRGB(50, 50, 50), UDim2.new(0, 145, 0, 5), function()
        WidgetGui.Enabled = not WidgetGui.Enabled
    end)
    
    -- // MENU TAB & FILE MANAGER //
    local Tab = UI:Tab("Record Fix")
    
    Tab:Label("Controls")
    Tab:Button("Toggle Widget", Theme.Button, function() WidgetGui.Enabled = not WidgetGui.Enabled end)
    
    Tab:Label("Manager - " .. (MapName or "Unknown"))
    
    local FileContainer = Tab:Container(250)
    
    local function RefreshFiles()
        FileContainer:Clear() -- Pastikan fungsi Clear ada di UI Lib kamu, atau hapus manual child
        
        -- Manual clear kalau UI Lib tidak support Clear()
        for _, v in pairs(FileContainer:GetChildren()) do
            if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end
        end
        
        local cps = LoadAllCheckpoints()
        
        if #cps == 0 then
            Tab:Label("No checkpoints found")
            return
        end
        
        -- Play All Button Besar
        Tab:Button("▶ PLAY ALL (GABUNG SEMUA)", Theme.Confirm, function()
            local merged = MergeCheckpoints(cps)
            if merged then PlayReplay(merged) end
        end)
        
        for _, cp in ipairs(cps) do
            local cpNum = cp.CPNum
            
            -- Container untuk item file
            local item = Instance.new("Frame", FileContainer)
            item.Size = UDim2.new(1, -10, 0, 30)
            item.BackgroundColor3 = Theme.Button
            item.BackgroundTransparency = 0.5
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
            Instance.new("UIListLayout", FileContainer).Padding = UDim.new(0, 5)
            
            local lbl = Instance.new("TextLabel", item)
            lbl.Text = "  CP " .. cpNum .. " (" .. #cp.Frames .. " frames)"
            lbl.Size = UDim2.new(0.6, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Load Button
            local load = Instance.new("TextButton", item)
            load.Size = UDim2.new(0, 40, 0.8, 0)
            load.Position = UDim2.new(0.6, 0, 0.1, 0)
            load.Text = "PLAY"
            load.BackgroundColor3 = Theme.Accent
            Instance.new("UICorner", load).CornerRadius = UDim.new(0, 4)
            load.MouseButton1Click:Connect(function() PlayReplay(cp) end)
            
            -- Delete Button (FIXED)
            local del = Instance.new("TextButton", item)
            del.Size = UDim2.new(0, 40, 0.8, 0)
            del.Position = UDim2.new(0.85, 0, 0.1, 0)
            del.Text = "DEL"
            del.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            Instance.new("UICorner", del).CornerRadius = UDim.new(0, 4)
            
            del.MouseButton1Click:Connect(function()
                -- Langsung delete tanpa konfirmasi ribet untuk memastikan fungsi jalan
                local filename = "CP" .. cpNum .. ".json"
                local path = CurrentMapFolder .. "/" .. filename
                if isfile(path) then
                    delfile(path)
                    task.wait(0.1)
                    RefreshFiles() -- Refresh UI otomatis
                end
            end)
        end
        
        -- Update Canvas Size
        -- FileContainer.CanvasSize = UDim2.new(0, 0, 0, #cps * 35 + 50) 
    end
    
    Tab:Button("🔄 Refresh List", Theme.Button, RefreshFiles)
    
    spawn(function()
        SetupFolders()
        task.wait(1)
        RefreshFiles()
    end)
    
    return true
end