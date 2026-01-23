-- [[ VANZYXXX RECORD & REPLAY SYSTEM (ULTIMATE V4) ]]
-- File: features/Record/recording.lua
-- Focus: Precision, Smoothness, Mobile UI, File System

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
    
    -- Ensure Folder Exists
    if makefolder and not isfolder(RecordSystem.Folder) then
        makefolder(RecordSystem.Folder)
    end

    -- [2] DATA SERIALIZATION HELPERS (CFrame Support)
    local function SerializeCFrame(cf)
        return {cf:GetComponents()}
    end
    
    local function DeserializeCFrame(tbl)
        return CFrame.new(table.unpack(tbl))
    end

    -- [3] UI ELEMENTS
    local RecordTab = UI:Tab("Record")
    RecordTab:Label("Advanced Replay System")
    
    local RecordListContainer = RecordTab:Container(250)
    local MiniWidget = nil -- Floating UI Reference

    -- [4] CORE LOGIC: RECORDING
    function RecordSystem:StartRecording()
        if self.IsRecording or self.IsPlaying then return end
        
        self.IsRecording = true
        self.RecordedFrames = {}
        self.StartTime = os.clock()
        
        -- Notification
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Recording started...", Duration=2})
        
        -- Heartbeat Loop (High Precision Capture)
        self.Connections["RecordLoop"] = RunService.Heartbeat:Connect(function(dt)
            local Char = LocalPlayer.Character
            if not Char then return end
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            
            if Root and Hum then
                local currentTime = os.clock() - self.StartTime
                
                -- Capture Frame Data
                local FrameData = {
                    t = currentTime, -- Timestamp
                    cf = SerializeCFrame(Root.CFrame), -- Position & Rotation
                    st = Hum:GetState().Value, -- Humanoid State (Enum Value)
                    anim = Hum.MoveDirection.Magnitude > 0 -- Simple Anim Check
                }
                
                table.insert(self.RecordedFrames, FrameData)
            end
        end)
        
        -- Update UI Button
        if MiniWidget then MiniWidget.UpdateStatus("RECORDING", Color3.fromRGB(255, 50, 50)) end
    end

    function RecordSystem:StopRecording()
        if not self.IsRecording then return end
        
        self.IsRecording = false
        if self.Connections["RecordLoop"] then
            self.Connections["RecordLoop"]:Disconnect()
            self.Connections["RecordLoop"] = nil
        end
        
        -- Auto Save Logic
        local fileName = "Rec_" .. os.date("%H%M%S") .. "_" .. self.CurrentMapID
        self:SaveRecord(fileName)
        
        StarterGui:SetCore("SendNotification", {Title="REC", Text="Stopped & Saved!", Duration=2})
        if MiniWidget then MiniWidget.UpdateStatus("IDLE", Theme.Text) end
    end

    -- [5] CORE LOGIC: SAVING & LOADING
    function RecordSystem:SaveRecord(name)
        local data = {
            Name = name,
            MapID = self.CurrentMapID,
            Duration = os.clock() - self.StartTime,
            Frames = self.RecordedFrames
        }
        
        local path = self.Folder .. "/" .. name .. ".json"
        writefile(path, HttpService:JSONEncode(data))
        self:RefreshList()
    end
    
    function RecordSystem:RefreshList()
        -- Clear UI
        for _, v in pairs(RecordListContainer:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        
        -- Scan Files
        if listfiles then
            local files = listfiles(self.Folder)
            for _, file in ipairs(files) do
                if file:sub(-5) == ".json" then
                    -- Parse filename purely for display
                    local simpleName = file:match("([^/]+)%.json$") or file
                    
                    -- Check if map matches (Optional, but good for specific maps)
                    -- We load content to check MapID header if needed, but for speed we just list all
                    
                    local btn = Instance.new("TextButton", RecordListContainer)
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.BackgroundColor3 = Theme.Sidebar
                    btn.Text = "📼 " .. simpleName
                    btn.TextColor3 = Theme.Text
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 12
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                    
                    -- Load Logic
                    btn.MouseButton1Click:Connect(function()
                        local content = readfile(file)
                        local decoded = HttpService:JSONDecode(content)
                        if tostring(decoded.MapID) == self.CurrentMapID then
                            self:StartReplay(decoded)
                        else
                            UI:Confirm("Map ID Mismatch! Load anyway?", function()
                                self:StartReplay(decoded)
                            end)
                        end
                    end)
                end
            end
            RecordListContainer.CanvasSize = UDim2.new(0,0,0, RecordListContainer.UIListLayout.AbsoluteContentSize.Y + 20)
        end
    end

    -- [6] CORE LOGIC: REPLAY (SMOOTH & ANTI-GETAR)
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
        
        -- [PHYSICS OVERRIDE] Matikan physics agar tidak getar/nabrak
        Hum.PlatformStand = true
        Root.Anchored = true -- Kunci posisi agar script yang mengontrol 100%
        
        -- Teleport ke frame pertama
        local firstFrame = Frames[1]
        Root.CFrame = DeserializeCFrame(firstFrame.cf)
        
        StarterGui:SetCore("SendNotification", {Title="REPLAY", Text="Playing: " .. recordData.Name, Duration=3})
        if MiniWidget then MiniWidget.UpdateStatus("PLAYING", Color3.fromRGB(0, 255, 100)) end
        
        -- RenderStepped Loop (Ultra Smooth Interpolation)
        self.Connections["ReplayLoop"] = RunService.RenderStepped:Connect(function()
            if not self.IsPlaying then return end
            
            local now = os.clock() - self.StartTime
            local maxIndex = #Frames
            
            -- Cari Frame A dan Frame B untuk Interpolasi
            -- Kita tidak loop semua frame, tapi melanjut dari index terakhir agar hemat CPU
            while self.CurrentReplayIndex < maxIndex - 1 do
                local nextFrame = Frames[self.CurrentReplayIndex + 1]
                if now >= nextFrame.t then
                    self.CurrentReplayIndex = self.CurrentReplayIndex + 1
                else
                    break
                end
            end
            
            local FrameA = Frames[self.CurrentReplayIndex]
            local FrameB = Frames[self.CurrentReplayIndex + 1]
            
            if not FrameB then
                self:StopReplay() -- Selesai
                return
            end
            
            -- Hitung Alpha (Persentase antara Frame A dan B)
            local alpha = (now - FrameA.t) / (FrameB.t - FrameA.t)
            alpha = math.clamp(alpha, 0, 1)
            
            -- [SMOOTH MOVEMENT] Gunakan CFrame Lerp
            local CFA = DeserializeCFrame(FrameA.cf)
            local CFB = DeserializeCFrame(FrameB.cf)
            Root.CFrame = CFA:Lerp(CFB, alpha)
            
            -- [STATE HANDLING]
            -- Paksa lepas gendongan dengan reset state jika perlu
            -- Namun karena Anchored=true, player tidak bisa digendong system physics Roblox
            
            -- Animasi Dummy (Agar kaki bergerak)
            if FrameA.anim then
                -- Teknik curang: Ubah state humanoid sebentar agar animasi jalan trigger (Client side visual)
                -- Tapi karena PlatformStand active, animasi mungkin freeze.
                -- Solusi terbaik tanpa script animasi kompleks: Biarkan melayang (smooth)
            end
        end)
    end

    function RecordSystem:StopReplay()
        if not self.IsPlaying then return end
        
        self.IsPlaying = false
        if self.Connections["ReplayLoop"] then
            self.Connections["ReplayLoop"]:Disconnect()
            self.Connections["ReplayLoop"] = nil
        end
        
        -- Kembalikan Physics Normal
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChild("Humanoid")
            if Root then Root.Anchored = false end
            if Hum then Hum.PlatformStand = false end
        end
        
        StarterGui:SetCore("SendNotification", {Title="REPLAY", Text="Finished / Stopped", Duration=2})
        if MiniWidget then MiniWidget.UpdateStatus("IDLE", Theme.Text) end
    end

    -- [7] MINI WIDGET (DRAGGABLE UI)
    local function CreateMiniWidget()
        local Screen = UI:GetScreenGui()
        if not Screen then return end
        
        local Widget = Instance.new("Frame", Screen)
        Widget.Name = "RecWidget"
        Widget.Size = UDim2.new(0, 160, 0, 50)
        Widget.Position = UDim2.new(0.8, -80, 0.7, 0)
        Widget.BackgroundColor3 = Theme.Main
        Widget.ZIndex = 50
        Instance.new("UICorner", Widget).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Widget); Stroke.Color = Theme.Accent; Stroke.Thickness = 2
        
        -- Status Dot
        local StatusDot = Instance.new("Frame", Widget)
        StatusDot.Size = UDim2.new(0, 8, 0, 8)
        StatusDot.Position = UDim2.new(0.05, 0, 0.15, 0)
        StatusDot.BackgroundColor3 = Theme.Text
        Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)
        
        local StatusText = Instance.new("TextLabel", Widget)
        StatusText.Size = UDim2.new(0.5, 0, 0.3, 0)
        StatusText.Position = UDim2.new(0.15, 0, 0.05, 0)
        StatusText.BackgroundTransparency = 1
        StatusText.Text = "IDLE"
        StatusText.TextColor3 = Theme.Text
        StatusText.TextXAlignment = Enum.TextXAlignment.Left
        StatusText.Font = Enum.Font.GothamBold
        StatusText.TextSize = 10
        
        -- Drag Button
        local DragBtn = Instance.new("TextButton", Widget)
        DragBtn.Size = UDim2.new(0, 20, 0, 20)
        DragBtn.Position = UDim2.new(0.85, 0, 0, 0)
        DragBtn.BackgroundTransparency = 1
        DragBtn.Text = "::"
        DragBtn.TextColor3 = Color3.fromRGB(150,150,150)
        
        -- Control Buttons Container
        local Btns = Instance.new("Frame", Widget)
        Btns.Size = UDim2.new(0.9, 0, 0.5, 0)
        Btns.Position = UDim2.new(0.05, 0, 0.45, 0)
        Btns.BackgroundTransparency = 1
        local UIList = Instance.new("UIListLayout", Btns)
        UIList.FillDirection = Enum.FillDirection.Horizontal
        UIList.Padding = UDim.new(0, 5)
        
        -- Helper Create Button
        local function MkBtn(txt, col, func)
            local b = Instance.new("TextButton", Btns)
            b.Size = UDim2.new(0.3, 0, 1, 0)
            b.BackgroundColor3 = col
            b.Text = txt
            b.TextColor3 = Color3.new(1,1,1)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 14
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
            b.MouseButton1Click:Connect(func)
            return b
        end
        
        -- Button Actions
        local BtnRec = MkBtn("⏺", Color3.fromRGB(200, 50, 50), function()
            if RecordSystem.IsRecording then RecordSystem:StopRecording() else RecordSystem:StartRecording() end
        end)
        
        local BtnStop = MkBtn("⏹", Color3.fromRGB(80, 80, 80), function()
            RecordSystem:StopRecording()
            RecordSystem:StopReplay()
        end)
        
        local BtnMenu = MkBtn("☰", Theme.Accent, function()
            -- Buka menu utama ke tab record (Logic manual user membuka menu)
            StarterGui:SetCore("SendNotification", {Title="Info", Text="Open Main Menu > Record Tab"})
        end)
        
        -- Drag Logic
        local dragging, dragStart, startPos
        DragBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=Widget.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
        UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and dragging then local delta=i.Position-dragStart; Widget.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y) end end)
        
        -- Export Control Functions
        MiniWidget = {
            Instance = Widget,
            UpdateStatus = function(txt, col)
                StatusText.Text = txt
                StatusDot.BackgroundColor3 = col
            end
        }
    end

    -- [8] INIT & CLEANUP
    RecordTab:Button("Show Mini Controller", Theme.Button, function()
        if not MiniWidget then CreateMiniWidget() end
        MiniWidget.Instance.Visible = not MiniWidget.Instance.Visible
    end)
    
    RecordTab:Button("Refresh Saved Records", Theme.ButtonDark, function()
        RecordSystem:RefreshList()
    end)
    
    RecordTab:Button("Stop All Actions", Theme.ButtonRed, function()
        RecordSystem:StopRecording()
        RecordSystem:StopReplay()
    end)
    
    -- Auto Load List
    spawn(function()
        task.wait(1)
        RecordSystem:RefreshList()
        CreateMiniWidget()
    end)
    
    -- Reset Event Cleanup
    Config.OnReset:Connect(function()
        RecordSystem:StopRecording()
        RecordSystem:StopReplay()
        if MiniWidget and MiniWidget.Instance then MiniWidget.Instance:Destroy() end
    end)
    
    print("[Vanzyxxx] Ultimate Record System Loaded")
end