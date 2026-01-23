-- Vanzyxxx Modular Executor - Mobile Friendly
-- Core Loader by Alfreadrorw1

-- SERVICES
local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    CoreGui = game:GetService("CoreGui"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
    TeleportService = game:GetService("TeleportService"),
    MarketplaceService = game:GetService("MarketplaceService")
}

-- GLOBALS
local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- CONFIG GLOBAL
local Config = {
    -- Movement
    FlySpeed = 50,
    Flying = false,
    Noclip = false,
    InfJump = false,
    SpeedHack = false,
    SpeedVal = 50,
    WallClimb = false,
    
    -- Visuals
    ESP_Box = false,
    ESP_Name = false,
    ESP_Health = false,
    
    -- UI
    MenuTitle = "Vanzyxxx",
    RainbowTheme = false,
    CustomColor = Color3.fromRGB(160, 32, 240),
    
    -- Checkpoint
    AutoPlaying = false,
    TapTP = false,
    LastSaveTime = 0,
    
    -- Events
    OnReset = Instance.new("BindableEvent"),
    OnFeatureLoaded = Instance.new("BindableEvent")
}

-- ASSETS & LINKS
local LogoURL = "https://files.catbox.moe/io8o2d.png"
local LocalPath = "VanzyLogo.jpg"
pcall(function() 
    if not isfile(LocalPath) then 
        writefile(LocalPath, game:HttpGet(LogoURL)) 
    end
end)
local FinalLogo = (getcustomasset and isfile(LocalPath)) and getcustomasset(LocalPath) or LogoURL

-- UI LIBRARY
local UILibrary = {}
local UIRefs = { MainFrame = nil, Sidebar = nil, Content = nil, Title = nil }

local Theme = {
    Main = Color3.fromRGB(20, 10, 30),
    Sidebar = Color3.fromRGB(30, 15, 45),
    Accent = Config.CustomColor,
    Text = Color3.fromRGB(255, 255, 255),
    Button = Color3.fromRGB(45, 25, 60),
    ButtonDark = Color3.fromRGB(35, 20, 50),
    ButtonRed = Color3.fromRGB(100, 30, 30),
    Confirm = Color3.fromRGB(40, 100, 40),
    PlayBtn = Color3.fromRGB(255, 170, 0)
}

-- Rainbow theme handler
spawn(function()
    while true do
        if Config.RainbowTheme then
            local hue = tick() % 5 / 5
            Theme.Accent = Color3.fromHSV(hue, 1, 1)
            Config.CustomColor = Theme.Accent
        else
            Theme.Accent = Config.CustomColor
        end
        if UIRefs.MainStroke then UIRefs.MainStroke.Color = Theme.Accent end
        if UIRefs.OpenBtnStroke then UIRefs.OpenBtnStroke.Color = Theme.Accent end
        if UIRefs.Title then UIRefs.Title.TextColor3 = Theme.Accent end
        task.wait(0.05)
    end
end)

