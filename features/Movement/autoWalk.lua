--[[
    VANZYXXX ADVANCED RECORD & REPLAY SYSTEM
    Author: Alfreadrorw1
    Type: LocalScript / Module
    
    Fitur:
    - Smooth CFrame Lerp Replay
    - Checkpoint Aware Recording
    - Folder Based Saving (VanzyData/Map/CP)
    - Draggable Mini UI
]]

local ReplaySystem = {}

-- // SERVICES //
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- // CONFIGURATION //
local Config = {
    Folder = "VanzyData",
    RecordInterval = 0, -- 0 = Record every frame (Smooth)
    PlaybackSpeed = 1,
    ShowPath = true, -- Visualisasi path (garis merah)
    UI_Color = Color3.fromRGB(160, 32, 240) -- Tema Ungu Premium
}

-- // STATE MANAGEMENT //
local State = {
    IsRecording = false,
    IsPlaying = false,
    IsPaused = false,
    CurrentFrame = 1,
    RecordedData = {},
    CurrentMap = "UnknownMap",
    CurrentCP = "CP1",
    TotalTime = 0
}

-- // FILE SYSTEM (Executor Check) //
local FileSystem = {}
function FileSystem.Init()
    if not isfolder then return warn("Executor not supported for Saving!") end
    if not isfolder(Config.Folder) then makefolder(Config.Folder) end
end

function FileSystem.Save(map, cp, data)
    if not isfolder then return end
    local mapPath = Config.Folder .. "/" .. map
    if not isfolder(mapPath) then makefolder(mapPath) end
    
    local filePath = mapPath .. "/" .. cp .. ".json"
    local encoded = Services.HttpService:JSONEncode(data)
    writefile(filePath, encoded)
    print("Saved to: " .. filePath)
end

function FileSystem.Load(map, cp)
    if not isfile then return nil end
    local path = Config.Folder .. "/" .. map .. "/" .. cp .. ".json"
    if isfile(path) then
        return Services.HttpService:JSONDecode(readfile(path))
    end
    return nil
end

-- // CORE LOGIC //
local Core = {}
local RecordConnection = nil
local PlayConnection = nil

-- Deteksi Map & Checkpoint (Sederhana: Cari Spawn terdekat)
function Core.DetectLocation()
    State.CurrentMap = tostring(game.PlaceId) -- Bisa diganti nama map asli jika ada di GUI game
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Cari checkpoint terdekat (Bisa disesuaikan dengan nama object di game)
    local closest, dist = "Start", math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if (v:IsA("SpawnLocation") or v.Name:lower():find("checkpoint") or v.Name:lower():find("stage")) and v:IsA("BasePart") then
            local mag = (root.Position - v.Position).Magnitude
            if mag < dist then
                dist = mag
                closest = v.Name
            end
        end
    end
    State.CurrentCP = closest
    return State.CurrentMap, State.CurrentCP
end

-- RECORDING
function Core.StartRecord()
    if State.IsPlaying then return end
    Core.DetectLocation()
    
    State.IsRecording = true
    State.RecordedData = {}
    State.TotalTime = 0
    
    local startTime = tick()
    
    -- Cleanup koneksi lama
    if RecordConnection then RecordConnection:Disconnect() end
    
    RecordConnection = Services.RunService.Heartbeat:Connect(function(dt)
        if not State.IsRecording then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local root = char.HumanoidRootPart
        
        -- Optimasi: Simpan data relatif terhadap waktu
        table.insert(State.RecordedData, {
            CF = {root.CFrame:GetComponents()}, -- Simpan komponen CFrame (X,Y,Z, R00...)
            DT = dt
        })
    end)
end

function Core.StopRecord()
    State.IsRecording = false
    if RecordConnection then RecordConnection:Disconnect() end
end

-- REPLAY (SMOOTH LERP)
function Core.Play(data)
    if State.IsRecording then return end
    if not data or #data < 2 then return warn("No Data / Data too short") end
    
    State.IsPlaying = true
    State.IsPaused = false
    State.CurrentFrame = 1
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    
    -- Physics Setup
    hum.PlatformStand = true -- Matikan animasi/fisika bawaan agar tidak bentrok
    root.Anchored = true -- Anchor agar teleport smooth
    
    if PlayConnection then PlayConnection:Disconnect() end
    
    local frameTime = 0
    
    PlayConnection = Services.RunService.RenderStepped:Connect(function(dt)
        if not State.IsPlaying then 
            if PlayConnection then PlayConnection:Disconnect() end
            -- Restore Physics
            if hum then hum.PlatformStand = false end
            if root then root.Anchored = false end
            return 
        end
        
        if State.IsPaused then return end
        
        -- Logic Frame Advance
        local currentData = data[State.CurrentFrame]
        local nextData = data[State.CurrentFrame + 1]
        
        if not nextData then
            -- Selesai
            Core.StopPlay()
            return
        end
        
        -- Akumulasi waktu real (untuk speed hack atau slow mo)
        frameTime = frameTime + (dt * Config.PlaybackSpeed)
        
        -- Jika waktu frame sudah lewat, pindah ke index array berikutnya
        while frameTime >= currentData.DT do
            frameTime = frameTime - currentData.DT
            State.CurrentFrame = State.CurrentFrame + 1
            currentData = data[State.CurrentFrame]
            nextData = data[State.CurrentFrame + 1]
            
            if not nextData then
                Core.StopPlay()
                return
            end
        end
        
        -- INTERPOLASI (LERP)
        -- Menghitung persentase perjalanan antar 2 frame (Alpha)
        local alpha = frameTime / currentData.DT
        
        local cf1 = CFrame.new(unpack(currentData.CF))
        local cf2 = CFrame.new(unpack(nextData.CF))
        
        -- Gerakkan karakter
        root.CFrame = cf1:Lerp(cf2, alpha)
    end)
