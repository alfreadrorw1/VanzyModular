-- Vanzyxxx Sky Changer System
-- Custom Skyboxes and Atmospheres

return function(UI, Services, Config, Theme)
    local Lighting = Services.Lighting
    local HttpService = Services.HttpService
    
    -- Create Tab
    local VisualTab = UI:Tab("Sky")
    
    VisualTab:Label("Sky Changer")
    
    -- Sky Variables
    local CurrentSky = nil
    local CurrentAtmosphere = nil
    local SkyContainer = nil
    
    -- GitHub Sky List URL
    local GithubSky = "https://raw.githubusercontent.com/alfreadrorw1/vanzyx/main/sky.json"
    local SkyList = {}
    
    -- Preset Skies
    local PresetSkies = {
        {
            Name = "Vanilla (Default)",
            ID = "reset",
            Type = "reset"
        },
        {
            Name = "Night Sky",
            ID = "2523258109",
            Type = "id"
        },
        {
            Name = "Sunset",
            ID = "2523256259",
            Type = "id"
        },
        {
            Name = "Northern Lights",
            ID = "5998201883",
            Type = "id"
        },
        {
            Name = "Galaxy",
            ID = "159454299",
            Type = "id"
        },
        {
            Name = "Purple Nebula",
            ID = "5998203170",
            Type = "id"
        },
        {
            Name = "Pink Clouds",
            ID = "5998201103",
            Type = "id"
        },
        {
            Name = "Blue Heaven",
            ID = "5998202521",
            Type = "id"
        }
    }
    
    -- Function to apply sky by ID
    local function ApplySky(skyId, skyName)
        pcall(function()
            -- Remove existing sky and atmosphere
            if CurrentSky then
                CurrentSky:Destroy()
                CurrentSky = nil
            end
            
            if CurrentAtmosphere then
                CurrentAtmosphere:Destroy()
                CurrentAtmosphere = nil
            end
            
            -- Remove all existing skies and atmospheres
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") then
                    obj:Destroy()
                end
            end
            
            if skyId == "reset" then
                -- Reset to default
                Lighting.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
                Lighting.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
                Lighting.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
                Lighting.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
                Lighting.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
                Lighting.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Sky",
                    Text = "Reset to default sky",
                    Duration = 3
                })
                return
            end
            
            -- Load sky object
            local success, skyObjects = pcall(function()
                return game:GetObjects("rbxassetid://" .. skyId)
            end)
            
            if success and skyObjects[1] then
                local asset = skyObjects[1]
                
                if asset:IsA("Sky") then
                    -- Single sky object
                    asset.Parent = Lighting
                    CurrentSky = asset
                elseif asset:IsA("Model") then
                    -- Model containing sky and atmosphere
                    for _, child in ipairs(asset:GetChildren()) do
                        if child:IsA("Sky") then
                            child.Parent = Lighting
                            CurrentSky = child
                        elseif child:IsA("Atmosphere") then
                            child.Parent = Lighting
                            CurrentAtmosphere = child
                        else
                            child.Parent = Lighting
                        end
                    end
                end
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Sky",
                    Text = "Applied: " .. skyName,
                    Duration = 3
                })
                
                print("[Vanzyxxx] Applied sky: " .. skyName .. " (ID: " .. skyId .. ")")
            else
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Error",
                    Text = "Failed to load sky",
                    Duration = 3
                })
            end
        end)
    end
    
    -- Function to load skies from GitHub
    local function LoadSkyList()
        pcall(function()
            local jsonData = game:HttpGet(GithubSky)
            if jsonData then
                SkyList = HttpService:JSONDecode(jsonData)
                
                Services.StarterGui:SetCore("SendNotification", {
                    Title = "Sky List",
                    Text = "Loaded " .. #SkyList .. " skies from GitHub",
                    Duration = 3
                })
                
                UpdateSkyContainer()
            end
        end)
    end
    
    -- Function to update sky container
    local function UpdateSkyContainer()
        if not SkyContainer then return end
        
        -- Clear container
        for _, child in ipairs(SkyContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add preset skies
        for _, sky in ipairs(PresetSkies) do
            local skyBtn = Instance.new("TextButton", SkyContainer)
            skyBtn.Size = UDim2.new(1, 0, 0, 25)
            skyBtn.BackgroundColor3 = Theme.ButtonDark
            skyBtn.Text = sky.Name
            skyBtn.TextColor3 = Theme.Text
            skyBtn.Font = Enum.Font.Gotham
            skyBtn.TextSize = 11
            skyBtn.AutoButtonColor = true
            
            local btnCorner = Instance.new("UICorner", skyBtn)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            skyBtn.MouseButton1Click:Connect(function()
                ApplySky(sky.ID, sky.Name)
            end)
        end
        
        -- Add separator
        local separator = Instance.new("TextLabel", SkyContainer)
        separator.Size = UDim2.new(1, 0, 0, 20)
        separator.BackgroundTransparency = 1
        separator.Text = "─ GitHub Skies ─"
        separator.TextColor3 = Theme.Accent
        separator.TextSize = 10
        separator.Font = Enum.Font.GothamBold
        
        -- Add GitHub skies
        for _, sky in ipairs(SkyList) do
            local skyBtn = Instance.new("TextButton", SkyContainer)
            skyBtn.Size = UDim2.new(1, 0, 0, 25)
            skyBtn.BackgroundColor3 = Theme.Button
            skyBtn.Text = sky.Name
            skyBtn.TextColor3 = Theme.Text
            skyBtn.Font = Enum.Font.Gotham
            skyBtn.TextSize = 11
            skyBtn.AutoButtonColor = true
            
            local btnCorner = Instance.new("UICorner", skyBtn)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            skyBtn.MouseButton1Click:Connect(function()
                ApplySky(sky.ID, sky.Name)
            end)
        end
    end
    
    -- Create sky container
    SkyContainer = VisualTab:Container(200)
    
    -- Sky controls
    VisualTab:Button("Load Sky List from GitHub", Theme.Button, function()
        LoadSkyList()
    end)
    
    VisualTab:Button("Reset Sky to Default", Theme.ButtonRed, function()
        ApplySky("reset", "Default")
    end)
    
    -- Custom sky ID input
    VisualTab:Label("Custom Sky ID")
    
    local customSkyInput = nil
    VisualTab:Input("Enter Asset ID...", function(text)
        if text and text ~= "" and tonumber(text) then
            ApplySky(text, "Custom Sky")
        end
    end)
    
    -- Real-time sky editing
    VisualTab:Label("Sky Editor (Advanced)")
    
    local skyEditorEnabled = false
    local skyEditorToggle = VisualTab:Toggle("Enable Sky Editor", function(state)
        skyEditorEnabled = state
        
        if state then
            -- Create editor GUI
            local screenGui = Services.CoreGui:FindFirstChild("Vanzyxxx")
            if screenGui then
                local editorFrame = Instance.new("Frame", screenGui)
                editorFrame.Name = "SkyEditor"
                editorFrame.Size = UDim2.new(0, 200, 0, 250)
                editorFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
                editorFrame.BackgroundColor3 = Theme.Main
                editorFrame.ZIndex = 100
                
                local editorCorner = Instance.new("UICorner", editorFrame)
                editorCorner.CornerRadius = UDim.new(0, 8)
                
                local editorStroke = Instance.new("UIStroke", editorFrame)
                editorStroke.Color = Theme.Accent
                
                -- Title
                local title = Instance.new("TextLabel", editorFrame)
                title.Size = UDim2.new(1, 0, 0, 30)
                title.BackgroundTransparency = 1
                title.Text = "Sky Editor"
                title.TextColor3 = Theme.Accent
                title.Font = Enum.Font.GothamBlack
                title.TextSize = 14
                
                -- Close button
                local closeBtn = Instance.new("TextButton", editorFrame)
                closeBtn.Size = UDim2.new(0, 30, 0, 30)
                closeBtn.Position = UDim2.new(1, -30, 0, 0)
                closeBtn.BackgroundTransparency = 1
                closeBtn.Text = "X"
                closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
                closeBtn.Font = Enum.Font.GothamBlack
                closeBtn.TextSize = 16
                
                closeBtn.MouseButton1Click:Connect(function()
                    editorFrame:Destroy()
                    skyEditorToggle.SetState(false)
                end)
                
                -- Color picker for sky
                local colorLabel = Instance.new("TextLabel", editorFrame)
                colorLabel.Size = UDim2.new(1, -10, 0, 20)
                colorLabel.Position = UDim2.new(0, 5, 0, 35)
                colorLabel.BackgroundTransparency = 1
                colorLabel.Text = "Sky Color:"
                colorLabel.TextColor3 = Theme.Text
                colorLabel.TextSize = 12
                colorLabel.Font = Enum.Font.Gotham
                
                -- Sky properties controls
                local properties = {
                    "StarCount",
                    "SunAngularSize",
                    "MoonAngularSize"
                }
                
                local yPos = 60
                for _, prop in ipairs(properties) do
                    local propLabel = Instance.new("TextLabel", editorFrame)
                    propLabel.Size = UDim2.new(0.6, -5, 0, 20)
                    propLabel.Position = UDim2.new(0, 5, 0, yPos)
                    propLabel.BackgroundTransparency = 1
                    propLabel.Text = prop .. ":"
                    propLabel.TextColor3 = Theme.Text
                    propLabel.TextSize = 11
                    propLabel.Font = Enum.Font.Gotham
                    propLabel.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local propInput = Instance.new("TextBox", editorFrame)
                    propInput.Size = UDim2.new(0.4, -5, 0, 20)
                    propInput.Position = UDim2.new(0.6, 0, 0, yPos)
                    propInput.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                    propInput.TextColor3 = Theme.Text
                    propInput.Text = "0"
                    propInput.Font = Enum.Font.Gotham
                    propInput.TextSize = 11
                    
                    local inputCorner = Instance.new("UICorner", propInput)
                    inputCorner.CornerRadius = UDim.new(0, 4)
                    
                    propInput.FocusLost:Connect(function()
                        if CurrentSky then
                            local value = tonumber(propInput.Text)
                            if value then
                                CurrentSky[prop] = value
                            end
                        end
                    end)
                    
                    yPos = yPos + 25
                end
                
                -- Cloud controls
                local cloudLabel = Instance.new("TextLabel", editorFrame)
                cloudLabel.Size = UDim2.new(1, -10, 0, 20)
                cloudLabel.Position = UDim2.new(0, 5, 0, yPos)
                cloudLabel.BackgroundTransparency = 1
                cloudLabel.Text = "Cloud Settings:"
                cloudLabel.TextColor3 = Theme.Accent
                cloudLabel.TextSize = 12
                cloudLabel.Font = Enum.Font.GothamBold
                
                yPos = yPos + 25
                
                local cloudProps = {"CloudsCover", "CloudsDensity"}
                
                for _, prop in ipairs(cloudProps) do
                    local propLabel = Instance.new("TextLabel", editorFrame)
                    propLabel.Size = UDim2.new(0.6, -5, 0, 20)
                    propLabel.Position = UDim2.new(0, 5, 0, yPos)
                    propLabel.BackgroundTransparency = 1
                    propLabel.Text = prop .. ":"
                    propLabel.TextColor3 = Theme.Text
                    propLabel.TextSize = 11
                    propLabel.Font = Enum.Font.Gotham
                    propLabel.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local propSlider = Instance.new("Frame", editorFrame)
                    propSlider.Size = UDim2.new(0.4, -5, 0, 20)
                    propSlider.Position = UDim2.new(0.6, 0, 0, yPos)
                    propSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    
                    local sliderCorner = Instance.new("UICorner", propSlider)
                    sliderCorner.CornerRadius = UDim.new(0, 4)
                    
                    local fill = Instance.new("Frame", propSlider)
                    fill.Size = UDim2.new(0.5, 0, 1, 0)
                    fill.BackgroundColor3 = Theme.Accent
                    
                    local sliderBtn = Instance.new("TextButton", propSlider)
                    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
                    sliderBtn.BackgroundTransparency = 1
                    sliderBtn.Text = ""
                    
                    sliderBtn.MouseButton1Down:Connect(function()
                        local connection
                        connection = Services.RunService.RenderStepped:Connect(function()
                            local percent = math.clamp(
                                (Services.UserInputService:GetMouseLocation().X - propSlider.AbsolutePosition.X) / propSlider.AbsoluteSize.X,
                                0, 1
                            )
                            fill.Size = UDim2.new(percent, 0, 1, 0)
                            if CurrentSky then
                                CurrentSky[prop] = percent
                            end
                            
                            if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                                connection:Disconnect()
                            end
                        end)
                    end)
                    
                    yPos = yPos + 25
                end
                
                Config.SkyEditorFrame = editorFrame
            end
        else
            if Config.SkyEditorFrame then
                Config.SkyEditorFrame:Destroy()
                Config.SkyEditorFrame = nil
            end
        end
    end)
    
    -- Time of day slider
    VisualTab:Label("Time of Day")
    
    VisualTab:Slider("Time", 0, 24, function(value)
        Lighting.ClockTime = value
    end)
    
    -- Brightness slider
    VisualTab:Slider("Brightness", 0, 5, function(value)
        Lighting.Brightness = value
    end)
    
    -- Fog controls
    VisualTab:Label("Fog Settings")
    
    VisualTab:Toggle("Enable Fog", function(state)
        Lighting.FogEnabled = state
    end)
    
    VisualTab:Slider("Fog Density", 0, 1, function(value)
        Lighting.FogEnd = 1000 * (1 - value)
        Lighting.FogStart = 100 * (1 - value)
    end)
    
    -- Initialize sky container
    spawn(function()
        task.wait(1)
        UpdateSkyContainer()
    end)
    
    -- Cleanup
    Config.OnReset:Connect(function()
        -- Reset sky to default
        ApplySky("reset", "Default")
        
        -- Reset lighting settings
        Lighting.ClockTime = 14
        Lighting.Brightness = 1
        Lighting.FogEnabled = false
        
        -- Remove editor frame
        if Config.SkyEditorFrame then
            Config.SkyEditorFrame:Destroy()
            Config.SkyEditorFrame = nil
        end
    end)
    
    print("[Vanzyxxx] Sky system loaded!")
end