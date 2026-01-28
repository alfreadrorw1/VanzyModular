return function(UI, Services, Config, Theme)
    -- Membuat Tab baru bernama "Teleport" (atau gunakan kategori yang sudah ada)
    local Tab = UI:Tab("Teleport")
    
    Tab:Label("Player List")
    
    -- Membuat wadah scroll untuk daftar pemain
    local ScrollContainer = Tab:Container(150) -- Tinggi container 150px
    
    -- Fungsi untuk teleport
    local function TeleportTo(targetPlayer)
        local LocalPlayer = Services.Players.LocalPlayer
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- Teleport sedikit di atas target agar tidak bug
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 2)
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Target has no character!",
                    Duration = 2
                })
            end
        end
    end

    -- Fungsi untuk memperbarui daftar pemain
    local function RefreshPlayers()
        -- Hapus tombol lama (bersihkan container)
        for _, child in pairs(ScrollContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        -- Loop semua pemain
        for _, player in pairs(Services.Players:GetPlayers()) do
            -- Jangan masukkan diri sendiri ke list
            if player ~= Services.Players.LocalPlayer then
                
                -- Buat tombol secara manual agar masuk ke dalam ScrollContainer
                local btn = Instance.new("TextButton", ScrollContainer)
                btn.Name = player.Name
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Theme.Button
                btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                local btnCorner = Instance.new("UICorner", btn)
                btnCorner.CornerRadius = UDim.new(0, 6)
                
                -- Event saat tombol ditekan
                btn.MouseButton1Click:Connect(function()
                    TeleportTo(player)
                end)
            end
        end
    end

    -- Tombol Refresh di luar container
    Tab:Button("Refresh Player List", Theme.Accent, function()
        RefreshPlayers()
    end)
    
    -- Load daftar pemain saat script pertama jalan
    RefreshPlayers()
end