end

function Core.StopPlay()
    State.IsPlaying = false
    State.IsPaused = false
    State.CurrentFrame = 1
    
    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
        if char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.Anchored = false end
    end
end

function Core.TogglePause()
    State.IsPaused = not State.IsPaused
end

-- // UI CONSTRUCTION (MINI DRAGGABLE) //
function ReplaySystem.CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VanzyRecorder"
    ScreenGui.Parent = Services.CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 160, 0, 200) -- Ukuran Mini
    MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner", MainFrame)
    Corner.CornerRadius = UDim.new(0, 8)
    
    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Config.UI_Color
    Stroke.Thickness = 2
    
    -- Header (Drag Area)
    local Header = Instance.new("TextLabel", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 25)
    Header.BackgroundTransparency = 1
    Header.Text = "RECORDER"
    Header.TextColor3 = Config.UI_Color
    Header.Font = Enum.Font.GothamBlack
    Header.TextSize = 14
    
    -- Status Label
    local StatusLbl = Instance.new("TextLabel", MainFrame)
    StatusLbl.Size = UDim2.new(1, 0, 0, 20)
    StatusLbl.Position = UDim2.new(0, 0, 0, 25)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text = "IDLE"
    StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLbl.Font = Enum.Font.Gotham
    StatusLbl.TextSize = 10
    
    -- CP Info
    local CPLbl = Instance.new("TextLabel", MainFrame)
    CPLbl.Size = UDim2.new(1, 0, 0, 15)
    CPLbl.Position = UDim2.new(0, 0, 0, 40)
    CPLbl.BackgroundTransparency = 1
    CPLbl.Text = "Map: ... | CP: ..."
    CPLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
    CPLbl.TextSize = 9
    
    -- Container Tombol
    local BtnContainer = Instance.new("Frame", MainFrame)
    BtnContainer.Size = UDim2.new(1, -10, 1, -60)
    BtnContainer.Position = UDim2.new(0, 5, 0, 55)
    BtnContainer.BackgroundTransparency = 1
    
    local Layout = Instance.new("UIGridLayout", BtnContainer)
    Layout.CellSize = UDim2.new(0.48, 0, 0, 30)
    Layout.CellPadding = UDim2.new(0.04, 0, 0.04, 0)
    
    -- Helper buat bikin tombol
    local function CreateBtn(text, color, func)
        local btn = Instance.new("TextButton", BtnContainer)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(func)
        return btn
    end
    
    -- Tombol-Tombol
    local RecBtn = CreateBtn("REC", Color3.fromRGB(200, 50, 50), function()
        if State.IsRecording then
            Core.StopRecord()
            StatusLbl.Text = "STOPPED"
        else
            Core.StartRecord()
            StatusLbl.Text = "RECORDING..."
            StatusLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
            -- Update UI loop
            spawn(function()
                while State.IsRecording do
                    CPLbl.Text = State.CurrentCP
                    task.wait(0.5)
                end
            end)
        end
    end)
    
    local PlayBtn = CreateBtn("PLAY", Color3.fromRGB(50, 200, 50), function()
        if State.IsRecording then return end
        if #State.RecordedData == 0 then return warn("No Data") end
        
        if State.IsPlaying then
            Core.StopPlay()
            StatusLbl.Text = "STOPPED"
        else
            StatusLbl.Text = "PLAYING..."
            StatusLbl.TextColor3 = Color3.fromRGB(50, 200, 50)
            Core.Play(State.RecordedData)
        end
    end)
    
    local PauseBtn = CreateBtn("PAUSE", Color3.fromRGB(200, 150, 50), function()
        Core.TogglePause()
        StatusLbl.Text = State.IsPaused and "PAUSED" or "PLAYING..."
    end)
    
    local SaveBtn = CreateBtn("SAVE", Color3.fromRGB(50, 100, 200), function()
        if #State.RecordedData > 0 then
            local map, cp = Core.DetectLocation()
            FileSystem.Save(map, cp, State.RecordedData)
            StatusLbl.Text = "SAVED: " .. cp
        end
    end)
    
    local LoadBtn = CreateBtn("LOAD LAST", Color3.fromRGB(100, 50, 150), function()
        local map, cp = Core.DetectLocation()
        local data = FileSystem.Load(map, cp)
        if data then
            State.RecordedData = data
            StatusLbl.Text = "LOADED: " .. cp
        else
            StatusLbl.Text = "NO FILE"
        end
    end)
    
    -- Toggle UI (Minimize)
    local MiniBtn = Instance.new("TextButton", MainFrame)
    MiniBtn.Size = UDim2.new(0, 20, 0, 20)
    MiniBtn.Position = UDim2.new(1, -25, 0, 2)
    MiniBtn.BackgroundTransparency = 1
    MiniBtn.Text = "-"
    MiniBtn.TextColor3 = Config.UI_Color
    MiniBtn.TextSize = 18
    
    local Expanded = true
    MiniBtn.MouseButton1Click:Connect(function()
        Expanded = not Expanded
        if Expanded then
            MainFrame:TweenSize(UDim2.new(0, 160, 0, 200), "Out", "Quad", 0.3)
            BtnContainer.Visible = true
        else
            MainFrame:TweenSize(UDim2.new(0, 160, 0, 30), "Out", "Quad", 0.3)
            BtnContainer.Visible = false
        end
    end)

    -- DRAGGABLE LOGIC
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- // INITIALIZATION //
FileSystem.Init()
ReplaySystem.CreateUI()

print("[Vanzyxxx] Modular Recorder Loaded")
return ReplaySystem