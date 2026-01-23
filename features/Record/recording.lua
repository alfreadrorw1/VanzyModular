-- [[ VANZYXXX RECORDER V8 - COPY PLAYER ANIMATION & ZERO JITTER ]]
-- Fixes: Uses Player's Equipped Animations, Fixed Camera Jittering

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    
    local LocalPlayer = Players.LocalPlayer
    
    -- [1] SYSTEM VARS
    local RecordSystem = {
        IsRecording = false,
        IsPlaying = false,
        StartTime = 0,
        RecordedFrames = {},
        Connections = {},
        Folder = "VanzyRecords",
        CurrentMapID = tostring(game.PlaceId),
        
        -- Animation Storage
        MyAnims = {
            Idle = {}, Walk = {}, Run = {}, Jump = {}, Fall = {}
        },
        ActiveTracks = {}
    }
    
    if makefolder and not isfolder(RecordSystem.Folder) then makefolder(RecordSystem.Folder) end

    -- [2] HELPER: SERIALIZE
    local function SerializeCF(cf) return {cf:GetComponents()} end
    local function DeserializeCF(t) return CFrame.new(table.unpack(t)) end

    -- [3] UI TAB
    local RecordTab = UI:Tab("Record")
    RecordTab:Label("Recorder V8 (Copy Anim)")
    local RecordListContainer = RecordTab:Container(220)
    local WidgetRef = {Instance=nil, StatusLbl=nil}

    -- [4] ANIMATION STEALER (CORE FEATURE)
    -- Fungsi ini mengambil ID animasi dari script 'Animate' di karakter
    local function GrabPlayerAnimations(Char)
        local AnimateScript = Char:FindFirstChild("Animate")
        if not AnimateScript then return end
        
        local function GetIDs(name)
            local Container = AnimateScript:FindFirstChild(name)
            local IDs = {}
            if Container then
                for _, v in pairs(Container:GetChildren()) do
                    if v:IsA("Animation") then table.insert(IDs, v.AnimationId) end
                end
            end
            return IDs
        end
        
        -- Simpan ID Animasi Player
        RecordSystem.MyAnims.Idle = GetIDs("idle")
        RecordSystem.MyAnims.Walk = GetIDs("walk")
        RecordSystem.MyAnims.Run  = GetIDs("run")
        RecordSystem.MyAnims.Jump = GetIDs("jump")
        RecordSystem.MyAnims.Fall = GetIDs("fall")
    end

    -- Fungsi memutar animasi
    local function PlaySmartAnim(Hum, Type, Speed)
        local AnimList = RecordSystem.MyAnims[Type]
        if not AnimList or #AnimList == 0 then return end
        
        -- Pilih satu ID random dari list (biasanya idle ada beberapa variasi)
        local ID = AnimList[math.random(1, #AnimList)]
        
        -- Cek apakah track ini sudah main?
        if RecordSystem.ActiveTracks[Type] and RecordSystem.ActiveTracks[Type].IsPlaying then
            -- Jika Walk/Run, sesuaikan speed
            if Type == "Walk" or Type == "Run" then
                RecordSystem.ActiveTracks[Type]:AdjustSpeed(Speed / 16)
            end
            return -- Jangan load baru jika masih main
        end
        
        -- Stop track lain agar tidak tumpang tindih
        for k, track in pairs(RecordSystem.ActiveTracks) do
            if k ~= Type then track:Stop(0.2) end
        end
        
        -- Load & Play
        local AnimObj = Instance.new("Animation")
        AnimObj.AnimationId = ID
        local Track = Hum:LoadAnimation(AnimObj)
        Track.Priority = Enum.AnimationPriority.Movement
        Track.Looped = (Type == "Idle" or Type == "Walk" or Type == "Run")
        Track:Play(0.2)
        
        RecordSystem.ActiveTracks[Type] = Track
    end

    -- [5] CORE LOGIC
    function RecordSystem:StartRecording()
        if self.IsRecording or self.IsPlaying then return end
        
        local Char = LocalPlayer.Character
        if not Char then return end
        
        -- Ambil Animasi Player Saat Ini
        GrabPlayerAnimations(Char)
        
        self.IsRecording = true
        self.RecordedFrames = {}
        self.StartTime = os.clock()
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Recording...", Duration=2})
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="REC..."; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(255,50,50) end
        
        -- Menggunakan Heartbeat agar sinkron dengan physics saat merekam
        self.Connections["Rec"] = RunService.Heartbeat:Connect(function()
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            
            if Root and Hum then
                table.insert(self.RecordedFrames, {
                    t = os.clock() - self.StartTime,
                    cf = SerializeCF(Root.CFrame),
                    v = Root.Velocity.Y, -- Vertical Velocity
                    s = (Root.Velocity * Vector3.new(1,0,1)).Magnitude, -- Horizontal Speed
                    st = Hum:GetState().Value -- Humanoid State
                })
            end
        end)
    end

    function RecordSystem:StopRecording()
        if not self.IsRecording then return end
        self.IsRecording = false
        if self.Connections["Rec"] then self.Connections["Rec"]:Disconnect() end
        
        local fName = "Rec_"..os.date("%H%M%S")..".json"
        writefile(self.Folder.."/"..fName, HttpService:JSONEncode({
            MapID=self.CurrentMapID, 
            Frames=self.RecordedFrames,
            -- Simpan juga ID animasi player ke file agar replay nanti tetap sama
            Anims=self.MyAnims 
        }))
        
        self:RefreshList()
        StarterGui:SetCore("SendNotification", {Title="REC", Text="SAVED!", Duration=2})
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="IDLE"; WidgetRef.StatusLbl.TextColor3=Theme.Text end
    end

    function RecordSystem:StartReplay(Data)
        if self.IsRecording or self.IsPlaying then return end
        if #Data.Frames < 2 then return end
        
        -- Restore animasi dari file json (jika ada), kalau tidak pakai yang current
        if Data.Anims then RecordSystem.MyAnims = Data.Anims end
        
        self.IsPlaying = true
        self.StartTime = os.clock()
        
        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")
        
        if not Root or not Hum then return end
        
        -- [SETUP REPLAY MODE]
        local AnimateScript = Char:FindFirstChild("Animate")
        if AnimateScript then AnimateScript.Disabled = true end -- Matikan default
        
        Hum.PlatformStand = false 
        Hum.AutoRotate = false
        Root.Anchored = true -- Wajib True untuk anti-getar
        
        -- Teleport Awal
        Root.CFrame = DeserializeCF(Data.Frames[1].cf)
        
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="PLAYING"; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(0,255,100) end
        
        local Idx = 1
        
        -- [ANTI-JITTER] Menggunakan BindToRenderStep Priority Camera
        -- Ini kuncinya agar gerakan halus di mata (Render Priority 200 = Camera)
        -- Kita set di 199 (Sebelum Kamera Render)
        RunService:BindToRenderStep("VanzyReplay", 199, function()
            if not self.IsPlaying then 
                RunService:UnbindFromRenderStep("VanzyReplay")
                return 
            end
            
            local now = os.clock() - self.StartTime
            
            -- Cari Frame Sinkron
            while Idx < #Data.Frames - 1 do
                if now >= Data.Frames[Idx+1].t then Idx = Idx + 1 else break end
            end
            
            local A = Data.Frames[Idx]
            local B = Data.Frames[Idx+1]
            
            if not B then self:StopReplay() return end
            
            -- Interpolasi Posisi (Smooth)
            local alpha = (now - A.t) / (B.t - A.t)
            local targetCF = DeserializeCF(A.cf):Lerp(DeserializeCF(B.cf), math.clamp(alpha,0,1))
            Root.CFrame = targetCF
            
            -- [SMART ANIMATION LOGIC]
            local Speed = A.s or 0
            local Vert = A.v or 0
            
            -- Logika pemilihan animasi berdasarkan data rekaman
            if Vert > 5 or Vert < -5 then
                if Vert > 0 then PlaySmartAnim(Hum, "Jump", 1) else PlaySmartAnim(Hum, "Fall", 1) end
            elseif Speed > 0.5 then
                if Speed > 20 then -- Anggap lari jika cepat
                    PlaySmartAnim(Hum, "Run", Speed)
                else
                    PlaySmartAnim(Hum, "Walk", Speed)
                end
            else
                PlaySmartAnim(Hum, "Idle", 1)
            end
        end)
    end

    function RecordSystem:StopReplay()
        self.IsPlaying = false
        RunService:UnbindFromRenderStep("VanzyReplay") -- Stop Loop
        
        -- Stop Manual Tracks
        for _, t in pairs(RecordSystem.ActiveTracks) do t:Stop() end
        RecordSystem.ActiveTracks = {}
        
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            if Root then Root.Anchored = false end
            if Hum then Hum.AutoRotate = true end
            
            -- Hidupkan lagi animasi bawaan
            local AnimateScript = Char:FindFirstChild("Animate")
            if AnimateScript then AnimateScript.Disabled = false end
        end
        
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="IDLE"; WidgetRef.StatusLbl.TextColor3=Theme.Text end
    end

    function RecordSystem:RefreshList()
        for _,v in pairs(RecordListContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        if listfiles then
            for _, file in ipairs(listfiles(self.Folder)) do
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/]+)%.json$")
                    local btn = Instance.new("TextButton", RecordListContainer)
                    btn.Size = UDim2.new(1,0,0,30); btn.BackgroundColor3 = Theme.Sidebar
                    btn.Text = "📼 "..name; btn.TextColor3 = Theme.Text; Instance.new("UICorner",btn)
                    btn.MouseButton1Click:Connect(function()
                        self:StartReplay(HttpService:JSONDecode(readfile(file)))
                    end)
                end
            end
            RecordListContainer.CanvasSize = UDim2.new(0,0,0, RecordListContainer.UIListLayout.AbsoluteContentSize.Y + 20)
        end
    end

    -- [6] FIXED MINI WIDGET (NO AUTO SHOW)
    local function CreateWidget()
        if WidgetRef.Instance then WidgetRef.Instance:Destroy() end
        local Screen = nil
        if UI.GetScreenGui then Screen = UI:GetScreenGui() else Screen = game.CoreGui:FindFirstChild("Vanzyxxx") end
        
        local Widget = Instance.new("Frame", Screen)
        Widget.Name = "RecWidget"
        Widget.Size = UDim2.new(0, 200, 0, 80); Widget.Position = UDim2.new(0.5, -100, 0.85, 0)
        Widget.BackgroundColor3 = Theme.Main; Widget.ZIndex = 500; Widget.Visible = false -- DEFAULT HIDDEN
        Instance.new("UICorner", Widget).CornerRadius = UDim.new(0,8)
        local Str = Instance.new("UIStroke", Widget); Str.Color = Theme.Accent; Str.Thickness = 2
        
        local DragBtn = Instance.new("TextButton", Widget); DragBtn.Size = UDim2.new(1,0,1,0); DragBtn.BackgroundTransparency = 1; DragBtn.Text = ""
        local dragging, dragStart, startPos
        DragBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=Widget.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
        UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and dragging then local d=i.Position-dragStart; Widget.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)

        WidgetRef.StatusLbl = Instance.new("TextLabel", Widget); WidgetRef.StatusLbl.Size = UDim2.new(1,0,0,20); WidgetRef.StatusLbl.Position = UDim2.new(0,0,0,5); WidgetRef.StatusLbl.BackgroundTransparency = 1; WidgetRef.StatusLbl.Text = "IDLE"; WidgetRef.StatusLbl.TextColor3 = Theme.Text; WidgetRef.StatusLbl.Font = Enum.Font.GothamBold; WidgetRef.StatusLbl.TextSize = 12; WidgetRef.StatusLbl.ZIndex = 501

        local Grid = Instance.new("Frame", Widget); Grid.Size = UDim2.new(0.9, 0, 0.5, 0); Grid.Position = UDim2.new(0.05, 0, 0.4, 0); Grid.BackgroundTransparency = 1; Grid.ZIndex = 501
        local Layout = Instance.new("UIListLayout", Grid); Layout.FillDirection = Enum.FillDirection.Horizontal; Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.Padding = UDim.new(0, 5)

        local function MakeBtn(txt, col, func)
            local B = Instance.new("TextButton", Grid); B.Size = UDim2.new(0, 45, 0, 35); B.BackgroundColor3 = col; B.Text = txt; B.TextColor3 = Color3.new(1,1,1); B.Font = Enum.Font.GothamBold; B.TextSize = 14; B.ZIndex = 502
            Instance.new("UICorner", B).CornerRadius = UDim.new(0,6); B.MouseButton1Click:Connect(func)
        end

        MakeBtn("⏺", Color3.fromRGB(200,50,50), function() if RecordSystem.IsRecording then RecordSystem:StopRecording() else RecordSystem:StartRecording() end end)
        MakeBtn("▶", Color3.fromRGB(50,200,50), function() 
            if listfiles then
                local files = listfiles(RecordSystem.Folder)
                if #files > 0 then RecordSystem:StartReplay(HttpService:JSONDecode(readfile(files[#files]))) else StarterGui:SetCore("SendNotification", {Title="Err", Text="No Records!"}) end
            end
        end)
        MakeBtn("⏹", Color3.fromRGB(80,80,80), function() RecordSystem:StopRecording(); RecordSystem:StopReplay() end)
        MakeBtn("X", Theme.Button, function() Widget.Visible = false end)
        
        WidgetRef.Instance = Widget
    end

    -- [7] INIT
    RecordTab:Button("Show Mini Controller", Theme.Button, function()
        if not WidgetRef.Instance or not WidgetRef.Instance.Parent then CreateWidget() end
        WidgetRef.Instance.Visible = not WidgetRef.Instance.Visible
    end)
    
    RecordTab:Button("Refresh List", Theme.ButtonDark, function() RecordSystem:RefreshList() end)
    
    spawn(function() task.wait(1); RecordSystem:RefreshList(); CreateWidget() end)
    Config.OnReset:Connect(function() RecordSystem:StopRecording(); RecordSystem:StopReplay(); if WidgetRef.Instance then WidgetRef.Instance:Destroy() end end)
    
    print("[Vanzyxxx] Recorder V8 (Copy Anim) Loaded")
end