-- features/Visual/cloneAvatar.lua
-- Fitur Clone Avatar untuk Vanzyxxx Modular
-- Author: FayintXCode (Updated by Gemini)
-- Version: 2.0.0 (Explosion Effect + Mini Button)

return function(UI, Services, Config, Theme)
    -- [[ SERVICES ]]
    local Players = Services.Players
    local UserInputService = Services.UserInputService
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    local RunService = Services.RunService
    local Debris = game:GetService("Debris")
    
    local LocalPlayer = Players.LocalPlayer
    
    -- [[ CONFIGURATION ]]
    local CloneConfig = {
        FileName = "VanzyAvatarFavorites.json",
        Theme = {
            Background = Color3.fromRGB(15, 15, 15),
            ItemBG = Color3.fromRGB(25, 25, 25),
            Accent = Color3.fromRGB(255, 40, 70), 
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(150, 150, 150),
            Random = Color3.fromRGB(200, 40, 60)
        }
    }
    
    local State = {
        OriginalDescription = nil,
        Favorites = {},
        IsGuiOpen = false
    }

    -- [[ FILE SYSTEM ]]
    local function LoadFavorites()
        if isfile and isfile(CloneConfig.FileName) then
            local success, result = pcall(function()
                return HttpService:JSONDecode(readfile(CloneConfig.FileName))
            end)
            if success and type(result) == "table" then State.Favorites = result end
        end
    end

    local function SaveFavorites()
        if writefile then
            writefile(CloneConfig.FileName, HttpService:JSONEncode(State.Favorites))
        end
    end
    LoadFavorites()

    -- [[ HELPER FUNCTIONS ]]
    local function Notify(title, text)
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end

    -- [[ EFFECT SYSTEM ]]
    local function PlayExplosionEffect()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- 1. Suara Ledakan
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://142070127" -- Explosion Sound
        sound.Volume = 2
        sound.Parent = root
        sound:Play()
        Debris:AddItem(sound, 3)

        -- 2. Ledakan Visual (Safe, tidak membunuh)
        local explosion = Instance.new("Explosion")
        explosion.Position = root.Position
        explosion.BlastPressure = 0 -- 0 Pressure = Tidak ada damage/dorongan
        explosion.BlastRadius = 15
        explosion.ExplosionType = Enum.ExplosionType.NoCraters
        explosion.Parent = root

        -- 3. Efek Api di Badan
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Color = Color3.fromRGB(255, 100, 50)
                fire.SecondaryColor = Color3.fromRGB(255, 255, 0)
                fire.Size = 5
                fire.Heat = 15
                fire.Parent = part
                Debris:AddItem(fire, 2) -- Api hilang setelah 2 detik
            end
        end
    end

    -- [[ CLONE LOGIC ]]
    -- Simpan avatar asli
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            State.OriginalDescription = LocalPlayer.Character.Humanoid:GetAppliedDescription()
        end
    end)

    local function ApplyAvatar(userId)
        userId = tonumber(userId)
        if not userId then return end

        task.spawn(function()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not humanoid then return end

            -- Simpan original jika belum ada
            if not State.OriginalDescription then
                State.OriginalDescription = humanoid:GetAppliedDescription()
            end

            Notify("Clone Avatar", "Mengambil data avatar...")

            -- Ambil Deskripsi Humanoid Target
            local success, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)

            if success and desc then
                -- Play Effect DULU sebelum ganti
                PlayExplosionEffect()
                task.wait(0.2) -- Delay sedikit biar pas sama ledakan

                -- Terapkan Avatar
                pcall(function()
                    humanoid:ApplyDescription(desc)
                end)
                
                Notify("Success", "Avatar berhasil di-clone!")
            else
                Notify("Error", "Gagal mengambil data. ID salah/User terbanned?")
            end
        end)
    end

    local function ResetAvatar()
        if State.OriginalDescription and LocalPlayer.Character then
            PlayExplosionEffect() -- Efek ledakan juga saat reset
            task.wait(0.2)
            LocalPlayer.Character.Humanoid:ApplyDescription(State.OriginalDescription)
            Notify("Reset", "Kembali ke avatar asli.")
        end
    end

    -- [[ UI CREATION ]]
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VanzyCloneUI_V2"
    if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = Services.CoreGui end

    -- Variables untuk UI Referensi
    local MainFrame = nil
    
    -- Function bikin Draggable
    local function MakeDraggable(frame)
        local dragging, dragInput, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- 1. MINI MENU (Floating Button)
    local MiniButton = Instance.new("TextButton", ScreenGui)
    MiniButton.Name = "MiniMenuToggle"
    MiniButton.Size = UDim2.new(0, 50, 0, 50)
    MiniButton.Position = UDim2.new(0.9, -60, 0.4, 0) -- Posisi awal di kanan layar
    MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
    MiniButton.Text = "👥" -- Logo Orang
    MiniButton.TextSize = 25
    MiniButton.TextColor3 = CloneConfig.Theme.Accent
    MiniButton.AutoButtonColor = true
    
    local MiniCorner = Instance.new("UICorner", MiniButton)
    MiniCorner.CornerRadius = UDim.new(1, 0) -- Bulat sempurna
    
    local MiniStroke = Instance.new("UIStroke", MiniButton)
    MiniStroke.Color = CloneConfig.Theme.Accent
    MiniStroke.Thickness = 2
    
    MakeDraggable(MiniButton)

    -- 2. MAIN FRAME (Menu Utama)
    MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    MainFrame.BackgroundColor3 = CloneConfig.Theme.Background
    MainFrame.Visible = false -- Hidden by default
    MainFrame.ClipsDescendants = true
    
    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 16)
    
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = CloneConfig.Theme.Accent
    MainStroke.Thickness = 2
    
    MakeDraggable(MainFrame)

    -- Toggle Logic
    MiniButton.MouseButton1Click:Connect(function()
        State.IsGuiOpen = not State.IsGuiOpen
        MainFrame.Visible = State.IsGuiOpen
        
        -- Animasi tombol
        Services.TweenService:Create(MiniButton, TweenInfo.new(0.2), {
            BackgroundColor3 = State.IsGuiOpen and CloneConfig.Theme.Accent or CloneConfig.Theme.Background,
            TextColor3 = State.IsGuiOpen and Color3.new(1,1,1) or CloneConfig.Theme.Accent
        }):Play()
    end)

    -- [[ ISI MAIN FRAME (Sama seperti sebelumnya dengan perbaikan) ]]
    -- Header
    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundTransparency = 1
    
    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -40, 0, 25)
    Title.Position = UDim2.new(0, 15, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "COPY AVATAR"
    Title.Font = Enum.Font.GothamBlack
    Title.TextColor3 = CloneConfig.Theme.Text
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local SubTitle = Instance.new("TextLabel", Header)
    SubTitle.Size = UDim2.new(1, -40, 0, 15)
    SubTitle.Position = UDim2.new(0, 15, 0, 28)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "by FayintXCode"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextColor3 = CloneConfig.Theme.SubText
    SubTitle.TextSize = 12
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left

    local CloseMain = Instance.new("TextButton", Header)
    CloseMain.Size = UDim2.new(0, 25, 0, 25)
    CloseMain.Position = UDim2.new(1, -35, 0, 12)
    CloseMain.BackgroundTransparency = 1
    CloseMain.Text = "×"
    CloseMain.TextColor3 = Color3.white
    CloseMain.TextSize = 24
    CloseMain.MouseButton1Click:Connect(function()
        State.IsGuiOpen = false
        MainFrame.Visible = false
        Services.TweenService:Create(MiniButton, TweenInfo.new(0.2), {
            BackgroundColor3 = CloneConfig.Theme.Background,
            TextColor3 = CloneConfig.Theme.Accent
        }):Play()
    end)

    -- Input & Buttons Area
    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -30, 1, -60)
    Content.Position = UDim2.new(0, 15, 0, 60)
    Content.BackgroundTransparency = 1

    local InputBox = Instance.new("TextBox", Content)
    InputBox.Size = UDim2.new(1, 0, 0, 45)
    InputBox.BackgroundColor3 = CloneConfig.Theme.ItemBG
    InputBox.Text = ""
    InputBox.PlaceholderText = "Username / User ID..."
    InputBox.TextColor3 = Color3.white
    InputBox.Font = Enum.Font.GothamBold
    InputBox.TextSize = 14
    
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 8)

    local CopyBtn = Instance.new("TextButton", Content)
    CopyBtn.Size = UDim2.new(0.48, 0, 0, 40)
    CopyBtn.Position = UDim2.new(0, 0, 0, 55)
    CopyBtn.BackgroundColor3 = CloneConfig.Theme.Accent
    CopyBtn.Text = "✅ COPY"
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextColor3 = Color3.white
    CopyBtn.TextSize = 14
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)

    local RandomBtn = Instance.new("TextButton", Content)
    RandomBtn.Size = UDim2.new(0.48, 0, 0, 40)
    RandomBtn.Position = UDim2.new(0.52, 0, 0, 55)
    RandomBtn.BackgroundColor3 = CloneConfig.Theme.Random
    RandomBtn.Text = "🎲 RANDOM"
    RandomBtn.Font = Enum.Font.GothamBold
    RandomBtn.TextColor3 = Color3.white
    RandomBtn.TextSize = 14
    Instance.new("UICorner", RandomBtn).CornerRadius = UDim.new(0, 8)

    local ResetBtn = Instance.new("TextButton", Content)
    ResetBtn.Size = UDim2.new(1, 0, 0, 40)
    ResetBtn.Position = UDim2.new(0, 0, 0, 105)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ResetBtn.Text = "✖ RESET AVATAR"
    ResetBtn.Font = Enum.Font.GothamBold
    ResetBtn.TextColor3 = Color3.white
    ResetBtn.TextSize = 14
    Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

    -- Logic Button
    CopyBtn.MouseButton1Click:Connect(function()
        local txt = InputBox.Text
        if tonumber(txt) then
            ApplyAvatar(tonumber(txt))
        else
            local succ, id = pcall(function() return Players:GetUserIdFromNameAsync(txt) end)
            if succ then ApplyAvatar(id) else Notify("Error", "Username tidak ditemukan!") end
        end
    end)

    RandomBtn.MouseButton1Click:Connect(function()
        local list = Players:GetPlayers()
        if #list > 1 then
            local target = list[math.random(1, #list)]
            if target == LocalPlayer then target = list[math.random(1, #list)] end
            InputBox.Text = target.Name
            ApplyAvatar(target.UserId)
        else
            Notify("Info", "Hanya kamu di server ini.")
        end
    end)

    ResetBtn.MouseButton1Click:Connect(ResetAvatar)

    -- [[ INTEGRASI KE MODULAR ]]
    -- Return interface agar Vanzy loader tidak error, tapi UI kita sudah jalan sendiri
    local Interface = {}
    function Interface:Destroy()
        ScreenGui:Destroy()
    end
    
    Notify("Vanzy Modular", "Clone Avatar UI Loaded! Cek tombol bulat 👥")
    
    return Interface
end
