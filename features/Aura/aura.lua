-- Vanzyxxx Aura System (FIXED PHYSICS)
-- Custom Character Auras with Anti-Stuck Logic

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local HttpService = Services.HttpService
    local RunService = Services.RunService
    local StarterGui = Services.StarterGui
    
    -- Create Tab
    local AuraTab = UI:Tab("Aura")
    
    AuraTab:Label("Character Auras")
    
    -- Aura Variables
    local CurrentAura = nil
    local AuraContainer = nil
    local AuraRotationSpeed = 1
    local AuraScale = 1
    local AuraTransparency = 0.5
    
    -- GitHub Aura List URL
    local GithubAura = "https://raw.githubusercontent.com/alfreadrorw1/vanzyx/main/aura.json"
    local AuraList = {}
    
    -- Preset Auras
    local PresetAuras = {
        { Name = "Fire Aura", ID = "9206613942" },
        { Name = "Ice Aura", ID = "9206615323" },
        { Name = "Lightning", ID = "9206616377" },
        { Name = "Darkness", ID = "9206617412" },
        { Name = "Holy Light", ID = "9206618545" },
        { Name = "Rainbow", ID = "9206619521" },
        { Name = "Dragon", ID = "9206620543" },
        { Name = "Super Saiyan", ID = "2941153370" }
    }
    
    -- Function to Clean Aura (PHYSICS FIX)
    local function CleanAuraPhysics(model)
        for _, desc in pairs(model:GetDescendants()) do
            -- Hapus Humanoid (Penyebab utama gak bisa gerak)
            if desc:IsA("Humanoid") then
                desc:Destroy()
            -- Hapus BodyMover (Penyebab karakter melayang aneh)
            elseif desc:IsA("BodyPosition") or desc:IsA("BodyVelocity") or desc:IsA("BodyGyro") then
                desc:Destroy()
            -- Atur Part agar tidak tabrakan & tidak berat
            elseif desc:IsA("BasePart") or desc:IsA("MeshPart") then
                desc.CanCollide = false
                desc.CanTouch = false
                desc.CanQuery = false
                desc.Anchored = false
                desc.Massless = true
                desc.CastShadow = false
                desc.Transparency = AuraTransparency
            elseif desc:IsA("Decal") then
                desc.Transparency = AuraTransparency
            end
        end
    end

    -- Function to apply aura
    local function ApplyAura(auraId, auraName)
        pcall(function()
            -- 1. Remove Existing
            if CurrentAura then CurrentAura:Destroy(); CurrentAura = nil end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("VanzyAura") then
                LocalPlayer.Character.VanzyAura:Destroy()
            end
            
            -- 2. Handle Reset
            if auraId == "reset" then
                StarterGui:SetCore("SendNotification", {Title = "Aura", Text = "Removed!", Duration = 2})
                return
            end
            
            -- 3. Load Aura
            local success, result = pcall(function() return game:GetObjects("rbxassetid://" .. auraId) end)
            
            if success and result[1] then
                local aura = result[1]
                aura.Name = "VanzyAura"
                
                -- 4. Apply Physics Fix (CRITICAL)
                CleanAuraPhysics(aura)
                
                -- 5. Attach to Character
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    aura.Parent = LocalPlayer.Character
                    
                    local root = LocalPlayer.Character.HumanoidRootPart
                    local primary = aura:IsA("Model") and aura.PrimaryPart or aura:FindFirstChildWhichIsA("BasePart")
                    
                    if primary then
                        -- Pindahkan ke posisi pemain dulu
                        primary.CFrame = root.CFrame
                        
                        -- Weld (Rekatkan)
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = root
                        weld.Part1 = primary
                        weld.Parent = primary
                        
                        CurrentAura = aura
                        StarterGui:SetCore("SendNotification", {Title = "Aura", Text = "Applied: " .. auraName})
                    else
                        -- Fallback jika tidak ada primary part
                        aura:Destroy()
                        StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Bad Aura Model (No Parts)"})
                    end
                end
            else
                StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Invalid ID / Asset"})
            end
        end)
    end
    
    -- Rotation Loop
    local auraRotationConnection = nil
    local function StartAuraRotation()
        if auraRotationConnection then auraRotationConnection:Disconnect() end
        auraRotationConnection = RunService.Heartbeat:Connect(function()
            if CurrentAura and Config.AuraRotate and LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Putar PrimaryPart atau Model relatif terhadap root
                    -- Catatan: Rotasi aura kompleks butuh CFrame math yang hati-hati agar tidak merusak Weld
                    -- Cara aman: Putar texture/particle atau gunakan Motor6D (terlalu kompleks untuk script ini)
                    -- Kita gunakan metode simple: Putar attachment jika ada
                end
            end
        end)
    end

    -- Container Updater
    local function UpdateAuraContainer()
        if not AuraContainer then return end
        for _, child in ipairs(AuraContainer:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
        
        -- Preset List
        for _, aura in ipairs(PresetAuras) do
            local btn = Instance.new("TextButton", AuraContainer)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Theme.ButtonDark
            btn.Text = aura.Name
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function() ApplyAura(aura.ID, aura.Name) end)
        end
        
        -- Separator
        local sep = Instance.new("TextLabel", AuraContainer)
        sep.Size = UDim2.new(1,0,0,20); sep.BackgroundTransparency=1; sep.Text="--- GitHub List ---"; sep.TextColor3=Theme.Accent; sep.Font=Enum.Font.GothamBold; sep.TextSize=10
        
        -- GitHub List
        for _, aura in ipairs(AuraList) do
            local btn = Instance.new("TextButton", AuraContainer)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Theme.Button
            btn.Text = aura.Name
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function() ApplyAura(aura.ID, aura.Name) end)
        end
    end
    
    local function LoadAuraList()
        pcall(function()
            local json = game:HttpGet(GithubAura)
            if json then
                AuraList = HttpService:JSONDecode(json)
                UpdateAuraContainer()
                StarterGui:SetCore("SendNotification", {Title="GitHub", Text="Loaded "..#AuraList.." Auras"})
            end
        end)
    end
    
    -- UI Construction
    AuraContainer = AuraTab:Container(200)
    
    AuraTab:Button("Load GitHub List", Theme.Button, LoadAuraList)
    AuraTab:Button("RESET AURA (Fix)", Theme.ButtonRed, function() ApplyAura("reset", "Reset") end)
    
    AuraTab:Label("Custom ID")
    AuraTab:Input("Enter ID...", function(t) if tonumber(t) then ApplyAura(t, "Custom") end end)
    
    AuraTab:Label("Settings")
    AuraTab:Slider("Transparency", 0, 1, function(v)
        AuraTransparency = v
        if CurrentAura then for _,p in pairs(CurrentAura:GetDescendants()) do if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = v end end end
    end)
    
    AuraTab:Toggle("Particles", function(s)
        Config.AuraParticles = s
        if CurrentAura then
            if s then
                for _,p in pairs(CurrentAura:GetDescendants()) do
                    if p:IsA("BasePart") and not p:FindFirstChild("VPart") then
                        local pe = Instance.new("ParticleEmitter", p); pe.Name="VPart"; pe.Texture="rbxassetid://243098098"; pe.Color=ColorSequence.new(Theme.Accent); pe.Lifetime=NumberRange.new(0.5); pe.Rate=20
                    end
                end
            else
                for _,p in pairs(CurrentAura:GetDescendants()) do if p:IsA("ParticleEmitter") and p.Name=="VPart" then p:Destroy() end end
            end
        end
    end)
    
    -- Init
    spawn(function() task.wait(1); UpdateAuraContainer() end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        if CurrentAura then CurrentAura:Destroy() end
    end)
    
    print("[Vanzyxxx] Fixed Aura System Loaded")
end
