-- [[ VANZYXXX RECORDER V6 - SMOOTH ANIMATION ]]
-- Fixes: Rigid Body (T-Pose), Jittering, Missing Buttons

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    local UserInputService = Services.UserInputService
    
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
        
        -- Animation Stuff
        LoadedAnimTrack = nil,
        DefaultAnimateScript = nil
    }
    
    if makefolder and not isfolder(RecordSystem.Folder) then makefolder(RecordSystem.Folder) end

    -- [2] DATA HELPER
    local function SerializeCF(cf) return {cf:GetComponents()} end
    local function DeserializeCF(t) return CFrame.new(table.unpack(t)) end

    -- [3] UI TAB
    local RecordTab = UI:Tab("Record")
    RecordTab:Label("Recorder V6 (Anim Fix)")
    local RecordListContainer = RecordTab:Container(220)
    
    local WidgetRef = {Instance=nil, StatusLbl=nil}

    -- [4] ANIMATION HANDLER (FIX BERDIRI TEGAK)
    local function ToggleAnimateScript(enable)
        local Char = LocalPlayer.Character
        if not Char then return end
        
        -- Matikan/Nyalakan Script Animate Bawaan Roblox
        local Animate = Char:FindFirstChild("Animate")
        if Animate and Animate:IsA("LocalScript") then
            Animate.Disabled = not enable
            if not enable then
                -- Stop semua track yang sedang jalan agar bersih
                local Hum = Char:FindFirstChild("Humanoid")
                if Hum then
                    for _, track in pairs(Hum:GetAnimator():GetPlayingAnimationTracks()) do
                        track:Stop()
                    end
                end
            end
        end
    end

    local function PlayWalkAnim(Hum, speed)
        -- Load animasi jalan standar jika belum ada
        if not RecordSystem.LoadedAnimTrack then
            local Anim = Instance.new("Animation")
            Anim.AnimationId = "rbxassetid://180426354" -- ID Jalan Standar Roblox
            RecordSystem.LoadedAnimTrack = Hum:LoadAnimation(Anim)
            RecordSystem.LoadedAnimTrack.Looped = true
            RecordSystem.LoadedAnimTrack.Priority = Enum.AnimationPriority.Movement
        end
        
        if speed > 0.1 then
            if not RecordSystem.LoadedAnimTrack.IsPlaying then
                RecordSystem.LoadedAnimTrack:Play()
            end
            -- Sesuaikan kecepatan animasi dengan kecepatan gerak
            RecordSystem.LoadedAnimTrack:AdjustSpeed(1) 
        else
            if RecordSystem.LoadedAnimTrack.IsPlaying then
                RecordSystem.LoadedAnimTrack:Stop(0.2)
            end
        end
    end

    -- [5] CORE LOGIC
    function RecordSystem:StartRecording()
        if self.IsRecording or self.IsPlaying then return end
        self.IsRecording = true
        self.RecordedFrames = {}
        self.StartTime = os.clock()
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Recording...", Duration=2})
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="REC..."; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(255,50,50) end
        
        -- Record Loop (Pakai RenderStepped agar movement player asli tertangkap mulus)
        self.Connections["Rec"] = RunService.RenderStepped:Connect(function()
            local Char = LocalPlayer.Character
            if not Char then return end
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            
            if Root then
                table.insert(self.RecordedFrames, {
                    t = os.clock() - self.StartTime,
                    cf = SerializeCF(Root.CFrame),
                    spd = Root.Velocity.Magnitude -- Simpan kecepatan untuk replay animasi
                })
            end
        end)
    end

    function RecordSystem:StopRecording()
        if not self.IsRecording then return end
        self.IsRecording = false
        if self.Connections["Rec"] then self.Connections["Rec"]:Disconnect() end
        
        local fName = "Rec_"..os.date("%H%M%S")..".json"
        writefile(self.Folder.."/"..fName, HttpService:JSONEncode({MapID=self.CurrentMapID, Frames=self.RecordedFrames}))
        
        self:RefreshList()
        StarterGui:SetCore("SendNotification", {Title="REC", Text="SAVED!", Duration=2})
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="IDLE"; WidgetRef.StatusLbl.TextColor3=Theme.Text end
    end

    function RecordSystem:StartReplay(Data)
        if self.IsRecording or self.IsPlaying then return end
        if #Data.Frames < 2 then return end
        
        self.IsPlaying = true
        self.StartTime = os.clock()
        
        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")
        
        if not Root or not Hum then return end
        
        -- [SETUP REPLAY]
        ToggleAnimateScript(false) -- Matikan animasi default
        Hum.PlatformStand = false -- JANGAN TRUE (Biar animasi jalan bisa play)
        Hum.AutoRotate = false -- Matikan rotasi otomatis engine
        Root.Anchored = true -- Kunci posisi (Anti Geter)
        
        -- Teleport Awal
        Root.CFrame = DeserializeCF(Data.Frames[1].cf)
        
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="PLAYING"; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(0,255,100) end
        
        local Idx = 1
        self.Connections["Play"] = RunService.RenderStepped:Connect(function()
            if not self.IsPlaying then return end
            local now = os.clock() - self.StartTime
            
            -- Cari Frame
            while Idx < #Data.Frames - 1 do
                if now >= Data.Frames[Idx+1].t then Idx = Idx + 1 else break end
            end
            
            local A = Data.Frames[Idx]
            local B = Data.Frames[Idx+1]
            
            if not B then self:StopReplay() return end
            
            -- Interpolasi Gerakan (Smooth Lerp)
            local alpha = (now - A.t) / (B.t - A.t)
            local targetCF = DeserializeCF(A.cf):Lerp(DeserializeCF(B.cf), math.clamp(alpha,0,1))
            
            Root.CFrame = targetCF
            
            -- [ANIMASI MANUAL]
            -- Jika speed di rekaman > 0.1, mainkan animasi jalan
            PlayWalkAnim(Hum, A.spd or 0)
        end)
    end

    function RecordSystem:StopReplay()
        self.IsPlaying = false
        if self.Connections["Play"] then self.Connections["Play"]:Disconnect() end
        
        -- Stop Animasi Jalan
        if RecordSystem.LoadedAnimTrack then RecordSystem.LoadedAnimTrack:Stop() end
        
        -- Restore Character
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            if Root then Root.Anchored = false end 
            if Hum then 
                Hum.PlatformStand = false 
                Hum.AutoRotate = true
            end
            ToggleAnimateScript(true) -- Nyalakan lagi animasi default
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

    -- [6] FIXED MINI WIDGET UI (OFFSET SIZE)
    local function CreateWidget()
        if WidgetRef.Instance then WidgetRef.Instance:Destroy() end
        
        local Screen = nil
        if UI.GetScreenGui then Screen = UI:GetScreenGui() else Screen = game.CoreGui:FindFirstChild("Vanzyxxx") end
        
        local Widget = Instance.new("Frame", Screen)
        Widget.Name = "RecWidget"
        Widget.Size = UDim2.new(0, 200, 0, 80) -- Lebih lebar dikit
        Widget.Position = UDim2.new(0.5, -100, 0.85, 0) -- Tengah Bawah
        Widget.BackgroundColor3 = Theme.Main
        Widget.ZIndex = 500
        Instance.new("UICorner", Widget).CornerRadius = UDim.new(0,8)
        local Str = Instance.new("UIStroke", Widget); Str.Color = Theme.Accent; Str.Thickness = 2
        
        -- Drag
        local DragBtn = Instance.new("TextButton", Widget)
        DragBtn.Size = UDim2.new(1,0,1,0); DragBtn.BackgroundTransparency = 1; DragBtn.Text = ""
        local dragging, dragStart, startPos
        DragBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=Widget.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
        UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and dragging then local d=i.Position-dragStart; Widget.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)

        -- Status Label
        WidgetRef.StatusLbl = Instance.new("TextLabel", Widget)
        WidgetRef.StatusLbl.Size = UDim2.new(1,0,0,20)
        WidgetRef.StatusLbl.Position = UDim2.new(0,0,0,5)
        WidgetRef.StatusLbl.BackgroundTransparency = 1
        WidgetRef.StatusLbl.Text = "IDLE"
        WidgetRef.StatusLbl.TextColor3 = Theme.Text
        WidgetRef.StatusLbl.Font = Enum.Font.GothamBold
        WidgetRef.StatusLbl.TextSize = 12
        WidgetRef.StatusLbl.ZIndex = 501

        -- BUTTON CONTAINER
        local Grid = Instance.new("Frame", Widget)
        Grid.Size = UDim2.new(0.9, 0, 0.5, 0)
        Grid.Position = UDim2.new(0.05, 0, 0.4, 0)
        Grid.BackgroundTransparency = 1
        Grid.ZIndex = 501
        
        local Layout = Instance.new("UIListLayout", Grid)
        Layout.FillDirection = Enum.FillDirection.Horizontal
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Layout.Padding = UDim.new(0, 5)

        local function MakeBtn(txt, col, func)
            local B = Instance.new("TextButton", Grid)
            B.Size = UDim2.new(0, 45, 0, 35) -- OFFSET SIZE (PASTI KELIHATAN)
            B.BackgroundColor3 = col
            B.Text = txt
            B.TextColor3 = Color3.new(1,1,1)
            B.Font = Enum.Font.GothamBold
            B.TextSize = 14
            B.ZIndex = 502
            Instance.new("UICorner", B).CornerRadius = UDim.new(0,6)
            B.MouseButton1Click:Connect(func)
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
        WidgetRef.Instance.Visible = true
    end)
    
    RecordTab:Button("Refresh List", Theme.ButtonDark, function() RecordSystem:RefreshList() end)
    
    spawn(function() task.wait(1); RecordSystem:RefreshList(); CreateWidget() end)
    Config.OnReset:Connect(function() RecordSystem:StopRecording(); RecordSystem:StopReplay(); if WidgetRef.Instance then WidgetRef.Instance:Destroy() end end)
    
    print("[Vanzyxxx] Recorder V6 (Smooth Anim) Loaded")
end
