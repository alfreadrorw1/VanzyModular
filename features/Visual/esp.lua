return function(UI, Services, Config, Theme)
    local VisualTab = UI:Tab("Visual")
    
    --[[ 
        ESP CONFIGURATION 
        Setting internal untuk fitur ESP
    ]]
    local ESPSettings = {
        Enabled = false,
        TeamCheck = false,
        ShowBox = false,
        ShowName = false,
        ShowHealth = false,
        ShowDistance = false,
        ShowChams = false, -- Highlight character
        ShowTracers = false,
        TextSize = 12,
        MaxDistance = 2000,
        
        -- Warna Default
        EnemyColor = Color3.fromRGB(255, 50, 50),
        TeamColor = Color3.fromRGB(50, 255, 50),
        TraceColor = Color3.fromRGB(255, 255, 255)
    }

    -- Container untuk menyimpan object ESP
    local ESPHolder = Instance.new("Folder")
    ESPHolder.Name = "VanzyESP_Holder"
    ESPHolder.Parent = Services.CoreGui

    -- Cache player agar tidak lag
    local ActiveESP = {}

    --[[ 
        CORE FUNCTIONS 
    ]]

    -- Fungsi untuk mendapatkan warna berdasarkan tim
    local function GetColor(player)
        if player.Team and Services.Players.LocalPlayer.Team and player.Team == Services.Players.LocalPlayer.Team then
            return ESPSettings.TeamColor
        else
            return ESPSettings.EnemyColor
        end
    end

    -- Fungsi membersihkan ESP pada player tertentu
    local function RemoveESP(player)
        if ActiveESP[player] then
            for _, instance in pairs(ActiveESP[player]) do
                if instance then instance:Destroy() end
            end
            ActiveESP[player] = nil
        end
    end

    -- Fungsi membuat ESP baru
    local function CreateESP(player)
        if player == Services.Players.LocalPlayer then return end
        
        RemoveESP(player) -- Bersihkan sisa ESP lama jika ada
        
        local objects = {}
        
        -- 1. BOX ESP (Menggunakan BoxHandleAdornment - Sangat Ringan)
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_Box"
        box.Size = Vector3.new(4, 5, 1)
        box.Adornee = nil
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Transparency = 0.5
        box.Color3 = GetColor(player)
        box.Visible = false
        box.Parent = ESPHolder
        objects.Box = box

        -- 2. INFO GUI (Nama, HP, Jarak)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Info"
        billboard.Adornee = nil
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = ESPHolder
        
        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = ESPSettings.TextSize
        objects.NameLabel = nameLabel

        local infoLabel = Instance.new("TextLabel", billboard)
        infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
        infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = "" -- Diisi nanti (HP | Jarak)
        infoLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        infoLabel.TextStrokeTransparency = 0
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = ESPSettings.TextSize - 2
        objects.InfoLabel = infoLabel
        
        objects.Billboard = billboard

        -- 3. CHAMS (Highlight - Tembus Tembok)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Chams"
        highlight.FillColor = GetColor(player)
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
        highlight.Parent = ESPHolder
        objects.Highlight = highlight
        
        -- 4. TRACERS (Beam - Lebih ringan dari Drawing Line)
        local beamPart = Instance.new("Part")
        beamPart.Name = "BeamStart"
        beamPart.Size = Vector3.new(0.1,0.1,0.1)
        beamPart.Transparency = 1
        beamPart.CanCollide = false
        beamPart.Anchored = true
        beamPart.Parent = ESPHolder
        
        local attach1 = Instance.new("Attachment", beamPart)
        local attach2 = Instance.new("Attachment") -- Akan diparent ke HumanoidRootPart target
        
        local beam = Instance.new("Beam", beamPart)
        beam.Attachment0 = attach1
        beam.Attachment1 = attach2
        beam.Color = ColorSequence.new(GetColor(player))
        beam.FaceCamera = true
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.Enabled = false
        
        objects.BeamPart = beamPart
        objects.Beam = beam
        objects.Attach2 = attach2

        ActiveESP[player] = objects
    end

    -- Fungsi Update Loop (Dijalankan setiap frame)
    Services.RunService.RenderStepped:Connect(function()
        if not ESPSettings.Enabled then 
            -- Jika master switch mati, sembunyikan semua
            for _, objects in pairs(ActiveESP) do
                if objects.Box then objects.Box.Visible = false end
                if objects.Billboard then objects.Billboard.Enabled = false end
                if objects.Highlight then objects.Highlight.Enabled = false end
                if objects.Beam then objects.Beam.Enabled = false end
            end
            return 
        end

        local LocalChar = Services.Players.LocalPlayer.Character
        local LocalRoot = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")

        for player, objects in pairs(ActiveESP) do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if char and root and hum and hum.Health > 0 then
                local color = GetColor(player)
                local dist = LocalRoot and (LocalRoot.Position - root.Position).Magnitude or 0
                
                -- Cek Team Check
                local isTeammate = (player.Team and Services.Players.LocalPlayer.Team and player.Team == Services.Players.LocalPlayer.Team)
                local showTarget = true
                if ESPSettings.TeamCheck and isTeammate then showTarget = false end
                if dist > ESPSettings.MaxDistance then showTarget = false end

                if showTarget then
                    -- UPDATE BOX
                    if ESPSettings.ShowBox then
                        objects.Box.Adornee = root
                        objects.Box.Size = Vector3.new(4, 6, 1) -- Ukuran box disesuaikan
                        objects.Box.Color3 = color
                        objects.Box.Visible = true
                    else
                        objects.Box.Visible = false
                    end

                    -- UPDATE TEXT (Nama, HP, Jarak)
                    if ESPSettings.ShowName or ESPSettings.ShowHealth or ESPSettings.ShowDistance then
                        objects.Billboard.Adornee = char:FindFirstChild("Head")
                        objects.Billboard.Enabled = true
                        objects.NameLabel.Visible = ESPSettings.ShowName
                        objects.NameLabel.TextColor3 = color
                        
                        local infoText = ""
                        if ESPSettings.ShowHealth then
                            infoText = infoText .. "HP: " .. math.floor(hum.Health) .. " "
                        end
                        if ESPSettings.ShowDistance then
                            infoText = infoText .. "[" .. math.floor(dist) .. "m]"
                        end
                        objects.InfoLabel.Text = infoText
                    else
                        objects.Billboard.Enabled = false
                    end

                    -- UPDATE CHAMS
                    if ESPSettings.ShowChams then
                        objects.Highlight.Adornee = char
                        objects.Highlight.FillColor = color
                        objects.Highlight.Enabled = true
                    else
                        objects.Highlight.Enabled = false
                    end
                    
                    -- UPDATE TRACERS
                    if ESPSettings.ShowTracers and LocalRoot then
                        objects.BeamPart.CFrame = CFrame.new(LocalRoot.Position - Vector3.new(0, 3, 0)) -- Tracer dari kaki
                        objects.Attach2.Parent = root
                        objects.Beam.Color = ColorSequence.new(color)
                        objects.Beam.Enabled = true
                    else
                        objects.Beam.Enabled = false
                    end

                else
                    -- Sembunyikan jika team check aktif atau kejauhan
                    objects.Box.Visible = false
                    objects.Billboard.Enabled = false
                    objects.Highlight.Enabled = false
                    objects.Beam.Enabled = false
                end
            else
                -- Player mati atau karakter hilang
                objects.Box.Visible = false
                objects.Billboard.Enabled = false
                objects.Highlight.Enabled = false
                objects.Beam.Enabled = false
            end
        end
    end)

    -- Event Listener: Player Added/Removed
    Services.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(1) -- Tunggu karakter load
            CreateESP(player)
        end)
    end)

    Services.Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)

    -- Init untuk player yang sudah ada saat script dijalankan
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer then
            if player.Character then
                CreateESP(player)
            end
            player.CharacterAdded:Connect(function()
                task.wait(1)
                CreateESP(player)
            end)
        end
    end

    --[[ 
        UI MENU CONSTRUCTION 
        Membuat tombol-tombol di Tab Visual
    ]]
    
    VisualTab:Label("--- MASTER SWITCH ---")
    
    VisualTab:Toggle("Enable ESP", function(state)
        ESPSettings.Enabled = state
        -- Sinkronisasi dengan Global Config di main.lua jika perlu
        Config.ESP_Box = state 
    end)

    VisualTab:Label("--- SETTINGS ---")

    VisualTab:Toggle("Team Check (Hide Friends)", function(state)
        ESPSettings.TeamCheck = state
    end)

    VisualTab:Slider("Max Distance", 100, 5000, function(val)
        ESPSettings.MaxDistance = val
    end)

    VisualTab:Label("--- FEATURES ---")

    VisualTab:Toggle("Box 2D", function(state)
        ESPSettings.ShowBox = state
    end)

    VisualTab:Toggle("Name Tag", function(state)
        ESPSettings.ShowName = state
    end)

    VisualTab:Toggle("Health Info", function(state)
        ESPSettings.ShowHealth = state
    end)

    VisualTab:Toggle("Distance", function(state)
        ESPSettings.ShowDistance = state
    end)

    VisualTab:Toggle("Chams (Wallhack Color)", function(state)
        ESPSettings.ShowChams = state
    end)
    
    VisualTab:Toggle("Tracers (Lines)", function(state)
        ESPSettings.ShowTracers = state
    end)

    VisualTab:Label("--- COLORS ---")
    
    -- Tombol reset warna simpel
    VisualTab:Button("Switch to Red/Green Theme", Theme.Button, function()
        ESPSettings.EnemyColor = Color3.fromRGB(255, 50, 50)
        ESPSettings.TeamColor = Color3.fromRGB(50, 255, 50)
    end)
    
    VisualTab:Button("Switch to Purple/Blue Theme", Theme.Button, function()
        ESPSettings.EnemyColor = Color3.fromRGB(170, 0, 255)
        ESPSettings.TeamColor = Color3.fromRGB(0, 170, 255)
    end)
    
    -- Bersihkan ESP saat script dimatikan (Event dari main.lua)
    Config.OnReset.Event:Connect(function()
        ESPHolder:Destroy()
    end)

    return true
end
