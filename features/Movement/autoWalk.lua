--[[
    AUTO WALK SYSTEM - RECORD & REPLAY
    Made for Roblox Mobile/PC Executors
    Features: 
    - Smooth CFrame Recording
    - Play/Pause/Resume
    - Simple JSON Save System
    - Segmented Checkpoints (CP1, CP2...)
]]

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui")
}

local LocalPlayer = Services.Players.LocalPlayer
local FileName = "SimpleRecordData.json"

-- >> VARIABLES << --
local State = {
    Recording = false,
    Playing = false,
    Paused = false,
    CurrentFrame = 0, -- Untuk Replay Index
    Data = {}, -- Data Sementara saat Record
}

local SavedMaps = {} -- Cache data dari file
local CurrentMap = "Map1"
local CurrentCP = "CP1"

-- >> HELPER: CFrame Serialization (Agar bisa di-save ke JSON) << --
local function SerializeCF(cf)
    local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
    return {x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22}
end

local function DeserializeCF(t)
    return CFrame.new(table.unpack(t))
end

-- >> FILE SYSTEM (SUPER SIMPLE) << --
local function SaveToFile()
    if writefile then
        local success, err = pcall(function()
            writefile(FileName, Services.HttpService:JSONEncode(SavedMaps))
        end)
        if not success then warn("Save Error:", err) end
    end
end

local function LoadFromFile()
    if isfile and isfile(FileName) then
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(readfile(FileName))
        end)
        if success then 
            SavedMaps = result 
        else
            SavedMaps = {}
        end
    end
end

-- Load Data Awal
LoadFromFile()

-- >> UI CONSTRUCTION (MINI & DRAGGABLE) << --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWalkUI"
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = Services.CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 280)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Header (Drag)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⏺ RECORDER MINI"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12

-- Drag Logic
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
Services.UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Controls Container
local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -10, 1, -40)
Container.Position = UDim2.new(0, 5, 0, 35)
Container.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 5)

-- >> UI COMPONENTS HELPERS << --
local function CreateInput(placeholder, text)
    local Box = Instance.new("TextBox", Container)
    Box.Size = UDim2.new(1, 0, 0, 25)
    Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.PlaceholderText = placeholder
    Box.Text = text or ""
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 11
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    return Box
end

local function CreateBtn(text, color, func)
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.BackgroundColor3 = color
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(func)
    return Btn
end

local function CreateStatus(text)
    local Lbl = Instance.new("TextLabel", Container)
    Lbl.Size = UDim2.new(1, 0, 0, 15)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    Lbl.Font = Enum.Font.Code
    Lbl.TextSize = 10
    return Lbl
end

-- >> UI ELEMENTS << --
local MapInput = CreateInput("Map Name (e.g. Obby1)", CurrentMap)
local CPInput = CreateInput("CheckPoint (e.g. CP1)", CurrentCP)
local StatusLbl = CreateStatus("Status: Idle")

local RecBtn -- Forward decl needed
local PlayBtn

-- >> LOGIC SYSTEMS << --

-- 1. RECORD SYSTEM
local RecordConnection
local function StartRecord()
    if State.Playing then return end
    
    -- Reset Data
    State.Data = {}
    State.Recording = true
    StatusLbl.Text = "Status: RECORDING..."
    RecBtn.Text = "⏹ STOP RECORD"
    RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red

    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    -- Heartbeat Loop
    RecordConnection = Services.RunService.Heartbeat:Connect(function(dt)
        if not State.Recording then 
            RecordConnection:Disconnect()
            return 
        end
        -- Simpan CFrame dan DeltaTime
        -- Optional: Hanya simpan jika bergerak (Optimization), tapi kita mau 100% akurat
        table.insert(State.Data, {
            cf = SerializeCF(Root.CFrame),
            dt = dt -- Delta time agar replay speed sesuai
        })
    end)
end

local function StopRecord()
    State.Recording = false
    if RecordConnection then RecordConnection:Disconnect() end
    
    RecBtn.Text = "⏺ RECORD"
    RecBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    StatusLbl.Text = "Status: Idle (Frames: " .. #State.Data .. ")"
end

