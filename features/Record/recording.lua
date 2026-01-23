-- [[ VANZYXXX RECORDER V7 - REAL ANIMATIONS ]]
-- Fixes: Rigid Body, Missing Animations (Walk/Jump/Idle), Auto-Widget Disabled

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
        
        -- Animation Tracks
        Tracks = {
            Walk = nil,
            Idle = nil,
            Jump = nil
        }
    }
    
    if makefolder and not isfolder(RecordSystem.Folder) then makefolder(RecordSystem.Folder) end

    -- [2] ANIMATION DATABASE (R6 & R15)
    local AnimIDs = {
        R6 = {
            Walk = "rbxassetid://180426354",
            Idle = "rbxassetid://180435571",
            Jump = "rbxassetid://125750702"
        },
        R15 = {
            Walk = "rbxassetid://507777826",
            Idle = "rbxassetid://507766388",
            Jump = "rbxassetid://507765000"
        }
    }

    -- [3] UI TAB
    local RecordTab = UI:Tab("Record")
    RecordTab:Label("Recorder V7 (Anim Fix)")
    local RecordListContainer = RecordTab:Container(220)
    
    local WidgetRef = {Instance=nil, StatusLbl=nil}

    -- [4] HELPER FUNCTIONS
    local function SerializeCF(cf) return {cf:GetComponents()} end
    local function DeserializeCF(t) return CFrame.new(table.unpack(t)) end

    -- SETUP ANIMATIONS
    local function SetupAnimations(Char)
        local Hum = Char:FindFirstChild("Humanoid")
        if not Hum then return end
        
        -- Deteksi R6 atau R15
        local RigType = (Hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
        local IDs = AnimIDs[RigType]
        
        -- Helper Load
        local function LoadAnim(id)
            local A = Instance.new("Animation")
            A.AnimationId = id
            return Hum:LoadAnimation(A)
        end
        
        RecordSystem.Tracks.Walk = LoadAnim(IDs.Walk)
        RecordSystem.Tracks.Idle = LoadAnim(IDs.Idle)
        RecordSystem.Tracks.Jump = LoadAnim(IDs.Jump)
        
        -- Setting Loops
        RecordSystem.Tracks.Walk.Looped = true
        RecordSystem.Tracks.Idle.Looped = true
        RecordSystem.Tracks.Jump.Looped = false
    end

    local function StopAllTracks()
        for _, t in pairs(RecordSystem.Tracks) do
            if t and t.IsPlaying then t:Stop() end
        end
    end

    -- [5] CORE LOGIC
    function RecordSystem:StartRecording()
        if self.IsRecording or self.IsPlaying then return end
        self.IsRecording = true
        self.RecordedFrames = {}
        self.StartTime = os.clock()
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Started...", Duration=2})
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="REC..."; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(255,50,50) end
        
        self.Connections["Rec"] = RunService.RenderStepped:Connect(function()
            local Char = LocalPlayer.Character
            if not Char then return end
            local Root = Char:FindFirstChild("HumanoidRootPart")
            
            if Root then
                -- Rekam CFrame DAN Kecepatan untuk replay animasi
                table.insert(self.RecordedFrames, {
                    t = os.clock() - self.StartTime,
                    cf = SerializeCF(Root.CFrame),
                    v = Root.Velocity.Y, -- Vertical Velocity (untuk Jump)
                    s = (Root.Velocity * Vector3.new(1,0,1)).Magnitude -- Horizontal Speed (untuk Walk)
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
        
        -- [SETUP PHYSICS & ANIM]
        SetupAnimations(Char)
        
        -- Matikan script animate bawaan agar tidak bentrok
        local AnimateScript = Char:FindFirstChild("Animate")
        if AnimateScript then AnimateScript.Disabled = true end
        
        -- Matikan Physics Roblox
        Hum.PlatformStand = false -- Biarkan False agar animasi jalan
        Root.Anchored = true -- Kunci posisi (Anti Geter)
        
        -- Teleport Awal
        Root.CFrame = DeserializeCF(Data.Frames[1].cf)
        
        if WidgetRef.StatusLbl then WidgetRef.StatusLbl.Text="PLAYING"; WidgetRef.StatusLbl.TextColor3=Color3.fromRGB(0,255,100) end
        
        local Idx = 1
        
        -- Mainkan Idle dulu
        if RecordSystem.Tracks.Idle then RecordSystem.Tracks.Idle:Play() end
        
        self.Connections["Play"] = RunService.RenderStepped:Connect(function()
            if not self.IsPlaying then return end
            local now = os.clock() - self.StartTime
            
            while Idx < #Data.Frames - 1 do
                if now >= Data.Frames[Idx+1].t then Idx = Idx + 1 else break end
            end
            
            local A = Data.Frames[Idx]
            local B = Data.Frames[Idx+1]
            
            if not B then self:StopReplay() return end
            
            -- [1] MOVEMENT (Lerp Smooth)
            local alpha = (now - A.t) / (B.t - A.t)
            local targetCF = DeserializeCF(A.cf):Lerp(DeserializeCF(B.cf), math.clamp(alpha,0,1))
            Root.CFrame = targetCF
            
            -- [2] ANIMATION LOGIC (Real-time update)
            local Speed = A.s or 0
            local VertVel = A.v or 0
            
            -- JUMPING
            if VertVel > 2 then
                if RecordSystem.Tracks.Jump and not RecordSystem.Tracks.Jump.IsPlaying then
                    RecordSystem.Tracks.Jump:Play()
                end
            -- WALKING
            elseif Speed > 0.5 then
                if RecordSystem.Tracks.Walk and not RecordSystem.Tracks.Walk.IsPlaying then
                    RecordSystem.Tracks.Walk:Play()
                end
                -- Adjust speed animasi sesuai kecepatan gerak
                if RecordSystem.Tracks.Walk.IsPlaying then
                    RecordSystem.Tracks.Walk:AdjustSpeed(Speed / 14) -- 16 is default walkspeed
                end
                if RecordSystem.Tracks.Idle.IsPlaying then RecordSystem.Tracks.Idle:Stop() end
            -- IDLE
            else
                if RecordSystem.Tracks.Walk.IsPlaying then RecordSystem.Tracks.Walk:Stop() end
                if not RecordSystem.Tracks.Idle.IsPlaying then RecordSystem.Tracks.Idle:Play() end
            end
        end)
    end

    function RecordSystem:StopReplay()
        self.IsPlaying = false
        if self.Connections["Play"] then self.Connections["Play"]:Disconnect() end
        
        -- Stop All Manual Anims
        StopAllTracks()
        
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            if Root then Root.Anchored = false end 
            
            -- Nyalakan lagi script animate bawaan
            local AnimateScript = Char:FindFirstChild("Animate")
            if AnimateScript then 
                AnimateScript.Disabled = false 
            end
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

    -- [6] FIXED MINI WIDGET UI
    local function CreateWidget()
        if WidgetRef.Instance then WidgetRef.Instance:Destroy() end
        
        local Screen = nil
        if UI.GetScreenGui then Screen = UI:GetScreenGui() else Screen = game.CoreGui:FindFirstChild("Vanzyxxx") end
        
        local Widget = Instance.new("Frame", Screen)
        Widget.Name = "RecWidget"
        Widget.Size = UDim2.new(0, 200, 0, 80)
        Widget.Position = UDim2.new(0.5, -100, 0.85, 0)
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

        WidgetRef.StatusLbl = Instance.new("TextLabel", Widget)
        WidgetRef.StatusLbl.Size = UDim2.new(1,0,0,20); WidgetRef.StatusLbl.Position = UDim2.new(0,0,0,5)
        WidgetRef.StatusLbl.BackgroundTransparency = 1; WidgetRef.StatusLbl.Text = "STATUS: IDLE"; WidgetRef.StatusLbl.TextColor3 = Theme.Text
        WidgetRef.StatusLbl.Font = Enum.Font.GothamBold; WidgetRef.StatusLbl.TextSize = 12; WidgetRef.StatusLbl.ZIndex = 501

        -- BUTTONS
        local Grid = Instance.new("Frame", Widget)
        Grid.Size = UDim2.new(0.9, 0, 0.5, 0); Grid.Position = UDim2.new(0.05, 0, 0.4, 0)
        Grid.BackgroundTransparency = 1; Grid.ZIndex = 501
        local Layout = Instance.new("UIListLayout", Grid); Layout.FillDirection = Enum.FillDirection.Horizontal; Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.Padding = UDim.new(0, 5)

        local function MakeBtn(txt, col, func)
            local B = Instance.new("TextButton", Grid); B.Size = UDim2.new(0, 45, 0, 35); B.BackgroundColor3 = col
            B.Text = txt; B.TextColor3 = Color3.new(1,1,1); B.Font = Enum.Font.GothamBold; B.TextSize = 14; B.ZIndex = 502
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

    -- [7] INIT (NO AUTO WIDGET)
    RecordTab:Button("Show Mini Controller", Theme.Button, function()
        if not WidgetRef.Instance or not WidgetRef.Instance.Parent then CreateWidget() end
        WidgetRef.Instance.Visible = true
    end)
    
    RecordTab:Button("Refresh List", Theme.ButtonDark, function() RecordSystem:RefreshList() end)
    
    -- Auto List Load Only
    spawn(function() task.wait(1); RecordSystem:RefreshList() end)
    Config.OnReset:Connect(function() RecordSystem:StopRecording(); RecordSystem:StopReplay(); if WidgetRef.Instance then WidgetRef.Instance:Destroy() end end)
    
    print("[Vanzyxxx] Recorder V7 Loaded")
end
