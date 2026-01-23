-- Vanzyxxx ESP System
-- Advanced Player ESP with Box, Name, Health, Distance

return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local Camera = Services.Workspace.CurrentCamera
    local RunService = Services.RunService
    
    -- Create Tab
    local VisualTab = UI:Tab("Visual")
    
    VisualTab:Label("ESP Settings")
    
    -- ESP Variables
    local ESP_Objects = {}
    local ESP_Connections = {}
    local ESP_Enabled = false
    
    -- Color settings
    local ESP_Colors = {
        Team = {
            Friendly = Color3.fromRGB(0, 255, 0),
            Enemy = Color3.fromRGB(255, 0, 0),
            Neutral = Color3.fromRGB(255, 255, 0)
        },
        Health = {
            High = Color3.fromRGB(0, 255, 0),
            Medium = Color3.fromRGB(255, 255, 0),
            Low = Color3.fromRGB(255, 0, 0)
        }
    }
    
    -- ESP Toggles
    VisualTab:Label("ESP Features")
    
    local espBoxToggle = VisualTab:Toggle("ESP Box", function(state)
        Config.ESP_Box = state
        UpdateESP()
    end)
    
    local espNameToggle = VisualTab:Toggle("ESP Name", function(state)
        Config.ESP_Name = state
        UpdateESP()
    end)
    
    local espHealthToggle = VisualTab:Toggle("ESP Health", function(state)
        Config.ESP_Health = state
        UpdateESP()
    end)
    
    local espDistanceToggle = VisualTab:Toggle("ESP Distance", function(state)
        Config.ESP_Distance = state
        UpdateESP()
    end)
    
    local espTeamToggle = VisualTab:Toggle("Team Color", function(state)
        Config.ESP_TeamColor = state
        UpdateESP()
    end)
    
    local espTracerToggle = VisualTab:Toggle("Tracer Line", function(state)
        Config.ESP_Tracer = state
        UpdateESP()
    end)
    
    local espChamsToggle = VisualTab:Toggle("Wall Chams", function(state)
        Config.ESP_Chams = state
        UpdateChams()
    end)
    
    -- ESP Settings
    VisualTab:Label("ESP Configuration")
    
    VisualTab:Slider("ESP Max Distance", 50, 1000, function(value)
        Config.ESP_MaxDistance = value
    end)
    
    VisualTab:Slider("ESP Text Size", 10, 20, function(value)
        Config.ESP_TextSize = value
        UpdateESP()
    end)
    
    -- ESP Color Picker (simplified)
    VisualTab:Label("ESP Colors")
    
    VisualTab:Toggle("Rainbow ESP", function(state)
        Config.ESP_Rainbow = state
    end)
    
    -- Function to get team color
    local function GetTeamColor(player)
        if not Config.ESP_TeamColor then
            return Color3.fromRGB(255, 255, 255)
        end
        
        if player.Team then
            if LocalPlayer.Team then
                if player.Team == LocalPlayer.Team then
                    return ESP_Colors.Team.Friendly
                else
                    return ESP_Colors.Team.Enemy
                end
            end
            return player.TeamColor.Color
        end
        return ESP_Colors.Team.Neutral
    end
    
    -- Function to get health color
    local function GetHealthColor(humanoid)
        if not humanoid then return Color3.fromRGB(255, 255, 255) end
        
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        if healthPercent > 0.7 then
            return ESP_Colors.Health.High
        elseif healthPercent > 0.3 then
            return ESP_Colors.Health.Medium
        else
            return ESP_Colors.Health.Low
        end
    end
    
    -- Function to create ESP for a player
    local function CreateESP(player)
        if player == LocalPlayer then return end
        if ESP_Objects[player] then return end
        
        local espObject = {
            Player = player,
            Box = nil,
            NameLabel = nil,
            HealthLabel = nil,
            DistanceLabel = nil,
            Tracer = nil,
            Connections = {}
        }
        
        ESP_Objects[player] = espObject
        
        -- Monitor character
        local function setupCharacter(character)
            if not character then return end
            
            local humanoid = character:WaitForChild("Humanoid", 5)
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            
            if not humanoid or not rootPart then return end
            
            -- Create BillboardGui
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "VanzyESP_" .. player.Name
            billboard.Adornee = rootPart
            billboard.Size = UDim2.new(0, 100, 0, 150)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = Config.ESP_MaxDistance or 500
            billboard.Parent = Services.CoreGui
            
            -- Box
            local box = Instance.new("Frame")
            box.Name = "Box"
            box.Size = UDim2.new(1, 0, 0.6, 0)
            box.Position = UDim2.new(0, 0, 0.2, 0)
            box.BackgroundTransparency = 1
            box.Parent = billboard
            
            local boxStroke = Instance.new("UIStroke")
            boxStroke.Parent = box
            boxStroke.Thickness = 2
            boxStroke.Color = GetTeamColor(player)
            
            -- Name Label
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Name"
            nameLabel.Size = UDim2.new(1, 0, 0.1, 0)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = GetTeamColor(player)
            nameLabel.TextSize = Config.ESP_TextSize or 14
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextStrokeTransparency = 0
            nameLabel.Parent = billboard
            
            -- Health Label
            local healthLabel = Instance.new("TextLabel")
            healthLabel.Name = "Health"
            healthLabel.Size = UDim2.new(1, 0, 0.1, 0)
            healthLabel.Position = UDim2.new(0, 0, 0.1, 0)
            healthLabel.BackgroundTransparency = 1
            healthLabel.Text = "HP: " .. math.floor(humanoid.Health)
            healthLabel.TextColor3 = GetHealthColor(humanoid)
            healthLabel.TextSize = Config.ESP_TextSize or 12
            healthLabel.Font = Enum.Font.Gotham
            healthLabel.TextStrokeTransparency = 0
            healthLabel.Parent = billboard
            
            -- Distance Label
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Name = "Distance"
            distanceLabel.Size = UDim2.new(1, 0, 0.1, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.8, 0)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
            distanceLabel.TextSize = Config.ESP_TextSize or 12
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.TextStrokeTransparency = 0
            distanceLabel.Parent = billboard
            
            -- Tracer Line
            local tracer = Instance.new("Frame")
            tracer.Name = "Tracer"
            tracer.BackgroundColor3 = GetTeamColor(player)
            tracer.BorderSizePixel = 0
            tracer.Visible = false
            tracer.Parent = Services.CoreGui
            
            -- Store references
            espObject.Billboard = billboard
            espObject.Box = boxStroke
            espObject.NameLabel = nameLabel
            espObject.HealthLabel = healthLabel
            espObject.DistanceLabel = distanceLabel
            espObject.Tracer = tracer
            espObject.Humanoid = humanoid
            espObject.RootPart = rootPart
            
            -- Update function
            local function updateESP()
                if not Config.ESP_Box and not Config.ESP_Name and not Config.ESP_Health and not Config.ESP_Distance and not Config.ESP_Tracer then
                    billboard.Enabled = false
                    tracer.Visible = false
                    return
                end
                
                billboard.Enabled = true
                
                -- Update box
                if boxStroke then
                    boxStroke.Enabled = Config.ESP_Box
                    if Config.ESP_Rainbow then
                        local hue = tick() % 5 / 5
                        boxStroke.Color = Color3.fromHSV(hue, 1, 1)
                    else
                        boxStroke.Color = GetTeamColor(player)
                    end
                end
                
                -- Update name
                if nameLabel then
                    nameLabel.Visible = Config.ESP_Name
                    nameLabel.TextColor3 = Config.ESP_Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or GetTeamColor(player)
                end
                
                -- Update health
                if healthLabel and humanoid then
                    healthLabel.Visible = Config.ESP_Health
                    local healthText = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                    local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                    healthText = healthText .. " (" .. healthPercent .. "%)"
                    healthLabel.Text = healthText
                    healthLabel.TextColor3 = GetHealthColor(humanoid)
                end
                
                -- Update distance
                if distanceLabel and rootPart and LocalPlayer.Character then
                    distanceLabel.Visible = Config.ESP_Distance
                    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if localRoot then
                        local distance = math.floor((rootPart.Position - localRoot.Position).Magnitude)
                        distanceLabel.Text = distance .. " studs"
                    end
                end
                
                -- Update tracer
                if tracer and rootPart and Config.ESP_Tracer then
                    tracer.Visible = true
                    
                    local viewportSize = Camera.ViewportSize
                    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    
                    if onScreen then
                        tracer.Size = UDim2.new(0, 1, 0, (viewportSize.Y - rootPos.Y))
                        tracer.Position = UDim2.new(0, rootPos.X, 0, rootPos.Y)
                        tracer.BackgroundColor3 = Config.ESP_Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or GetTeamColor(player)
                    else
                        tracer.Visible = false
                    end
                else
                    if tracer then
                        tracer.Visible = false
                    end
                end
            end
            
            -- Add update connection
            local updateConnection = RunService.RenderStepped:Connect(updateESP)
            table.insert(espObject.Connections, updateConnection)
            
            -- Health changed connection
            local healthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                updateESP()
            end)
            table.insert(espObject.Connections, healthConnection)
            
            -- Initial update
            updateESP()
        end
        
        -- Setup existing character
        if player.Character then
            setupCharacter(player.Character)
        end
        
        -- Monitor character changes
        local charConnection = player.CharacterAdded:Connect(function(character)
            task.wait(1)
            setupCharacter(character)
        end)
        table.insert(espObject.Connections, charConnection)
    end
    
    -- Function to remove ESP for a player
    local function RemoveESP(player)
        local espObject = ESP_Objects[player]
        if not espObject then return end
        
        -- Disconnect all connections
        for _, connection in ipairs(espObject.Connections) do
            pcall(function() connection:Disconnect() end)
        end
        
        -- Remove GUI objects
        if espObject.Billboard then
            espObject.Billboard:Destroy()
        end
        
        if espObject.Tracer then
            espObject.Tracer:Destroy()
        end
        
        ESP_Objects[player] = nil
    end
    
    -- Function to update all ESP
    local function UpdateESP()
        for player, espObject in pairs(ESP_Objects) do
            if espObject.UpdateFunction then
                pcall(espObject.UpdateFunction)
            end
        end
    end
    
    -- Function to update chams
    local function UpdateChams()
        for player, espObject in pairs(ESP_Objects) do
            if espObject.Humanoid and espObject.Humanoid.Parent then
                local character = espObject.Humanoid.Parent
                
                if Config.ESP_Chams then
                    -- Create chams
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Transparency < 1 then
                            if not part:FindFirstChild("ChamsHighlight") then
                                local highlight = Instance.new("Highlight")
                                highlight.Name = "ChamsHighlight"
                                highlight.Parent = part
                                highlight.FillColor = GetTeamColor(player)
                                highlight.FillTransparency = 0.5
                                highlight.OutlineColor = GetTeamColor(player)
                                highlight.OutlineTransparency = 0
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            end
                        end
                    end
                else
                    -- Remove chams
                    for _, part in ipairs(character:GetDescendants()) do
                        local highlight = part:FindFirstChild("ChamsHighlight")
                        if highlight then
                            highlight:Destroy()
                        end
                    end
                end
            end
        end
    end
    
    -- Function to setup ESP for all players
    local function SetupAllESP()
        -- Clear existing ESP
        for player in pairs(ESP_Objects) do
            RemoveESP(player)
        end
        
        -- Setup ESP for existing players
        for _, player in ipairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESP(player)
            end
        end
        
        -- Monitor new players
        local playerAddedConnection = Services.Players.PlayerAdded:Connect(function(player)
            CreateESP(player)
        end)
        table.insert(ESP_Connections, playerAddedConnection)
        
        -- Monitor player leaving
        local playerRemovingConnection = Services.Players.PlayerRemoving:Connect(function(player)
            RemoveESP(player)
        end)
        table.insert(ESP_Connections, playerRemovingConnection)
    end
    
    -- Toggle ESP
    local espMasterToggle = VisualTab:Toggle("Master ESP Switch", function(state)
        ESP_Enabled = state
        
        if state then
            SetupAllESP()
            Services.StarterGui:SetCore("SendNotification", {
                Title = "ESP",
                Text = "ESP System Activated!",
                Duration = 3
            })
        else
            -- Disable all ESP
            for player in pairs(ESP_Objects) do
                RemoveESP(player)
            end
            
            -- Disconnect connections
            for _, connection in ipairs(ESP_Connections) do
                pcall(function() connection:Disconnect() end)
            end
            ESP_Connections = {}
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "ESP",
                Text = "ESP System Deactivated",
                Duration = 2
            })
        end
    end)
    
    -- Button to refresh ESP
    VisualTab:Button("Refresh ESP", Theme.Button, function()
        if ESP_Enabled then
            SetupAllESP()
            Services.StarterGui:SetCore("SendNotification", {
                Title = "ESP",
                Text = "ESP Refreshed!",
                Duration = 2
            })
        end
    end)
    
    -- Button to clear ESP
    VisualTab:Button("Clear All ESP", Theme.ButtonRed, function()
        for player in pairs(ESP_Objects) do
            RemoveESP(player)
        end
        Services.StarterGui:SetCore("SendNotification", {
            Title = "ESP",
            Text = "All ESP Cleared!",
            Duration = 2
        })
    end)
    
    -- Initialize with saved settings
    spawn(function()
        task.wait(2)
        if Config.ESP_Box or Config.ESP_Name or Config.ESP_Health then
            espMasterToggle.SetState(true)
        end
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        ESP_Enabled = false
        Config.ESP_Box = false
        Config.ESP_Name = false
        Config.ESP_Health = false
        Config.ESP_Distance = false
        Config.ESP_Tracer = false
        Config.ESP_Chams = false
        Config.ESP_TeamColor = false
        Config.ESP_Rainbow = false
        
        -- Remove all ESP
        for player in pairs(ESP_Objects) do
            RemoveESP(player)
        end
        
        -- Disconnect all connections
        for _, connection in ipairs(ESP_Connections) do
            pcall(function() connection:Disconnect() end)
        end
        ESP_Connections = {}
    end)
    
    print("[Vanzyxxx] ESP system loaded!")
end