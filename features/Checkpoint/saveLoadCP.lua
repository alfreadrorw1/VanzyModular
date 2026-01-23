-- Vanzyxxx Checkpoint System
-- Save and Load Checkpoints with Auto-Play

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
    local GithubCP = "https://raw.githubusercontent.com/alfreadrorw1/vanzyx/main/SaveCp.json"
    
    -- Mini Widget
    local MiniWidget = nil
    local CPManagerFrame = nil
    local CPMainList = nil
    local CPDetailList = nil
    
    -- Function to get map info
    local function GetMapID()
        return tostring(game.PlaceId)
    end
    
    local function GetMapName()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        
        if success and info then
            return info.Name
        else
            return "Unknown Map"
        end
    end
    
    -- Function to load data
    local function LoadData()
        if isfile and isfile(AutoCPFile) then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(AutoCPFile))
            end)
            
            if success then
                return data
            end
        end
        return {}
    end
    
    -- Function to save data
    local function SaveData(data)
        if writefile then
            pcall(function()
                writefile(AutoCPFile, HttpService:JSONEncode(data))
            end)
        end
    end
    
    -- Function to save checkpoint
    local function SaveCheckpoint(name)
        if not LocalPlayer.Character then return end
        
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local position = root.Position
        
        local mapID = GetMapID()
        local mapName = GetMapName()
        
        -- Load existing data
        CP_Data = LoadData()
        
        -- Initialize map data if not exists
        if not CP_Data[mapID] then
            CP_Data[mapID] = {
                MapName = mapName,
                CPs = {}
            }
        end
        
        -- Add checkpoint
        table.insert(CP_Data[mapID].CPs, {
            Name = name,
            X = position.X,
            Y = position.Y,
            Z = position.Z,
            Timestamp = os.time()
        })
        
        -- Save data
        SaveData(CP_Data)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Checkpoint Saved",
            Text = name,
            Duration = 3
        })
        
        RefreshCPList()
    end
    
    -- Function to teleport to checkpoint
    local function TeleportToCheckpoint(cp)
        if not LocalPlayer.Character then return end
        
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        root.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Teleported",
            Text = cp.Name,
            Duration = 2
        })
    end
    
    -- Function to refresh CP list
    function RefreshCPList()
        if not CPMainList then return end
        
        -- Clear main list
        for _, child in ipairs(CPMainList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Load data
        CP_Data = LoadData()
        
        -- Add maps to list
        for mapId, mapInfo in pairs(CP_Data) do
            local mapFrame = Instance.new("Frame", CPMainList)
            mapFrame.Size = UDim2.new(1, 0, 0, 35)
            mapFrame.BackgroundColor3 = Theme.Sidebar
            mapFrame.ZIndex = 32
            
            local mapCorner = Instance.new("UICorner", mapFrame)
            mapCorner.CornerRadius = UDim.new(0, 6)
            
            -- Map button
            local mapBtn = Instance.new("TextButton", mapFrame)
            mapBtn.Size = UDim2.new(0.7, 0, 1, 0)
            mapBtn.BackgroundTransparency = 1
            mapBtn.Text = "📁 " .. mapInfo.MapName
            mapBtn.TextColor3 = Theme.Accent
            mapBtn.TextXAlignment = Enum.TextXAlignment.Left
            mapBtn.Font = Enum.Font.GothamBold
            mapBtn.TextSize = 12
            mapBtn.ZIndex = 33
            
            local mapPadding = Instance.new("UIPadding", mapBtn)
            mapPadding.PaddingLeft = UDim.new(0, 10)
            
            -- CP count
            local cpCount = Instance.new("TextLabel", mapFrame)
            cpCount.Size = UDim2.new(0.2, 0, 1, 0)
            cpCount.Position = UDim2.new(0.7, 0, 0, 0)
            cpCount.BackgroundTransparency = 1
            cpCount.Text = #mapInfo.CPs .. " CPs"
            cpCount.TextColor3 = Color3.fromRGB(200, 200, 200)
            cpCount.TextSize = 11
            cpCount.Font = Enum.Font.Gotham
            cpCount.ZIndex = 33
            
            -- Delete map button
            local delMapBtn = Instance.new("TextButton", mapFrame)
            delMapBtn.Size = UDim2.new(0.1, 0, 1, 0)
            delMapBtn.Position = UDim2.new(0.9, 0, 0, 0)
            delMapBtn.BackgroundColor3 = Theme.ButtonRed
            delMapBtn.Text = "X"
            delMapBtn.TextColor3 = Theme.Text
            delMapBtn.Font = Enum.Font.GothamBold
            delMapBtn.TextSize = 12
            delMapBtn.ZIndex = 33
            
            local delCorner = Instance.new("UICorner", delMapBtn)
            
            -- Map button click - show CPs
            mapBtn.MouseButton1Click:Connect(function()
                ShowMapCPs(mapId, mapInfo)
            end)
            
            -- Delete map
            delMapBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete map: " .. mapInfo.MapName .. "?", function()
                    CP_Data[mapId] = nil
                    SaveData(CP_Data)
                    RefreshCPList()
                end)
            end)
        end
        
        -- Update canvas size
        CPMainList.CanvasSize = UDim2.new(0, 0, 0, CPMainList.UIListLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- Function to show map checkpoints
    local function ShowMapCPs(mapId, mapInfo)
        if not CPDetailList then return end
        
        -- Hide main list, show detail list
        CPMainList.Visible = false
        CPDetailList.Visible = true
        
        -- Clear detail list
        for _, child in ipairs(CPDetailList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Back button
        local backBtn = Instance.new("TextButton", CPDetailList)
        backBtn.Size = UDim2.new(1, 0, 0, 30)
        backBtn.BackgroundColor3 = Theme.ButtonRed
        backBtn.Text = "← BACK to Maps"
        backBtn.TextColor3 = Theme.Text
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 12
        backBtn.ZIndex = 33
        
        local backCorner = Instance.new("UICorner", backBtn)
        backCorner.CornerRadius = UDim.new(0, 6)
        
        backBtn.MouseButton1Click:Connect(function()
            CPDetailList.Visible = false
            CPMainList.Visible = true
            RefreshCPList()
        end)
        
        -- Map title
        local mapTitle = Instance.new("TextLabel", CPDetailList)
        mapTitle.Size = UDim2.new(1, 0, 0, 25)
        mapTitle.BackgroundTransparency = 1
        mapTitle.Text = "📌 " .. mapInfo.MapName
        mapTitle.TextColor3 = Theme.Accent
        mapTitle.TextSize = 14
        mapTitle.Font = Enum.Font.GothamBlack
        mapTitle.ZIndex = 32
        
        -- Add CPs
        for i, cp in ipairs(mapInfo.CPs) do
            local cpFrame = Instance.new("Frame", CPDetailList)
            cpFrame.Size = UDim2.new(1, 0, 0, 40)
            cpFrame.BackgroundColor3 = Theme.Button
            cpFrame.ZIndex = 32
            
            local cpCorner = Instance.new("UICorner", cpFrame)
            cpCorner.CornerRadius = UDim.new(0, 6)
            
            -- CP name and info
            local cpInfo = Instance.new("TextLabel", cpFrame)
            cpInfo.Size = UDim2.new(0.6, 0, 1, 0)
            cpInfo.BackgroundTransparency = 1
            cpInfo.Text = "📍 " .. cp.Name .. "\nX: " .. math.floor(cp.X) .. " Y: " .. math.floor(cp.Y) .. " Z: " .. math.floor(cp.Z)
            cpInfo.TextColor3 = Theme.Text
            cpInfo.TextSize = 11
            cpInfo.TextXAlignment = Enum.TextXAlignment.Left
            cpInfo.Font = Enum.Font.Gotham
            cpInfo.ZIndex = 33
            
            local infoPadding = Instance.new("UIPadding", cpInfo)
            infoPadding.PaddingLeft = UDim.new(0, 10)
            
            -- Teleport button
            local tpBtn = Instance.new("TextButton", cpFrame)
            tpBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
            tpBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
            tpBtn.BackgroundColor3 = Theme.Confirm
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Theme.Text
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 11
            tpBtn.ZIndex = 33
            
            local tpCorner = Instance.new("UICorner", tpBtn)
            tpCorner.CornerRadius = UDim.new(0, 4)
            
            -- Delete CP button
            local delBtn = Instance.new("TextButton", cpFrame)
            delBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
            delBtn.Position = UDim2.new(0.8, 0, 0.15, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed
            delBtn.Text = "DEL"
            delBtn.TextColor3 = Theme.Text
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 11
            delBtn.ZIndex = 33
            
            local delCorner = Instance.new("UICorner", delBtn)
            delCorner.CornerRadius = UDim.new(0, 4)
            
            -- Button events
            tpBtn.MouseButton1Click:Connect(function()
                TeleportToCheckpoint(cp)
            end)
            
            delBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete checkpoint: " .. cp.Name .. "?", function()
                    table.remove(CP_Data[mapId].CPs, i)
                    SaveData(CP_Data)
                    ShowMapCPs(mapId, mapInfo) -- Refresh
                end)
            end)
        end
        
        -- Update canvas size
        CPDetailList.CanvasSize = UDim2.new(0, 0, 0, CPDetailList.UIListLayout.AbsoluteContentSize.Y + 10)
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
        
        -- Drag button
        local dragBtn = Instance.new("TextButton", MW)
        dragBtn.Size = UDim2.new(0, 30, 1, 0)
        dragBtn.BackgroundTransparency = 1
        dragBtn.Text = "[+]"
        dragBtn.TextColor3 = Theme.Accent
        dragBtn.Font = Enum.Font.GothamBlack
        dragBtn.TextSize = 14
        
        -- Save button
        local saveBtn = Instance.new("TextButton", MW)
        saveBtn.Size = UDim2.new(0, 70, 1, 0)
        saveBtn.Position = UDim2.new(0, 30, 0, 0)
        saveBtn.BackgroundTransparency = 1
        saveBtn.Text = "SAVE CP"
        saveBtn.TextColor3 = Theme.Text
        saveBtn.Font = Enum.Font.GothamBlack
        saveBtn.TextSize = 16
        
        -- Menu button
        local menuBtn = Instance.new("TextButton", MW)
        menuBtn.Size = UDim2.new(0, 30, 1, 0)
        menuBtn.Position = UDim2.new(0, 100, 0, 0)
        menuBtn.BackgroundTransparency = 1
        menuBtn.Text = "[×]"
        menuBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        menuBtn.Font = Enum.Font.GothamBlack
        menuBtn.TextSize = 14
        
        -- Drag function
        local function Drag(frame, handle)
            handle = handle or frame
            local dragging, dragStart, startPos
            
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            
            Services.UserInputService.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                    local delta = input.Position - dragStart
                    frame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end
        
        Drag(MW, dragBtn)
        MiniWidget = MW
        
        -- Button events
        local lastSaveTime = 0
        saveBtn.MouseButton1Click:Connect(function()
            local currentTime = tick()
            local isDoubleClick = (currentTime - lastSaveTime) < 0.5
            lastSaveTime = currentTime
            
            if isDoubleClick then
                -- Double click = save as SUMMIT
                UI:Confirm("Save as SUMMIT (Finish)?", function()
                    SaveCheckpoint("SUMMIT")
                end)
            else
                -- Single click = save as next CP
                local mapID = GetMapID()
                CP_Data = LoadData()
                
                local cpCount = 0
                if CP_Data[mapID] and CP_Data[mapID].CPs then
                    cpCount = #CP_Data[mapID].CPs
                end
                
                local cpName = (cpCount == 0) and "SPAWN" or "CP" .. cpCount
                
                UI:Confirm("Save as " .. cpName .. "?", function()
                    SaveCheckpoint(cpName)
                end)
            end
        end)
        
        menuBtn.MouseButton1Click:Connect(function()
            CreateCPManager()
            CPManagerFrame.Visible = true
            RefreshCPList()
        end)
        
        return MW
    end
    
    -- Create CP Manager
    local function CreateCPManager()
        if CPManagerFrame then
            CPManagerFrame:Destroy()
        end
        
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        local CPF = Instance.new("Frame", screenGui)
        CPF.Name = "CPManager"
        CPF.Size = UDim2.new(0, 320, 0, 380)
        CPF.Position = UDim2.new(0.5, -160, 0.5, -190)
        CPF.BackgroundColor3 = Theme.Main
        CPF.Visible = false
        CPF.ZIndex = 50
        
        local CPFCorner = Instance.new("UICorner", CPF)
        CPFCorner.CornerRadius = UDim.new(0, 10)
        
        local CPFStroke = Instance.new("UIStroke", CPF)
        CPFStroke.Color = Theme.Accent
        
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
        
        -- Close button
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
            Config.AutoPlaying = false
        end)
        
        -- Main list (maps)
        local mainList = Instance.new("ScrollingFrame", CPF)
        mainList.Size = UDim2.new(1, -10, 0.75, -5)
        mainList.Position = UDim2.new(0, 5, 0.1, 0)
        mainList.BackgroundTransparency = 1
        mainList.ScrollBarThickness = 2
        mainList.ZIndex = 51
        
        local mainLayout = Instance.new("UIListLayout", mainList)
        mainLayout.Padding = UDim.new(0, 4)
        
        CPMainList = mainList
        
        -- Detail list (CPs)
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
        
        -- Buttons
        local loadLocalBtn = Instance.new("TextButton", CPF)
        loadLocalBtn.Size = UDim2.new(0.3, 0, 0, 35)
        loadLocalBtn.Position = UDim2.new(0.03, 0, 0.88, 0)
        loadLocalBtn.BackgroundColor3 = Theme.ButtonDark
        loadLocalBtn.Text = "Load Local"
        loadLocalBtn.TextColor3 = Theme.Text
        loadLocalBtn.Font = Enum.Font.Gotham
        loadLocalBtn.TextSize = 11
        loadLocalBtn.ZIndex = 52
        
        local loadLocalCorner = Instance.new("UICorner", loadLocalBtn)
        
        local playBtn = Instance.new("TextButton", CPF)
        playBtn.Size = UDim2.new(0.3, 0, 0, 35)
        playBtn.Position = UDim2.new(0.35, 0, 0.88, 0)
        playBtn.BackgroundColor3 = Theme.PlayBtn
        playBtn.Text = "PLAY"
        playBtn.TextColor3 = Theme.Text
        playBtn.Font = Enum.Font.GothamBlack
        playBtn.TextSize = 14
        playBtn.ZIndex = 52
        
        local playCorner = Instance.new("UICorner", playBtn)
        
        local loadGitBtn = Instance.new("TextButton", CPF)
        loadGitBtn.Size = UDim2.new(0.3, 0, 0, 35)
        loadGitBtn.Position = UDim2.new(0.67, 0, 0.88, 0)
        loadGitBtn.BackgroundColor3 = Theme.Button
        loadGitBtn.Text = "Load GitHub"
        loadGitBtn.TextColor3 = Theme.Text
        loadGitBtn.Font = Enum.Font.Gotham
        loadGitBtn.TextSize = 11
        loadGitBtn.ZIndex = 52
        
        local loadGitCorner = Instance.new("UICorner", loadGitBtn)
        
        -- Button events
        loadLocalBtn.MouseButton1Click:Connect(function()
            RefreshCPList()
            Services.StarterGui:SetCore("SendNotification", {
                Title = "CP Manager",
                Text = "Loaded local checkpoints",
                Duration = 2
            })
        end)
        
        playBtn.MouseButton1Click:Connect(function()
            -- Auto-play feature will be in separate autoPlay.lua
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Auto Play",
                Text = "Starting from nearest CP...",
                Duration = 2
            })
        end)
        
        loadGitBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local webData = game:HttpGet(GithubCP)
                if writefile then
                    writefile(AutoCPFile, webData)
                    task.wait(0.1)
                    RefreshCPList()
                    
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "CP Manager",
                        Text = "Loaded from GitHub",
                        Duration = 2
                    })
                end
            end)
        end)
        
        CPManagerFrame = CPF
        return CPF
    end
    
    -- UI Controls
    CPTab:Label("Quick Controls")
    
    local widgetToggle = CPTab:Toggle("Show Mini Widget", function(state)
        if state then
            if not MiniWidget then
                CreateMiniWidget()
            end
            if MiniWidget then
                MiniWidget.Visible = true
            end
        elseif MiniWidget then
            MiniWidget.Visible = false
        end
    end)
    
    CPTab:Button("Open CP Manager", Theme.ButtonDark, function()
        CreateCPManager()
        CPManagerFrame.Visible = true
        RefreshCPList()
    end)
    
    CPTab:Button("Save Current Position", Theme.Confirm, function()
        local cpName = "CP_" .. os.time()
        SaveCheckpoint(cpName)
    end)
    
    CPTab:Button("Load from GitHub", Theme.Button, function()
        pcall(function()
            local webData = game:HttpGet(GithubCP)
            if writefile then
                writefile(AutoCPFile, webData)
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Success",
                    Text = "Loaded CPs from GitHub",
                    Duration = 3
                })
                
                RefreshCPList()
            end
        end)
    end)
    
    CPTab:Button("Clear All CPs", Theme.ButtonRed, function()
        UI:Confirm("Clear ALL checkpoints?", function()
            if writefile then
                writefile(AutoCPFile, "{}")
                CP_Data = {}
                RefreshCPList()
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "CP Manager",
                    Text = "All checkpoints cleared",
                    Duration = 3
                })
            end
        end)
    end)
    
    -- Import/Export
    CPTab:Label("Import/Export")
    
    CPTab:Input("Export Code...", function(text)
        -- Placeholder for export feature
    end)
    
    CPTab:Button("Copy All CPs to Clipboard", Theme.Button, function()
        if setclipboard then
            local exportData = HttpService:JSONEncode(CP_Data)
            setclipboard(exportData)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Export",
                Text = "CP data copied to clipboard",
                Duration = 3
            })
        end
    end)
    
    -- Initialize
    spawn(function()
        task.wait(2)
        -- Create mini widget
        CreateMiniWidget()
        -- Create CP manager
        CreateCPManager()
        -- Load initial data
        CP_Data = LoadData()
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        Config.AutoPlaying = false
        
        if MiniWidget then
            MiniWidget:Destroy()
            MiniWidget = nil
        end
        
        if CPManagerFrame then
            CPManagerFrame:Destroy()
            CPManagerFrame = nil
        end
    end)
    
    print("[Vanzyxxx] Checkpoint system loaded!")
end