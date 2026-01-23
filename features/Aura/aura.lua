-- Vanzyxxx Aura System (GITHUB ONLY - FIXED)
-- Fix: Load Logic, Physics, & Removing Presets

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local HttpService = Services.HttpService
    local RunService = Services.RunService
    local StarterGui = Services.StarterGui
    
    -- Create Tab
    local AuraTab = UI:Tab("Aura")
    AuraTab:Label("GitHub Aura Loader")
    
    -- Variables
    local CurrentAura = nil
    local AuraContainer = nil
    local GithubAura = "https://raw.githubusercontent.com/alfreadrorw1/vanzyx/main/aura.json"
    local AuraList = {} -- Data akan masuk ke sini dari GitHub
    
    -- [FIX] Fungsi untuk membersihkan Aura agar tidak bikin macet/berat
    local function CleanAuraPhysics(model)
        for _, desc in pairs(model:GetDescendants()) do
            if desc:IsA("BasePart") or desc:IsA("MeshPart") then
                -- Buat part dummy jadi transparan & tidak bisa disentuh
                desc.Transparency = 1 
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.Anchored = false
                desc.Massless = true
                desc.CastShadow = false
            elseif desc:IsA("Humanoid") then
                -- Hapus humanoid bawaan model agar tidak bentrok
                desc:Destroy()
            elseif desc:IsA("BodyMover") then
                -- Hapus script penggerak lama
                desc:Destroy()
            end
        end
    end

    -- [FIX] Fungsi Apply Aura yang Lebih Kuat
    local function ApplyAura(auraId, auraName)
        pcall(function()
            -- 1. Hapus Aura Lama
            if CurrentAura then CurrentAura:Destroy(); CurrentAura = nil end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("VanzyAura") then
                LocalPlayer.Character.VanzyAura:Destroy()
            end
            
            -- 2. Cek Reset
            if auraId == "reset" then
                StarterGui:SetCore("SendNotification", {Title = "Aura", Text = "Removed!", Duration = 2})
                return
            end
            
            -- 3. Load Aura dari ID
            StarterGui:SetCore("SendNotification", {Title = "Loading...", Text = "Fetching ID: " .. auraId})
            
            local success, result = pcall(function() 
                return game:GetObjects("rbxassetid://" .. auraId) 
            end)
            
            if success and result and result[1] then
                local aura = result[1]
                aura.Name = "VanzyAura"
                
                -- 4. Bersihkan Fisik Aura (PENTING)
                CleanAuraPhysics(aura)
                
                -- 5. Tempel ke Karakter
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local root = LocalPlayer.Character.HumanoidRootPart
                    
                    -- Cari part utama dari Aura untuk ditempel
                    local primary = aura:IsA("Model") and aura.PrimaryPart or aura:FindFirstChildWhichIsA("BasePart")
                    
                    -- Jika tidak ada primary part, cari part apa saja
                    if not primary and aura:IsA("Model") then
                        primary = aura:FindFirstChildWhichIsA("BasePart", true)
                    end
                    
                    if primary then
                        aura.Parent = LocalPlayer.Character
                        
                        -- Pindahkan posisi aura ke pemain
                        primary.CFrame = root.CFrame
                        
                        -- Kunci (Weld) Aura ke Pemain
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = root
                        weld.Part1 = primary
                        weld.Parent = primary
                        
                        CurrentAura = aura
                        StarterGui:SetCore("SendNotification", {Title = "Success", Text = "Applied: " .. auraName})
                    else
                        -- Jika model aura kosong/rusak
                        aura:Destroy()
                        StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Aura Model Empty/Broken"})
                    end
                else
                    StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Character not found!"})
                end
            else
                StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Invalid ID / Asset Locked"})
            end
        end)
    end
    
    -- [FIX] Update Container List (Hanya GitHub)
    local function UpdateAuraList()
        if not AuraContainer then return end
        
        -- Bersihkan list lama
        for _, child in ipairs(AuraContainer:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then 
                child:Destroy() 
            end
        end
        
        -- Cek jika list kosong
        if #AuraList == 0 then
            local lbl = Instance.new("TextLabel", AuraContainer)
            lbl.Size = UDim2.new(1,0,0,30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No Auras Found / Load GitHub First"
            lbl.TextColor3 = Color3.fromRGB(150,150,150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            return
        end

        -- Generate Button dari List GitHub
        for _, aura in ipairs(AuraList) do
            local btn = Instance.new("TextButton", AuraContainer)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Theme.ButtonDark
            btn.Text = "✨ " .. (aura.Name or "Unknown")
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = UDim.new(0, 6)
            
            btn.MouseButton1Click:Connect(function() 
                ApplyAura(aura.ID, aura.Name) 
            end)
        end
        
        -- Update ukuran scroll
        AuraContainer.CanvasSize = UDim2.new(0, 0, 0, AuraContainer.UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Load Data dari GitHub
    local function LoadGitHubData()
        StarterGui:SetCore("SendNotification", {Title = "GitHub", Text = "Downloading List..."})
        pcall(function()
            local json = game:HttpGet(GithubAura)
            if json then
                local data = HttpService:JSONDecode(json)
                if data then
                    AuraList = data
                    UpdateAuraList()
                    StarterGui:SetCore("SendNotification", {Title = "Success", Text = "Loaded " .. #AuraList .. " Auras"})
                end
            else
                StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Failed to fetch GitHub"})
            end
        end)
    end
    
    -- >>> UI SETUP <<<
    
    -- Tombol Load GitHub
    AuraTab:Button("📥 LOAD LIST FROM GITHUB", Theme.Button, LoadGitHubData)
    
    -- Container List
    AuraContainer = AuraTab:Container(250) -- Tinggi container
    
    -- Tombol Reset & Custom ID
    AuraTab:Label("Controls")
    AuraTab:Button("❌ RESET AURA", Theme.ButtonRed, function() ApplyAura("reset", "Reset") end)
    
    AuraTab:Input("Custom ID (Number Only)", function(text)
        if tonumber(text) then
            ApplyAura(text, "Custom ID")
        end
    end)
    
    -- Init (Auto Load saat script jalan - Opsional)
    spawn(function()
        task.wait(1)
        LoadGitHubData() -- Otomatis load pas script nyala
    end)
    
    -- Cleanup saat reset
    Config.OnReset:Connect(function()
        if CurrentAura then CurrentAura:Destroy() end
    end)
    
    print("[Vanzyxxx] Aura Module (GitHub Only) Loaded")
end
