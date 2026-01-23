-- Vanzyxxx Checkpoint System (FIXED VISUALS + AUTO PLAY)
-- Fix: ZIndex Layering, Text Visibility, AutoPlay Logic

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
    -- URL Updated sesuai request
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

    -- [NEW] AUTO PLAY FUNCTION
    local function StartAutoPlay(mapInfo)
        if not mapInfo or not mapInfo.CPs or #mapInfo.CPs == 0 then
            Services.StarterGui:SetCore("SendNotification", {Title="Error", Text="No CPs to play!"})
            return
        end

        Config.AutoPlaying = true
        Services.StarterGui:SetCore("SendNotification", {Title="Auto Play", Text="Starting in 1s...", Duration=1})
        task.wait(1)

        for i, cp in ipairs(mapInfo.CPs) do
            if not Config.AutoPlaying then break end -- Stop button logic
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z)
                
                -- Notifikasi kecil di layar (optional)
                local hint = Instance.new("Hint", Services.Workspace)
                hint.Text = "AutoPlay: " .. cp.Name .. " ("..i.."/"..#mapInfo.CPs..")"
                game.Debris:AddItem(hint, 1)
            end
            
            -- DELAY 1.5 DETIK SESUAI REQUEST
            task.wait(1.5)
        end

        Config.AutoPlaying = false
        Services.StarterGui:SetCore("SendNotification", {Title="Auto Play", Text="Finished!", Duration=3})
    end
    
    -- Core Functions: Refresh List (FIXED VISUALS)
    local function RefreshCPList()
        if not CPMainList then return end
        
        -- Reset Tampilan
        CPMainList.Visible = true
        if CPDetailList then CPDetailList.Visible = false end
        
        -- Bersihkan List Lama
        for _, child in ipairs(CPMainList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        CP_Data = LoadData()
        
        -- Cek Data Kosong
        local count = 0
        for _ in pairs(CP_Data) do count = count + 1 end
        
        if count == 0 then
            local emptyLbl = Instance.new("TextLabel", CPMainList)
            emptyLbl.Size = UDim2.new(1, 0, 0, 30)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "No Data Found. Load GitHub or Save CP."
            emptyLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.TextSize = 12
            emptyLbl.ZIndex = 55
            return
        end
        
        -- Loop Map Folder
        for mapId, mapInfo in pairs(CP_Data) do
            local mapFrame = Instance.new("Frame", CPMainList)
            mapFrame.Size = UDim2.new(1, 0, 0, 35)
            mapFrame.BackgroundColor3 = Theme.Sidebar
            mapFrame.ZIndex = 55 -- ZIndex Tinggi agar tidak tertutup
            
            local mapCorner = Instance.new("UICorner", mapFrame)
            mapCorner.CornerRadius = UDim.new(0, 6)
            
            -- Nama Map Button
            local mapBtn = Instance.new("TextButton", mapFrame)
            mapBtn.Size = UDim2.new(0.75, 0, 1, 0)
            mapBtn.BackgroundTransparency = 1
            mapBtn.Text = "📂 " .. (mapInfo.MapName or "Unknown")
            mapBtn.TextColor3 = Theme.Accent
            mapBtn.TextXAlignment = Enum.TextXAlignment.Left
            mapBtn.Font = Enum.Font.GothamBold
            mapBtn.TextSize = 12
            mapBtn.ZIndex = 56
            
            local mapPadding = Instance.new("UIPadding", mapBtn)
            mapPadding.PaddingLeft = UDim.new(0, 10)
            
            -- Jumlah CP Text
            local cpCount = Instance.new("TextLabel", mapFrame)
            cpCount.Size = UDim2.new(0.15, 0, 1, 0)
            cpCount.Position = UDim2.new(0.75, 0, 0, 0)
            cpCount.BackgroundTransparency = 1
            cpCount.Text = "(" .. (#mapInfo.CPs or 0) .. ")"
            cpCount.TextColor3 = Color3.fromRGB(200, 200, 200)
            cpCount.TextSize = 11
            cpCount.Font = Enum.Font.Gotham
            cpCount.ZIndex = 56
            
            -- Delete Button
            local delMapBtn = Instance.new("TextButton", mapFrame)
            delMapBtn.Size = UDim2.new(0.1, 0, 1, 0)
            delMapBtn.Position = UDim2.new(0.9, 0, 0, 0)
            delMapBtn.BackgroundColor3 = Theme.ButtonRed
            delMapBtn.Text = "X"
            delMapBtn.TextColor3 = Theme.Text
            delMapBtn.Font = Enum.Font.GothamBold
            delMapBtn.TextSize = 12
            delMapBtn.ZIndex = 56
            
            local delCorner = Instance.new("UICorner", delMapBtn)
            delCorner.CornerRadius = UDim.new(0, 6) -- Rounded kanan
            
            -- Events
            mapBtn.MouseButton1Click:Connect(function()
                ShowMapCPs(mapId, mapInfo) -- Buka detail folder
            end)
            
            delMapBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete Map: " .. mapInfo.MapName .. "?", function()
                    CP_Data[mapId] = nil
                    SaveData(CP_Data)
                    RefreshCPList()
                end)
            end)
        end
        
        CPMainList.CanvasSize = UDim2.new(0, 0, 0, CPMainList.UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Show Details (Isi Checkpoints + Play Feature)
    function ShowMapCPs(mapId, mapInfo)
        if not CPDetailList then return end
        
        CPMainList.Visible = false
        CPDetailList.Visible = true
        
        -- Bersihkan List
        for _, child in ipairs(CPDetailList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        -- [HEADER CONTROLS]
        local HeaderFrame = Instance.new("Frame", CPDetailList)
        HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
        HeaderFrame.BackgroundTransparency = 1
        HeaderFrame.ZIndex = 56
        
        -- Back Button
        local backBtn = Instance.new("TextButton", HeaderFrame)
        backBtn.Size = UDim2.new(0.2, 0, 1, 0)
        backBtn.BackgroundColor3 = Theme.ButtonRed
        backBtn.Text = "<"
        backBtn.TextColor3 = Theme.Text
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 14
        backBtn.ZIndex = 57
        Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)
        
        -- Play Button (NEW)
        local playAllBtn = Instance.new("TextButton", HeaderFrame)
        playAllBtn.Size = UDim2.new(0.75, 0, 1, 0)
        playAllBtn.Position = UDim2.new(0.25, 0, 0, 0)
        playAllBtn.BackgroundColor3 = Theme.PlayBtn or Color3.fromRGB(0, 170, 255)
        playAllBtn.Text = "▶ PLAY (1.5s Delay)"
        playAllBtn.TextColor3 = Theme.Text
        playAllBtn.Font = Enum.Font.GothamBlack
        playAllBtn.TextSize = 12
        playAllBtn.ZIndex = 57
        Instance.new("UICorner", playAllBtn).CornerRadius = UDim.new(0, 6)
        
        -- Header Events
        backBtn.MouseButton1Click:Connect(function()
            Config.AutoPlaying = false -- Stop auto play if back
            CPDetailList.Visible = false
            CPMainList.Visible = true
            RefreshCPList()
        end)
        
        playAllBtn.MouseButton1Click:Connect(function()
            if Config.AutoPlaying then
                Config.AutoPlaying = false
                playAllBtn.Text = "▶ PLAY (1.5s Delay)"
                playAllBtn.BackgroundColor3 = Theme.PlayBtn
            else
                playAllBtn.Text = "⏹ STOP"
                playAllBtn.BackgroundColor3 = Theme.ButtonRed
                StartAutoPlay(mapInfo)
                -- Reset button when done
                if playAllBtn and playAllBtn.Parent then
                    playAllBtn.Text = "▶ PLAY (1.5s Delay)"
                    playAllBtn.BackgroundColor3 = Theme.PlayBtn
                end
            end
        end)
        
        -- Spacer agar list CP tidak ketutup header
        local spacer = Instance.new("Frame", CPDetailList)
        spacer.Size = UDim2.new(1, 0, 0, 5)
        spacer.BackgroundTransparency = 1
        
        -- List CP Items
        for i, cp in ipairs(mapInfo.CPs) do
            local cpFrame = Instance.new("Frame", CPDetailList)
            cpFrame.Size = UDim2.new(1, 0, 0, 35)
            cpFrame.BackgroundColor3 = Theme.Button
            cpFrame.ZIndex = 55
            
            local cpCorner = Instance.new("UICorner", cpFrame)
            cpCorner.CornerRadius = UDim.new(0, 6)
            
            -- Nama CP
            local cpInfo = Instance.new("TextLabel", cpFrame)
            cpInfo.Size = UDim2.new(0.6, 0, 1, 0)
            cpInfo.BackgroundTransparency = 1
            cpInfo.Text = "📍 " .. cp.Name
            cpInfo.TextColor3 = Theme.Text
            cpInfo.TextSize = 11
            cpInfo.TextXAlignment = Enum.TextXAlignment.Left
            cpInfo.Font = Enum.Font.Gotham
            cpInfo.ZIndex = 56
            
            Instance.new("UIPadding", cpInfo).PaddingLeft = UDim.new(0, 10)
            
            -- TP Button
            local tpBtn = Instance.new("TextButton", cpFrame)
            tpBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
            tpBtn.Position = UDim2.new(0.6, 0, 0.1, 0)
            tpBtn.BackgroundColor3 = Theme.Confirm
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Theme.Text
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 10
            tpBtn.ZIndex = 56
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
            
            -- Del Button
            local delBtn = Instance.new("TextButton", cpFrame)
            delBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
            delBtn.Position = UDim2.new(0.82, 0, 0.1, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed
            delBtn.Text = "X"
            delBtn.TextColor3 = Theme.Text
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.ZIndex = 56
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            
            -- Logic
            tpBtn.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cp.X, cp.Y + 3, cp.Z)
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
        
        CPDetailList.CanvasSize = UDim2.new(0, 0, 0, CPDetailList.UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
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
        RefreshCPList()
    end
    
    -- Create Main UI Frame
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
        CPF.ZIndex = 50
        
        Instance.new("UICorner", CPF).CornerRadius = UDim.new(0, 10)
        local str = Instance.new("UIStroke", CPF); str.Color = Theme.Accent; str.Thickness = 2
        
        -- Title
        local header = Instance.new("TextLabel", CPF)
        header.Size = UDim2.new(1, -30, 0, 30)
        header.Position = UDim2.new(0, 10, 0, 0)
        header.BackgroundTransparency = 1
        header.Text = "CHECKPOINT MANAGER"
        header.TextColor3 = Theme.Accent
        header.Font = Enum.Font.GothamBlack
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 51
        Instance.new("UIPadding", header).PaddingLeft = UDim.new(0, 10)
        
        -- Close
        local closeBtn = Instance.new("TextButton", CPF)
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -30, 0, 0)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 18
        closeBtn.ZIndex = 51
        closeBtn.MouseButton1Click:Connect(function() CPF.Visible = false; Config.AutoPlaying = false end)
        
        -- Lists
        local mainList = Instance.new("ScrollingFrame", CPF)
        mainList.Size = UDim2.new(1, -20, 0.75, -5)
        mainList.Position = UDim2.new(0, 10, 0.1, 0)
        mainList.BackgroundTransparency = 1
        mainList.ScrollBarThickness = 2
        mainList.ZIndex = 51
        Instance.new("UIListLayout", mainList).Padding = UDim.new(0, 4)
        CPMainList = mainList
        
        local detailList = Instance.new("ScrollingFrame", CPF)
        detailList.Size = UDim2.new(1, -20, 0.75, -5)
        detailList.Position = UDim2.new(0, 10, 0.1, 0)
        detailList.BackgroundTransparency = 1
        detailList.ScrollBarThickness = 2
        detailList.Visible = false
        detailList.ZIndex = 51
        Instance.new("UIListLayout", detailList).Padding = UDim.new(0, 4)
        CPDetailList = detailList
        
        -- Bottom Buttons
        local loadLocalBtn = Instance.new("TextButton", CPF)
        loadLocalBtn.Size = UDim2.new(0.45, 0, 0, 35)
        loadLocalBtn.Position = UDim2.new(0.03, 0, 0.88, 0)
        loadLocalBtn.BackgroundColor3 = Theme.ButtonDark
        loadLocalBtn.Text = "Load Local"
        loadLocalBtn.TextColor3 = Theme.Text
        loadLocalBtn.ZIndex = 52
        Instance.new("UICorner", loadLocalBtn)
        
        local loadGitBtn = Instance.new("TextButton", CPF)
        loadGitBtn.Size = UDim2.new(0.45, 0, 0, 35)
        loadGitBtn.Position = UDim2.new(0.52, 0, 0.88, 0)
        loadGitBtn.BackgroundColor3 = Theme.Button
        loadGitBtn.Text = "Load GitHub"
        loadGitBtn.TextColor3 = Theme.Text
        loadGitBtn.ZIndex = 52
        Instance.new("UICorner", loadGitBtn)
        
        loadLocalBtn.MouseButton1Click:Connect(function() RefreshCPList(); Services.StarterGui:SetCore("SendNotification", {Title="Local", Text="Refreshed"}) end)
        loadGitBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local webData = game:HttpGet(GithubCP)
                writefile(AutoCPFile, webData)
                task.wait(0.2)
                RefreshCPList()
                Services.StarterGui:SetCore("SendNotification", {Title="GitHub", Text="Loaded!"})
            end)
        end)
        
        CPManagerFrame = CPF
        return CPF
    end
    
    -- Mini Widget
    local function CreateMiniWidget()
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        local MW = Instance.new("Frame", screenGui); MW.Name="MiniWidget"; MW.Size=UDim2.new(0,140,0,45); MW.Position=UDim2.new(0.8,-70,0.4,0); MW.BackgroundColor3=Theme.Main; MW.Visible=false; MW.ZIndex=40; Instance.new("UICorner",MW).CornerRadius=UDim.new(0,8); local str=Instance.new("UIStroke",MW); str.Color=Theme.Accent; str.Thickness=2
        
        local dragBtn=Instance.new("TextButton",MW); dragBtn.Size=UDim2.new(0,30,1,0); dragBtn.BackgroundTransparency=1; dragBtn.Text="[+]"; dragBtn.TextColor3=Theme.Accent; dragBtn.ZIndex=41
        local saveBtn=Instance.new("TextButton",MW); saveBtn.Size=UDim2.new(0,70,1,0); saveBtn.Position=UDim2.new(0,30,0,0); saveBtn.BackgroundTransparency=1; saveBtn.Text="SAVE CP"; saveBtn.TextColor3=Theme.Text; saveBtn.Font=Enum.Font.GothamBlack; saveBtn.ZIndex=41
        local menuBtn=Instance.new("TextButton",MW); menuBtn.Size=UDim2.new(0,30,1,0); menuBtn.Position=UDim2.new(0,100,0,0); menuBtn.BackgroundTransparency=1; menuBtn.Text="[×]"; menuBtn.TextColor3=Color3.fromRGB(255,200,50); menuBtn.ZIndex=41
        
        -- Drag Logic
        local dragging, dragStart, startPos
        dragBtn.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; startPos=MW.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
        Services.UserInputService.InputChanged:Connect(function(input) if (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) and dragging then local delta=input.Position-dragStart; MW.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y) end end)
        
        saveBtn.MouseButton1Click:Connect(function()
            local id = GetMapID(); CP_Data = LoadData()
            local count = (CP_Data[id] and CP_Data[id].CPs) and #CP_Data[id].CPs or 0
            local name = (count == 0) and "SPAWN" or "CP"..(count+1)
            UI:Confirm("Save as "..name.."?", function() SaveCheckpoint(name) end)
        end)
        
        menuBtn.MouseButton1Click:Connect(function() CreateCPManager(); CPManagerFrame.Visible=true; RefreshCPList() end)
        MiniWidget = MW
    end
    
    -- Init Controls
    CPTab:Toggle("Show Mini Widget", function(s) if s then if not MiniWidget then CreateMiniWidget() end; MiniWidget.Visible=true else if MiniWidget then MiniWidget.Visible=false end end end)
    CPTab:Button("Open CP Manager", Theme.ButtonDark, function() CreateCPManager(); CPManagerFrame.Visible=true; RefreshCPList() end)
    
    spawn(function() task.wait(1); CreateMiniWidget(); CreateCPManager(); CP_Data=LoadData() end)
    Config.OnReset:Connect(function() if MiniWidget then MiniWidget:Destroy() end; if CPManagerFrame then CPManagerFrame:Destroy() end end)
    print("[Vanzyxxx] Checkpoint System Fixed Loaded")
end