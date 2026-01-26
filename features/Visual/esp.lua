-- Vanzyxxx ESP Universal V3 (Auto-Fix & Respawn Logic)
-- Fix: ESP Hilang saat musuh respawn & Kompatibel semua Executor
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local CoreGui = Services.CoreGui
    local LocalPlayer = Players.LocalPlayer

    -- 1. Tab & Config Setup
    local VisualTab = UI:Tab("Visual")
    VisualTab:Label("ESP V3 (Auto-Fix Version)")

    Config.ESP_Enabled = false
    Config.ESP_Box = false
    Config.ESP_Name = false
    Config.ESP_Health = false
    Config.ESP_TeamCheck = false

    -- 2. Container (Tempat nyimpen UI biar aman)
    local HolderName = "VanzyESP_Holder_V3"
    local ESP_Folder = nil

    -- Fungsi untuk mencari atau membuat folder aman di CoreGui
    local function GetHolder()
        if ESP_Folder then return ESP_Folder end
        
        -- Coba cari folder lama dan hapus
        local old = CoreGui:FindFirstChild(HolderName)
        if old then old:Destroy() end

        -- Buat baru
        local f = Instance.new("Folder")
        f.Name = HolderName
        
        -- Proteksi GUI (Coba gethui dulu, kalau gak ada ya CoreGui)
        if gethui then
            f.Parent = gethui()
        elseif syn and syn.protect_gui then 
            f.Parent = CoreGui
            syn.protect_gui(f)
        else
            f.Parent = CoreGui
        end
        
        ESP_Folder = f
        return f
    end

    -- 3. Fungsi Membuat ESP Unit
    local function CreateESP(player)
        -- Jangan pasang di diri sendiri
        if player == LocalPlayer then return end

        local holder = GetHolder()
        
        -- Hapus ESP lama player ini jika ada (Reset)
        local old = holder:FindFirstChild(player.Name)
        if old then old:Destroy() end

        -- 1. Main Billboard (Kotak Utama)
        local bg = Instance.new("BillboardGui")
        bg.Name = player.Name
        bg.Adornee = nil -- Nanti di-set di loop
        bg.Size = UDim2.new(0, 4, 0, 5) -- Ukuran relatif (Scale)
        bg.StudsOffset = Vector3.new(0, 0, 0)
        bg.AlwaysOnTop = true
        bg.Enabled = false
        bg.Parent = holder

        -- 2. Box Frame
        local box = Instance.new("Frame", bg)
        box.Name = "Box"
        box.Size = UDim2.new(4, 0, 5, 0) -- Proporsional badan
        box.Position = UDim2.new(0.5, 0, 0.5, 0)
        box.AnchorPoint = Vector2.new(0.5, 0.5)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Visible = false

        -- Stroke (Garis Kotak)
        local stroke = Instance.new("UIStroke", box)
        stroke.Thickness = 1.5
        stroke.Color = Theme.Accent
        stroke.Transparency = 0

        -- 3. Name Tag
        local nameTag = Instance.new("TextLabel", bg)
        nameTag.Name = "Name"
        nameTag.Size = UDim2.new(10, 0, 1, 0)
        nameTag.Position = UDim2.new(0.5, 0, -3, 0) -- Di atas kepala
        nameTag.AnchorPoint = Vector2.new(0.5, 0)
        nameTag.BackgroundTransparency = 1
        nameTag.Text = player.DisplayName
        nameTag.TextColor3 = Color3.new(1, 1, 1)
        nameTag.TextStrokeTransparency = 0
        nameTag.Font = Enum.Font.GothamBold
        nameTag.TextSize = 12
        nameTag.Visible = false

        -- 4. Health Bar (Samping Kiri)
        local hpBg = Instance.new("Frame", box)
        hpBg.Name = "HP_BG"
        hpBg.Size = UDim2.new(0.05, 0, 1, 0)
        hpBg.Position = UDim2.new(-0.1, 0, 0, 0)
        hpBg.BackgroundColor3 = Color3.new(0,0,0)
        hpBg.BorderSizePixel = 0
        hpBg.Visible = false

        local hpBar = Instance.new("Frame", hpBg)
        hpBar.Name = "HP_Bar"
        hpBar.Size = UDim2.new(1, 0, 1, 0)
        hpBar.Position = UDim2.new(0, 0, 1, 0)
        hpBar.AnchorPoint = Vector2.new(0, 1) -- Tumbuh ke atas
        hpBar.BackgroundColor3 = Color3.new(0, 1, 0)
        hpBar.BorderSizePixel = 0
    end

    -- 4. Loop Utama (Jantung Script)
    -- Kita update setiap frame agar responsif dan mendeteksi respawn
    local function UpdateESP()
        local holder = GetHolder()
        
        -- Kalau fitur mati, sembunyikan semua
        if not Config.ESP_Enabled then
            for _, gui in pairs(holder:GetChildren()) do
                if gui:IsA("BillboardGui") then gui.Enabled = false end
            end
            return
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local gui = holder:FindFirstChild(player.Name)

                -- Jika GUI belum ada, buat baru
                if not gui then
                    CreateESP(player)
                    gui = holder:FindFirstChild(player.Name)
                end

                if gui then
                    local char = player.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")

                    -- Cek Validitas: Karakter ada & Hidup
                    if char and hum and root and hum.Health > 0 then
                        
                        -- TEAM CHECK
                        local isTeammate = (player.Team ~= nil and player.Team == LocalPlayer.Team)
                        if Config.ESP_TeamCheck and isTeammate then
                            gui.Enabled = false
                            continue -- Skip ke player berikutnya
                        end

                        -- AKTIFKAN ESP
                        gui.Adornee = root -- Tempelkan ke root part terbaru
                        gui.Enabled = true

                        -- Ambil komponen
                        local box = gui:FindFirstChild("Box")
                        local nameTag = gui:FindFirstChild("Name")
                        local hpBg = box and box:FindFirstChild("HP_BG")
                        local stroke = box and box:FindFirstChild("UIStroke")

                        -- UPDATE WARNA (Musuh vs Teman)
                        local color = isTeammate and Color3.fromRGB(0, 255, 0) or Theme.Accent
                        if stroke then stroke.Color = color end
                        if nameTag then nameTag.TextColor3 = color end

                        -- 1. BOX
                        if box then box.Visible = Config.ESP_Box end

                        -- 2. NAME & DISTANCE
                        if nameTag then 
                            nameTag.Visible = Config.ESP_Name 
                            if Config.ESP_Name then
                                local dist = math.floor((root.Position - Services.Workspace.CurrentCamera.CFrame.Position).Magnitude)
                                nameTag.Text = string.format("%s\n[%d m]", player.DisplayName, dist)
                            end
                        end

                        -- 3. HEALTH BAR
                        if hpBg then 
                            hpBg.Visible = Config.ESP_Health
                            local hpBar = hpBg:FindFirstChild("HP_Bar")
                            if hpBar then
                                local percent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                hpBar.Size = UDim2.new(1, 0, percent, 0)
                                hpBar.BackgroundColor3 = Color3.fromHSV(percent * 0.3, 1, 1) -- Merah ke Hijau
                            end
                        end

                    else
                        -- Kalau mati/tidak ada karakter, sembunyikan
                        gui.Enabled = false
                        gui.Adornee = nil
                    end
                end
            end
        end
    end

    -- 5. UI Controls
    VisualTab:Toggle("Enable ESP (Master)", function(state)
        Config.ESP_Enabled = state
        if not state then
            -- Force hide saat dimatikan
            local holder = GetHolder()
            for _, gui in pairs(holder:GetChildren()) do gui.Enabled = false end
        end
    end)

    VisualTab:Toggle("Show Box", function(state) Config.ESP_Box = state end)
    VisualTab:Toggle("Show Name", function(state) Config.ESP_Name = state end)
    VisualTab:Toggle("Show Health", function(state) Config.ESP_Health = state end)
    VisualTab:Toggle("Team Check", function(state) Config.ESP_TeamCheck = state end)

    -- 6. Event Connections
    local RenderConn = RunService.RenderStepped:Connect(UpdateESP)
    
    -- Auto-Refresh saat player baru masuk
    local AddConn = Players.PlayerAdded:Connect(function(p)
        task.wait(1)
        CreateESP(p)
    end)
    
    -- Bersihkan saat player keluar
    local RemConn = Players.PlayerRemoving:Connect(function(p)
        local holder = GetHolder()
        local gui = holder:FindFirstChild(p.Name)
        if gui then gui:Destroy() end
    end)

    -- Cleanup saat script reset (Tombol X)
    Config.OnReset:Connect(function()
        if RenderConn then RenderConn:Disconnect() end
        if AddConn then AddConn:Disconnect() end
        if RemConn then RemConn:Disconnect() end
        if ESP_Folder then ESP_Folder:Destroy() end


