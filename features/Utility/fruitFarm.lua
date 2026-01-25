return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local LocalPlayer = Players.LocalPlayer
    local RunService = Services.RunService
    local Workspace = Services.Workspace
    
    local UtilityTab = UI:Tab("Utility")
    
    UtilityTab:Label("--- PHYSICS EXPLOITS (VISIBLE) ---")
    
    -- 1. INVISIBLE FLING (Paling Mematikan & Visible)
    local flingLoop = nil
    TrollTab:Toggle("Invisible Fling (Walk near enemy)", function(state)
        if state then
            Services.StarterGui:SetCore("SendNotification", {Title = "Fling Active", Text = "Dekati musuh untuk lempar mereka!", Duration = 3})
            
            -- Sembunyikan karakter visual, tapi fisik tetap ada
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Transparency = 0.5 -- Biar lu masih liat diri sendiri dikit
                        v.CanCollide = false
                    end
                end
            end
            
            -- Loop putaran maut
            flingLoop = RunService.Heartbeat:Connect(function()
                local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if Root then
                    local Vel = Vector3.new(99999, 99999, 99999) -- Kecepatan gila
                    Root.Velocity = Vel
                    Root.RotVelocity = Vel
                    -- Pastikan lu gak jatuh ke void
                    -- Note: Di mobile kontrolnya agak susah, pake Fly biar stabil
                end
            end)
        else
            if flingLoop then 
                flingLoop:Disconnect() 
                flingLoop = nil
            end
            local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                Root.Velocity = Vector3.new(0,0,0)
                Root.RotVelocity = Vector3.new(0,0,0)
            end
        end
    end)
    
    -- 2. HITBOX EXPANDER (Combat Curang)
    TrollTab:Label("--- COMBAT (VISIBLE EFFECT) ---")
    
    TrollTab:Button("Expand Enemy Hitbox (All Enemies)", Theme.ButtonRed, function()
        -- Ini bikin kepala musuh jadi gede banget
        -- Lu tembak kemana aja, mereka kena. Mereka gak liat kepalanya gede (client-sided visual), 
        -- TAPI mereka bakal mati (Server-sided effect).
        
        local Size = Vector3.new(5, 5, 5) -- Ukuran Hitbox
        local Transparency = 0.7
        
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    v.Character.HumanoidRootPart.Size = Size
                    v.Character.HumanoidRootPart.Transparency = Transparency
                    v.Character.HumanoidRootPart.CanCollide = false
                end)
            end
        end
        
        Services.StarterGui:SetCore("SendNotification", {Title = "Hitbox Expanded", Text = "Musuh sekarang gampang dipukul.", Duration = 2})
    end)
    
    -- 3. LOOP KILL (Teleport Kill)
    local killLoop = false
    TrollTab:Toggle("Loop Kill Aura (Touch to Kill)", function(state)
        killLoop = state
        spawn(function()
            while killLoop and task.wait() do
                pcall(function()
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                            local MyRoot = LocalPlayer.Character.HumanoidRootPart
                            local EnemyRoot = v.Character.HumanoidRootPart
                            
                            -- Teleport ke belakang musuh + Equip Tool
                            MyRoot.CFrame = EnemyRoot.CFrame * CFrame.new(0, 0, 2)
                            
                            -- Auto Activate Tool (Kalo lu pegang pedang)
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                end)
            end
        end)
    end)
end
