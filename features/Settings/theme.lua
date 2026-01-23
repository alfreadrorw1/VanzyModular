-- Theme Settings Module
return function(UI, Services, Config, Theme)
    local LocalPlayer = Services.Players.LocalPlayer
    local TweenService = Services.TweenService
    local StarterGui = Services.StarterGui
    
    local ThemeTab = UI:Tab("Theme")
    
    -- Theme Colors Database
    local ThemeColors = {
        ["Default Purple"] = Color3.fromRGB(160, 32, 240),
        ["Ocean Blue"] = Color3.fromRGB(0, 150, 255),
        ["Fire Red"] = Color3.fromRGB(255, 50, 50),
        ["Emerald Green"] = Color3.fromRGB(0, 200, 100),
        ["Sunset Orange"] = Color3.fromRGB(255, 120, 0),
        ["Cyber Pink"] = Color3.fromRGB(255, 0, 150),
        ["Gold"] = Color3.fromRGB(255, 215, 0),
        ["Ice Blue"] = Color3.fromRGB(100, 200, 255),
        ["Dark Mode"] = Color3.fromRGB(30, 30, 40),
        ["Neon Cyan"] = Color3.fromRGB(0, 255, 255)
    }
    
    -- UI References Storage
    local UIRefs = {}
    
    -- Theme Preview Window
    local PreviewFrame = nil
    
    local function CreatePreviewWindow()
        if PreviewFrame then PreviewFrame:Destroy() end
        
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        PreviewFrame = Instance.new("Frame", screenGui)
        PreviewFrame.Name = "ThemePreview"
        PreviewFrame.Size = UDim2.new(0, 200, 0, 150)
        PreviewFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
        PreviewFrame.BackgroundColor3 = Theme.Main
        PreviewFrame.Visible = false
        PreviewFrame.ZIndex = 45
        
        local corner = Instance.new("UICorner", PreviewFrame)
        corner.CornerRadius = UDim.new(0, 10)
        
        local stroke = Instance.new("UIStroke", PreviewFrame)
        stroke.Color = Theme.Accent
        stroke.Thickness = 2
        
        local title = Instance.new("TextLabel", PreviewFrame)
        title.Size = UDim2.new(1, -10, 0, 25)
        title.Position = UDim2.new(0, 5, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = "THEME PREVIEW"
        title.TextColor3 = Theme.Accent
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 12
        
        local sampleButton = Instance.new("TextButton", PreviewFrame)
        sampleButton.Size = UDim2.new(0.8, 0, 0, 30)
        sampleButton.Position = UDim2.new(0.1, 0, 0.3, 0)
        sampleButton.BackgroundColor3 = Theme.Button
        sampleButton.Text = "Sample Button"
        sampleButton.TextColor3 = Color3.new(1, 1, 1)
        sampleButton.Font = Enum.Font.Gotham
        sampleButton.TextSize = 11
        
        local btnCorner = Instance.new("UICorner", sampleButton)
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        local sampleToggle = Instance.new("Frame", PreviewFrame)
        sampleToggle.Size = UDim2.new(0.8, 0, 0, 20)
        sampleToggle.Position = UDim2.new(0.1, 0, 0.6, 0)
        sampleToggle.BackgroundColor3 = Theme.Button
        
        local toggleCorner = Instance.new("UICorner", sampleToggle)
        toggleCorner.CornerRadius = UDim.new(0, 6)
        
        local toggleCircle = Instance.new("Frame", sampleToggle)
        toggleCircle.Size = UDim2.new(0, 16, 0, 16)
        toggleCircle.Position = UDim2.new(0.05, 0, 0.1, 0)
        toggleCircle.BackgroundColor3 = Theme.Accent
        
        local circleCorner = Instance.new("UICorner", toggleCircle)
        circleCorner.CornerRadius = UDim.new(1, 0)
        
        local closeBtn = Instance.new("TextButton", PreviewFrame)
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -25, 0, 5)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        
        closeBtn.MouseButton1Click:Connect(function()
            PreviewFrame.Visible = false
        end)
        
        -- Make draggable
        local dragging, dragStart, startPos
        PreviewFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = PreviewFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                PreviewFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        return PreviewFrame
    end
    
    local function UpdatePreview()
        if not PreviewFrame then return end
        
        -- Update all preview elements
        PreviewFrame.BackgroundColor3 = Theme.Main
        PreviewFrame.UIStroke.Color = Theme.Accent
        
        local title = PreviewFrame:FindFirstChildWhichIsA("TextLabel")
        if title then
            title.TextColor3 = Theme.Accent
        end
        
        local sampleButton = PreviewFrame:FindFirstChildWhichIsA("TextButton")
        if sampleButton and sampleButton.Name == "SampleButton" then
            sampleButton.BackgroundColor3 = Theme.Button
        end
        
        local sampleToggle = PreviewFrame:FindFirstChild("SampleToggle")
        if sampleToggle then
            sampleToggle.BackgroundColor3 = Theme.Button
            local circle = sampleToggle:FindFirstChildWhichIsA("Frame")
            if circle then
                circle.BackgroundColor3 = Theme.Accent
            end
        end
    end
    
    local function ApplyThemeToUI()
        -- Update main UI elements
        local screenGui = UI:GetScreenGui()
        if not screenGui then return end
        
        -- Update all UI elements with theme
        for _, gui in ipairs(screenGui:GetDescendants()) do
            if gui:IsA("Frame") then
                if gui.Name == "Main" then
                    gui.BackgroundColor3 = Theme.Main
                elseif gui.Name:find("Sidebar") then
                    gui.BackgroundColor3 = Theme.Sidebar
                end
            elseif gui:IsA("UIStroke") then
                if gui.Parent.Name == "Main" then
                    gui.Color = Theme.Accent
                elseif gui.Parent.Name == "Open" then
                    gui.Color = Theme.Accent
                end
            elseif gui:IsA("TextLabel") then
                if gui.Name == "Title" then
                    gui.TextColor3 = Theme.Accent
                end
            end
        end
        
        -- Update all tab buttons
        for _, child in ipairs(screenGui:GetDescendants()) do
            if child:IsA("TextButton") and child.Text ~= "X" and child.Text ~= "+" and child.Text ~= "_" then
                if child.BackgroundColor3 == Theme.Button or 
                   child.BackgroundColor3 == Theme.ButtonDark then
                    child.BackgroundColor3 = Theme.Button
                end
            end
        end
        
        -- Update preview if exists
        UpdatePreview()
        
        StarterGui:SetCore("SendNotification", {
            Title = "Theme Updated",
            Text = Config.CustomTheme or "Default",
            Duration = 2
        })
    end
    
    -- Theme Selection UI
    ThemeTab:Label("Color Themes")
    
    local ThemeContainer = ThemeTab:Container(150)
    
    local function CreateThemeButton(name, color)
        local btn = Instance.new("TextButton", ThemeContainer)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = color
        btn.Text = name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            Config.CustomColor = color
            Theme.Accent = color
            ApplyThemeToUI()
        end)
        
        return btn
    end
    
    -- Create theme buttons
    for themeName, themeColor in pairs(ThemeColors) do
        CreateThemeButton(themeName, themeColor)
    end
    
    -- Custom Color Picker
    ThemeTab:Label("Custom Color")
    
    local function CreateColorSlider(text, colorChannel)
        local frame = Instance.new("Frame", nil)
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundColor3 = Theme.Button
        
        local frameCorner = Instance.new("UICorner", frame)
        frameCorner.CornerRadius = UDim.new(0, 6)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.3, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": 255"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UIPadding", label).PaddingLeft = UDim.new(0, 10)
        
        local sliderBar = Instance.new("TextButton", frame)
        sliderBar.Size = UDim2.new(0.6, 0, 0.4, 0)
        sliderBar.Position = UDim2.new(0.35, 0, 0.3, 0)
        sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        sliderBar.Text = ""
        
        local fill = Instance.new("Frame", sliderBar)
        fill.Size = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(
            colorChannel == "R" and 255 or 0,
            colorChannel == "G" and 255 or 0,
            colorChannel == "B" and 255 or 0
        )
        
        local value = 255
        
        sliderBar.MouseButton1Down:Connect(function()
            local connection
            connection = Services.RunService.RenderStepped:Connect(function()
                local percent = math.clamp(
                    (Services.UserInputService:GetMouseLocation().X - sliderBar.AbsolutePosition.X) / 
                    sliderBar.AbsoluteSize.X,
                    0, 1
                )
                fill.Size = UDim2.new(percent, 0, 1, 0)
                value = math.floor(percent * 255)
                label.Text = text .. ": " .. value
                
                if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    connection:Disconnect()
                end
            end)
        end)
        
        local function GetValue()
            return value
        end
        
        local function SetValue(newValue)
            value = math.clamp(newValue, 0, 255)
            fill.Size = UDim2.new(value / 255, 0, 1, 0)
            label.Text = text .. ": " .. value
        end
        
        return frame, GetValue, SetValue
    end
    
    -- Create RGB sliders
    local rSlider, getR, setR = CreateColorSlider("Red", "R")
    local gSlider, getG, setG = CreateColorSlider("Green", "G")
    local bSlider, getB, setB = CreateColorSlider("Blue", "B")
    
    -- Add sliders to container
    local customContainer = ThemeTab:Container(120)
    
    local function AddToContainer(obj)
        obj.Parent = customContainer
    end
    
    AddToContainer(rSlider)
    AddToContainer(gSlider)
    AddToContainer(bSlider)
    
    -- Apply Custom Color Button
    ThemeTab:Button("Apply Custom Color", Theme.Confirm, function()
        local r = getR()
        local g = getG()
        local b = getB()
        
        Config.CustomColor = Color3.fromRGB(r, g, b)
        Theme.Accent = Config.CustomColor
        Config.RainbowTheme = false -- Turn off rainbow when using custom color
        
        ApplyThemeToUI()
    end)
    
    -- Rainbow Theme Toggle
    local rainbowToggle = ThemeTab:Toggle("Rainbow Theme", function(state)
        Config.RainbowTheme = state
        if state then
            StarterGui:SetCore("SendNotification", {
                Title = "Rainbow Mode",
                Text = "Colors will cycle!",
                Duration = 2
            })
        end
    end)
    
    -- Theme Intensity Slider
    ThemeTab:Slider("Theme Intensity", 0.5, 2, function(value)
        Config.ThemeIntensity = value
        -- Adjust theme colors based on intensity
        local intensity = value
        
        Theme.Main = Color3.fromRGB(
            math.clamp(20 * intensity, 10, 50),
            math.clamp(10 * intensity, 5, 30),
            math.clamp(30 * intensity, 15, 60)
        )
        
        Theme.Sidebar = Color3.fromRGB(
            math.clamp(30 * intensity, 15, 60),
            math.clamp(15 * intensity, 8, 40),
            math.clamp(45 * intensity, 20, 80)
        )
        
        ApplyThemeToUI()
    end)
    
    -- Theme Preview Toggle
    ThemeTab:Toggle("Show Theme Preview", function(state)
        if state then
            if not PreviewFrame then
                CreatePreviewWindow()
            end
            PreviewFrame.Visible = true
            UpdatePreview()
        elseif PreviewFrame then
            PreviewFrame.Visible = false
        end
    end)
    
    -- Reset to Default
    ThemeTab:Button("Reset to Default", Theme.ButtonRed, function()
        Config.CustomColor = Color3.fromRGB(160, 32, 240)
        Config.RainbowTheme = false
        Config.ThemeIntensity = 1
        
        Theme.Accent = Config.CustomColor
        Theme.Main = Color3.fromRGB(20, 10, 30)
        Theme.Sidebar = Color3.fromRGB(30, 15, 45)
        
        setR(160)
        setG(32)
        setB(240)
        
        rainbowToggle.SetState(false)
        ApplyThemeToUI()
    end)
    
    -- Save/Load Theme Profiles
    ThemeTab:Label("Theme Profiles")
    
    local function SaveThemeProfile(name)
        if not writefile or not makefolder then return end
        
        local themePath = "VanzyData/Themes"
        if not isfolder("VanzyData") then
            makefolder("VanzyData")
        end
        if not isfolder(themePath) then
            makefolder(themePath)
        end
        
        local profile = {
            Name = name,
            CustomColor = {Config.CustomColor.R, Config.CustomColor.G, Config.CustomColor.B},
            RainbowTheme = Config.RainbowTheme,
            ThemeIntensity = Config.ThemeIntensity or 1,
            Timestamp = os.date("%Y-%m-%d %H:%M:%S")
        }
        
        local fileName = name:gsub("[^%w]", "_") .. ".json"
        writefile(themePath .. "/" .. fileName, Services.HttpService:JSONEncode(profile))
        
        StarterGui:SetCore("SendNotification", {
            Title = "Theme Saved",
            Text = "Profile: " .. name,
            Duration = 2
        })
    end
    
    local function LoadThemeProfile(data)
        Config.CustomColor = Color3.fromRGB(data.CustomColor[1], data.CustomColor[2], data.CustomColor[3])
        Config.RainbowTheme = data.RainbowTheme
        Config.ThemeIntensity = data.ThemeIntensity or 1
        
        Theme.Accent = Config.CustomColor
        Theme.Main = Color3.fromRGB(20, 10, 30)
        Theme.Sidebar = Color3.fromRGB(30, 15, 45)
        
        setR(data.CustomColor[1])
        setG(data.CustomColor[2])
        setB(data.CustomColor[3])
        rainbowToggle.SetState(data.RainbowTheme)
        
        ApplyThemeToUI()
    end
    
    ThemeTab:Input("Profile Name", function(text)
        -- Store for save button
        Config.CurrentProfileName = text
    end)
    
    ThemeTab:Button("💾 Save Profile", Theme.Button, function()
        if Config.CurrentProfileName and Config.CurrentProfileName ~= "" then
            SaveThemeProfile(Config.CurrentProfileName)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "Enter profile name first!",
                Duration = 2
            })
        end
    end)
    
    local ProfileContainer = ThemeTab:Container(100)
    
    local function RefreshProfiles()
        if not ProfileContainer then return end
        
        for _, child in ipairs(ProfileContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        if not isfolder or not isfolder("VanzyData/Themes") then return end
        
        local files = listfiles("VanzyData/Themes")
        for _, file in ipairs(files) do
            if file:match("%.json$") then
                local fileName = file:match("[^/\\]+$"):gsub("%.json$", "")
                
                local btn = Instance.new("TextButton", ProfileContainer)
                btn.Size = UDim2.new(1, -10, 0, 25)
                btn.BackgroundColor3 = Theme.ButtonDark
                btn.Text = "📁 " .. fileName
                btn.TextColor3 = Theme.Text
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 10
                btn.TextXAlignment = Enum.TextXAlignment.Left
                
                local corner = Instance.new("UICorner", btn)
                corner.CornerRadius = UDim.new(0, 4)
                
                Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 10)
                
                local loadBtn = Instance.new("TextButton", btn)
                loadBtn.Size = UDim2.new(0, 40, 0.8, 0)
                loadBtn.Position = UDim2.new(0.7, 0, 0.1, 0)
                loadBtn.BackgroundColor3 = Theme.Confirm
                loadBtn.Text = "LOAD"
                loadBtn.TextColor3 = Color3.new(1, 1, 1)
                loadBtn.Font = Enum.Font.GothamBold
                loadBtn.TextSize = 8
                Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 3)
                
                loadBtn.MouseButton1Click:Connect(function()
                    local success, data = pcall(function()
                        local content = readfile(file)
                        return Services.HttpService:JSONDecode(content)
                    end)
                    
                    if success and data then
                        LoadThemeProfile(data)
                    end
                end)
                
                local delBtn = Instance.new("TextButton", btn)
                delBtn.Size = UDim2.new(0, 30, 0.8, 0)
                delBtn.Position = UDim2.new(0.9, -30, 0.1, 0)
                delBtn.BackgroundColor3 = Theme.ButtonRed
                delBtn.Text = "X"
                delBtn.TextColor3 = Color3.new(1, 1, 1)
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 9
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)
                
                delBtn.MouseButton1Click:Connect(function()
                    UI:Confirm("Delete profile '" .. fileName .. "'?", function()
                        delfile(file)
                        RefreshProfiles()
                    end)
                end)
            end
        end
    end
    
    ThemeTab:Button("🔄 Refresh Profiles", Theme.ButtonDark, RefreshProfiles)
    
    -- Initialize
    spawn(function()
        task.wait(1)
        RefreshProfiles()
    end)
    
    print("[Vanzyxxx] Theme Module Loaded")
    return true
end