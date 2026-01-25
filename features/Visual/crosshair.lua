-- Vanzyxxx Crosshair & Target HUD
-- Utility untuk Aiming & Informasi Musuh
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local RunService = Services.RunService
    local Players = Services.Players
    local Workspace = Services.Workspace
    local CoreGui = Services.CoreGui
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    -- Tab Setup
    local VisualTab = UI:Tab("Visual") -- Masuk ke Tab Visual
    VisualTab:Label("Crosshair & Target Info")

    -- Config Variables
    Config.Crosshair_Enabled = false
    Config.Crosshair_Size = 10
    Config.Crosshair_Gap = 4
    Config.Crosshair_Thickness = 2
    Config.TargetHUD_Enabled = false

    -- Container UI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VanzyCrosshair"
    
    -- Proteksi GUI (Biar gak kedetect game basic)
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then 
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end

    --------------------------------------------------------------------------------
    -- 1. CUSTOM CROSSHAIR SYSTEM
    --------------------------------------------------------------------------------
    local Crosshair = {
        Top = Instance.new("Frame"),
        Bottom = Instance.new("Frame"),
        Left = Instance.new("Frame"),
        Right = Instance.new("Frame")
    }

    -- Setup Bagian Crosshair
    for _, part in pairs(Crosshair) do
        part.Parent = ScreenGui
        part.BackgroundColor3 = Theme.Accent
        part.BorderSizePixel = 0
        part.Visible = false
        part.ZIndex = 100
    end

    local function UpdateCrosshair()
        if not Config.Crosshair_Enabled then
            for _, part in pairs(Crosshair) do part.Visible = false end
            return
        end

        local center = Camera.ViewportSize / 2
        local size = Config.Crosshair_Size
        local gap = Config.Crosshair_Gap
        local thick = Config.Crosshair_Thickness

        -- Update Warna (Ikut tema)
        local color = Config.RainbowTheme and Theme.Accent or Config.CustomColor
        
        -- Top
        Crosshair.Top.Size = UDim2.new(0, thick, 0, size)
        Crosshair.Top.Position = UDim2.new(0, center.X - (thick/2), 0, center.Y - gap - size)
        Crosshair.Top.BackgroundColor3 = color
        Crosshair.Top.Visible = true

        -- Bottom
        Crosshair.Bottom.Size = UDim2.new(0, thick, 0, size)
        Crosshair.Bottom.Position = UDim2.new(0, center.X - (thick/2), 0, center.Y + gap)
        Crosshair.Bottom.BackgroundColor3 = color
        Crosshair.Bottom.Visible = true

        -- Left
        Crosshair.Left.Size = UDim2.new(0, size, 0, thick)
        Crosshair.Left.Position = UDim2.new(0, center.X - gap - size, 0, center.Y - (thick/2))
        Crosshair.Left.BackgroundColor3 = color
        Crosshair.Left.Visible = true

        -- Right
        Crosshair.Right.Size = UDim2.new(0, size, 0, thick)
        Crosshair.Right.Position = UDim2.new(0, center.X + gap, 0, center.Y - (thick/2))
        Crosshair.Right.BackgroundColor3 = color
        Crosshair.Right.Visible = true
    end

    --------------------------------------------------------------------------------
    -- 2. TARGET HUD SYSTEM (Raycasting)
    --------------------------------------------------------------------------------
    
    local TargetFrame = Instance.new("Frame", ScreenGui)
    TargetFrame.Size = UDim2.new(0, 200, 0, 70)
    TargetFrame.Position = UDim2.new(0.5, 30, 0.5, 30) -- Di sebelah kanan crosshair
    TargetFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TargetFrame.BackgroundTransparency = 0.3
    TargetFrame.Visible = false
    
    local TFCorner = Instance.new("UICorner", TargetFrame)
    TFCorner.CornerRadius = UDim.new(0, 8)
    
    local TFStroke = Instance.new("UIStroke", TargetFrame)
    TFStroke.Color = Theme.Accent
    TFStroke.Thickness = 1.5

    -- Info Labels
    local TName = Instance.new("TextLabel", TargetFrame)
    TName.Size = UDim2.new(1, -10, 0, 20)
    TName.Position = UDim2.new(0, 5, 0, 5)
    TName.BackgroundTransparency = 1
    TName.Text = "Player Name"
    TName.TextColor3 = Theme.Accent
    TName.Font = Enum.Font.GothamBold
    TName.TextSize = 14
    TName.TextXAlignment = Enum.TextXAlignment.Left

    local THealth = Instance.new("TextLabel", TargetFrame)
    THealth.Size = UDim2.new(1, -10, 0, 15)
    THealth.Position = UDim2.new(0, 5, 0, 25)
    THealth.BackgroundTransparency = 1
    THealth.Text = "Health: 100%"
    THealth.TextColor3 = Color3.fromRGB(0, 255, 100)
    THealth.Font = Enum.Font.Gotham
    THealth.TextSize = 12
    THealth.TextXAlignment = Enum.TextXAlignment.Left

    local TTool = Instance.new("TextLabel", TargetFrame)
    TTool.Size = UDim2.new(1, -10, 0, 15)
    TTool.Position = UDim2.new(0, 5, 0, 45)
    TTool.BackgroundTransparency = 1
    TTool.Text = "Weapon: None"
    TTool.TextColor3 = Color3.fromRGB(200, 200, 200)
    TTool.Font = Enum.Font.Gotham
    TTool.TextSize = 11
    TTool.TextXAlignment = Enum.TextXAlignment.Left

    local function UpdateTargetHUD()
        if not Config.TargetHUD_Enabled then 
            TargetFrame.Visible = false
            return 
        end

        -- Raycast dari tengah layar
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = Camera.CFrame.LookVector * 1000
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        if raycastResult and raycastResult.Instance then
            local hitPart = raycastResult.Instance
            local character = hitPart.Parent
            local humanoid = character:FindFirstChild("Humanoid")

            -- Cek apakah yang kena raycast adalah player/NPC hidup
            if character and humanoid and humanoid.Health > 0 then
                local player = Players:GetPlayerFromCharacter(character)
                local name = player and player.DisplayName or character.Name
                
                -- Update Info UI
                TName.Text = name
                TName.TextColor3 = Theme.Accent
                
                local hp = math.floor(humanoid.Health)
                local maxHp = math.floor(humanoid.MaxHealth)
                THealth.Text = "HP: " .. hp .. " / " .. maxHp
                
                -- Warna HP (Hijau -> Merah)
                local hpPercent = hp / maxHp
                THealth.TextColor3 = Color3.fromHSV(hpPercent * 0.3, 1, 1)

                -- Cek Senjata
                local tool = character:FindFirstChildOfClass("Tool")
                TTool.Text = "Hold: " .. (tool and tool.Name or "None")

                TargetFrame.Visible = true
                
                -- Update Stroke Color ikut tema
                TFStroke.Color = Theme.Accent
            else
                TargetFrame.Visible = false
            end
        else
            TargetFrame.Visible = false
        end
    end

    --------------------------------------------------------------------------------
    -- 3. UI CONTROLS
    --------------------------------------------------------------------------------
    
    -- Toggle Crosshair
    VisualTab:Toggle("Enable Crosshair", function(state)
        Config.Crosshair_Enabled = state
        UpdateCrosshair()
    end)

    -- Toggle Target HUD
    VisualTab:Toggle("Target Info HUD", function(state)
        Config.TargetHUD_Enabled = state
    end)

    -- Sliders untuk Customisasi Crosshair
    VisualTab:Slider("Size", 2, 50, function(val)
        Config.Crosshair_Size = val
        UpdateCrosshair()
    end)

    VisualTab:Slider("Gap", 0, 20, function(val)
        Config.Crosshair_Gap = val
        UpdateCrosshair()
    end)

    -- Connection Loop
    local RenderConn = RunService.RenderStepped:Connect(function()
        if Config.Crosshair_Enabled then UpdateCrosshair() end
        if Config.TargetHUD_Enabled then UpdateTargetHUD() end
    end)

    -- Cleanup
    Config.OnReset:Connect(function()
        if RenderConn then RenderConn:Disconnect() end
        if ScreenGui then ScreenGui:Destroy() end
        print("[Vanzyxxx] Crosshair Unloaded")
    end)

    print("[Vanzyxxx] Crosshair & HUD Loaded!")
end
