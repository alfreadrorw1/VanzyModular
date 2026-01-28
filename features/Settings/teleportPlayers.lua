return function(UI, Services, Config, Theme)
    local Tab = UI:Tab("Teleport")
    
    Tab:Label("Player List")
    
    -- Container untuk list player
    local ScrollContainer = Tab:Container(150)
    
    -- Fungsi Teleport yang diperbaiki
    local function TeleportTo(targetPlayer)
        local LocalPlayer = Services.Players.LocalPlayer
        
        -- Cek 1: Apakah karakter KITA ada?
        if not LocalPlayer.Character then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Gagal",
                Text = "Karaktermu belum spawn!",
                Duration = 2
            })
            return
        end

        local MyRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso")
        if not MyRoot then return end

        -- Cek 2: Apakah karakter TARGET ada?
        local TargetChar = targetPlayer.Character
        if not TargetChar then
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Gagal",
                Text = targetPlayer.DisplayName .. " sedang mati/respawn.",
                Duration = 2
            })
            return
        end

        -- Cari RootPart target (Support R6 dan R15)
        local TargetRoot = TargetChar:FindFirstChild("HumanoidRootPart") or TargetChar:FindFirstChild("Torso")
        
        if TargetRoot then
            -- Menggunakan PivotTo (Lebih aman daripada CFrame manual)
            local targetPos = TargetRoot.CFrame * CFrame.new(0, 3, 2) -- Muncul sedikit di belakang/atas target
            LocalPlayer.Character:PivotTo(targetPos)
        else
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Target tidak memiliki fisik (RootPart)!",
                Duration = 2
            })
        end
    end

    -- Fungsi Refresh List
    local function RefreshPlayers()
        -- Bersihkan tombol lama
        for _, child in pairs(ScrollContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        -- Buat tombol baru untuk setiap player
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player ~= Services.Players.LocalPlayer then
                local btn = Instance.new("TextButton", ScrollContainer)
                btn.Name = player.Name
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Theme.Button
                btn.Text = player.DisplayName
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 11
                
                local btnCorner = Instance.new("UICorner", btn)
                btnCorner.CornerRadius = UDim.new(0, 6)
                
                btn.MouseButton1Click:Connect(function()
                    TeleportTo(player)
                end)
            end
        end
    end

    -- Tombol Refresh
    Tab:Button("Refresh Player List", Theme.Accent, function()
        RefreshPlayers()
    end)
    
    -- Load awal
    RefreshPlayers()
end
