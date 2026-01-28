return function(UI, Services, Config, Theme)
    local Tab = UI:Tab("Teleport")
    
    Tab:Label("Player Teleport (Ultra Safe)")
    
    local ScrollContainer = Tab:Container(200) -- Ukuran container diperbesar
    
    -- Fungsi untuk mencari bagian tubuh yang valid (Apa saja yang ketemu)
    local function GetTargetPosition(character)
        -- Cek 1: Coba ambil posisi Pivot (Metode paling modern)
        if character.PrimaryPart then
            return character:GetPivot()
        end
        
        -- Cek 2: Cari bagian tubuh vital
        local partsToCheck = {
            "HumanoidRootPart", 
            "Torso", 
            "UpperTorso", 
            "LowerTorso", 
            "Head", 
            "Humanoid" -- Kadang HumanoidRootPart jadi child Humanoid di game aneh
        }
        
        for _, partName in ipairs(partsToCheck) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                return part.CFrame
            end
        end
        
        return nil
    end

    local function TeleportTo(targetPlayer)
        local LocalPlayer = Services.Players.LocalPlayer
        
        -- 1. Cek Karakter Kita Sendiri
        if not LocalPlayer.Character then
            Services.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Karaktermu belum spawn!", Duration = 2})
            return
        end
        
        local MyRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso") or LocalPlayer.Character:FindFirstChild("Head")
        if not MyRoot then
            -- Coba spawn ulang jika karakter kita bug
            Services.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Karaktermu bug (tidak ada body)!", Duration = 2})
            return 
        end

        -- 2. Cek Karakter Target
        local TargetChar = targetPlayer.Character
        if not TargetChar then
            Services.StarterGui:SetCore("SendNotification", {Title = "Gagal", Text = "Target sedang mati/respawn.", Duration = 2})
            return
        end

        -- 3. Coba dapatkan posisi target dengan segala cara
        local targetCFrame = GetTargetPosition(TargetChar)

        if targetCFrame then
            -- Teleportasi
            local newPos = targetCFrame * CFrame.new(0, 4, 0) -- Muncul 4 stud di atas kepala mereka
            
            -- Metode PivotTo (Paling aman agar tidak tertinggal kakinya)
            LocalPlayer.Character:PivotTo(newPos)
            
            -- Metode Cadangan (Set CFrame manual jika Pivot gagal)
            if MyRoot then
                MyRoot.CFrame = newPos
            end
        else
            -- 4. StreamingEnabled Handler (Masalah jarak jauh)
            -- Jika kita tidak bisa melihat part mereka karena kejauhan
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Target Terlalu Jauh",
                Text = "Game ini menyembunyikan player jauh (StreamingEnabled). Mendekatlah manual dulu.",
                Duration = 4
            })
            
            warn("[Vanzyxxx] Target character exists but no parts found (StreamingEnabled restriction).")
        end
    end

    -- Fungsi Refresh
    local function RefreshPlayers()
        -- Hapus list lama
        for _, child in pairs(ScrollContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        -- Isi list baru
        local players = Services.Players:GetPlayers()
        
        -- Urutkan nama player abjad A-Z agar rapi
        table.sort(players, function(a, b) return a.Name < b.Name end)

        for _, player in pairs(players) do
            if player ~= Services.Players.LocalPlayer then
                local btn = Instance.new("TextButton", ScrollContainer)
                btn.Name = player.Name
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = Theme.Button
                
                -- Tampilkan Nama Asli & Display Name
                btn.Text = string.format("%s (@%s)", player.DisplayName, player.Name)
                
                btn.TextColor3 = Color3.fromRGB(240, 240, 240)
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 12
                
                local btnCorner = Instance.new("UICorner", btn)
                btnCorner.CornerRadius = UDim.new(0, 4)
                
                -- Indikator status (Hijau = Hidup, Merah = Mati/Jauh)
                local statusIndicator = Instance.new("Frame", btn)
                statusIndicator.Size = UDim2.new(0, 4, 1, 0)
                statusIndicator.BorderSizePixel = 0
                
                -- Cek status awal
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- Hijau (Ready)
                else
                    statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Merah (Mati/Jauh)
                end

                btn.MouseButton1Click:Connect(function()
                    TeleportTo(player)
                end)
            end
        end
    end

    Tab:Button("⟳ Refresh List", Theme.Confirm, function()
        RefreshPlayers()
    end)
    
    -- Auto refresh setiap 10 detik (Opsional, agar list tidak basi)
    spawn(function()
        while task.wait(10) do
            if ScrollContainer and ScrollContainer.Parent then
                -- Cek sederhana update status warna saja tanpa rebuild semua tombol (untuk performa)
                for _, btn in pairs(ScrollContainer:GetChildren()) do
                    if btn:IsA("TextButton") then
                        local plr = Services.Players:FindFirstChild(btn.Name)
                        local indicator = btn:FindFirstChild("Frame")
                        if plr and indicator then
                            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                                indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                            else
                                indicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                            end
                        end
                    end
                end
            else
                break
            end
        end
    end)
    
    RefreshPlayers()
end
