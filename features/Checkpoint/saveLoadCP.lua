-- Vanzyxxx Checkpoint System (FIXED)
-- Save and Load Checkpoints with Auto-Play & Folder Fix

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
    local GithubCP = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/LoadJson/main/VanzyCP.json"
    
    -- UI References
    local MiniWidget = nil
    local CPManagerFrame = nil
    local CPMainList = nil
    local CPDetailList = nil
    
    -- Helper Functions
    local function GetMapID()
        return tostring(game.PlaceId)
    end
    
    local function GetMapName()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        return (success and info) and info.Name or "Unknown Map"
    end
    
    -- Data Functions
    local function LoadData()
        if isfile and isfile(AutoCPFile) then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(AutoCPFile))
            end)
            if success then return data end
        end
        return {}
    end
    
    local function SaveData(data)
        if writefile then
            pcall(function()
                writefile(AutoCPFile, HttpService:JSONEncode(data))
            end)
        end
    end
    
    -- Core Functions
    local function RefreshCPList()
        -- Pastikan Main List ada sebelum lanjut
        if not CPMainList then return end
        
        -- Reset Visibility: Tampilkan Folder List, Sembunyikan Isi CP
        CPMainList.Visible = true
        if CPDetailList then CPDetailList.Visible = false end
        
        -- Bersihkan list lama
        for _, child in ipairs(CPMainList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        -- Load data terbaru
        CP_Data = LoadData()
        
        -- Loop setiap map
        for mapId, mapInfo in pairs(CP_Data) do
            local mapFrame = Instance.new("Frame", CPMainList)
            mapFrame.Size = UDim2.new(1, 0, 0, 35)
            mapFrame.BackgroundColor3 = Theme.Sidebar
            mapFrame.ZIndex = 52 -- FIX: Harus lebih tinggi dari background (50)
            
            local mapCorner = Instance.new("UICorner", mapFrame)
            mapCorner.CornerRadius = UDim.new(0, 6)
            
            -- Tombol Nama Map
            local mapBtn = Instance.new("TextButton", mapFrame)
            mapBtn.Size = UDim2.new(0.7, 0, 1, 0)
            mapBtn.BackgroundTransparency = 1
            mapBtn.Text = "📁 " .. (mapInfo.MapName or "Unknown")
            mapBtn.TextColor3 = Theme.Accent
            mapBtn.TextXAlignment = Enum.TextXAlignment.Left
            mapBtn.Font = Enum.Font.GothamBold
            mapBtn.TextSize = 12
            mapBtn.ZIndex = 53 -- FIX
            
            local mapPadding = Instance.new("UIPadding", mapBtn)
            mapPadding.PaddingLeft = UDim.new(0, 10)
            
            -- Counter CP
            local cpCountStr = mapInfo.CPs and #mapInfo.CPs or 0
            local cpCount = Instance.new("TextLabel", mapFrame)
            cpCount.Size = UDim2.new(0.2, 0, 1, 0)
            cpCount.Position = UDim2.new(0.7, 0, 0, 0)
            cpCount.BackgroundTransparency = 1
            cpCount.Text = cpCountStr .. " CPs"
            cpCount.TextColor3 = Color3.fromRGB(200, 200, 200)
            cpCount.TextSize = 11
            cpCount.Font = Enum.Font.Gotham
            cpCount.ZIndex = 53 -- FIX
            
            -- Tombol Hapus Map
            local delMapBtn = Instance.new("TextButton", mapFrame)
            delMapBtn.Size = UDim2.new(0.1, 0, 1, 0)
            delMapBtn.Position = UDim2.new(0.9, 0, 0, 0)
            delMapBtn.BackgroundColor3 = Theme.ButtonRed
            delMapBtn.Text = "X"
            delMapBtn.TextColor3 = Theme.Text
            delMapBtn.Font = Enum.Font.GothamBold
            delMapBtn.TextSize = 12
            delMapBtn.ZIndex = 53 -- FIX
            
            local delCorner = Instance.new("UICorner", delMapBtn)
            
            -- Events
            mapBtn.MouseButton1Click:Connect(function()
                ShowMapCPs(mapId, mapInfo) -- Buka isi folder
            end)
            
            delMapBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete map: " .. mapInfo.MapName .. "?", function()
                    CP_Data[mapId] = nil
                    SaveData(CP_Data)
                    RefreshCPList()
                end)
            end)
        end
        
        -- Update scrolling size
        CPMainList.CanvasSize = UDim2.new(0, 0, 0, CPMainList.UIListLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- Show Details (Isi Folder)
    function ShowMapCPs(mapId, mapInfo)
        if not CPDetailList then return end
        
        CPMainList.Visible = false
        CPDetailList.Visible = true
        
        -- Clear list
        for _, child in ipairs(CPDetailList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
        
        -- Tombol Back
        local backBtn = Instance.new("TextButton", CPDetailList)
        backBtn.Size = UDim2.new(1, 0, 0, 30)
        backBtn.BackgroundColor3 = Theme.ButtonRed
        backBtn.Text = "← BACK to Maps"
        backBtn.TextColor3 = Theme.Text
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 12
        backBtn.ZIndex = 53 -- FIX
        
        local backCorner = Instance.new("UICorner", backBtn)
        backCorner.CornerRadius = UDim.new(0, 6)
        
        backBtn.MouseButton1Click:Connect(function()
            CPDetailList.Visible = false
            CPMainList.Visible = true
            RefreshCPList()
        end)
        
        -- Header Nama Map
        local mapTitle = Instance.new("TextLabel", CPDetailList)
        mapTitle.Size = UDim2.new(1, 0, 0, 25)
        mapTitle.BackgroundTransparency = 1
        mapTitle.Text = "📌 " .. mapInfo.MapName
        mapTitle.TextColor3 = Theme.Accent
        mapTitle.TextSize = 14
        mapTitle.Font = Enum.Font.GothamBlack
        mapTitle.ZIndex = 53
        
        -- List Checkpoints
        for i, cp in ipairs(mapInfo.CPs) do
            local cpFrame = Instance.new("Frame", CPDetailList)
            cpFrame.Size = UDim2.new(1, 0, 0, 40)
            cpFrame.BackgroundColor3 = Theme.Button
            cpFrame.ZIndex = 52 -- FIX
            
            local cpCorner = Instance.new("UICorner", cpFrame)
            cpCorner.CornerRadius = UDim.new(0, 6)
            
            local cpInfo = Instance.new("TextLabel", cpFrame)
            cpInfo.Size = UDim2.new(0.6, 0, 1, 0)
            cpInfo.BackgroundTransparency = 1
            cpInfo.Text = "📍 " .. cp.Name .. "\nX: " .. math.floor(cp.X)
            cpInfo.TextColor3 = Theme.Text
            cpInfo.TextSize = 11
            cpInfo.TextXAlignment = Enum.TextXAlignment.Left
            cpInfo.Font = Enum.Font.Gotham
            cpInfo.ZIndex = 53
            
            local infoPadding = Instance.new("UIPadding", cpInfo)
            infoPadding.PaddingLeft = UDim.new(0, 10)
            
            local tpBtn = Instance.new("TextButton", cpFrame)
            tpBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
            tpBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
            tpBtn.BackgroundColor3 = Theme.Confirm
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Theme.Text
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 11
            tpBtn.ZIndex = 53
            
            local tpCorner = Instance.new("UICorner", tpBtn)
            tpCorner.CornerRadius = UDim.new(0, 4)
            
            local delBtn = Instance.new("TextButton", cpFrame)
            delBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
            delBtn.Position = UDim2.new(0.8, 0, 0.15, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed
            delBtn.Text = "DEL"
            delBtn.TextColor3 = Theme.Text
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 11
            delBtn.ZIndex = 53
            
            local delCorner = Instance.new("UICorner", delBtn)
            delCorner.CornerRadius = UDim.new(0, 4)
            
            tpBtn.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z)
                    Services.StarterGui:SetCore("SendNotification", {Title = "Teleported", Text = cp.Name, Duration = 2})
                end
            end)
            
            delBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete " .. cp.Name .. "?", function()
                    table.remove(CP_Data[mapId].CPs, i)
                    SaveData(CP_Data)
                    ShowMapCPs(mapId, mapInfo) -- Refresh halaman ini
                end)
            end)
        end
        
        CPDetailList.CanvasSize = UDim2.new(0, 0, 0, CPDetailList.UIListLayout.AbsoluteContentSize.Y + 10)
    end
    
    local function SaveCheckpoint(name)
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        local mapID = GetMapID()
        local mapName = GetMapName()
        
        CP_Data = LoadData()
        
        if not CP_Data[mapID] then
            CP_Data[mapID] = { MapName = mapName, CPs = {} }
        end
        
        table.insert(CP_Data[mapID].CPs, {
            Name = name, X = pos.X, Y = pos.Y, Z = pos.Z, Timestamp = os.time()
        })
        
        SaveData(CP_Data)
        Services.StarterGui:SetCore("SendNotification", {Title = "Saved", Text = name, Duration = 2})
        RefreshCPList()
    end
    
    -- Create CP Manager UI
    local function CreateCPManager()
        if CPManagerFrame then CPManagerFrame:Destroy() end
        
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        local CPF = Instance.new("Frame", screenGui)
        CPF.Name = "CPManager"
        CPF.Size = UDim2.new(0, 320, 0, 380)
        CPF.Position = UDim2.new(0.5, -160, 0.5, -190)
        CPF.BackgroundColor3 = Theme.Main
        CPF.Visible = false
        CPF.ZIndex = 50 -- Base ZIndex
        
        local CPFCorner = Instance.new("UICorner", CPF)
        CPFCorner.CornerRadius = UDim.new(0, 10)
        
        local CPFStroke = Instance.new("UIStroke", CPF)
        CPFStroke.Color = Theme.Accent
        CPFStroke.Thickness = 2
        
        -- Header
        local header = Instance.new("TextLabel", CPF)
        header.Size = UDim2.new(1, -30, 0, 30)
        header.Position = UDim2.new(0, 10, 0, 0)
        header.BackgroundTransparency = 1
        header.Text = "CHECKPOINT MANAGER"
        header.TextColor3 = Theme.Accent
        header.Font = Enum.Font.GothamBlack
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 51
        
        -- Close Button
        local closeBtn = Instance.new("TextButton", CPF)
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -30, 0, 0)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 18
        closeBtn.ZIndex = 51
        
        closeBtn.MouseButton1Click:Connect(function()
            CPF.Visible = false
        end)
        
        -- Main List Container (Untuk Folder Map)
        local mainList = Instance.new("ScrollingFrame", CPF)
        mainList.Size = UDim2.new(1, -10, 0.75, -5)
        mainList.Position = UDim2.new(0, 5, 0.1, 0)
        mainList.BackgroundTransparency = 1
        mainList.ScrollBarThickness = 2
        mainList.ZIndex = 51
        local mainLayout = Instance.new("UIListLayout", mainList)
        mainLayout.Padding = UDim.new(0, 4)
        CPMainList = mainList
        
        -- Detail List Container (Untuk Isi CP)
        local detailList = Instance.new("ScrollingFrame", CPF)
        detailList.Size = UDim2.new(1, -10, 0.75, -5)
        detailList.Position = UDim2.new(0, 5, 0.1, 0)
        detailList.BackgroundTransparency = 1
        detailList.ScrollBarThickness = 2
        detailList.Visible = false
        detailList.ZIndex = 51
        local detailLayout = Instance.new("UIListLayout", detailList)
        detailLayout.Padding = UDim.new(0, 4)
        CPDetailList = detailList
        
        -- Bottom Buttons
        local loadLocalBtn = Instance.new("TextButton", CPF)
        loadLocalBtn.Size = UDim2.new(0.45, 0, 0, 35)
        loadLocalBtn.Position = UDim2.new(0.03, 0, 0.88, 0)
        loadLocalBtn.BackgroundColor3 = Theme.ButtonDark
        loadLocalBtn.Text = "Load Local"
        loadLocalBtn.TextColor3 = Theme.Text
        loadLocalBtn.Font = Enum.Font.Gotham
        loadLocalBtn.TextSize = 12
        loadLocalBtn.ZIndex = 52
        local llc = Instance.new("UICorner", loadLocalBtn)
        
        local loadGitBtn = Instance.new("TextButton", CPF)
        loadGitBtn.Size = UDim2.new(0.45, 0, 0, 35)
        loadGitBtn.Position = UDim2.new(0.52, 0, 0.88, 0)
        loadGitBtn.BackgroundColor3 = Theme.Button
        loadGitBtn.Text = "Load GitHub"
        loadGitBtn.TextColor3 = Theme.Text
        loadGitBtn.Font = Enum.Font.Gotham
        loadGitBtn.TextSize = 12
        loadGitBtn.ZIndex = 52
        local lgc = Instance.new("UICorner", loadGitBtn)
        
        -- Events
        loadLocalBtn.MouseButton1Click:Connect(function()
            RefreshCPList()
            Services.StarterGui:SetCore("SendNotification", {Title="CP Manager", Text="Local Data Loaded"})
        end)
        
        loadGitBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local webData = game:HttpGet(GithubCP)
                if writefile then
                    writefile(AutoCPFile, webData)
                    task.wait(0.1)
                    RefreshCPList()
                    Services.StarterGui:SetCore("SendNotification", {Title="CP Manager", Text="GitHub Data Loaded"})
                end
            end)
        end)
        
        CPManagerFrame = CPF
        return CPF
    end
    
    -- Create Mini Widget
    local function CreateMiniWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        local MW = Instance.new("Frame", screenGui)
        MW.Name = "MiniWidget"
        MW.Size = UDim2.new(0, 140, 0, 45)
        MW.Position = UDim2.new(0.8, -70, 0.4, 0)
        MW.BackgroundColor3 = Theme.Main
        MW.Visible = false
        MW.ZIndex = 40
        
        local MWCorner = Instance.new("UICorner", MW)
        MWCorner.CornerRadius = UDim.new(0, 8)
        local MWStroke = Instance.new("UIStroke", MW)
        MWStroke.Color = Theme.Accent
        MWStroke.Thickness = 2
        
        -- Drag & Buttons
        local dragBtn = Instance.new("TextButton", MW)
        dragBtn.Size = UDim2.new(0, 30, 1, 0)
        dragBtn.BackgroundTransparency = 1
        dragBtn.Text = "[+]"
        dragBtn.TextColor3 = Theme.Accent
        dragBtn.Font = Enum.Font.GothamBlack
        dragBtn.TextSize = 14
        
        local saveBtn = Instance.new("TextButton", MW)
        saveBtn.Size = UDim2.new(0, 70, 1, 0)
        saveBtn.Position = UDim2.new(0, 30, 0, 0)
        saveBtn.BackgroundTransparency = 1
        saveBtn.Text = "SAVE CP"
        saveBtn.TextColor3 = Theme.Text
        saveBtn.Font = Enum.Font.GothamBlack
        saveBtn.TextSize = 16
        
        local menuBtn = Instance.new("TextButton", MW)
        menuBtn.Size = UDim2.new(0, 30, 1, 0)
        menuBtn.Position = UDim2.new(0, 100, 0, 0)
        menuBtn.BackgroundTransparency = 1
        menuBtn.Text = "[×]"
        menuBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        menuBtn.Font = Enum.Font.GothamBlack
        menuBtn.TextSize = 14
        
        -- Drag Logic
        local dragging, dragStart, startPos
        dragBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MW.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        Services.UserInputService.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                local delta = input.Position - dragStart
                MW.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        MiniWidget = MW
        
        -- Events
        saveBtn.MouseButton1Click:Connect(function()
            local mapID = GetMapID()
            CP_Data = LoadData()
            
            local cpCount = 0
            if CP_Data[mapID] and CP_Data[mapID].CPs then
                cpCount = #CP_Data[mapID].CPs
            end
            
            -- FIX: Gunakan Count + 1 agar nama menjadi CP1, CP2, dst.
            local nextNum = cpCount + 1
            local cpName = (cpCount == 0) and "SPAWN" or "CP" .. nextNum
            
            UI:Confirm("Save as " .. cpName .. "?", function()
                SaveCheckpoint(cpName)
            end)
        end)
        
        menuBtn.MouseButton1Click:Connect(function()
            CreateCPManager()
            CPManagerFrame.Visible = true
            RefreshCPList()
        end)
        
        return MW
    end
    
    -- Main UI Tab Controls
    CPTab:Label("Quick Controls")
    CPTab:Toggle("Show Mini Widget", function(state)
        if state then
            if not MiniWidget then CreateMiniWidget() end
            MiniWidget.Visible = true
        elseif MiniWidget then
            MiniWidget.Visible = false
        end
    end)
    
    CPTab:Button("Open CP Manager", Theme.ButtonDark, function()
        CreateCPManager()
        CPManagerFrame.Visible = true
        RefreshCPList()
    end)
    
    -- Init
    spawn(function()
        task.wait(1)
        CreateMiniWidget()
        CreateCPManager()
        CP_Data = LoadData()
    end)
    
    -- Cleanup on script reload
    Config.OnReset:Connect(function()
        if MiniWidget then MiniWidget:Destroy() end
        if CPManagerFrame then CPManagerFrame:Destroy() end
    end)
    
    print("[Vanzyxxx] Checkpoint System Fixed Loaded")
end