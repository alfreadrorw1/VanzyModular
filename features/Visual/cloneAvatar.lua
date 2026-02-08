-- features/Visual/cloneAvatar.lua
-- Fitur Clone Avatar untuk Vanzyxxx Modular
-- Author: FayintXCode (Fixed by Gemini)
-- Version: 4.0.0 (Purple Theme + Mobile Drag Fix)

return function(UI, Services, Config, Theme)
    -- [[ SERVICES ]]
    local Players = Services.Players
    local UserInputService = Services.UserInputService
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    local Debris = game:GetService("Debris")
    local TweenService = Services.TweenService
    local RunService = Services.RunService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- [[ THEME CONFIGURATION (PURPLE VERSION) ]]
    local CloneConfig = {
        Theme = {
            -- Warna Utama: Ungu Premium
            Accent = Color3.fromRGB(160, 32, 240),      -- Ungu Terang (Tombol/List)
            Background = Color3.fromRGB(20, 15, 30),    -- Ungu Gelap (Background)
            ItemBG = Color3.fromRGB(35, 25, 45),        -- Ungu Abu (Input Box)
            Text = Color3.fromRGB(255, 255, 255),       -- Putih
            SubText = Color3.fromRGB(180, 160, 200),    -- Ungu Muda Pudar
            Random = Color3.fromRGB(255, 50, 100),      -- Merah/Pink (Tombol Reset/Random)
        }
    }
    
    local State = {
        OriginalDescription = nil,
        WidgetEnabled = false,
        IsGuiOpen = false
    }

    -- [[ UI VARIABLES ]]
    local ScreenGui = nil
    local MiniButton = nil
    local MainFrame = nil

    -- [[ HELPER FUNCTIONS ]]
    local function Notify(title, text)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = 2,
                Icon = "rbxassetid://135254" -- Optional Icon
            })
        end)
    end

    -- [[ MOBILE DRAGGABLE SYSTEM (FIXED) ]]
    -- Logika drag ini lebih stabil untuk executor mobile seperti Delta
    local function MakeDraggable(guiObject)
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil

        guiObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = guiObject.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        guiObject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                guiObject.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        -- Aktifkan interaksi touch
        guiObject.Active = true
        guiObject.Selectable = true
    end

    -- [[ EXPLOSION EFFECT ]]
    local function PlayExplosionEffect()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Suara
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://142070127"
        sound.Volume = 2
        sound.Parent = root
        sound:Play()
        Debris:AddItem(sound, 3)

        -- Visual Ledakan
        local explosion = Instance.new("Explosion")
        explosion.Position = root.Position
        explosion.BlastPressure = 0
        explosion.BlastRadius = 12
        explosion.ExplosionType = Enum.ExplosionType.NoCraters
        explosion.Parent = root

        -- Api Ungu (Biar sesuai tema)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Color = Color3.fromRGB(170, 0, 255) -- Api Ungu
                fire.SecondaryColor = Color3.fromRGB(255, 100, 255)
                fire.Size = 4
                fire.Heat = 10
                fire.Parent = part
                Debris:AddItem(fire, 2)
            end
        end
    end

    -- [[ CLONE LOGIC ]]
    local function ApplyAvatar(userId)
        userId = tonumber(userId)
        if not userId then return end

        task.spawn(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if not hum then return end

            if not State.OriginalDescription then
                State.OriginalDescription = hum:GetAppliedDescription()
            end

            Notify("Clone Avatar", "Sedang mengambil data...")

            local success, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)

            if success and desc then
                PlayExplosionEffect()
                task.wait(0.15)
                hum:ApplyDescription(desc)
                Notify("Success", "Avatar berhasil diubah!")
            else
                Notify("Error", "Gagal load avatar. ID Invalid?")
            end
        end)
    end

    local function ResetAvatar()
        if State.OriginalDescription and LocalPlayer.Character then
            PlayExplosionEffect()
            task.wait(0.15)
            LocalPlayer.Character.Humanoid:ApplyDescription(State.OriginalDescription)
            Notify("Reset", "Avatar dikembalikan.")
        end
    end

    -- [[ UI CONSTRUCTION ]]
    local function CreateUI()
        if ScreenGui then ScreenGui:Destroy() end

        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VanzyPurpleCloneUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.DisplayOrder = 9999 -- Pastikan di atas segalanya
        
        -- Parent ke CoreGui atau PlayerGui
        if gethui then 
            ScreenGui.Parent = gethui() 
        elseif game:GetService("CoreGui") then
            ScreenGui.Parent = game:GetService("CoreGui")
        else
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end

        -- 1. FLOATING WIDGET (BULAT)
        MiniButton = Instance.new("TextButton", ScreenGui)
        MiniButton.Name = "WidgetButton"
        MiniButton.Size = UDim2.new(0, 50, 0, 50)
        MiniButton.Position = UDim2.new(0.85, 0, 0.4, 0) -- Posisi Default Kanan
        MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
        MiniButton.Text = "👥"
        MiniButton.TextSize = 25
        MiniButton.TextColor3 = CloneConfig.Theme.Accent
        MiniButton.AutoButtonColor = true
        MiniButton.BorderSizePixel = 0
        MiniButton.Visible = false -- Dimulai sembunyi
        MiniButton.ZIndex = 10

        local MiniStroke = Instance.new("UIStroke", MiniButton)
        MiniStroke.Color = CloneConfig.Theme.Accent
        MiniStroke.Thickness = 2.5
        MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local MiniCorner = Instance.new("UICorner", MiniButton)
        MiniCorner.CornerRadius = UDim.new(1, 0) -- Bulat Sempurna

        -- Pasang Drag ke Widget
        MakeDraggable(MiniButton)

        -- 2. MAIN PANEL (MENU UTAMA)
        MainFrame = Instance.new("Frame", ScreenGui)
        MainFrame.Name = "MainPanel"
        MainFrame.Size = UDim2.new(0, 300, 0, 350)
        MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175) -- Center
        MainFrame.BackgroundColor3 = CloneConfig.Theme.Background
        MainFrame.Visible = false
        MainFrame.ClipsDescendants = true
        MainFrame.ZIndex = 5

        local MainStroke = Instance.new("UIStroke", MainFrame)
        MainStroke.Color = CloneConfig.Theme.Accent
        MainStroke.Thickness = 2

        local MainCorner = Instance.new("UICorner", MainFrame)
        MainCorner.CornerRadius = UDim.new(0, 12)

        -- Pasang Drag ke Panel Utama
        MakeDraggable(MainFrame)

        -- HEADER
        local Header = Instance.new("Frame", MainFrame)
        Header.Size = UDim2.new(1, 0, 0, 45)
        Header.BackgroundTransparency = 1
        Header.ZIndex = 6

        local Title = Instance.new("TextLabel", Header)
        Title.Size = UDim2.new(1, -40, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "CLONE AVATAR"
        Title.Font = Enum.Font.GothamBlack
        Title.TextColor3 = CloneConfig.Theme.Accent -- Judul Ungu
        Title.TextSize = 18
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 6

        local CloseBtn = Instance.new("TextButton", Header)
        CloseBtn.Size = UDim2.new(0, 30, 0, 30)
        CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.Text = "×"
        CloseBtn.TextColor3 = CloneConfig.Theme.SubText
        CloseBtn.TextSize = 24
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.ZIndex = 7

        -- CONTENT AREA
        local Content = Instance.new("Frame", MainFrame)
        Content.Size = UDim2.new(1, -30, 1, -55)
        Content.Position = UDim2.new(0, 15, 0, 50)
        Content.BackgroundTransparency = 1
        Content.ZIndex = 6

        -- INPUT
        local InputBox = Instance.new("TextBox", Content)
        InputBox.Size = UDim2.new(1, 0, 0, 45)
        InputBox.BackgroundColor3 = CloneConfig.Theme.ItemBG
        InputBox.Text = ""
        InputBox.PlaceholderText = "Username / User ID"
        InputBox.PlaceholderColor3 = CloneConfig.Theme.SubText
        InputBox.TextColor3 = CloneConfig.Theme.Text
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 14
        InputBox.ZIndex = 7

        local InputCorner = Instance.new("UICorner", InputBox)
        InputCorner.CornerRadius = UDim.new(0, 8)
        
        local InputStroke = Instance.new("UIStroke", InputBox)
        InputStroke.Color = CloneConfig.Theme.Accent
        InputStroke.Thickness = 1
        InputStroke.Transparency = 0.5

        -- BUTTONS
        local CopyBtn = Instance.new("TextButton", Content)
        CopyBtn.Size = UDim2.new(0.48, 0, 0, 40)
        CopyBtn.Position = UDim2.new(0, 0, 0, 60)
        CopyBtn.BackgroundColor3 = CloneConfig.Theme.Accent -- Tombol Ungu
        CopyBtn.Text = "COPY"
        CopyBtn.Font = Enum.Font.GothamBlack
        CopyBtn.TextColor3 = Color3.white
        CopyBtn.TextSize = 14
        CopyBtn.ZIndex = 7
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)

        local RandomBtn = Instance.new("TextButton", Content)
        RandomBtn.Size = UDim2.new(0.48, 0, 0, 40)
        RandomBtn.Position = UDim2.new(0.52, 0, 0, 60)
        RandomBtn.BackgroundColor3 = CloneConfig.Theme.Random -- Tombol Pink/Merah
        RandomBtn.Text = "RANDOM"
        RandomBtn.Font = Enum.Font.GothamBlack
        RandomBtn.TextColor3 = Color3.white
        RandomBtn.TextSize = 14
        RandomBtn.ZIndex = 7
        Instance.new("UICorner", RandomBtn).CornerRadius = UDim.new(0, 8)

        local ResetBtn = Instance.new("TextButton", Content)
        ResetBtn.Size = UDim2.new(1, 0, 0, 40)
        ResetBtn.Position = UDim2.new(0, 0, 0, 110)
        ResetBtn.BackgroundColor3 = CloneConfig.Theme.ItemBG
        ResetBtn.Text = "RESET TO ORIGINAL"
        ResetBtn.Font = Enum.Font.GothamBold
        ResetBtn.TextColor3 = CloneConfig.Theme.SubText
        ResetBtn.TextSize = 12
        ResetBtn.ZIndex = 7
        Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

        -- INTERACTION LOGIC (FIXED)
        
        -- Logic Toggle Menu
        MiniButton.MouseButton1Click:Connect(function()
            State.IsGuiOpen = not State.IsGuiOpen
            MainFrame.Visible = State.IsGuiOpen
            
            -- Efek Visual saat dibuka
            if State.IsGuiOpen then
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Accent
                MiniButton.TextColor3 = Color3.white
            else
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
                MiniButton.TextColor3 = CloneConfig.Theme.Accent
            end
        end)

        -- Logic Tutup Menu
        CloseBtn.MouseButton1Click:Connect(function()
            State.IsGuiOpen = false
            MainFrame.Visible = false
            MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
            MiniButton.TextColor3 = CloneConfig.Theme.Accent
        end)

        -- Logic Copy
        CopyBtn.MouseButton1Click:Connect(function()
            local txt = InputBox.Text
            if tonumber(txt) then
                ApplyAvatar(tonumber(txt))
            else
                local s, id = pcall(function() return Players:GetUserIdFromNameAsync(txt) end)
                if s then ApplyAvatar(id) else Notify("Error", "User tidak ditemukan!") end
            end
        end)

        -- Logic Random
        RandomBtn.MouseButton1Click:Connect(function()
            local list = Players:GetPlayers()
            if #list > 1 then
                local t = list[math.random(1, #list)]
                if t == LocalPlayer then t = list[math.random(1, #list)] end
                InputBox.Text = t.Name
                ApplyAvatar(t.UserId)
            else
                Notify("Info", "Tidak ada player lain.")
            end
        end)

        -- Logic Reset
        ResetBtn.MouseButton1Click:Connect(ResetAvatar)
    end

    -- [[ VANZYXXX MENU INTEGRATION ]]
    
    local CosmeticsTab = UI:Tab("Cosmetics")
    
    CosmeticsTab:Label("Clone Avatar (Purple Edition)")
    
    -- TOGGLE YANG DIMINTA
    CosmeticsTab:Toggle("Show Widget 👥", function(state)
        State.WidgetEnabled = state
        
        if state then
            -- Buat GUI jika belum ada
            if not ScreenGui then CreateUI() end
            
            -- Munculkan Widget
            if MiniButton then MiniButton.Visible = true end
            Notify("Clone UI", "Widget Aktif! Geser & Klik.")
        else
            -- Sembunyikan Widget & Menu
            if MiniButton then MiniButton.Visible = false end
            if MainFrame then MainFrame.Visible = false end
            State.IsGuiOpen = false
        end
    end)

    CosmeticsTab:Label("Controls")
    CosmeticsTab:Button("Force Reset Avatar", CloneConfig.Theme.Random, function()
        ResetAvatar()
    end)

    -- Auto cleanup
    Config.OnReset.Event:Connect(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)

    return CosmeticsTab
end