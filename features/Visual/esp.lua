-- features/Visual/esp.lua
return function(UI, Services, Config, Theme)
    -- Ambil Tab "Visual" yang sudah dibuat di main.lua
    local VisualTab = UI:Tab("Visual")
    
    -- Variables
    local Players = Services.Players
    local LocalPlayer = Players.LocalPlayer
    local RunService = Services.RunService
    local CoreGui = Services.CoreGui
    
    -- Container untuk menyimpan GUI ESP agar tidak terhapus saat reset
    local ESPHolder = Instance.new("Folder")
    ESPHolder.Name = "VanzyESP_Holder"
    -- Cek jika executor support protect_gui, jika tidak taruh di CoreGui biasa
    if syn and syn.protect_gui then 
        syn.protect_gui(ESPHolder)
        ESPHolder.Parent = CoreGui
    elseif gethui then
        ESPHolder.Parent = gethui()
    else
        ESPHolder.Parent = CoreGui
    end

    -- Fungsi untuk membersihkan ESP yang invalid (pemain keluar/mati)
    local function ClearESP(character)
        if not character then return end
        local espBox = character:FindFirstChild("VanzyHighlight")
        local espTag = character:FindFirstChild("VanzyTag")
        
        if espBox then espBox:Destroy() end
        if espTag then espTag:Destroy() end
    end

    -- Fungsi Utama Pembuatan ESP
    local function AddESP(player)
        if player == LocalPlayer then return end -- Jangan kasih ESP ke diri sendiri

        local function CharacterSetup(character)
            -- Tunggu sampai character load sepenuhnya
            task.wait(0.1)
            
            -- 1. Setup ESP Box (Menggunakan Highlight agar tembus tembok & ringan)
            if not character:FindFirstChild("VanzyHighlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "VanzyHighlight"
                highlight.Adornee = character
                highlight.FillTransparency = 1 -- Transparan tengahnya (jadi cuma outline)
                highlight.OutlineTransparency = 0 -- Garis terlihat jelas
                highlight.OutlineColor = Config.CustomColor
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Selalu terlihat menembus tembok
                highlight.Enabled = Config.ESP_Box
                highlight.Parent = character
            end

            -- 2. Setup ESP Name & Health (Menggunakan BillboardGui)
            if not character:FindFirstChild("VanzyTag") then
                local head = character:WaitForChild("Head", 5)
                if not head then return end

                local bb = Instance.new("BillboardGui")
                bb.Name = "VanzyTag"
                bb.Adornee = head
                bb.Size = UDim2.new(0, 100, 0, 50)
                bb.StudsOffset = Vector3.new(0, 2, 0) -- Di atas kepala
                bb.AlwaysOnTop = true
                bb.Enabled = (Config.ESP_Name or Config.ESP_Health)
                bb.Parent = character

                -- Label Nama
                local nameLabel = Instance.new("TextLabel", bb)
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.Position = UDim2.new(0, 0, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.DisplayName
                nameLabel.TextColor3 = Color3.new(1, 1, 1)
                nameLabel.TextStrokeTransparency = 0 -- Outline hitam teks
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 12
                nameLabel.Visible = Config.ESP_Name

                -- Label Darah
                local healthLabel = Instance.new("TextLabel", bb)
                healthLabel.Name = "HealthLabel"
                healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
                healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
                healthLabel.BackgroundTransparency = 1
                healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                healthLabel.TextStrokeTransparency = 0
                healthLabel.Font = Enum.Font.Gotham
                healthLabel.TextSize = 10
                healthLabel.Visible = Config.ESP_Health
                
                -- Update Text Darah secara realtime
                local hum = character:FindFirstChild("Humanoid")
                if hum then
                    hum.HealthChanged:Connect(function()
                        healthLabel.Text = "HP: " .. math.floor(hum.Health)
                        -- Ubah warna text jika darah sekarat
                        if hum.Health < 30 then
                            healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                        else
                            healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        end
                    end)
                    healthLabel.Text = "HP: " .. math.floor(hum.Health) -- Set awal
                end
            end
        end

        -- Jika player sudah punya karakter saat script dijalankan
        if player.Character then
            CharacterSetup(player.Character)
        end

        -- Jika player respawn (mati lalu hidup lagi)
        player.CharacterAdded:Connect(CharacterSetup)
    end

    -- Loop Update (Untuk menyalakan/mematikan visibilitas berdasarkan Config)
    -- Kita pakai loop ringan agar tidak membebani HP
    RunService.RenderStepped:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                
                -- Update Box (Highlight)
                local hl = char:FindFirstChild("VanzyHighlight")
                if hl then
                    hl.Enabled = Config.ESP_Box
                    hl.OutlineColor = Config.CustomColor -- Sinkron dengan tema menu
                elseif Config.ESP_Box then
                    -- Jika highlight hilang tapi fitur nyala, buat ulang
                    AddESP(player)
                end

                -- Update Name & Health
                local tag = char:FindFirstChild("VanzyTag")
                if tag then
                    tag.Enabled = (Config.ESP_Name or Config.ESP_Health)
                    
                    local nameLbl = tag:FindFirstChild("NameLabel")
                    if nameLbl then nameLbl.Visible = Config.ESP_Name end
                    
                    local hpLbl = tag:FindFirstChild("HealthLabel")
                    if hpLbl then hpLbl.Visible = Config.ESP_Health end
                elseif (Config.ESP_Name or Config.ESP_Health) then
                    AddESP(player)
                end
            end
        end
    end)

    -- Event Listener untuk Player Baru Masuk
    Players.PlayerAdded:Connect(function(player)
        AddESP(player)
    end)

    -- Inisialisasi awal untuk semua player yang sudah ada di game
    for _, player in pairs(Players:GetPlayers()) do
        AddESP(player)
    end

    -- UI CONTROLS (Toggles di Menu)
    VisualTab:Label("ESP Visuals")

    VisualTab:Toggle("ESP Box (Wallhack)", function(state)
        Config.ESP_Box = state
    end)

    VisualTab:Toggle("ESP Name", function(state)
        Config.ESP_Name = state
    end)

    VisualTab:Toggle("ESP Health", function(state)
        Config.ESP_Health = state
    end)
    
    VisualTab:Label("Settings")
    -- Slider untuk mengatur ketebalan atau transparansi bisa ditambahkan disini
    -- Contoh simple info
    VisualTab:Button("Refresh ESP", Theme.Button, function()
        for _, p in pairs(Players:GetPlayers()) do
            ClearESP(p.Character)
            AddESP(p)
        end
    end)
end
