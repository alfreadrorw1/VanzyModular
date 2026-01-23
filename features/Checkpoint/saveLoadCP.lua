-- Vanzyxxx Checkpoint System (SMART LOGIC UPDATE)
-- Features: Gap Filling, Double Tap Summit, Smart AutoPlay

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local HttpService = Services.HttpService
    local MarketplaceService = Services.MarketplaceService
    
    -- Create Tab
    local CPTab = UI:Tab("Checkpoint")
    CPTab:Label("Save/Load Checkpoints")
    
    -- Variables
    local CP_Data = {}
    local AutoCPFile = "VanzyCP.json"
    local GithubCP = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/main/JsonLoad/VanzyCP.json"
    
    -- UI References
    local MiniWidget = nil
    local CPManagerFrame = nil
    local CPMainList = nil
    local CPDetailList = nil
    
    -- Helper Functions
    local function GetMapID() return tostring(game.PlaceId) end
    
    local function GetMapName()
        local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
        return (success and info) and info.Name or "Unknown Map"
    end
    
    -- [NEW] SMART NAMING FUNCTION (GAP FILLING)
    local function GetSmartCPName(cpList)
        local usedNumbers = {}
        
        -- Cek nomor yang sudah ada
        for _, cp in ipairs(cpList) do
            -- Ambil angka dari string "CP1", "CP5" dsb
            local num = string.match(cp.Name, "^CP(%d+)$")
            if num then
                usedNumbers[tonumber(num)] = true
            end
        end
        
        -- Cari angka terkecil yang hilang (Gap Filling)
        local counter = 1
        while true do
            if not usedNumbers[counter] then
                return "CP" .. counter
            end
            counter = counter + 1
        end
    end
    
    -- Data Functions
    local function LoadData()
        if isfile and isfile(AutoCPFile) then
            local success, data = pcall(function() return HttpService:JSONDecode(readfile(AutoCPFile)) end)
            if success then return data end
        end
        return {}
    end
    
    local function SaveData(data)
        if writefile then
            pcall(function() writefile(AutoCPFile, HttpService:JSONEncode(data)) end)
        end
    end

    -- [NEW] SMART AUTO PLAY FUNCTION
    local function StartAutoPlay(mapInfo)
        if not mapInfo or not mapInfo.CPs or #mapInfo.CPs == 0 then
            Services.StarterGui:SetCore("SendNotification", {Title="Error", Text="No CPs to play!"})
            return
        end

        -- Logic: Cari CP terdekat dengan posisi pemain sekarang
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local closestIndex = 0
        local closestDist = math.huge -- Jarak tak terhingga

        for i, cp in ipairs(mapInfo.CPs) do
            local cpPos = Vector3.new(cp.X, cp.Y, cp.Z)
            local dist = (cpPos - myPos).Magnitude
            
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end

        -- Tentukan start index (Lanjut ke CP berikutnya dari yang terdekat)
        -- Jika closestIndex = 4 (kita di CP4), maka mulai dari 5.
        local startIndex = closestIndex + 1
        if startIndex > #mapInfo.CPs then
            startIndex = 1 -- Jika sudah di akhir, ulang dari awal (opsional)
            Services.StarterGui:SetCore("SendNotification", {Title="Info", Text="Restarting from CP1..."})
        else
            local targetName = mapInfo.CPs[startIndex].Name
            Services.StarterGui:SetCore("SendNotification", {Title="Smart Play", Text="Continuing to "..targetName, Duration=2})
        end

        Config.AutoPlaying = true
        task.wait(0.5)

        -- Loop dari Start Index sampai Habis
        for i = startIndex, #mapInfo.CPs do
            if not Config.AutoPlaying then break end
            
            local cp = mapInfo.CPs[i]
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z)
                
                local hint = Instance.new("Hint", Services.Workspace)
                hint.Text = "Playing: " .. cp.Name .. " ("..i.."/"..#mapInfo.CPs..")"
                game.Debris:AddItem(hint, 1)
            end
            
            task.wait(1.5) -- Delay 1.5 Detik
        end

        Config.AutoPlaying = false
        Services.StarterGui:SetCore("SendNotification", {Title="Auto Play", Text="Finished!", Duration=3})
    end
    
    -- Save Logic Implementation
    local function SaveCheckpoint(name)
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        local mapID = GetMapID()
        local mapName = GetMapName()
        
        CP_Data = LoadData()
        if not CP_Data[mapID] then CP_Data[mapID] = { MapName = mapName, CPs = {} } end
        
        table.insert(CP_Data[mapID].CPs, {Name = name, X = pos.X, Y = pos.Y, Z = pos.Z})
        
        SaveData(CP_Data)
        Services.StarterGui:SetCore("SendNotification", {Title = "Saved", Text = name, Duration = 2})
        
        -- Refresh list jika menu terbuka
        if CPManagerFrame and CPManagerFrame.Visible then
            -- Trigger refresh via UI logic (perlu akses ke refresh function, kita buat global local di bawah)
        end
    end

    -- Core Functions: Refresh List
    local function RefreshCPList()
        if not CPMainList then return end
        CPMainList.Visible = true
        if CPDetailList then CPDetailList.Visible = false end
        
        for _, child in ipairs(CPMainList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        CP_Data = LoadData()
        
        local count = 0
        for _ in pairs(CP_Data) do count = count + 1 end
        
        if count == 0 then
            local emptyLbl = Instance.new("TextLabel", CPMainList)
            emptyLbl.Size = UDim2.new(1, 0, 0, 30); emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "No Data Found."; emptyLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLbl.Font = Enum.Font.Gotham; emptyLbl.TextSize = 12; emptyLbl.ZIndex = 55
            return
        end
        
        for mapId, mapInfo in pairs(CP_Data) do
            local mapFrame = Instance.new("Frame", CPMainList)
            mapFrame.Size = UDim2.new(1, 0, 0, 35); mapFrame.BackgroundColor3 = Theme.Sidebar; mapFrame.ZIndex = 55
            Instance.new("UICorner", mapFrame).CornerRadius = UDim.new(0, 6)
            
            local mapBtn = Instance.new("TextButton", mapFrame)
            mapBtn.Size = UDim2.new(0.75, 0, 1, 0); mapBtn.BackgroundTransparency = 1
            mapBtn.Text = "📂 " .. (mapInfo.MapName or "Unknown"); mapBtn.TextColor3 = Theme.Accent
            mapBtn.TextXAlignment = Enum.TextXAlignment.Left; mapBtn.Font = Enum.Font.GothamBold; mapBtn.TextSize = 12; mapBtn.ZIndex = 56
            Instance.new("UIPadding", mapBtn).PaddingLeft = UDim.new(0, 10)
            
            local cpCount = Instance.new("TextLabel", mapFrame)
            cpCount.Size = UDim2.new(0.15, 0, 1, 0); cpCount.Position = UDim2.new(0.75, 0, 0, 0)
            cpCount.BackgroundTransparency = 1; cpCount.Text = "(" .. (#mapInfo.CPs or 0) .. ")"
            cpCount.TextColor3 = Color3.fromRGB(200, 200, 200); cpCount.TextSize = 11; cpCount.Font = Enum.Font.Gotham; cpCount.ZIndex = 56
            
            local delMapBtn = Instance.new("TextButton", mapFrame)
            delMapBtn.Size = UDim2.new(0.1, 0, 1, 0); delMapBtn.Position = UDim2.new(0.9, 0, 0, 0)
            delMapBtn.BackgroundColor3 = Theme.ButtonRed; delMapBtn.Text = "X"; delMapBtn.TextColor3 = Theme.Text
            delMapBtn.Font = Enum.Font.GothamBold; delMapBtn.TextSize = 12; delMapBtn.ZIndex = 56
            Instance.new("UICorner", delMapBtn).CornerRadius = UDim.new(0, 6)
            
            mapBtn.MouseButton1Click:Connect(function() ShowMapCPs(mapId, mapInfo) end)
            delMapBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete Map?", function() CP_Data[mapId] = nil; SaveData(CP_Data); RefreshCPList() end)
            end)
        end
        CPMainList.CanvasSize = UDim2.new(0, 0, 0, CPMainList.UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
    function ShowMapCPs(mapId, mapInfo)
        if not CPDetailList then return end
        CPMainList.Visible = false; CPDetailList.Visible = true
        
        for _, child in ipairs(CPDetailList:GetChildren()) do if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
        
        local HeaderFrame = Instance.new("Frame", CPDetailList); HeaderFrame.Size = UDim2.new(1, 0, 0, 30); HeaderFrame.BackgroundTransparency = 1; HeaderFrame.ZIndex = 56
        
        local backBtn = Instance.new("TextButton", HeaderFrame); backBtn.Size = UDim2.new(0.2, 0, 1, 0); backBtn.BackgroundColor3 = Theme.ButtonRed; backBtn.Text = "<"; backBtn.TextColor3 = Theme.Text; backBtn.Font = Enum.Font.GothamBold; backBtn.TextSize = 14; backBtn.ZIndex = 57
        Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)
        
        local playAllBtn = Instance.new("TextButton", HeaderFrame); playAllBtn.Size = UDim2.new(0.75, 0, 1, 0); playAllBtn.Position = UDim2.new(0.25, 0, 0, 0); playAllBtn.BackgroundColor3 = Theme.PlayBtn or Color3.fromRGB(0, 170, 255); playAllBtn.Text = "▶ SMART PLAY"; playAllBtn.TextColor3 = Theme.Text; playAllBtn.Font = Enum.Font.GothamBlack; playAllBtn.TextSize = 12; playAllBtn.ZIndex = 57
        Instance.new("UICorner", playAllBtn).CornerRadius = UDim.new(0, 6)
        
        backBtn.MouseButton1Click:Connect(function() Config.AutoPlaying = false; CPDetailList.Visible = false; CPMainList.Visible = true; RefreshCPList() end)
        
        playAllBtn.MouseButton1Click:Connect(function()
            if Config.AutoPlaying then
                Config.AutoPlaying = false; playAllBtn.Text = "▶ SMART PLAY"; playAllBtn.BackgroundColor3 = Theme.PlayBtn
            else
                playAllBtn.Text = "⏹ STOP"; playAllBtn.BackgroundColor3 = Theme.ButtonRed; StartAutoPlay(mapInfo)
                if playAllBtn and playAllBtn.Parent then playAllBtn.Text = "▶ SMART PLAY"; playAllBtn.BackgroundColor3 = Theme.PlayBtn end
            end
        end)
        
        local spacer = Instance.new("Frame", CPDetailList); spacer.Size = UDim2.new(1, 0, 0, 5); spacer.BackgroundTransparency = 1
        
        for i, cp in ipairs(mapInfo.CPs) do
            local cpFrame = Instance.new("Frame", CPDetailList); cpFrame.Size = UDim2.new(1, 0, 0, 35); cpFrame.BackgroundColor3 = Theme.Button; cpFrame.ZIndex = 55
            Instance.new("UICorner", cpFrame).CornerRadius = UDim.new(0, 6)
            
            local cpInfo = Instance.new("TextLabel", cpFrame); cpInfo.Size = UDim2.new(0.6, 0, 1, 0); cpInfo.BackgroundTransparency = 1; cpInfo.Text = "📍 " .. cp.Name; cpInfo.TextColor3 = Theme.Text; cpInfo.TextSize = 11; cpInfo.TextXAlignment = Enum.TextXAlignment.Left; cpInfo.Font = Enum.Font.Gotham; cpInfo.ZIndex = 56; Instance.new("UIPadding", cpInfo).PaddingLeft = UDim.new(0, 10)
            
            local tpBtn = Instance.new("TextButton", cpFrame); tpBtn.Size = UDim2.new(0.2, 0, 0.8, 0); tpBtn.Position = UDim2.new(0.6, 0, 0.1, 0); tpBtn.BackgroundColor3 = Theme.Confirm; tpBtn.Text = "TP"; tpBtn.TextColor3 = Theme.Text; tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 10; tpBtn.ZIndex = 56; Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
            
            local delBtn = Instance.new("TextButton", cpFrame); delBtn.Size = UDim2.new(0.15, 0, 0.8, 0); delBtn.Position = UDim2.new(0.82, 0, 0.1, 0); delBtn.BackgroundColor3 = Theme.ButtonRed; delBtn.Text = "X"; delBtn.TextColor3 = Theme.Text; delBtn.Font = Enum.Font.GothamBold; delBtn.TextSize = 10; delBtn.ZIndex = 56; Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            
            tpBtn.MouseButton1Click:Connect(function() if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z) end end)
            delBtn.MouseButton1Click:Connect(function() UI:Confirm("Delete?", function() table.remove(CP_Data[mapId].CPs, i); SaveData(CP_Data); ShowMapCPs(mapId, mapInfo) end) end)
        end
        CPDetailList.CanvasSize = UDim2.new(0, 0, 0, CPDetailList.UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
    local function CreateCPManager()
        if CPManagerFrame then CPManagerFrame:Destroy() end
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        local CPF = Instance.new("Frame", screenGui); CPF.Name = "CPManager"; CPF.Size = UDim2.new(0, 320, 0, 380); CPF.Position = UDim2.new(0.5, -160, 0.5, -190); CPF.BackgroundColor3 = Theme.Main; CPF.Visible = false; CPF.ZIndex = 50
        Instance.new("UICorner", CPF).CornerRadius = UDim.new(0, 10); local str = Instance.new("UIStroke", CPF); str.Color = Theme.Accent; str.Thickness = 2
        
        local header = Instance.new("TextLabel", CPF); header.Size = UDim2.new(1, -30, 0, 30); header.Position = UDim2.new(0, 10, 0, 0); header.BackgroundTransparency = 1; header.Text = "CHECKPOINT MANAGER"; header.TextColor3 = Theme.Accent; header.Font = Enum.Font.GothamBlack; header.TextXAlignment = Enum.TextXAlignment.Left; header.ZIndex = 51; Instance.new("UIPadding", header).PaddingLeft = UDim.new(0, 10)
        local closeBtn = Instance.new("TextButton", CPF); closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -30, 0, 0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 18; closeBtn.ZIndex = 51
        closeBtn.MouseButton1Click:Connect(function() CPF.Visible = false; Config.AutoPlaying = false end)
        
        local mainList = Instance.new("ScrollingFrame", CPF); mainList.Size = UDim2.new(1, -20, 0.75, -5); mainList.Position = UDim2.new(0, 10, 0.1, 0); mainList.BackgroundTransparency = 1; mainList.ScrollBarThickness = 2; mainList.ZIndex = 51; Instance.new("UIListLayout", mainList).Padding = UDim.new(0, 4); CPMainList = mainList
        local detailList = Instance.new("ScrollingFrame", CPF); detailList.Size = UDim2.new(1, -20, 0.75, -5); detailList.Position = UDim2.new(0, 10, 0.1, 0); detailList.BackgroundTransparency = 1; detailList.ScrollBarThickness = 2; detailList.Visible = false; detailList.ZIndex = 51; Instance.new("UIListLayout", detailList).Padding = UDim.new(0, 4); CPDetailList = detailList
        
        local loadLocalBtn = Instance.new("TextButton", CPF); loadLocalBtn.Size = UDim2.new(0.45, 0, 0, 35); loadLocalBtn.Position = UDim2.new(0.03, 0, 0.88, 0); loadLocalBtn.BackgroundColor3 = Theme.ButtonDark; loadLocalBtn.Text = "Load Local"; loadLocalBtn.TextColor3 = Theme.Text; loadLocalBtn.ZIndex = 52; Instance.new("UICorner", loadLocalBtn)
        local loadGitBtn = Instance.new("TextButton", CPF); loadGitBtn.Size = UDim2.new(0.45, 0, 0, 35); loadGitBtn.Position = UDim2.new(0.52, 0, 0.88, 0); loadGitBtn.BackgroundColor3 = Theme.Button; loadGitBtn.Text = "Load GitHub"; loadGitBtn.TextColor3 = Theme.Text; loadGitBtn.ZIndex = 52; Instance.new("UICorner", loadGitBtn)
        
        loadLocalBtn.MouseButton1Click:Connect(function() RefreshCPList(); Services.StarterGui:SetCore("SendNotification", {Title="Local", Text="Refreshed"}) end)
        loadGitBtn.MouseButton1Click:Connect(function() pcall(function() local webData = game:HttpGet(GithubCP); writefile(AutoCPFile, webData); task.wait(0.2); RefreshCPList(); Services.StarterGui:SetCore("SendNotification", {Title="GitHub", Text="Loaded!"}) end) end)
        
        CPManagerFrame = CPF
        return CPF
    end
    
    local function CreateMiniWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        local MW = Instance.new("Frame", screenGui); MW.Name="MiniWidget"; MW.Size=UDim2.new(0,140,0,45); MW.Position=UDim2.new(0.8,-70,0.4,0); MW.BackgroundColor3=Theme.Main; MW.Visible=false; MW.ZIndex=40; Instance.new("UICorner",MW).CornerRadius=UDim.new(0,8); local str=Instance.new("UIStroke",MW); str.Color=Theme.Accent; str.Thickness=2
        local dragBtn=Instance.new("TextButton",MW); dragBtn.Size=UDim2.new(0,30,1,0); dragBtn.BackgroundTransparency=1; dragBtn.Text="[+]"; dragBtn.TextColor3=Theme.Accent; dragBtn.ZIndex=41
        local saveBtn=Instance.new("TextButton",MW); saveBtn.Size=UDim2.new(0,70,1,0); saveBtn.Position=UDim2.new(0,30,0,0); saveBtn.BackgroundTransparency=1; saveBtn.Text="SAVE CP"; saveBtn.TextColor3=Theme.Text; saveBtn.Font=Enum.Font.GothamBlack; saveBtn.ZIndex=41
        local menuBtn=Instance.new("TextButton",MW); menuBtn.Size=UDim2.new(0,30,1,0); menuBtn.Position=UDim2.new(0,100,0,0); menuBtn.BackgroundTransparency=1; menuBtn.Text="[×]"; menuBtn.TextColor3=Color3.fromRGB(255,200,50); menuBtn.ZIndex=41
        
        local dragging, dragStart, startPos
        dragBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=MW.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
        Services.UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and dragging then local delta=i.Position-dragStart; MW.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y) end end)
        
        -- [NEW] DOUBLE TAP SAVE LOGIC
        local lastClickTime = 0
        saveBtn.MouseButton1Click:Connect(function()
            local currentTime = tick()
            local timeDiff = currentTime - lastClickTime
            lastClickTime = currentTime
            
            if timeDiff < 0.5 then
                -- Double Tap -> SUMMIT
                UI:Confirm("Save as SUMMIT/FINISH?", function()
                    SaveCheckpoint("SUMMIT")
                end)
            else
                -- Single Tap -> Normal CP (Smart Naming)
                local id = GetMapID()
                CP_Data = LoadData()
                local cpList = (CP_Data[id] and CP_Data[id].CPs) and CP_Data[id].CPs or {}
                
                -- Gunakan fungsi Smart Naming (mengisi gap CP5 jika dihapus)
                local smartName = GetSmartCPName(cpList)
                
                UI:Confirm("Save as "..smartName.."?", function()
                    SaveCheckpoint(smartName)
                end)
            end
        end)
        
        menuBtn.MouseButton1Click:Connect(function() CreateCPManager(); CPManagerFrame.Visible=true; RefreshCPList() end)
        MiniWidget = MW
    end
    
    CPTab:Toggle("Show Mini Widget", function(s) if s then if not MiniWidget then CreateMiniWidget() end; MiniWidget.Visible=true else if MiniWidget then MiniWidget.Visible=false end end end)
    CPTab:Button("Open CP Manager", Theme.ButtonDark, function() CreateCPManager(); CPManagerFrame.Visible=true; RefreshCPList() end)
    
    spawn(function() task.wait(1); CreateMiniWidget(); CreateCPManager(); CP_Data=LoadData() end)
    Config.OnReset:Connect(function() if MiniWidget then MiniWidget:Destroy() end; if CPManagerFrame then CPManagerFrame:Destroy() end end)
    print("[Vanzyxxx] Checkpoint System Smart Loaded")
end