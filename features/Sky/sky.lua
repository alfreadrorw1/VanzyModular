-- Vanzyxxx Sky System (GITHUB ONLY - FIXED)
-- Fix: Model wrapper detection, Atmosphere support, & Removing Presets

return function(UI, Services, Config, Theme)
    local Lighting = Services.Lighting
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    
    -- Create Tab
    local SkyTab = UI:Tab("Sky")
    SkyTab:Label("GitHub Sky Loader")
    
    -- Variables
    local SkyContainer = nil
    local GithubSky = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/JsonLoad/main/sky.json"
    local SkyList = {} -- Data akan masuk ke sini dari GitHub

    -- [FIX] Fungsi Apply Sky yang Pintar
    local function ApplySky(skyId, skyName)
        pcall(function()
            -- 1. Notifikasi Loading
            if skyId ~= "reset" then
                StarterGui:SetCore("SendNotification", {Title = "Loading...", Text = "Fetching Sky: " .. skyId})
            end

            -- 2. Hapus Sky Lama (Bersih-bersih)
            for _, child in pairs(Lighting:GetChildren()) do
                if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
                    child:Destroy()
                end
            end

            -- 3. Cek Reset
            if skyId == "reset" then
                StarterGui:SetCore("SendNotification", {Title = "Sky", Text = "Reset to Default", Duration = 2})
                return
            end

            -- 4. Load Asset Baru
            local success, result = pcall(function() 
                return game:GetObjects("rbxassetid://" .. skyId) 
            end)

            if success and result and result[1] then
                local asset = result[1]
                local found = false

                -- Jika Asset adalah Model (Biasanya berisi Sky + Atmosphere)
                if asset:IsA("Model") then
                    -- Cari dan pindahkan Sky
                    local sky = asset:FindFirstChildOfClass("Sky")
                    if sky then 
                        sky.Parent = Lighting 
                        found = true
                    end
                    
                    -- Cari dan pindahkan Atmosphere (Agar lebih realistis)
                    local atmos = asset:FindFirstChildOfClass("Atmosphere")
                    if atmos then atmos.Parent = Lighting end
                    
                    -- Cari dan pindahkan Clouds (Awan bergerak)
                    local clouds = asset:FindFirstChildOfClass("Clouds")
                    if clouds then clouds.Parent = Lighting end

                    -- Jika di root model tidak ada, cari di anak-anaknya (Deep Search)
                    if not found then
                         for _, v in pairs(asset:GetDescendants()) do
                            if v:IsA("Sky") then
                                v.Parent = Lighting
                                found = true
                                break
                            end
                         end
                    end
                
                -- Jika Asset langsung berupa objek Sky
                elseif asset:IsA("Sky") then
                    asset.Parent = Lighting
                    found = true
                end

                if found then
                    StarterGui:SetCore("SendNotification", {Title = "Success", Text = "Applied: " .. skyName})
                else
                    StarterGui:SetCore("SendNotification", {Title = "Error", Text = "No Sky object found in asset"})
                end
            else
                StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Invalid ID / Asset Locked"})
            end
        end)
    end

    -- [FIX] Update List UI (Hanya GitHub)
    local function UpdateSkyList()
        if not SkyContainer then return end
        
        -- Bersihkan list lama
        for _, child in ipairs(SkyContainer:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then 
                child:Destroy() 
            end
        end
        
        -- Cek jika kosong
        if #SkyList == 0 then
            local lbl = Instance.new("TextLabel", SkyContainer)
            lbl.Size = UDim2.new(1,0,0,30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "No Skies Found / Load GitHub First"
            lbl.TextColor3 = Color3.fromRGB(150,150,150)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            return
        end

        -- Generate Tombol
        for _, sky in ipairs(SkyList) do
            local btn = Instance.new("TextButton", SkyContainer)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Theme.ButtonDark
            btn.Text = "☁️ " .. (sky.Name or "Unknown")
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = UDim.new(0, 6)
            
            btn.MouseButton1Click:Connect(function() 
                ApplySky(sky.ID, sky.Name) 
            end)
        end
        
        -- Update ukuran scroll
        SkyContainer.CanvasSize = UDim2.new(0, 0, 0, SkyContainer.UIListLayout.AbsoluteContentSize.Y + 20)
    end

    -- Load Data dari GitHub
    local function LoadGitHubData()
        StarterGui:SetCore("SendNotification", {Title = "GitHub", Text = "Downloading Sky List..."})
        pcall(function()
            local json = game:HttpGet(GithubSky)
            if json then
                local data = HttpService:JSONDecode(json)
                if data then
                    SkyList = data
                    UpdateSkyList()
                    StarterGui:SetCore("SendNotification", {Title = "Success", Text = "Loaded " .. #SkyList .. " Skies"})
                end
            else
                StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Failed to fetch GitHub"})
            end
        end)
    end

    -- >>> UI SETUP <<<
    
    -- Tombol Load GitHub
    SkyTab:Button("📥 LOAD LIST FROM GITHUB", Theme.Button, LoadGitHubData)
    
    -- Container List
    SkyContainer = SkyTab:Container(250)
    
    -- Kontrol Reset & Custom
    SkyTab:Label("Controls")
    SkyTab:Button("❌ RESET SKY", Theme.ButtonRed, function() ApplySky("reset", "Default") end)
    
    SkyTab:Input("Custom ID (Number Only)", function(text)
        if tonumber(text) then
            ApplySky(text, "Custom ID")
        end
    end)
    
    -- Init (Auto Load)
    spawn(function()
        task.wait(1)
        LoadGitHubData()
    end)
    
    print("[Vanzyxxx] Sky Module (GitHub Only) Loaded")
end
