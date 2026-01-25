-- Vanzyxxx Visual ESP System
-- Universal Version (BillboardGui) - 100% Support Mobile
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local LocalPlayer = Players.LocalPlayer

    -- Create Tab
    local VisualTab = UI:Tab("Visual")
    VisualTab:Label("ESP Visuals (Universal)")

    -- Config Injection
    Config.ESP_Enabled = false
    Config.ESP_Box = false
    Config.ESP_Name = false
    Config.ESP_Health = false
    Config.ESP_TeamCheck = false

    -- Container Folder (Untuk menyimpan GUI)
    local ESP_Folder = Instance.new("Folder")
    ESP_Folder.Name = "VanzyESP_Holder"
    ESP_Folder.Parent = Services.CoreGui

    -- Cleanup helper
    local function ClearESP(player)
        if player.Character then
            local oldEsp = player.Character:FindFirstChild("VanzyESP")
            if oldEsp then oldEsp:Destroy() end
            
            local highlight = player.Character:FindFirstChild("VanzyHighlight")
            if highlight then highlight:Destroy() end
        end
    end

    -- Create ESP Elements
    local function CreateESP(player)
        if player == LocalPlayer or not player.Character then return end
        
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        
        if not rootPart or not head then return end
        
        -- Hapus ESP lama jika ada
        ClearESP(player)

        -- 1. Main BillboardGui (Untuk Box & Name)
        local bg = Instance.new("BillboardGui")
        bg.Name = "VanzyESP"
        bg.Adornee = rootPart
        bg.Size = UDim2.new(0, 2000, 0, 2000) -- Ukuran besar untuk cover layar
        bg.StudsOffset = Vector3.new(0, 0, 0)
        bg.AlwaysOnTop = true
        bg.Parent = player.Character

        -- Container Frame (Biar posisi pas di tengah karakter)
        local container = Instance.new("Frame", bg)
        container.Size = UDim2.new(4, 0, 5.5, 0) -- Ukuran relatif Box
        container.Position = UDim2.new(0.5, 0, 0.5, 0)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.BackgroundTransparency = 1

        -- A. BOX ESP (Frame Biasa)
        local box = Instance.new("Frame", container)
        box.Name = "Box"
        box.Size = UDim2.new(1, 0, 1, 0)
        box.Position = UDim2.new(0, 0, 0, 0)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Visible = Config.ESP_Box

        -- Stroke (Garis Kotak)
        local stroke = Instance.new("UIStroke", box)
        stroke.Color = Theme.Accent
        stroke.Thickness = 1.5
        stroke.Transparency = 0

        -- B. HEALTH BAR
        local healthBg = Instance.new("Frame", container)
        healthBg.Name = "HealthBg"
        healthBg.Size = UDim2.new(0.05, 0, 1, 0)
        healthBg.Position = UDim2.new(-0.1, 0, 0, 0) -- Di sebelah kiri box
        healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        healthBg.BorderSizePixel = 0
        healthBg.Visible = Config.ESP_Health

        local healthBar = Instance.new("Frame", healthBg)
        healthBar.Name = "Bar"
        healthBar.Size = UDim2.new(1, 0, 1, 0) -- Nanti diupdate ukurannya
        healthBar.Position = UDim2.new(0, 0, 1, 0)
        healthBar.AnchorPoint = Vector2.new(0, 1) -- Tumbuh dari bawah ke atas
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0

        -- C. NAME ESP
        local nameTag = Instance.new("TextLabel", container)
        nameTag.Name = "NameTag"
        nameTag.Size = UDim2.new(1, 0, 0.2, 0)
        nameTag.Position = UDim2.new(0, 0, -0.25, 0) -- Di atas kepala
        nameTag.BackgroundTransparency = 1
        nameTag.Text = player.DisplayName
        nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameTag.TextStrokeTransparency = 0 -- Outline hitam
        nameTag.Font = Enum.Font.GothamBold
        nameTag.TextScaled = true
        nameTag.Visible = Config.ESP_Name

        -- Simpan referensi objek untuk diupdate
        return {
            GUI = bg,
            BoxStroke = stroke,
            HealthBar = healthBar,
            NameTag = nameTag,
            Player = player
        }
    end

    -- Loop Update (Untuk Update Warna, Jarak, & Darah)
    local function UpdateESP()
        if not Config.ESP_Enabled then return end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local esp = player.Character:FindFirstChild("VanzyESP")
                local hum = player.Character:FindFirstChild("Humanoid")
                local root = player.Character:FindFirstChild("HumanoidRootPart")

                -- Team Check
                if Config.ESP_TeamCheck and player.Team == LocalPlayer.Team then
                    if esp then esp.Enabled = false end
                    continue
                end

                if esp and hum and root and hum.Health > 0 then
                    esp.Enabled = true
                    
                    -- Update Komponen
                    local box = esp:FindFirstChild("Frame"):FindFirstChild("Box")
                    local nameTag = esp:FindFirstChild("Frame"):FindFirstChild("NameTag")
                    local healthBg = esp:FindFirstChild("Frame"):FindFirstChild("HealthBg")
                    
                    -- 1. Visibility Config
                    if box then box.Visible = Config.ESP_Box end
                    if nameTag then nameTag.Visible = Config.ESP_Name end
                    if healthBg then healthBg.Visible = Config.ESP_Health end
                    
                    -- 2. Update Health Bar
                    if healthBg and healthBg.Visible then
                        local percent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local bar = healthBg:FindFirstChild("Bar")
                        if bar then
                            bar.Size = UDim2.new(1, 0, percent, 0)
                            bar.BackgroundColor3 = Color3.fromHSV(percent * 0.3, 1, 1) -- Merah ke Hijau
                        end
                    end

                    -- 3. Update Name & Distance
                    if nameTag and nameTag.Visible then
                        local dist = math.floor((root.Position - Services.Workspace.CurrentCamera.CFrame.Position).Magnitude)
                        nameTag.Text = string.format("%s\n[%d m]", player.DisplayName, dist)
                        nameTag.TextColor3 = Theme.Text
                    end
                    
                    -- 4. Update Warna Box
                    if box then
                        local stroke = box:FindFirstChild("UIStroke")
                        if stroke then stroke.Color = Theme.Accent end
                    end

                elseif not esp and hum and hum.Health > 0 then
                    -- Jika ESP belum ada tapi player hidup, buat baru
                    CreateESP(player)
                elseif esp and hum and hum.Health <= 0 then
                    -- Jika mati, sembunyikan
                    esp.Enabled = false
                end
            end
        end
    end

    -- UI Controls
    VisualTab:Toggle("Enable ESP (Master)", function(state)
        Config.ESP_Enabled = state
        -- Force update visibility saat toggle dimatikan
        if not state then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then
                    local esp = p.Character:FindFirstChild("VanzyESP")
                    if esp then esp.Enabled = false end
                end
            end
        end
    end)

    VisualTab:Toggle("Show Box", function(state)
        Config.ESP_Box = state
    end)

    VisualTab:Toggle("Show Name", function(state)
        Config.ESP_Name = state
    end)

    VisualTab:Toggle("Show Health", function(state)
        Config.ESP_Health = state
    end)
    
    VisualTab:Toggle("Team Check", function(state)
        Config.ESP_TeamCheck = state
    end)

    -- Events
    local render = RunService.RenderStepped:Connect(UpdateESP)
    
    local added = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(1)
            CreateESP(p)
        end)
    end)

    for _, p in pairs(Players:GetPlayers()) do
        p.CharacterAdded:Connect(function()
            task.wait(1)
            CreateESP(p)
        end)
        if p.Character then CreateESP(p) end
    end

    -- Cleanup
    Config.OnReset:Connect(function()
        if render then render:Disconnect() end
        if added then added:Disconnect() end
        
        -- Hapus semua ESP
        for _, p in pairs(Players:GetPlayers()) do
            ClearESP(p)
        end
        ESP_Folder:Destroy()
        print("[Vanzyxxx] Universal ESP Unloaded")
    end)

    print("[Vanzyxxx] Universal ESP Loaded!")
end