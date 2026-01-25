-- Vanzyxxx Fast Fruit Farmer
-- Speed Up Harvest & Instant Proximity Prompt
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Workspace = Services.Workspace
    local Players = Services.Players
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local LocalPlayer = Players.LocalPlayer

    local Utility = UI:Tab("Fruit Farm")
    UtilityTab:Label("Instant Harvest (Time Skipper)")

    -- Config
    Config.AutoHarvest = false
    Config.InstantPrompt = false
    Config.FarmRange = 50 -- Jarak teleport
    
    -- 1. INSTANT INTERACTION (Mempercepat 'Hold E')
    -- Ini trik "Speed Up Time" paling ampuh buat farming
    -- Mengubah waktu tahan tombol dari 5 detik jadi 0 detik
    
    local function EnableInstantPrompt()
        spawn(function()
            while Config.InstantPrompt do
                for _, prompt in pairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        -- Ubah durasi tahan jadi 0 (Instan)
                        prompt.HoldDuration = 0
                        prompt.MaxActivationDistance = 50 -- Perjauh jarak ambil
                    end
                end
                task.wait(1)
            end
        end)
    end

    -- 2. AUTO HARVEST (Teleport ke Buah Matang)
    -- Daripada nunggu jalan kaki, kita teleport langsung
    
    local function StartAutoHarvest()
        spawn(function()
            while Config.AutoHarvest do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root then
                    -- Cari ProximityPrompt (Tombol Ambil)
                    for _, prompt in pairs(Workspace:GetDescendants()) do
                        if not Config.AutoHarvest then break end
                        
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local part = prompt.Parent
                            
                            -- Pastikan itu objek fisik & bukan punya kita sendiri
                            if part and part:IsA("BasePart") and not part:IsDescendantOf(char) then
                                
                                -- Cek apakah ini "Buah" atau "Tanaman" (Filter sederhana)
                                -- Sesuaikan nama ini dengan game kamu!
                                local name = string.lower(part.Name)
                                local parentName = string.lower(part.Parent.Name)
                                
                                -- Kamu bisa tambah filter nama di sini kalau mau spesifik
                                -- Contoh: if string.find(name, "fruit") or string.find(name, "tree") then
                                
                                    -- 1. Teleport ke target
                                    root.CFrame = part.CFrame
                                    task.wait(0.2) -- Jeda dikit biar gak ngebug
                                    
                                    -- 2. Paksa tekan tombol (Fire Prompt)
                                    fireproximityprompt(prompt) 
                                    -- Jika executor gak support fireproximityprompt, dia akan pakai cara manual (HoldDuration 0)
                                    
                                    task.wait(0.1)
                                -- end
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end

    -- UI CONTROLS
    
    FarmTab:Toggle("Instant Hold (0 Sec Delay)", function(state)
        Config.InstantPrompt = state
        if state then EnableInstantPrompt() end
    end)

    FarmTab:Toggle("Teleport & Harvest All", function(state)
        Config.AutoHarvest = state
        if state then StartAutoHarvest() end
    end)
    
    FarmTab:Label("Note: This removes the waiting time")
    FarmTab:Label("when picking up fruits.")

    -- Cleanup
    Config.OnReset:Connect(function()
        Config.AutoHarvest = false
        Config.InstantPrompt = false
    end)

    print("[Vanzyxxx] Fruit Farm Loaded!")
end
