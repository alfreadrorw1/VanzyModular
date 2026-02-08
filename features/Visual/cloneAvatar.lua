-- features/Visual/cloneAvatar.lua
-- Fitur Clone Avatar untuk Vanzyxxx Modular
-- Author: FayintXCode (Super Fixed by Gemini)
-- Version: 5.0.0 (Touch Threshold Logic + Purple Theme)

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
            Accent = Color3.fromRGB(160, 32, 240),      -- Ungu Terang
            Background = Color3.fromRGB(20, 15, 30),    -- Ungu Gelap
            ItemBG = Color3.fromRGB(35, 25, 45),        -- Ungu Abu
            Text = Color3.fromRGB(255, 255, 255),       -- Putih
            SubText = Color3.fromRGB(180, 160, 200),    -- Ungu Muda
            Random = Color3.fromRGB(255, 50, 100),      -- Pink/Merah
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
                Duration = 2
            })
        end)
    end

    -- [[ SUPER FIX: HYBRID DRAG & CLICK SYSTEM ]]
    -- Fungsi ini menangani Drag DAN Click sekaligus agar tidak bentrok
    local function EnableDragAndClick(guiObject, onClickFunction)
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        local hasMoved = false -- Penanda apakah jari bergerak

        guiObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                hasMoved = false -- Reset status gerak
                dragStart = input.Position
                startPos = guiObject.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        -- LOGIKA KLIK: Jika jari diangkat dan TIDAK bergerak (atau gerak dikit banget), itu KLIK.
                        if not hasMoved and onClickFunction then
                            onClickFunction()
                        end
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
                
                -- Threshold Check: Hanya dianggap "Geser" jika bergerak lebih dari 5 pixel
                if (input.Position - dragStart).Magnitude > 5 then
                    hasMoved = true -- Tandai bahwa ini adalah gerakan geser, BUKAN klik
                    guiObject.Position = UDim2.new(
                        startPos.X.Scale, 
                        startPos.X.Offset + delta.X, 
                        startPos.Y.Scale, 
                        startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end

    -- [[ EXPLOSION EFFECT ]]
    local function PlayExplosionEffect()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local sound = Instance.new("Sound", root)
        sound.SoundId = "rbxassetid://142070127"
        sound.Volume = 2
        sound:Play()
        Debris:AddItem(sound, 3)

        local explosion = Instance.new("Explosion", root)
        explosion.Position = root.Position
        explosion.BlastPressure = 0
        explosion.BlastRadius = 12
        explosion.ExplosionType = Enum.ExplosionType.NoCraters

        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire", part)
                fire.Color = Color3.fromRGB(170, 0, 255)
                fire.SecondaryColor = Color3.fromRGB(255, 100, 255)
                fire.Size = 4
                fire.Heat = 10
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

            Notify("Loading...", "Mengambil data avatar...")

            local success, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)

            if success and desc then
                PlayExplosionEffect()
                task.wait(0.15)
                hum:ApplyDescription(desc)
                Notify("Success", "Avatar Berubah!")
            else
                Notify("Error", "Gagal. ID Invalid?")
            end
        end)
    end

    local function ResetAvatar()
        if State.OriginalDescription and LocalPlayer.Character then
            PlayExplosionEffect()
            task.wait(0.15)
            LocalPlayer.Character.Humanoid:ApplyDescription(State.OriginalDescription)
            Notify("Reset", "Avatar Kembali.")
        end
    end

    -- [[ UI CONSTRUCTION ]]
    local function CreateUI()
        if ScreenGui then ScreenGui:Destroy() end

        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VanzyPurpleV5"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.DisplayOrder = 10000 -- Layer Tertinggi
        
        if gethui then 
            ScreenGui.Parent = gethui() 
        elseif game:GetService("CoreGui") then
            ScreenGui.Parent = game:GetService("CoreGui")
        else
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end

        -- 1. WIDGET BUTTON (Touch Friendly)
        MiniButton = Instance.new("TextButton", ScreenGui)
        MiniButton.Name = "WidgetButton"
        MiniButton.Size = UDim2.new(0, 50, 0, 50)
        MiniButton.Position = UDim2.new(0.85, 0, 0.4, 0)
        MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
        MiniButton.Text = "👥"
        MiniButton.TextSize = 25
        MiniButton.TextColor3 = CloneConfig.Theme.Accent
        MiniButton.AutoButtonColor = false -- Matikan auto color biar ga glitch
        MiniButton.Visible = false
        MiniButton.ZIndex = 20

        local MiniCorner = Instance.new("UICorner", MiniButton)
        MiniCorner.CornerRadius = UDim.new(1, 0)

        local MiniStroke = Instance.new("UIStroke", MiniButton)
        MiniStroke.Color = CloneConfig.Theme.Accent
        MiniStroke.Thickness = 2.5
        MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        -- 2. MAIN MENU (Hidden)
        MainFrame = Instance.new("Frame", ScreenGui)
        MainFrame.Name = "MainPanel"
        MainFrame.Size = UDim2.new(0, 300, 0, 350)
        MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
        MainFrame.BackgroundColor3 = CloneConfig.Theme.Background
        MainFrame.Visible = false
        MainFrame.ClipsDescendants = true
        MainFrame.ZIndex = 10
        
        -- Fitur Drag untuk Panel Utama (Tanpa klik function, cuma drag)
        EnableDragAndClick(MainFrame, nil)

        local MainStroke = Instance.new("UIStroke", MainFrame)
        MainStroke.Color = CloneConfig.Theme.Accent
        MainStroke.Thickness = 2

        local MainCorner = Instance.new("UICorner", MainFrame)
        MainCorner.CornerRadius = UDim.new(0, 12)

        -- HEADER
        local Header = Instance.new("Frame", MainFrame)
        Header.Size = UDim2.new(1, 0, 0, 45)
        Header.BackgroundTransparency = 1
        Header.ZIndex = 11

        local Title = Instance.new("TextLabel", Header)
        Title.Size = UDim2.new(1, -40, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "CLONE AVATAR"
        Title.Font = Enum.Font.GothamBlack
        Title.TextColor3 = CloneConfig.Theme.Accent
        Title.TextSize = 18
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 11

        local CloseBtn = Instance.new("TextButton", Header)
        CloseBtn.Size = UDim2.new(0, 30, 0, 30)
        CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.Text = "×"
        CloseBtn.TextColor3 = CloneConfig.Theme.SubText
        CloseBtn.TextSize = 24
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.ZIndex = 12

        -- CONTENT
        local Content = Instance.new("Frame", MainFrame)
        Content.Size = UDim2.new(1, -30, 1, -55)
        Content.Position = UDim2.new(0, 15, 0, 50)
        Content.BackgroundTransparency = 1
        Content.ZIndex = 11

        local InputBox = Instance.new("TextBox", Content)
        InputBox.Size = UDim2.new(1, 0, 0, 45)
        InputBox.BackgroundColor3 = CloneConfig.Theme.ItemBG
        InputBox.Text = ""
        InputBox.PlaceholderText = "Username / User ID"
        InputBox.PlaceholderColor3 = CloneConfig.Theme.SubText
        InputBox.TextColor3 = CloneConfig.Theme.Text
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 14
        InputBox.ZIndex = 12
        Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 8)
        
        local InputStroke = Instance.new("UIStroke", InputBox)
        InputStroke.Color = CloneConfig.Theme.Accent
        InputStroke.Transparency = 0.6
        InputStroke.Thickness = 1

        local CopyBtn = Instance.new("TextButton", Content)
        CopyBtn.Size = UDim2.new(0.48, 0, 0, 40)
        CopyBtn.Position = UDim2.new(0, 0, 0, 60)
        CopyBtn.BackgroundColor3 = CloneConfig.Theme.Accent
        CopyBtn.Text = "COPY"
        CopyBtn.Font = Enum.Font.GothamBlack
        CopyBtn.TextColor3 = Color3.white
        CopyBtn.TextSize = 14
        CopyBtn.ZIndex = 12
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)

        local RandomBtn = Instance.new("TextButton", Content)
        RandomBtn.Size = UDim2.new(0.48, 0, 0, 40)
        RandomBtn.Position = UDim2.new(0.52, 0, 0, 60)
        RandomBtn.BackgroundColor3 = CloneConfig.Theme.Random
        RandomBtn.Text = "RANDOM"
        RandomBtn.Font = Enum.Font.GothamBlack
        RandomBtn.TextColor3 = Color3.white
        RandomBtn.TextSize = 14
        RandomBtn.ZIndex = 12
        Instance.new("UICorner", RandomBtn).CornerRadius = UDim.new(0, 8)

        local ResetBtn = Instance.new("TextButton", Content)
        ResetBtn.Size = UDim2.new(1, 0, 0, 40)
        ResetBtn.Position = UDim2.new(0, 0, 0, 110)
        ResetBtn.BackgroundColor3 = CloneConfig.Theme.ItemBG
        ResetBtn.Text = "RESET TO ORIGINAL"
        ResetBtn.Font = Enum.Font.GothamBold
        ResetBtn.TextColor3 = CloneConfig.Theme.SubText
        ResetBtn.TextSize = 12
        ResetBtn.ZIndex = 12
        Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

        -- [[ LOGIC ]]
        
        -- FUNCTION TOGGLE (Dipanggil oleh EnableDragAndClick)
        local function ToggleMenu()
            State.IsGuiOpen = not State.IsGuiOpen
            MainFrame.Visible = State.IsGuiOpen
            
            -- Reset posisi frame ke tengah setiap kali dibuka (safety measure)
            if State.IsGuiOpen then
                MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Accent
                MiniButton.TextColor3 = Color3.white
            else
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
                MiniButton.TextColor3 = CloneConfig.Theme.Accent
            end
        end

        -- PASANG LOGIKA HYBRID KE WIDGET
        EnableDragAndClick(MiniButton, ToggleMenu)

        -- Button Events Standard
        CloseBtn.MouseButton1Click:Connect(function()
            State.IsGuiOpen = false
            MainFrame.Visible = false
            MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
            MiniButton.TextColor3 = CloneConfig.Theme.Accent
        end)

        CopyBtn.MouseButton1Click:Connect(function()
            local txt = InputBox.Text
            if tonumber(txt) then
                ApplyAvatar(tonumber(txt))
            else
                local s, id = pcall(function() return Players:GetUserIdFromNameAsync(txt) end)
                if s then ApplyAvatar(id) else Notify("Error", "User tidak ditemukan!") end
            end
        end)

        RandomBtn.MouseButton1Click:Connect(function()
            local list = Players:GetPlayers()
            if #list > 1 then
                local t = list[math.random(1, #list)]
                if t == LocalPlayer then t = list[math.random(1, #list)] end
                InputBox.Text = t.Name
                ApplyAvatar(t.UserId)
            else
                Notify("Info", "Sepi amat servernya.")
            end
        end)

        ResetBtn.MouseButton1Click:Connect(ResetAvatar)
    end

    -- [[ VANZY MENU INTEGRATION ]]
    
    local CosmeticsTab = UI:Tab("Cosmetics")
    
    CosmeticsTab:Label("Clone Avatar (Super Fix)")
    
    CosmeticsTab:Toggle("Show Widget 👥", function(state)
        State.WidgetEnabled = state
        
        if state then
            if not ScreenGui then CreateUI() end
            if MiniButton then MiniButton.Visible = true end
            Notify("Clone UI", "Widget Aktif! (Geser/Klik)")
        else
            if MiniButton then MiniButton.Visible = false end
            if MainFrame then MainFrame.Visible = false end
            State.IsGuiOpen = false
        end
    end)

    CosmeticsTab:Button("Force Reset Avatar", CloneConfig.Theme.Random, function()
        ResetAvatar()
    end)

    Config.OnReset.Event:Connect(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)

    return CosmeticsTab
end