function UILibrary:Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Vanzyxxx"
    ScreenGui.ResetOnSpawn = false
    
    local function GetGuiParent()
        if gethui then return gethui() end
        if syn and syn.protect_gui then 
            local sg = Instance.new("ScreenGui")
            syn.protect_gui(sg)
            sg.Parent = Services.CoreGui
            return sg
        end
        return Services.CoreGui
    end
    
    ScreenGui.Parent = GetGuiParent()
    
    -- Open Button
    local OpenBtn = Instance.new("ImageButton", ScreenGui)
    OpenBtn.Name = "Open"
    OpenBtn.Size = UDim2.new(0, 50, 0, 50)
    OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    OpenBtn.BackgroundColor3 = Theme.Main
    OpenBtn.Image = FinalLogo
    
    local OpenCorner = Instance.new("UICorner", OpenBtn)
    OpenCorner.CornerRadius = UDim.new(1, 0)
    
    local OS = Instance.new("UIStroke", OpenBtn)
    OS.Color = Theme.Accent
    OS.Thickness = 2
    UIRefs.OpenBtnStroke = OS
    
    -- Main Frame
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 400, 0, 220)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -110)
    MainFrame.BackgroundColor3 = Theme.Main
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    
    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 12)
    
    local MS = Instance.new("UIStroke", MainFrame)
    MS.Color = Theme.Accent
    MS.Thickness = 2
    UIRefs.MainFrame = MainFrame
    UIRefs.MainStroke = MS
    
    local UIScale = Instance.new("UIScale", MainFrame)
    UIScale.Scale = 0
    
    -- Title
    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, -100, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = Config.MenuTitle
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 16
    Title.TextColor3 = Theme.Accent
    Title.TextXAlignment = Enum.TextXAlignment.Left
    UIRefs.Title = Title
    
    -- Control Buttons
    local BtnContainer = Instance.new("Frame", MainFrame)
    BtnContainer.Size = UDim2.new(0, 120, 0, 30)
    BtnContainer.Position = UDim2.new(1, -125, 0, 0)
    BtnContainer.BackgroundTransparency = 1
    
    local CloseX = Instance.new("TextButton", BtnContainer)
    CloseX.Size = UDim2.new(0, 30, 0, 30)
    CloseX.Position = UDim2.new(1, -30, 0, 0)
    CloseX.BackgroundTransparency = 1
    CloseX.Text = "X"
    CloseX.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseX.Font = Enum.Font.GothamBlack
    CloseX.TextSize = 18
    
    local LayoutBtn = Instance.new("TextButton", BtnContainer)
    LayoutBtn.Size = UDim2.new(0, 30, 0, 30)
    LayoutBtn.Position = UDim2.new(1, -60, 0, 0)
    LayoutBtn.BackgroundTransparency = 1
    LayoutBtn.Text = "+"
    LayoutBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    LayoutBtn.Font = Enum.Font.GothamBlack
    LayoutBtn.TextSize = 20
    
    local MinBtn = Instance.new("TextButton", BtnContainer)
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -90, 0, 0)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Theme.Accent
    MinBtn.Font = Enum.Font.GothamBlack
    MinBtn.TextSize = 18
    
    -- Sidebar
    local Sidebar = Instance.new("ScrollingFrame", MainFrame)
    Sidebar.Size = UDim2.new(0, 110, 1, -35)
    Sidebar.Position = UDim2.new(0, 0, 0, 35)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.ScrollBarThickness = 0
    Sidebar.BorderSizePixel = 0
    UIRefs.Sidebar = Sidebar
    
    local SideLayout = Instance.new("UIListLayout", Sidebar)
    SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SideLayout.Padding = UDim.new(0, 6)
    
    local SidePadding = Instance.new("UIPadding", Sidebar)
    SidePadding.PaddingTop = UDim.new(0, 10)
    
    -- Content Area
    local Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, -110, 1, -35)
    Content.Position = UDim2.new(0, 110, 0, 35)
    Content.BackgroundTransparency = 1
    UIRefs.Content = Content
    
    -- Drag Function
    local function Drag(frame, handle)
        handle = handle or frame
        local dragging, dragStart, startPos
        
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    
    Drag(MainFrame)
    Drag(OpenBtn)
    
    -- Menu Toggle
    local function ToggleMenu(state)
        if state then
            MainFrame.Visible = true
            OpenBtn.Visible = false
            Services.TweenService:Create(UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Scale = 1}):Play()
        else
            local tween = Services.TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            tween:Play()
            tween.Completed:Connect(function()
                MainFrame.Visible = false
                OpenBtn.Visible = true
            end)
        end
    end
    
    -- Layout Toggle
    local isVertical = false
    local function ToggleLayout()
        isVertical = not isVertical
        if isVertical then
            LayoutBtn.Text = "-"
            Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 220, 0, 400)}):Play()
            Sidebar.Size = UDim2.new(0, 60, 1, -35)
            Content.Size = UDim2.new(1, -60, 1, -35)
            Content.Position = UDim2.new(0, 60, 0, 35)
            MainFrame.Position = UDim2.new(0.5, -110, 0.5, -200)
        else
            LayoutBtn.Text = "+"
            Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 400, 0, 220)}):Play()
            Sidebar.Size = UDim2.new(0, 110, 1, -35)
            Content.Size = UDim2.new(1, -110, 1, -35)
            Content.Position = UDim2.new(0, 110, 0, 35)
            MainFrame.Position = UDim2.new(0.5, -200, 0.5, -110)
        end
    end
    
    OpenBtn.MouseButton1Click:Connect(function() ToggleMenu(true) end)
    MinBtn.MouseButton1Click:Connect(function() ToggleMenu(false) end)
    LayoutBtn.MouseButton1Click:Connect(ToggleLayout)
    
    -- Confirmation Popup
    local GlobalPopup = Instance.new("Frame", ScreenGui)
    GlobalPopup.Size = UDim2.new(0, 240, 0, 130)
    GlobalPopup.Position = UDim2.new(0.5, -120, 0.5, -65)
    GlobalPopup.BackgroundColor3 = Theme.Main
    GlobalPopup.Visible = false
    GlobalPopup.ZIndex = 50
    
    local PopupCorner = Instance.new("UICorner", GlobalPopup)
    PopupCorner.CornerRadius = UDim.new(0, 12)
    
    local PopupStroke = Instance.new("UIStroke", GlobalPopup)
    PopupStroke.Color = Theme.Accent
    PopupStroke.Thickness = 2
    
    local GPTitle = Instance.new("TextLabel", GlobalPopup)
    GPTitle.Size = UDim2.new(1, 0, 0, 30)
    GPTitle.BackgroundTransparency = 1
    GPTitle.Text = "CONFIRMATION"
    GPTitle.TextColor3 = Theme.Accent
    GPTitle.Font = Enum.Font.GothamBlack
    GPTitle.TextSize = 14
    GPTitle.ZIndex = 51
    
    local GPDesc = Instance.new("TextLabel", GlobalPopup)
    GPDesc.Size = UDim2.new(0.9, 0, 0.4, 0)
    GPDesc.Position = UDim2.new(0.05, 0, 0.25, 0)
    GPDesc.BackgroundTransparency = 1
    GPDesc.Text = "Are you sure?"
    GPDesc.TextColor3 = Theme.Text
    GPDesc.Font = Enum.Font.Gotham
    GPDesc.TextSize = 12
    GPDesc.TextWrapped = true
    GPDesc.ZIndex = 51
    
    local GPYes = Instance.new("TextButton", GlobalPopup)
    GPYes.Size = UDim2.new(0.4, 0, 0.25, 0)
    GPYes.Position = UDim2.new(0.05, 0, 0.7, 0)
    GPYes.BackgroundColor3 = Theme.Confirm
    GPYes.Text = "YES"
    GPYes.TextColor3 = Theme.Text
    GPYes.ZIndex = 51
    
    local GPYesCorner = Instance.new("UICorner", GPYes)
    GPYesCorner.CornerRadius = UDim.new(0, 6)
    
    local GPNo = Instance.new("TextButton", GlobalPopup)
    GPNo.Size = UDim2.new(0.4, 0, 0.25, 0)
    GPNo.Position = UDim2.new(0.55, 0, 0.7, 0)
    GPNo.BackgroundColor3 = Theme.ButtonRed
    GPNo.Text = "NO"
    GPNo.TextColor3 = Theme.Text
    GPNo.ZIndex = 51
    
    local GPNoCorner = Instance.new("UICorner", GPNo)
    GPNoCorner.CornerRadius = UDim.new(0, 6)
    
    local PopupAction = nil
    GPNo.MouseButton1Click:Connect(function()
        GlobalPopup.Visible = false
        PopupAction = nil
    end)
    
    GPYes.MouseButton1Click:Connect(function()
        if PopupAction then PopupAction() end
        GlobalPopup.Visible = false
    end)
    
    -- Tab System
    local Tabs = {}
    
    function UILibrary:Tab(name)
        local TabButton = Instance.new("TextButton", Sidebar)
        TabButton.Size = UDim2.new(0.85, 0, 0, 28)
        TabButton.BackgroundColor3 = Theme.Button
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 10
        
        local ButtonCorner = Instance.new("UICorner", TabButton)
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        
        local TabContent = Instance.new("ScrollingFrame", Content)
        TabContent.Size = UDim2.new(1, -5, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 2
        TabContent.Visible = false
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local ContentLayout = Instance.new("UIListLayout", TabContent)
        ContentLayout.Padding = UDim.new(0, 5)
        
        local ContentPadding = Instance.new("UIPadding", TabContent)
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Tabs) do
                tab.Content.Visible = false
                tab.Button.BackgroundColor3 = Theme.Button
                tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Theme.Accent
            TabButton.TextColor3 = Color3.new(1, 1, 1)
        end)
        
        table.insert(Tabs, {Button = TabButton, Content = TabContent})
        
        local Elements = {}
        
        function Elements:Button(text, color, callback)
            local button = Instance.new("TextButton", TabContent)
            button.Size = UDim2.new(1, 0, 0, 26)
            button.BackgroundColor3 = color or Theme.Button
            button.Text = text
            button.TextColor3 = Color3.new(1, 1, 1)
            button.Font = Enum.Font.Gotham
            button.TextSize = 11
            
            local btnCorner = Instance.new("UICorner", button)
            btnCorner.CornerRadius = UDim.new(0, 6)
            
            button.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
        end
        
        function Elements:Toggle(text, callback)
            local frame = Instance.new("Frame", TabContent)
            frame.Size = UDim2.new(1, 0, 0, 26)
            frame.BackgroundColor3 = Theme.Button
            
            local frameCorner = Instance.new("UICorner", frame)
            frameCorner.CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(0.65, 0, 1, 0)
            label.Position = UDim2.new(0.05, 0, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 11
            
            local toggleButton = Instance.new("TextButton", frame)
            toggleButton.Size = UDim2.new(0, 30, 0, 18)
            toggleButton.Position = UDim2.new(0.75, 0, 0.15, 0)
            toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            toggleButton.Text = ""
            
            local toggleCorner = Instance.new("UICorner", toggleButton)
            toggleCorner.CornerRadius = UDim.new(1, 0)
            
            local state = false
            toggleButton.MouseButton1Click:Connect(function()
                state = not state
                toggleButton.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 60, 60)
                callback(state)
            end)
        end
        
        function Elements:Input(placeholder, callback)
            local frame = Instance.new("Frame", TabContent)
            frame.Size = UDim2.new(1, 0, 0, 26)
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            
            local frameCorner = Instance.new("UICorner", frame)
            frameCorner.CornerRadius = UDim.new(0, 6)
            
            local textBox = Instance.new("TextBox", frame)
            textBox.Size = UDim2.new(0.9, 0, 1, 0)
            textBox.Position = UDim2.new(0.05, 0, 0, 0)
            textBox.BackgroundTransparency = 1
            textBox.Text = ""
            textBox.PlaceholderText = placeholder
            textBox.TextColor3 = Color3.new(1, 1, 1)
            textBox.Font = Enum.Font.Gotham
            textBox.TextSize = 11
            
            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                callback(textBox.Text)
            end)
        end
        
        function Elements:Label(text)
            local label = Instance.new("TextLabel", TabContent)
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Theme.Accent
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        function Elements:Slider(text, min, max, callback)
            local frame = Instance.new("Frame", TabContent)
            frame.Size = UDim2.new(1, 0, 0, 32)
            frame.BackgroundColor3 = Theme.Button
            
            local frameCorner = Instance.new("UICorner", frame)
            frameCorner.CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1, 0, 0.5, 0)
            label.Position = UDim2.new(0.05, 0, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local sliderBar = Instance.new("TextButton", frame)
            sliderBar.Size = UDim2.new(0.9, 0, 0.3, 0)
            sliderBar.Position = UDim2.new(0.05, 0, 0.6, 0)
            sliderBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            sliderBar.Text = ""
            
            local fill = Instance.new("Frame", sliderBar)
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            
            sliderBar.MouseButton1Down:Connect(function()
                local connection
                connection = Services.RunService.RenderStepped:Connect(function()
                    local percent = math.clamp(
                        (Services.UserInputService:GetMouseLocation().X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X,
                        0, 1
                    )
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    callback(min + (max - min) * percent)
                    
                    if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        connection:Disconnect()
                    end
                end)
            end)
        end
        
        function Elements:Container(height)
            local container = Instance.new("ScrollingFrame", TabContent)
            container.Size = UDim2.new(1, 0, 0, height)
            container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            container.ScrollBarThickness = 2
            
            local containerCorner = Instance.new("UICorner", container)
            containerCorner.CornerRadius = UDim.new(0, 6)
            
            local layout = Instance.new("UIListLayout", container)
            layout.Padding = UDim.new(0, 2)
            container.AutomaticCanvasSize = Enum.AutomaticSize.Y
            
            return container
        end
        
        return Elements
    end
    
    function UILibrary:Confirm(text, callback)
        GPDesc.Text = text
        PopupAction = callback
        GlobalPopup.Visible = true
    end
    
    -- Close Button Logic
    CloseX.MouseButton1Click:Connect(function()
        UILibrary:Confirm("Close script?", function()
            Config.Flying = false
            Config.SpeedHack = false
            Config.TapTP = false
            
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.WalkSpeed = 16
                end
                
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                    if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
                    if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
                end
            end
            
            Config.OnReset:Fire()
            ScreenGui:Destroy()
        end)
    end)
    
    return UILibrary, ScreenGui
end

-- Create UI
local UI, ScreenGui = UILibrary:Create()

-- FEATURE LOADER SYSTEM
local FeatureLoader = {
    LoadedFeatures = {},
    FeatureErrors = {}
}

function FeatureLoader:LoadFromGitHub(folder, baseURL)
    local featureFolders = {
        "Movement",
        "Visual",
        "Aura",
        "Checkpoint",
        "Settings"
    }
    
    Services.StarterGui:SetCore("SendNotification", {
        Title = "Vanzyxxx",
        Text = "Loading features..."
    })
    
    for _, folderName in pairs(featureFolders) do
        -- Create Tab for folder
        local tab = UI:Tab(folderName)
        
        -- Load all features in this folder
        local features = {
            ["Movement"] = {"fly", "speed", "infinityJump", "noclip", "wallClimb"},
            ["Visual"] = {"esp", "fullbright", "sky"},
            ["Aura"] = {"aura"},
            ["Checkpoint"] = {"saveLoadCP", "autoPlay"},
            ["Settings"] = {"theme", "fpsBoost"}
        }
        
        if features[folderName] then
            for _, featureName in pairs(features[folderName]) do
                local featureURL = baseURL .. folderName .. "/" .. featureName .. ".lua"
                
                pcall(function()
                    Services.StarterGui:SetCore("SendNotification", {
                        Title = "Loading",
                        Text = "Loading " .. featureName .. ".lua..."
                    })
                    
                    local success, featureFunc = pcall(function()
                        return loadstring(game:HttpGet(featureURL))()
                    end)
                    
                    if success and type(featureFunc) == "function" then
                        featureFunc(UI, Services, Config, Theme)
                        FeatureLoader.LoadedFeatures[featureName] = true
                        
                        Services.StarterGui:SetCore("SendNotification", {
                            Title = "Success",
                            Text = featureName .. " loaded!"
                        })
                    else
                        FeatureLoader.FeatureErrors[featureName] = "Failed to load"
                        warn("Failed to load feature: " .. featureName)
                    end
                end)
                
                task.wait(0.5) -- Prevent rate limiting
            end
        end
    end
    
    -- Summary notification
    local loadedCount = 0
    for _ in pairs(FeatureLoader.LoadedFeatures) do
        loadedCount = loadedCount + 1
    end
    
    Services.StarterGui:SetCore("SendNotification", {
        Title = "Vanzyxxx",
        Text = "Loaded " .. loadedCount .. " features!",
        Duration = 5
    })
    
    if next(FeatureLoader.FeatureErrors) then
        warn("Some features failed to load:")
        for feature, error in pairs(FeatureLoader.FeatureErrors) do
            warn("  " .. feature .. ": " .. error)
        end
    end
end

-- Anti-AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame)
end)

-- Start loading features
Services.StarterGui:SetCore("SendNotification", {
    Title = "Vanzyxxx",
    Text = "Modular V6 Loading...",
    Duration = 3
})

-- Load features from GitHub
FeatureLoader:LoadFromGitHub("features", "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/main/")

return {
    UI = UI,
    Services = Services,
    Config = Config,
    Theme = Theme,
    ScreenGui = ScreenGui
}