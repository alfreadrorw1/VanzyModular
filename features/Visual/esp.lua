-- Vanzyxxx Visual ESP System
-- Optimized for Mobile (Drawing API)
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local RunService = Services.RunService
    local Camera = Services.Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- Create Tab
    local VisualTab = UI:Tab("Visual")
    VisualTab:Label("ESP Visuals (Drawing API)")

    -- Extended Config (Injecting new keys if they don't exist)
    Config.ESP_Enabled = false
    Config.ESP_Tracers = false
    Config.ESP_TeamCheck = false
    Config.ESP_TextSize = 13

    -- Cache for Drawing Objects
    -- Structure: { [Player] = { Box = ..., Name = ..., Health = ..., Tracer = ... } }
    local ESP_Cache = {}

    -- Utility: Create Drawing Object
    local function NewDrawing(type, properties)
        local drawing = Drawing.new(type)
        for k, v in pairs(properties) do
            drawing[k] = v
        end
        return drawing
    end

    -- Cleanup Function for Single Player
    local function RemoveESP(player)
        if ESP_Cache[player] then
            for _, drawing in pairs(ESP_Cache[player]) do
                if drawing and drawing.Remove then
                    drawing:Remove()
                end
            end
            ESP_Cache[player] = nil
        end
    end

    -- Create ESP Objects for Player
    local function CreateESP(player)
        if player == LocalPlayer then return end
        RemoveESP(player) -- Ensure clean state

        ESP_Cache[player] = {
            Box = NewDrawing("Square", {
                Thickness = 1.5,
                Color = Theme.Accent,
                Transparency = 1,
                Filled = false,
                Visible = false
            }),
            BoxOutline = NewDrawing("Square", {
                Thickness = 2.5,
                Color = Color3.new(0, 0, 0),
                Transparency = 0.5,
                Filled = false,
                Visible = false
            }),
            Name = NewDrawing("Text", {
                Size = Config.ESP_TextSize,
                Center = true,
                Outline = true,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            HealthBar = NewDrawing("Line", {
                Thickness = 2,
                Color = Color3.new(0, 1, 0),
                Transparency = 1,
                Visible = false
            }),
            Tracer = NewDrawing("Line", {
                Thickness = 1.5,
                Color = Theme.Accent,
                Transparency = 1,
                Visible = false
            })
        }
    end

    -- Main Update Loop
    local function UpdateESP()
        for player, drawings in pairs(ESP_Cache) do
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            -- Validasi dasar: Pemain ada, hidup, dan fitur nyala
            if Config.ESP_Enabled and character and humanoid and rootPart and humanoid.Health > 0 then
                
                -- Team Check
                local isTeammate = (LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team)
                if Config.ESP_TeamCheck and isTeammate then
                    -- Hide everything if team check is on and player is teammate
                    for _, d in pairs(drawings) do d.Visible = false end
                    continue
                end

                -- World to Screen Conversion
                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude

                if onScreen then
                    -- Dynamic Box Size Calculation
                    local rootPos = rootPart.Position
                    local legPos = rootPos - Vector3.new(0, 3, 0)
                    local headPos = rootPos + Vector3.new(0, 3.5, 0) -- Slightly above head
                    
                    local legScreen = Camera:WorldToViewportPoint(legPos)
                    local headScreen = Camera:WorldToViewportPoint(headPos)
                    
                    local boxHeight = math.abs(headScreen.Y - legScreen.Y)
                    local boxWidth = boxHeight * 0.65

                    -- 1. BOX ESP
                    if Config.ESP_Box then
                        -- Outline (Black background for visibility)
                        drawings.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                        drawings.BoxOutline.Position = Vector2.new(vector.X - boxWidth / 2, vector.Y - boxHeight / 2)
                        drawings.BoxOutline.Visible = true

                        -- Main Box
                        drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                        drawings.Box.Position = Vector2.new(vector.X - boxWidth / 2, vector.Y - boxHeight / 2)
                        drawings.Box.Color = isTeammate and Color3.fromRGB(0, 255, 0) or Theme.Accent -- Green for team, Theme for enemy
                        drawings.Box.Visible = true
                    else
                        drawings.Box.Visible = false
                        drawings.BoxOutline.Visible = false
                    end

                    -- 2. NAME ESP
                    if Config.ESP_Name then
                        drawings.Name.Text = string.format("%s\n[%d m]", player.DisplayName, math.floor(distance))
                        drawings.Name.Position = Vector2.new(vector.X, vector.Y - boxHeight / 2 - 15)
                        drawings.Name.Color = Theme.Text
                        drawings.Name.Visible = true
                    else
                        drawings.Name.Visible = false
                    end

                    -- 3. HEALTH ESP (Bar di sebelah kiri box)
                    if Config.ESP_Health then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        local barHeight = boxHeight * healthPercent
                        local barOffset = 5 -- Jarak dari box
                        
                        -- Warna berubah dari Hijau ke Merah
                        local healthColor = Color3.fromHSV(healthPercent * 0.3, 1, 1)

                        drawings.HealthBar.From = Vector2.new(vector.X - boxWidth / 2 - barOffset, vector.Y + boxHeight / 2)
                        drawings.HealthBar.To = Vector2.new(vector.X - boxWidth / 2 - barOffset, vector.Y + boxHeight / 2 - barHeight)
                        drawings.HealthBar.Color = healthColor
                        drawings.HealthBar.Visible = true
                    else
                        drawings.HealthBar.Visible = false
                    end

                    -- 4. TRACERS (Garis)
                    if Config.ESP_Tracers then
                        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Bottom Center
                        drawings.Tracer.To = Vector2.new(vector.X, vector.Y + boxHeight / 2) -- Bottom of character
                        drawings.Tracer.Color = isTeammate and Color3.fromRGB(0, 255, 0) or Theme.Accent
                        drawings.Tracer.Visible = true
                    else
                        drawings.Tracer.Visible = false
                    end

                else
                    -- Off Screen -> Hide All
                    for _, d in pairs(drawings) do d.Visible = false end
                end
            else
                -- Invalid Character/Dead -> Hide All
                for _, d in pairs(drawings) do d.Visible = false end
            end
        end
    end

    -- UI CONTROLS
    
    VisualTab:Toggle("Enable Master Switch", function(state)
        Config.ESP_Enabled = state
        if not state then
            -- Hide all immediately when master switch is off
            for _, pDrawings in pairs(ESP_Cache) do
                for _, d in pairs(pDrawings) do d.Visible = false end
            end
        end
    end)

    VisualTab:Toggle("Box ESP", function(state)
        Config.ESP_Box = state
    end)

    VisualTab:Toggle("Name & Distance", function(state)
        Config.ESP_Name = state
    end)

    VisualTab:Toggle("Health Bar", function(state)
        Config.ESP_Health = state
    end)

    VisualTab:Toggle("Tracers (Lines)", function(state)
        Config.ESP_Tracers = state
    end)
    
    VisualTab:Toggle("Team Check", function(state)
        Config.ESP_TeamCheck = state
    end)

    -- EVENT CONNECTIONS
    
    -- Add existing players
    for _, player in ipairs(Players:GetPlayers()) do
        CreateESP(player)
    end

    -- Handle new players
    local PlayerAddedConn = Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)

    -- Handle removing players
    local PlayerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)

    -- Run Loop
    local RenderConn = RunService.RenderStepped:Connect(UpdateESP)

    -- CLEANUP ON SCRIPT RESET
    Config.OnReset:Connect(function()
        if RenderConn then RenderConn:Disconnect() end
        if PlayerAddedConn then PlayerAddedConn:Disconnect() end
        if PlayerRemovingConn then PlayerRemovingConn:Disconnect() end
        
        for player, _ in pairs(ESP_Cache) do
            RemoveESP(player)
        end
        ESP_Cache = {}
        
        print("[Vanzyxxx] ESP Stopped & Cleaned")
    end)

    print("[Vanzyxxx] ESP System Loaded!")
end
