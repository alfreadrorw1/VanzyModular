-- features/Visual/cloneAvatar.lua
-- Fitur Clone Avatar untuk Vanzyxxx Modular
-- Author: FayintXCode (Fixed by Gemini)
-- Version: 3.0.0 (Fix Blank UI + Toggle Widget)

return function(UI, Services, Config, Theme)
    -- [[ SERVICES ]]
    local Players = Services.Players
    local UserInputService = Services.UserInputService
    local HttpService = Services.HttpService
    local StarterGui = Services.StarterGui
    local RunService = Services.RunService
    local Debris = game:GetService("Debris")
    local TweenService = Services.TweenService
    
    local LocalPlayer = Players.LocalPlayer
    
    -- [[ UI VARIABLES ]]
    local ScreenGui = nil
    local MiniButton = nil
    local MainFrame = nil
    local CurrentConnection = nil
    
    -- [[ CONFIGURATION ]]
    local CloneConfig = {
        FileName = "VanzyAvatarFavorites.json",
        Theme = {
            Background = Color3.fromRGB(15, 15, 15),
            ItemBG = Color3.fromRGB(30, 30, 30),
            Accent = Color3.fromRGB(255, 40, 70), -- Merah Pink
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(180, 180, 180),
            Random = Color3.fromRGB(200, 40, 60)
        }
    }
    
    local State = {
        OriginalDescription = nil,
        Favorites = {},
        IsGuiOpen = false,
        WidgetEnabled = false
    }

    -- [[ HELPER FUNCTIONS ]]
    local function Notify(title, text)
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 2})
    end

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

    -- [[ EXPLOSION EFFECT ]]
    local function PlayExplosionEffect()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://142070127"
        sound.Volume = 2
        sound.Parent = root
        sound:Play()
        Debris:AddItem(sound, 3)

        local explosion = Instance.new("Explosion")
        explosion.Position = root.Position
        explosion.BlastPressure = 0
        explosion.BlastRadius = 10
        explosion.ExplosionType = Enum.ExplosionType.NoCraters
        explosion.Parent = root

        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Color = Color3.fromRGB(255, 100, 50)
                fire.SecondaryColor = Color3.fromRGB(255, 255, 0)
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

            Notify("Loading...", "Fetching Avatar ID: " .. userId)

            local success, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)

            if success and desc then
                PlayExplosionEffect()
                task.wait(0.1)
                hum:ApplyDescription(desc)
                Notify("Success", "Avatar Cloned!")
            else
                Notify("Error", "Gagal mengambil avatar.")
            end
        end)
    end

    local function ResetAvatar()
        if State.OriginalDescription and LocalPlayer.Character then
            PlayExplosionEffect()
            task.wait(0.1)
            LocalPlayer.Character.Humanoid:ApplyDescription(State.OriginalDescription)
            Notify("Reset", "Avatar dikembalikan.")
        end
    end

    -- [[ UI CREATION SYSTEM ]]
    local function CreateInterface()
        if ScreenGui then ScreenGui:Destroy() end

        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VanzyCloneUI_V3"
        ScreenGui.ResetOnSpawn = false
        if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = Services.CoreGui end

        -- 1. FLOATING WIDGET (Tombol Bulat)
        MiniButton = Instance.new("TextButton", ScreenGui)
        MiniButton.Name = "MiniWidget"
        MiniButton.Size = UDim2.new(0, 45, 0, 45)
        MiniButton.Position = UDim2.new(0.85, 0, 0.4, 0)
        MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
        MiniButton.Text = "👥"
        MiniButton.TextSize = 24
        MiniButton.TextColor3 = CloneConfig.Theme.Accent
        MiniButton.AutoButtonColor = true
        MiniButton.Visible = State.WidgetEnabled -- Controlled by Menu
        
        local MiniCorner = Instance.new("UICorner", MiniButton)
        MiniCorner.CornerRadius = UDim.new(1, 0) -- Bulat Sempurna
        
        local MiniStroke = Instance.new("UIStroke", MiniButton)
        MiniStroke.Color = CloneConfig.Theme.Accent
        MiniStroke.Thickness = 2
        MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        MakeDraggable(MiniButton)

        -- 2. MAIN PANEL (The Window)
        MainFrame = Instance.new("Frame", ScreenGui)
        MainFrame.Name = "MainPanel"
        MainFrame.Size = UDim2.new(0, 300, 0, 380)
        MainFrame.Position = UDim2.new(0.5, -150, 0.5, -190)
        MainFrame.BackgroundColor3 = CloneConfig.Theme.Background
        MainFrame.Visible = false
        MainFrame.ZIndex = 1
        
        local MainCorner = Instance.new("UICorner", MainFrame)
        MainCorner.CornerRadius = UDim.new(0, 12)
        
        local MainStroke = Instance.new("UIStroke", MainFrame)
        MainStroke.Color = CloneConfig.Theme.Accent
        MainStroke.Thickness = 2

        MakeDraggable(MainFrame)

        -- HEADER
        local Header = Instance.new("Frame", MainFrame)
        Header.Size = UDim2.new(1, 0, 0, 50)
        Header.BackgroundTransparency = 1
        Header.ZIndex = 2
        
        local Title = Instance.new("TextLabel", Header)
        Title.Size = UDim2.new(1, -40, 0, 25)
        Title.Position = UDim2.new(0, 15, 0, 8)
        Title.BackgroundTransparency = 1
        Title.Text = "COPY AVATAR"
        Title.Font = Enum.Font.GothamBlack
        Title.TextColor3 = CloneConfig.Theme.Text
        Title.TextSize = 18
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 2
        
        local SubTitle = Instance.new("TextLabel", Header)
        SubTitle.Size = UDim2.new(1, -40, 0, 15)
        SubTitle.Position = UDim2.new(0, 15, 0, 28)
        SubTitle.BackgroundTransparency = 1
        SubTitle.Text = "by FayintXCode"
        SubTitle.Font = Enum.Font.Gotham
        SubTitle.TextColor3 = CloneConfig.Theme.SubText
        SubTitle.TextSize = 12
        SubTitle.TextXAlignment = Enum.TextXAlignment.Left
        SubTitle.ZIndex = 2

        local CloseBtn = Instance.new("TextButton", Header)
        CloseBtn.Size = UDim2.new(0, 30, 0, 30)
        CloseBtn.Position = UDim2.new(1, -35, 0, 10)
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.Text = "×"
        CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        CloseBtn.TextSize = 24
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.ZIndex = 3
        
        CloseBtn.MouseButton1Click:Connect(function()
            MainFrame.Visible = false
            State.IsGuiOpen = false
            MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
            MiniButton.TextColor3 = CloneConfig.Theme.Accent
        end)

        -- CONTENT CONTAINER
        local Content = Instance.new("Frame", MainFrame)
        Content.Size = UDim2.new(1, -30, 1, -60)
        Content.Position = UDim2.new(0, 15, 0, 60)
        Content.BackgroundTransparency = 1
        Content.ZIndex = 2

        -- INPUT BOX
        local InputBox = Instance.new("TextBox", Content)
        InputBox.Size = UDim2.new(1, 0, 0, 45)
        InputBox.BackgroundColor3 = CloneConfig.Theme.ItemBG
        InputBox.Text = ""
        InputBox.PlaceholderText = "Username or ID..."
        InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        InputBox.TextColor3 = Color3.white
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 14
        InputBox.ZIndex = 3
        
        local InputCorner = Instance.new("UICorner", InputBox)
        InputCorner.CornerRadius = UDim.new(0, 8)

        -- BUTTONS
        local CopyBtn = Instance.new("TextButton", Content)
        CopyBtn.Size = UDim2.new(0.48, 0, 0, 40)
        CopyBtn.Position = UDim2.new(0, 0, 0, 55)
        CopyBtn.BackgroundColor3 = CloneConfig.Theme.Accent
        CopyBtn.Text = "✅ COPY"
        CopyBtn.Font = Enum.Font.GothamBlack
        CopyBtn.TextColor3 = Color3.white
        CopyBtn.TextSize = 14
        CopyBtn.ZIndex = 3
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)

        local RandomBtn = Instance.new("TextButton", Content)
        RandomBtn.Size = UDim2.new(0.48, 0, 0, 40)
        RandomBtn.Position = UDim2.new(0.52, 0, 0, 55)
        RandomBtn.BackgroundColor3 = CloneConfig.Theme.Random
        RandomBtn.Text = "🎲 RANDOM"
        RandomBtn.Font = Enum.Font.GothamBlack
        RandomBtn.TextColor3 = Color3.white
        RandomBtn.TextSize = 14
        RandomBtn.ZIndex = 3
        Instance.new("UICorner", RandomBtn).CornerRadius = UDim.new(0, 8)

        local ResetBtn = Instance.new("TextButton", Content)
        ResetBtn.Size = UDim2.new(1, 0, 0, 40)
        ResetBtn.Position = UDim2.new(0, 0, 0, 105)
        ResetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ResetBtn.Text = "✖ RESET AVATAR"
        ResetBtn.Font = Enum.Font.GothamBold
        ResetBtn.TextColor3 = Color3.white
        ResetBtn.TextSize = 14
        ResetBtn.ZIndex = 3
        Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

        -- FOOTER
        local FooterTxt = Instance.new("TextLabel", Content)
        FooterTxt.Size = UDim2.new(1, 0, 0, 20)
        FooterTxt.Position = UDim2.new(0, 0, 1, -25)
        FooterTxt.BackgroundTransparency = 1
        FooterTxt.Text = "Supports R15 & R6"
        FooterTxt.TextColor3 = Color3.fromRGB(100, 100, 100)
        FooterTxt.Font = Enum.Font.Gotham
        FooterTxt.TextSize = 10
        FooterTxt.ZIndex = 2

        -- LOGIC
        MiniButton.MouseButton1Click:Connect(function()
            State.IsGuiOpen = not State.IsGuiOpen
            MainFrame.Visible = State.IsGuiOpen
            
            if State.IsGuiOpen then
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Accent
                MiniButton.TextColor3 = Color3.white
            else
                MiniButton.BackgroundColor3 = CloneConfig.Theme.Background
                MiniButton.TextColor3 = CloneConfig.Theme.Accent
            end
        end)

        CopyBtn.MouseButton1Click:Connect(function()
            local txt = InputBox.Text
            if tonumber(txt) then
                ApplyAvatar(tonumber(txt))
            else
                local s, id = pcall(function() return Players:GetUserIdFromNameAsync(txt) end)
                if s then ApplyAvatar(id) else Notify("Error", "User not found!") end
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
                Notify("Info", "No other players.")
            end
        end)

        ResetBtn.MouseButton1Click:Connect(ResetAvatar)
    end

    -- [[ VANZY MENU INTEGRATION ]]
    
    local CosmeticsTab = UI:Tab("Cosmetics")
    
    CosmeticsTab:Label("Clone Avatar Utility")
    
    -- TOGGLE WIDGET (Ini yang diminta)
    CosmeticsTab:Toggle("Show Clone Widget 👥", function(state)
        State.WidgetEnabled = state
        
        if state then
            if not ScreenGui then CreateInterface() end
            if MiniButton then MiniButton.Visible = true end
            Notify("Clone UI", "Widget Enabled!")
        else
            if MiniButton then MiniButton.Visible = false end
            if MainFrame then MainFrame.Visible = false end
            State.IsGuiOpen = false
        end
    end)
    
    CosmeticsTab:Label("Manual Controls")
    
    CosmeticsTab:Button("Force Reset Avatar", CloneConfig.Theme.Random, function()
        ResetAvatar()
    end)

    -- Cleanup saat script dimatikan
    Config.OnReset.Event:Connect(function()
        if ScreenGui then ScreenGui:Destroy() end
    end)

    return CosmeticsTab
end