local function SaveDataToMemory()
    local map = MapInput.Text
    local cp = CPInput.Text
    if map == "" or cp == "" then return end
    
    if not SavedMaps[map] then SavedMaps[map] = {} end
    SavedMaps[map][cp] = State.Data
    
    SaveToFile() -- Write JSON
    StatusLbl.Text = "Saved: " .. map .. " > " .. cp
end

-- 2. REPLAY SYSTEM
local PlayConnection
local function StopPlay()
    State.Playing = false
    State.Paused = false
    if PlayConnection then PlayConnection:Disconnect() end
    
    -- Reset Character Physics
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if root then root.Anchored = false end
    end
    
    PlayBtn.Text = "▶ PLAY"
    PlayBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    StatusLbl.Text = "Status: Stopped"
end

local function StartPlay()
    if State.Recording then return end
    
    -- Jika sedang playing, fungsinya jadi Pause/Resume
    if State.Playing then
        State.Paused = not State.Paused
        if State.Paused then
            PlayBtn.Text = "⏯ RESUME"
            StatusLbl.Text = "Status: PAUSED"
        else
            PlayBtn.Text = "⏸ PAUSE"
            StatusLbl.Text = "Status: PLAYING"
        end
        return
    end

    -- Load Data
    local map = MapInput.Text
    local cp = CPInput.Text
    
    if not SavedMaps[map] or not SavedMaps[map][cp] then
        StatusLbl.Text = "Error: Data not found!"
        return
    end
    
    local loadedFrames = SavedMaps[map][cp]
    if #loadedFrames == 0 then return end

    State.Playing = true
    State.Paused = false
    State.CurrentFrame = 1
    
    PlayBtn.Text = "⏸ PAUSE"
    PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0) -- Orange
    StatusLbl.Text = "Status: PLAYING..."

    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if not Root or not Hum then return end

    -- Setup Physics
    Hum.PlatformStand = true -- Agar tidak diganggu physics gravity/animation bawaan
    Root.Anchored = true -- Agar movement murni dari CFrame

    -- Teleport Awal
    Root.CFrame = DeserializeCF(loadedFrames[1].cf)
    task.wait(0.1)

    -- Replay Loop
    PlayConnection = Services.RunService.Heartbeat:Connect(function()
        if not State.Playing then StopPlay(); return end
        
        if State.Paused then 
            -- Jika pause, kita diam di frame terakhir
            if loadedFrames[State.CurrentFrame] then
                Root.CFrame = DeserializeCF(loadedFrames[State.CurrentFrame].cf)
            end
            return 
        end

        -- Next Frame
        State.CurrentFrame = State.CurrentFrame + 1
        
        if State.CurrentFrame > #loadedFrames then
            StopPlay() -- Selesai
            return
        end
        
        local frameData = loadedFrames[State.CurrentFrame]
        Root.CFrame = DeserializeCF(frameData.cf)
        
        -- Kita tidak perlu task.wait(dt) karena Heartbeat sudah sync dengan frame rate.
        -- Namun jika FPS record != FPS replay, movement tetap smooth karena CFrame disimpan per-render step.
    end)
end

-- 3. BUTTONS
RecBtn = CreateBtn("⏺ RECORD", Color3.fromRGB(50, 50, 50), function()
    if State.Recording then
        StopRecord()
    else
        StartRecord()
    end
end)

local SaveBtn = CreateBtn("💾 SAVE RECORD", Color3.fromRGB(0, 100, 200), function()
    if #State.Data > 0 then
        SaveDataToMemory()
    else
        StatusLbl.Text = "No record to save!"
    end
end)

local Separator = Instance.new("Frame", Container)
Separator.Size = UDim2.new(1, 0, 0, 2); Separator.BackgroundColor3 = Color3.fromRGB(60,60,60); Separator.BorderSizePixel=0

PlayBtn = CreateBtn("▶ PLAY", Color3.fromRGB(0, 150, 100), StartPlay)

local StopBtn = CreateBtn("⏹ STOP REPLAY", Color3.fromRGB(200, 50, 50), StopPlay)

local DeleteBtn = CreateBtn("🗑 DELETE CP", Color3.fromRGB(100, 30, 30), function()
    local map = MapInput.Text
    local cp = CPInput.Text
    if SavedMaps[map] and SavedMaps[map][cp] then
        SavedMaps[map][cp] = nil
        SaveToFile()
        StatusLbl.Text = "Deleted: " .. cp
    end
end)

print("Simple Record & Replay Loaded!")