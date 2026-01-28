-- Vanzyxxx FPS Boost & Counter
-- Optimized for Mobile Performance
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local RunService = Services.RunService
    local Lighting = Services.Lighting
    local Workspace = Services.Workspace
    local Players = Services.Players
    local CoreGui = Services.CoreGui
    
    -- Create Tab
    local SettingsTab = UI:Tab("Settings")
    SettingsTab:Label("Performance & Info")

    -- State Variables
    local FPS_Connection = nil
    local FPS_Gui = nil
    local Boost_Enabled = false
    local HidePlayers_Enabled = false

    --------------------------------------------------------------------------------
    -- 1. FPS COUNTER SYSTEM
    --------------------------------------------------------------------------------
    
    local function CreateFPSCounter()
        if FPS_Gui then return end
        
        -- Gunakan ScreenGui terpisah agar tidak ikut ter-hide saat menu utama ditutup
        local screen = Instance.new("ScreenGui")
        screen.Name = "VanzyFPS"
        screen.Parent = CoreGui -- Masuk ke CoreGui agar aman
        screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screen.ResetOnSpawn = false

        -- Frame Background (Semi transparan)
        local frame = Instance.new("Frame", screen)
        frame.Name = "FPSFrame"
        frame.Size = UDim2.new(0, 80, 0, 25)
        -- Posisi aman di kiri atas (Support Notch/Horizontal/Vertical)
        -- Menggunakan Scale X sedikit masuk (0.02) dan Offset Y (5)
        frame.Position = UDim2.new(0.02, 0, 0.0, 5) 
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.5
        
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 1.5

        -- Text Label
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "FPS: 60"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        
        FPS_Gui = screen
        
        -- Logic Update FPS
        local lastUpdate = 0
        FPS_Connection = RunService.RenderStepped:Connect(function(deltaTime)
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= 0.5 then -- Update setiap 0.5 detik biar ga spam
                local fps = math.floor(1 / deltaTime)
                label.Text = "fps: " .. fps
                
                -- Warna dinamis berdasarkan performa
                if fps >= 50 then
                    label.TextColor3 = Color3.fromRGB(0, 255, 100) -- Hijau
                elseif fps >= 30 then
                    label.TextColor3 = Color3.fromRGB(255, 200, 0) -- Kuning
                else
                    label.TextColor3 = Color3.fromRGB(255, 50, 50) -- Merah
                end
                
                -- Update warna stroke sesuai tema
                stroke.Color = Theme.Accent
                
                lastUpdate = 0
            end
        end)
    end

    local function DestroyFPSCounter()
        if FPS_Connection then FPS_Connection:Disconnect() FPS_Connection = nil end
        if FPS_Gui then FPS_Gui:Destroy() FPS_Gui = nil end
    end

    --------------------------------------------------------------------------------
    -- 2. FPS BOOST LOGIC
    --------------------------------------------------------------------------------

    local function ApplyFullBoost()
        -- 1. Optimasi Lighting
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere:Destroy() end
        if Lighting:FindFirstChild("Bloom") then Lighting.Bloom:Destroy() end
        if Lighting:FindFirstChild("Blur") then Lighting.Blur:Destroy() end
        if Lighting:FindFirstChild("DepthOfField") then Lighting.DepthOfField:Destroy() end
        if Lighting:FindFirstChild("SunRays") then Lighting.SunRays:Destroy() end
        
        -- 2. Optimasi Terrain
        local Terrain = Workspace.Terrain
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        
        -- 3. Loop Workspace (Hapus texture, decal, particle)
        -- Menggunakan pcall agar tidak error jika part terkunci
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                -- Jangan ubah transparency part penting
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.TextureID = "" -- Hapus tekstur mesh
            end
        end
        
        -- Notifikasi
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Boost Applied",
            Text = "Textures & Shadows removed!",
            Duration = 2
        })
    end

    --------------------------------------------------------------------------------
    -- 3. HIDE PLAYERS LOGIC
    --------------------------------------------------------------------------------
    
    local function ToggleHidePlayers(state)
        HidePlayers_Enabled = state
        
        local function ProcessPlayer(player)
            if player == Players.LocalPlayer then return end
            if not player.Character then return end
            
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = state and 1 or 0
                end
            end
        end

        -- Proses player yang sudah ada
        for _, player in pairs(Players:GetPlayers()) do
            ProcessPlayer(player)
        end
        
        -- Jika aktif, pasang listener untuk player baru/respawn
        if state then
            Config.HidePlayerConn = RunService.Stepped:Connect(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= Players.LocalPlayer and player.Character then
                        for _, part in pairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") or part:IsA("Decal") then
                                part.Transparency = 1
                            end
                        end
                    end
                end
            end)
        else
            if Config.HidePlayerConn then 
                Config.HidePlayerConn:Disconnect() 
                Config.HidePlayerConn = nil
            end
        end
    end

    --------------------------------------------------------------------------------
    -- UI CONTROLS
    --------------------------------------------------------------------------------

    -- Toggle: Show FPS
    SettingsTab:Toggle("Show FPS Counter", function(state)
        if state then
            CreateFPSCounter()
        else
            DestroyFPSCounter()
        end
    end)

    -- Button: Full Boost
    SettingsTab:Button("Full FPS Boost (No Textures)", Theme.Button, function()
        ApplyFullBoost()
    end)

    -- Toggle: Hide Players
    SettingsTab:Toggle("Hide All Players (Extreme)", function(state)
        ToggleHidePlayers(state)
    end)

    -- Cleanup saat script di-reset
    Config.OnReset:Connect(function()
        DestroyFPSCounter()
        if Config.HidePlayerConn then Config.HidePlayerConn:Disconnect() end
        print("[Vanzyxxx] FPS Settings Cleaned")
    end)

    print("[Vanzyxxx] FPS Boost Loaded!")
end
