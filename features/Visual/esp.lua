-- Vanzyxxx Visual ESP System
-- Method: Highlight (Chams) & BillboardGui (CoreGui Parenting)
-- Status: FIXED & TESTED

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local CoreGui = Services.CoreGui
    local LocalPlayer = Players.LocalPlayer

    -- 1. Setup UI Tab
    local VisualTab = UI:Tab("Visual")
    VisualTab:Label("ESP (Highlight Method)")

    -- 2. Config Defaults
    Config.ESP_Enabled = false
    Config.ESP_Chams = false -- Ganti Box jadi Chams (Highlight)
    Config.ESP_Name = false
    Config.ESP_TeamCheck = false

    -- 3. Container (PENTING: Folder di CoreGui, bukan di Character)
    local ESP_Holder = Instance.new("Folder")
    ESP_Holder.Name = "VanzyESP_Holder"
    
    -- Coba masukkan ke CoreGui (lebih aman dari reset), fallback ke PlayerGui
    local protectedGui
    if gethui then
        protectedGui = gethui()
    elseif syn and syn.protect_gui then 
        protectedGui = Services.CoreGui 
        syn.protect_gui(ESP_Holder)
    else
        protectedGui = Services.CoreGui
    end
    ESP_Holder.Parent = protectedGui

    -- 4. Cleanup Function
    local function RemoveESP(player)
        local item = ESP_Holder:FindFirstChild(player.Name)
        if item then item:Destroy() end
    end

    -- 5. Create ESP Function
    local function CreateESP(player)
        if player == LocalPlayer then return end
        
        -- Hapus yang lama dulu biar gak duplikat
        RemoveESP(player)

        -- Buat Folder per Player
        local pFolder = Instance.new("Folder")
        pFolder.Name = player.Name
        pFolder.Parent = ESP_Holder

        -- A. HIGHLIGHT (Chams/Glow)
        -- Ini membuat karakter bersinar, jauh lebih ringan dari Box
        local highlight = Instance.new("Highlight")
        highlight.Name = "Chams"
        highlight.FillColor = Theme.Accent
        highlight.OutlineColor = Color3.new(0,0,0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Tembus tembok
        highlight.Enabled = false -- Nanti diaktifkan di loop
        highlight.Parent = pFolder

        -- B. NAME TAG (BillboardGui)
        local bg = Instance.new("BillboardGui")
        bg.Name = "NameTag"
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3.5, 0) -- Di atas kepala
        bg.AlwaysOnTop = true
        bg.Enabled = false
        bg.Parent = pFolder

        local nameLabel = Instance.new("TextLabel", bg)
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0 -- Outline hitam teks
    end

    -- 6. Main Update Loop (Jantung script)
    -- Kita update setiap frame agar responsif
    local function UpdateESP()
        -- Jika Master Switch mati, matikan semua visual dan return
        if not Config.ESP_Enabled then 
            for _, folder in pairs(ESP_Holder:GetChildren()) do
                if folder:FindFirstChild("Chams") then folder.Chams.Enabled = false end
                if folder:FindFirstChild("NameTag") then folder.NameTag.Enabled = false end
            end
            return 
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local folder = ESP_Holder:FindFirstChild(player.Name)
                
                -- Jika folder belum ada tapi player ada, buatkan
                if not folder then
                    CreateESP(player)
                    folder = ESP_Holder:FindFirstChild(player.Name)
                end

                if folder then
                    local char = player.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")

                    -- Cek Validitas Karakter
                    if char and hum and root and hum.Health > 0 then
                        
                        -- TEAM CHECK
                        local isTeam = (player.Team == LocalPlayer.Team)
                        if Config.ESP_TeamCheck and isTeam then
                            -- Sembunyikan teman satu tim
                            if folder:FindFirstChild("Chams") then folder.Chams.Enabled = false end
                            if folder:FindFirstChild("NameTag") then folder.NameTag.Enabled = false end
                            continue -- Lanjut ke player berikutnya
                        end

                        -- UPDATE CHAMS (Highlight)
                        local chams = folder:FindFirstChild("Chams")
                        if chams then
                            chams.Adornee = char -- TEMPELKAN KE KARAKTER
                            chams.FillColor = isTeam and Color3.fromRGB(0, 255, 0) or Theme.Accent
                            chams.Enabled = Config.ESP_Chams
                        end

                        -- UPDATE NAME TAG
                        local tag = folder:FindFirstChild("NameTag")
                        if tag then
                            tag.Adornee = root -- TEMPELKAN KE KEPALA/ROOT
                            
                            -- Hitung Jarak
                            local dist = math.floor((Services.Workspace.CurrentCamera.CFrame.Position - root.Position).Magnitude)
                            local textLabel = tag:FindFirstChild("TextLabel")
                            if textLabel then
                                textLabel.Text = string.format("%s\n[%d m]", player.DisplayName, dist)
                                textLabel.TextColor3 = isTeam and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
                            end
                            
                            tag.Enabled = Config.ESP_Name
                        end

                    else
                        -- Jika karakter mati/hilang, sembunyikan visual
                        if folder:FindFirstChild("Chams") then folder.Chams.Adornee = nil folder.Chams.Enabled = false end
                        if folder:FindFirstChild("NameTag") then folder.NameTag.Adornee = nil folder.NameTag.Enabled = false end
                    end
                end
            end
        end
    end

    -- 7. UI Controls
    VisualTab:Toggle("Enable ESP (Master)", function(state)
        Config.ESP_Enabled = state
        if not state then
            -- Force clean visual saat dimatikan
            for _, folder in pairs(ESP_Holder:GetChildren()) do
                if folder:FindFirstChild("Chams") then folder.Chams.Enabled = false end
                if folder:FindFirstChild("NameTag") then folder.NameTag.Enabled = false end
            end
        end
    end)

    VisualTab:Toggle("Chams (Highlight)", function(state)
        Config.ESP_Chams = state
    end)

    VisualTab:Toggle("Name & Distance", function(state)
        Config.ESP_Name = state
    end)
    
    VisualTab:Toggle("Team Check", function(state)
        Config.ESP_TeamCheck = state
    end)

    -- 8. Connections
    -- Update setiap frame render
    local renderConn = RunService.RenderStepped:Connect(UpdateESP)
    
    -- Handle player yang baru masuk
    local addedConn = Players.PlayerAdded:Connect(function(p)
        CreateESP(p)
    end)
    
    -- Handle player keluar
    local removingConn = Players.PlayerRemoving:Connect(function(p)
        RemoveESP(p)
    end)

    -- Inisialisasi awal
    for _, p in pairs(Players:GetPlayers()) do
        CreateESP(p)
    end

    -- 9. Cleanup saat script reset (Tombol X)
    Config.OnReset:Connect(function()
        if renderConn then renderConn:Disconnect() end
        if addedConn then addedConn:Disconnect() end
        if removingConn then removingConn:Disconnect() end
        ESP_Holder:Destroy()
        print("[Vanzyxxx] ESP Cleaned Up")
    end)

    print("[Vanzyxxx] Highlight ESP Loaded!")
end
