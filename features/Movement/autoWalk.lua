-- Vanzyxxx Auto Walk & Replay System (SMART PATHING)
-- Features: Smooth Lerp Replay, Smart Resume, JSON Storage

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local RunService = Services.RunService
    local HttpService = Services.HttpService
    
    -- Create Tab
    local WalkTab = UI:Tab("Auto Walk")
    WalkTab:Label("Record & Replay Movement")

    -- Variables
    local Recorder = {
        IsRecording = false,
        IsPlaying = false,
        StartTime = 0,
        Data = {}, -- { {t=0, cf={...}}, {t=0.1, cf={...}} }
        CurrentReplayIndex = 1,
        Connection = nil
    }
    
    local FolderName = "VanzyWalks"
    if not isfolder(FolderName) then makefolder(FolderName) end

    -- Helper: CFrame Serialization (JSON doesn't support CFrame objects)
    local function EncodeCFrame(cf)
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        return {x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22}
    end

    local function DecodeCFrame(tbl)
        return CFrame.new(table.unpack(tbl))
    end

    -- Helper: Get Nearest Frame Index
    -- Digunakan agar replay bisa mulai dari posisi player saat ini (Smart Start)
    local function GetNearestFrameIndex(currentPos, frames)
        local closestDist = math.huge
        local closestIndex = 1
        
        for i = 1, #frames, 5 do -- Skip check every 5 frames for performance
            local data = frames[i]
            -- Frame structure: [1]=time, [2]=cframe_table
            local framePos = Vector3.new(data[2][1], data[2][2], data[2][3]) 
            local dist = (currentPos - framePos).Magnitude
            
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end
        return closestIndex
    end

    -- ===========================
    -- RECORDING SYSTEM
    -- ===========================
    local function StartRecording()
        if Recorder.IsPlaying then return end
        
        Recorder.Data = {}
        Recorder.IsRecording = true
        Recorder.StartTime = tick()
        
        Services.StarterGui:SetCore("SendNotification", {Title="Recorder", Text="Started Recording..."})

        -- Menggunakan Heartbeat agar sinkron dengan physics engine
        Recorder.Connection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local root = LocalPlayer.Character.HumanoidRootPart
            local timeStamp = tick() - Recorder.StartTime
            
            -- Simpan TimeStamp dan CFrame (Encoded)
            table.insert(Recorder.Data, {
                timeStamp, 
                EncodeCFrame(root.CFrame)
            })
        end)
    end

    local function StopRecording(saveName)
        if Recorder.Connection then Recorder.Connection:Disconnect() end
        Recorder.IsRecording = false
        
        if saveName and #Recorder.Data > 0 then
            local fileName = FolderName .. "/" .. saveName .. ".json"
            writefile(fileName, HttpService:JSONEncode(Recorder.Data))
            Services.StarterGui:SetCore("SendNotification", {Title="Saved", Text="Path saved as "..saveName})
        end
    end

    -- ===========================
    -- REPLAY SYSTEM (The Core Logic)
    -- ===========================
    local function PlayPath(pathData)
        if Recorder.IsRecording then return end
        if not LocalPlayer.Character then return end
        
        local Root = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        local Hum = LocalPlayer.Character:WaitForChild("Humanoid")
        
        Recorder.IsPlaying = true
        
        -- 1. SMART START: Cari posisi start terdekat
        local startIndex = GetNearestFrameIndex(Root.Position, pathData)
        local startTimeOffset = pathData[startIndex][1]
        
        -- Jika start index bukan 1, beri notifikasi
        if startIndex > 10 then
            Services.StarterGui:SetCore("SendNotification", {Title="Smart Resume", Text="Resuming from " .. math.floor((startIndex/#pathData)*100) .. "%"})
        end

        -- Setup Physics
        Root.Anchored = true -- Wajib Anchored agar gerakan mulus mengikuti path
        if LocalPlayer.Character:FindFirstChild("Animate") then
            LocalPlayer.Character.Animate.Disabled = true -- Matikan animasi bawaan agar tidak glitch
        end

        local playStartTime = tick()
        
        Recorder.Connection = RunService.Heartbeat:Connect(function()
            if not Recorder.IsPlaying then return end
            
            -- Hitung waktu saat ini dalam konteks rekaman
            -- (Waktu Sejak Play ditekan) + (Offset waktu di mana kita mulai resume)
            local currentTime = (tick() - playStartTime) + startTimeOffset
            
            -- Logic Loop: Cari Frame A dan Frame B untuk Interpolasi
            -- Kita mencari frame di mana: Frame[i].Time <= currentTime <= Frame[i+1].Time
            local foundFrame = false
            
            -- Optimasi: Loop mulai dari index terakhir yang kita kunjungi
            for i = startIndex, #pathData - 1 do
                local frameA = pathData[i]
                local frameB = pathData[i+1]
                
                if currentTime >= frameA[1] and currentTime <= frameB[1] then
                    -- KITA BERADA DI ANTARA FRAME A DAN B
                    
                    -- Hitung Alpha (Persentase progress antara A dan B)
                    -- Rumus: (WaktuSekarang - WaktuA) / (WaktuB - WaktuA)
                    local timeDiff = frameB[1] - frameA[1]
                    local alpha = (currentTime - frameA[1]) / timeDiff
                    
                    local cfA = DecodeCFrame(frameA[2])
                    local cfB = DecodeCFrame(frameB[2])
                    
                    -- Lakukan Lerp (Linear Interpolation) agar halus
                    Root.CFrame = cfA:Lerp(cfB, alpha)
                    
                    startIndex = i -- Update index agar loop berikutnya lebih cepat
                    foundFrame = true
                    break
                end
            end
            
            -- Jika waktu sudah melebihi frame terakhir, stop.
            if not foundFrame and currentTime > pathData[#pathData][1] then
                Recorder.IsPlaying = false
                Root.Anchored = false
                if LocalPlayer.Character:FindFirstChild("Animate") then
                    LocalPlayer.Character.Animate.Disabled = false
                end
                if Recorder.Connection then Recorder.Connection:Disconnect() end
                Services.StarterGui:SetCore("SendNotification", {Title="Finished", Text="Auto Walk Complete"})
            end
        end)
    end

    local function StopPlaying()
        if Recorder.Connection then Recorder.Connection:Disconnect() end
        Recorder.IsPlaying = false
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
            if LocalPlayer.Character:FindFirstChild("Animate") then
                LocalPlayer.Character.Animate.Disabled = false
            end
        end
    end

    -- ===========================
    -- UI ELEMENTS
    -- ===========================
    
    local PathNameInput = ""
    
    WalkTab:Input("Path Name (e.g., Tower1)", function(text)
        PathNameInput = text
    end)
    
    WalkTab:Button("Start Recording", Theme.Button, function()
        StartRecording()
    end)
    
    WalkTab:Button("Stop & Save", Theme.Confirm, function()
        if PathNameInput == "" then
            PathNameInput = "AutoSave_"..math.random(1000)
        end
        StopRecording(PathNameInput)
        -- Refresh dropdown list later if needed
    end)
    
    WalkTab:Label("Playback Controls")
    
    -- File List Dropdown Logic
    local SelectedFile = nil
    local Dropdown = nil -- Placeholder if UI lib supports dropdown update
    
    local function GetFiles()
        local files = listfiles(FolderName)
        local names = {}
        for _, v in pairs(files) do
            table.insert(names, v:match("([^/]+)%.json$"))
        end
        return names
    end

    -- Simple Dropdown implementation (Adjust based on your UI Lib capabilities)
    -- Asumsi UI Library kamu belum punya fungsi update dropdown dinamis, kita buat manual input atau refresh button
    
    WalkTab:Input("Load File Name", function(text)
        SelectedFile = text
    end)

    local ToggleWalk = WalkTab:Toggle("Enable Auto Walk", function(state)
        if state then
            if not SelectedFile then
                Services.StarterGui:SetCore("SendNotification", {Title="Error", Text="Enter file name first!"})
                return
            end
            
            local path = FolderName .. "/" .. SelectedFile .. ".json"
            if isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                Services.StarterGui:SetCore("SendNotification", {Title="Loading", Text="Points: " .. #data})
                PlayPath(data)
            else
                Services.StarterGui:SetCore("SendNotification", {Title="Error", Text="File not found!"})
            end
        else
            StopPlaying()
        end
    end)

    Config.OnReset.Event:Connect(function()
        StopPlaying()
        if Recorder.Connection then Recorder.Connection:Disconnect() end
    end)
end
