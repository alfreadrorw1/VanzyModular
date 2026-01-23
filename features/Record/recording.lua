-- [[ VANZYXXX RECORD & REPLAY SYSTEM (FIXED UI) ]]
-- File: features/Record/recording.lua
-- Fixes: Mini Controller Buttons Missing (ZIndex & Sizing)

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    local UserInputService = Services.UserInputService
    local StarterGui = Services.StarterGui
    
    local LocalPlayer = Players.LocalPlayer
    
    -- [1] SYSTEM VARIABLES
    local RecordSystem = {
        IsRecording = false,
        IsPlaying = false,
        StartTime = 0,
        RecordedFrames = {},
        CurrentReplayIndex = 1,
        Connections = {},
        Folder = "VanzyRecords",
        CurrentMapID = tostring(game.PlaceId)
    }
    
    if makefolder and not isfolder(RecordSystem.Folder) then makefolder(RecordSystem.Folder) end

    -- [2] HELPERS
    local function SerializeCFrame(cf) return {cf:GetComponents()} end
    local function DeserializeCFrame(tbl) return CFrame.new(table.unpack(tbl)) end

    -- [3] UI ELEMENTS
    local RecordTab = UI:Tab("Record")
    RecordTab:Label("Advanced Replay System")
    local RecordListContainer = RecordTab:Container(250)
    
    -- Referensi Global untuk MiniWidget agar bisa diakses fungsi lain
    local WidgetRef = {
        Instance = nil,
        StatusText = nil,
        StatusDot = nil
    }

    -- [4] CORE LOGIC (Recording & Replay)
    function RecordSystem:StartRecording()
        if self.IsRecording or self.IsPlaying then return end
        self.IsRecording = true
        self.RecordedFrames = {}
        self.StartTime = os.clock()
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Recording started...", Duration=2})
        
        self.Connections["RecordLoop"] = RunService.Heartbeat:Connect(function()
            local Char = LocalPlayer.Character
            if not Char then return end
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            
            if Root and Hum then
                table.insert(self.RecordedFrames, {
                    t = os.clock() - self.StartTime,
                    cf = SerializeCFrame(Root.CFrame),
                    st = Hum:GetState().Value,
                    anim = Hum.MoveDirection.Magnitude > 0
                })
            end
        end)
        
        if WidgetRef.StatusText then 
            WidgetRef.StatusText.Text = "RECORDING"
            WidgetRef.StatusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end
    end

    function RecordSystem:StopRecording()
        if not self.IsRecording then return end
        self.IsRecording = false
        if self.Connections["RecordLoop"] then self.Connections["RecordLoop"]:Disconnect() end
        
        local fileName = "Rec_" .. os.date("%H%M%S") .. "_" .. self.CurrentMapID
        self:SaveRecord(fileName)
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Saved: "..fileName, Duration=2})
        if WidgetRef.StatusText then 
            WidgetRef.StatusText.Text = "IDLE" 
            WidgetRef.StatusDot.BackgroundColor3 = Theme.Text
        end
    end

    function RecordSystem:SaveRecord(name)
        local data = {Name = name, MapID = self.CurrentMapID, Frames = self.RecordedFrames}
        writefile(self.Folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        self:RefreshList()
    end
    
    function RecordSystem:RefreshList()
        for _, v in pairs(RecordListContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        if listfiles then
            for _, file in ipairs(listfiles(self.Folder)) do
                if file:sub(-5) == ".json" then
                    local simpleName = file:match("([^/]+)%.json$") or file
                    local btn = Instance.new("TextButton", RecordListContainer)
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.BackgroundColor3 = Theme.Sidebar
                    btn.Text = "📼 " .. simpleName
                    btn.TextColor3 = Theme.Text
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 12
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                    
                    btn.MouseButton1Click:Connect(function()
                        local content = readfile(file)
                        self:StartReplay(HttpService:JSONDecode(content))
                    end)
                end
            end
            RecordListContainer.CanvasSize = UDim2.new(0,0,0, RecordListContainer.UIListLayout.AbsoluteContentSize.Y + 20)
        end
    end

    function RecordSystem:StartReplay(recordData)
        if self.IsRecording or self.IsPlaying then return end
        local Frames = recordData.Frames
        if #Frames < 2 then return end
        
        self.IsPlaying = true
        self.StartTime = os.clock()
        self.CurrentReplayIndex = 1
        
        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")
        
        if not Root or not Hum then return end
        
        Hum.PlatformStand = true
        Root.Anchored = true
        Root.CFrame = DeserializeCFrame(Frames[1].cf)
        
        if WidgetRef.StatusText then 
            WidgetRef.StatusText.Text = "PLAYING"
            WidgetRef.StatusDot.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
        end
        
        self.Connections["ReplayLoop"] = RunService.RenderStepped:Connect(function()
            if not self.IsPlaying then return end
            local now = os.clock() - self.StartTime
            
            while self.CurrentReplayIndex < #Frames - 1 do
                if now >= Frames[self.CurrentReplayIndex + 1].t then
                    self.CurrentReplayIndex = self.CurrentReplayIndex + 1
                else
                    break
                end
            end
            
            local FrameA = Frames[self.CurrentReplayIndex]
            local FrameB = Frames[self.CurrentReplayIndex + 1]
            
            if not FrameB then self:StopReplay() return end
            
            local alpha = math.clamp((now - FrameA.t) / (FrameB.t - FrameA.t), 0, 1)
            Root.CFrame = DeserializeCFrame(FrameA.cf):Lerp(DeserializeCFrame(FrameB.cf), alpha)
        end)
    end

    function RecordSystem:StopReplay()
        if not self.IsPlaying then return end
        self.IsPlaying = false
        if self.Connections["ReplayLoop"] then self.Connections["ReplayLoop"]:Disconnect() end
        
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            if Root then Root.Anchored = false end
            if Hum then Hum.PlatformStand = false end
        end
        
        if WidgetRef.StatusText then 
            WidgetRef.StatusText.Text = "IDLE" 
            WidgetRef.StatusDot.BackgroundColor3 = Theme.Text
        end
    end

    -- [5] MINI WIDGET (FIXED BUTTONS)
    local function CreateMiniWidget()
        -- Hapus widget lama jika ada
        if WidgetRef.Instance then WidgetRef.Instance:Destroy() end

        -- Cari ScreenGui yang valid
        local Screen = nil
        if UI.GetScreenGui then 
            Screen = UI:GetScreenGui() 
        else
            -- Fallback jika fungsi library beda
            Screen = game.CoreGui:FindFirstChild("Vanzyxxx") or Services.Players.LocalPlayer.PlayerGui:FindFirstChild("Vanzyxxx")
        end
        
        if not Screen then 
            warn("[REC] No ScreenGui found!") 
            return 
        end
        
        -- Main Frame
        local Widget = Instance.new("Frame", Screen)
        Widget.Name = "RecWidget"
        Widget.Size = UDim2.new(0, 180, 0, 60) -- Diperbesar sedikit
        Widget.Position = UDim2.new(0.8, -90, 0.7, 0)
        Widget.BackgroundColor3 = Theme.Main
        Widget.ZIndex = 500 -- ZIndex Tinggi
        Instance.new("UICorner", Widget).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Widget); Stroke.Color = Theme.Accent; Stroke.Thickness = 2
        
        -- Status Text
        local StatusDot = Instance.new("Frame", Widget)
        StatusDot.Size = UDim2.new(0, 10, 0, 10)
        StatusDot.Position = UDim2.new(0.05, 0, 0.15, 0)
        StatusDot.BackgroundColor3 = Theme.Text
        StatusDot.ZIndex = 501
        Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)
        
        local StatusText = Instance.new("TextLabel", Widget)
        StatusText.Size = UDim2.new(0.6, 0, 0.3, 0)
        StatusText.Position = UDim2.new(0.15, 0, 0.05, 0)
        StatusText.BackgroundTransparency = 1
        StatusText.Text = "IDLE"
        StatusText.TextColor3 = Theme.Text
        StatusText.Font = Enum.Font.GothamBold
        StatusText.TextSize = 12
        StatusText.TextXAlignment = Enum.TextXAlignment.Left
        StatusText.ZIndex = 501
        
        -- Drag Handle
        local DragBtn = Instance.new("TextButton", Widget)
        DragBtn.Size = UDim2.new(0, 30, 0, 20)
        DragBtn.Position = UDim2.new(0.8, 0, 0, 0)
        DragBtn.BackgroundTransparency = 1
        DragBtn.Text = "::"
        DragBtn.TextColor3 = Color3.fromRGB(150,150,150)
        DragBtn.ZIndex = 502
        
        -- Buttons Container (PENTING: ZIndex Tinggi)
        local Btns = Instance.new("Frame", Widget)
        Btns.Name = "ButtonContainer"
        Btns.Size = UDim2.new(0.9, 0, 0.5, 0)
        Btns.Position = UDim2.new(0.05, 0, 0.45, 0)
        Btns.BackgroundTransparency = 1
        Btns.ZIndex = 502
        
        local UIList = Instance.new("UIListLayout", Btns)
        UIList.FillDirection = Enum.FillDirection.Horizontal
        UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIList.Padding = UDim.new(0, 5)
        
        -- Function Bikin Tombol (FIXED SIZING)
        local function MkBtn(txt, col, func)
            local b = Instance.new("TextButton", Btns)
            b.Size = UDim2.new(0, 45, 1, 0) -- Gunakan OFFSET (45px) bukan Scale biar gak gepeng
            b.BackgroundColor3 = col
            b.Text = txt
            b.TextColor3 = Color3.new(1,1,1)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 14
            b.ZIndex = 503 -- Paling atas
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
            b.MouseButton1Click:Connect(func)
            return b
        end
        
        -- Buat Tombol
        local BtnRec = MkBtn("⏺", Color3.fromRGB(200, 50, 50), function()
            if RecordSystem.IsRecording then RecordSystem:StopRecording() else RecordSystem:StartRecording() end
        end)
        
        local BtnStop = MkBtn("⏹", Color3.fromRGB(80, 80, 80), function()
            RecordSystem:StopRecording()
            RecordSystem:StopReplay()
        end)
        
        local BtnClose = MkBtn("❌", Theme.Button, function()
            Widget.Visible = false
        end)
        
        -- Simpan Ref
        WidgetRef.Instance = Widget
        WidgetRef.StatusText = StatusText
        WidgetRef.StatusDot = StatusDot
        
        -- Drag Logic
        local dragging, dragStart, startPos
        DragBtn.InputBegan:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
                dragging = true; dragStart = i.Position; startPos = Widget.Position 
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end 
        end)
        UserInputService.InputChanged:Connect(function(i) 
            if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) and dragging then 
                local delta = i.Position - dragStart
                Widget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
            end 
        end)
    end

    -- [6] CONTROLS
    RecordTab:Button("Show Mini Controller", Theme.Button, function()
        if not WidgetRef.Instance or not WidgetRef.Instance.Parent then 
            CreateMiniWidget() 
        end
        WidgetRef.Instance.Visible = true
    end)
    
    RecordTab:Button("Refresh Saved Records", Theme.ButtonDark, function()
        RecordSystem:RefreshList()
    end)
    
    RecordTab:Button("Stop All Actions", Theme.ButtonRed, function()
        RecordSystem:StopRecording()
        RecordSystem:StopReplay()
    end)
    
    -- Init
    spawn(function()
        task.wait(1)
        RecordSystem:RefreshList()
        CreateMiniWidget() -- Auto create saat load
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        RecordSystem:StopRecording()
        RecordSystem:StopReplay()
        if WidgetRef.Instance then WidgetRef.Instance:Destroy() end
    end)
    
    print("[Vanzyxxx] Record System V4 Loaded")
end
